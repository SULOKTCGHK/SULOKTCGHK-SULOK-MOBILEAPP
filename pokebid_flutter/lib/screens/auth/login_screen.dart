import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../services/auth_service.dart';
import '../main_shell.dart';
import '../../i18n/strings.dart';
import 'email_login_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  // Apple 登入按鈕只在 Apple 平台顯示（Apple 規定 iOS 上必須提供）
  bool get _showApple =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    await AuthService.signInWithGoogle();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _appleSignIn() async {
    setState(() => _loading = true);
    final error = await AuthService.signInWithApple();
    if (mounted) setState(() => _loading = false);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9EC),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                ),
                child: const Center(
                  child: Text('🎴', style: TextStyle(fontSize: 40)),
                ),
              ),
              const SizedBox(height: 20),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                      color: Color(0xFF111827)),
                  children: [
                    TextSpan(text: 'TCG'),
                    TextSpan(text: 'spot',
                        style: TextStyle(color: Color(0xFFE8A52A))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                L.loginTagline,
                style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
              ),

              const Spacer(flex: 2),

              _featureRow('🎴', L.featBrowseTitle, L.featBrowseSub),
              const SizedBox(height: 14),
              _featureRow('💬', L.featChatTitle, L.featChatSub),
              const SizedBox(height: 14),
              _featureRow('📊', L.featRecordTitle, L.featRecordSub),

              const Spacer(flex: 2),

              // Sign in with Apple（Apple 平台才顯示，App Store 規定）
              if (_showApple && !_loading) ...[
                SignInWithAppleButton(
                  onPressed: _appleSignIn,
                  text: L.signInAppleBtn,
                  height: 50,
                  style: SignInWithAppleButtonStyle.black,
                  borderRadius: BorderRadius.circular(14),
                ),
                const SizedBox(height: 12),
              ],

              // Google Sign In button
              _loading
                  ? const CircularProgressIndicator(
                      color: Color(0xFFE8A52A), strokeWidth: 2)
                  : GestureDetector(
                      onTap: _googleSignIn,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8, offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 22, height: 22,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Center(
                                child: Text('G',
                                    style: TextStyle(fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF4285F4))),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(L.signInGoogleBtn,
                                style: const TextStyle(fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151))),
                          ],
                        ),
                      ),
                    ),
              const SizedBox(height: 14),

              // 電郵登入 / 建立帳號
              if (!_loading)
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const EmailLoginScreen())),
                    child: Text(L.loginEmailTitle,
                        style: const TextStyle(fontSize: 13.5, color: Color(0xFF374151), fontWeight: FontWeight.w600)),
                  ),
                  const Text('·', style: TextStyle(color: Color(0xFFD1D5DB))),
                  TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen())),
                    child: Text(L.registerTitle,
                        style: const TextStyle(fontSize: 13.5, color: Color(0xFFE8A52A), fontWeight: FontWeight.w700)),
                  ),
                ]),
              const SizedBox(height: 6),

              GestureDetector(
                onTap: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const MainShell()),
                ),
                child: Text(L.browseWithoutLogin,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF),
                        decoration: TextDecoration.underline)),
              ),
              const SizedBox(height: 12),
              Text(L.loginAgreement,
                  style: const TextStyle(fontSize: 11, color: Color(0xFFD1D5DB)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureRow(String emoji, String title, String subtitle) {
    return Row(children: [
      Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF9EC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 14,
            fontWeight: FontWeight.w500, color: Color(0xFF111827))),
        Text(subtitle, style: const TextStyle(fontSize: 12,
            color: Color(0xFF9CA3AF))),
      ]),
    ]);
  }
}
