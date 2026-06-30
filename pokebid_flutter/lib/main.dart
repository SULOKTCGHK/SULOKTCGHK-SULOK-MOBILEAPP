import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/main_shell.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/set_new_password_screen.dart';
import 'services/api_service.dart';
import 'services/profile_service.dart';
import 'services/push_service.dart';
import 'config/env.dart';
import 'firebase_options.dart';
import 'i18n/locale_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.assertValid();

  // 載入已儲存的語言設定
  await LocaleController.instance.load();

  // Firebase / Push 只在行動平台（iOS / Android）初始化。
  // Web 與桌面（macOS 等）沒有對應的 Firebase 設定，會 throw → 白畫面，故略過。
  final isMobile = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  // Firebase 初始化失敗不致命（推播屬選用功能）：記錄後繼續，避免白畫面。
  bool firebaseReady = false;
  if (isMobile) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      firebaseReady = true;
    } catch (e, st) {
      debugPrint('Firebase 初始化失敗（略過推播）：$e\n$st');
    }
  }

  // Crashlytics：Firebase 初始化成功時，自動收集未捕捉的錯誤與閃退。
  // - FlutterError.onError：捕捉 widget/framework 同步錯誤
  // - PlatformDispatcher.onError：捕捉未被 catch 的非同步錯誤
  if (firebaseReady) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Supabase 是核心（登入/資料），失敗則顯示錯誤畫面而非白畫面。
  String? fatalError;
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  } catch (e, st) {
    fatalError = 'Supabase 初始化失敗：$e';
    debugPrint('$fatalError\n$st');
    if (firebaseReady) {
      FirebaseCrashlytics.instance
          .recordError(e, st, reason: 'Supabase init failed', fatal: true);
    }
  }

  // Pre-fetch Traditional Chinese set names in background (non-blocking)
  PokemonApiService.fetchZhTwSetNames();

  if (fatalError != null) {
    runApp(_StartupErrorApp(message: fatalError));
    return;
  }

  runApp(const PokeBidApp());

  // 推播初始化「不」阻塞啟動：放在 runApp 之後 fire-and-forget。
  // 若在 runApp 前 await，iOS 上一旦卡住（如等待權限/APNs）就會永遠白畫面。
  if (isMobile) {
    PushService.init().catchError((Object e, StackTrace st) {
      debugPrint('Push 初始化失敗（略過）：$e\n$st');
    });
  }
}

// 啟動失敗時顯示的畫面（取代白畫面，方便看到原因）。
class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text('App 啟動失敗',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PokeBidApp extends StatelessWidget {
  const PokeBidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: LocaleController.instance,
      builder: (context, locale, _) {
        // 確保當前語言的系列名稱已抓取（各語言只抓一次，抓完會自動刷新）
        PokemonApiService.fetchSetNames();
        return MaterialApp(
          title: 'TCGspot',
          debugShowCheckedModeBanner: false,
          navigatorKey: PushService.navigatorKey,
          locale: locale,
          supportedLocales: const [Locale('zh'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFE8A52A),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F6FA),
            useMaterial3: true,
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

// Auth gate — decides whether to show login or main app
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    // Listen for auth state changes (login, logout, token refresh, deep link callback)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      // 點擊重設密碼連結 → 進入設定新密碼畫面
      if (data.event == AuthChangeEvent.passwordRecovery) {
        PushService.navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const SetNewPasswordScreen()));
        return;
      }
      // 先依 session 狀態切換畫面，不被後續工作阻塞（否則登入後卡在登入頁）。
      if (mounted) setState(() {});
      if (data.session != null) {
        // 建立/取得個人檔案；失敗不阻塞導航。
        try {
          await ProfileService.getOrCreateMyProfile();
        } catch (e, st) {
          debugPrint('getOrCreateMyProfile 失敗：$e\n$st');
        }
        // 登入後儲存 FCM token：fire-and-forget，避免卡住導航。
        if (!kIsWeb) {
          PushService.init().catchError((Object e, StackTrace st) {
            debugPrint('Push 初始化失敗（略過）：$e\n$st');
          });
        }
        if (mounted) setState(() {});
      }
    });
    if (Supabase.instance.client.auth.currentSession != null) {
      ProfileService.getOrCreateMyProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      return const MainShell();
    }
    return const LoginScreen();
  }
}
