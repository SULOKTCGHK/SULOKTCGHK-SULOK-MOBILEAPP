import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/main_shell.dart';
import 'screens/auth/login_screen.dart';
import 'services/api_service.dart';
import 'services/profile_service.dart';
import 'config/env.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Env.assertValid();

  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Pre-fetch Traditional Chinese set names in background (non-blocking)
  PokemonApiService.fetchZhTwSetNames();

  runApp(const PokeBidApp());
}

class PokeBidApp extends StatelessWidget {
  const PokeBidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PokeBid',
      debugShowCheckedModeBanner: false,
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
      // 登入後確保已建立個人檔案（id = 帳號 uid）
      if (data.session != null) {
        await ProfileService.getOrCreateMyProfile();
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
