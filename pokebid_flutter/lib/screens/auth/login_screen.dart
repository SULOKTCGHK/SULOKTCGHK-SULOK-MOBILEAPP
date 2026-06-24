import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../main_shell.dart';
import '../../i18n/strings.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;

  Future<void> _googleSignIn() async {
    setState(() => _loading = true);
    await AuthService.signInWithGoogle();
    if (mounted) setState(() => _loading = false);
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
                    TextSpan(text: 'Poke'),
                    TextSpan(text: 'Bid',
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
