import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
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

  // Firebase（Web 略過，避免未設定時 crash）
  if (!kIsWeb) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Push notification 初始化（非 Web）
  if (!kIsWeb) {
    await PushService.init();
  }

  // Pre-fetch Traditional Chinese set names in background (non-blocking)
  PokemonApiService.fetchZhTwSetNames();

  runApp(const PokeBidApp());
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
      if (data.session != null) {
        await ProfileService.getOrCreateMyProfile();
        // 登入後儲存 FCM token
        if (!kIsWeb) await PushService.init();
      }
      if (mounted) setState(() {});
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
