import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/verification_service.dart';
import '../../i18n/strings.dart';

/// Email + 電話（SMS 認證）註冊。電郵不需認證；SMS 通過才建立帳號。
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _sent = false;       // 已發送 SMS
  bool _busy = false;
  String? _error;
  String _fullPhone = '';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _pwCtrl.dispose();
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  String _normalizePhone(String raw) {
    var p = raw.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (p.startsWith('+')) return p;
    return '+852$p'; // 預設香港
  }

  bool _validEmail(String e) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);

  // 第一步：驗證輸入 → 發送 SMS 驗證碼
  Future<void> _sendCode() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pw = _pwCtrl.text;
    final phone = _normalizePhone(_phoneCtrl.text);
    if (name.isEmpty) { setState(() => _error = L.errEnterDisplayName); return; }
    if (!_validEmail(email)) { setState(() => _error = L.errEnterEmail); return; }
    if (pw.length < 6) { setState(() => _error = L.errEnterPassword); return; }
    if (phone.length < 8) { setState(() => _error = L.errInvalidPhone); return; }

    setState(() { _busy = true; _error = null; });
    final err = await VerificationService.sendForRegister(phone);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (err == null) { _sent = true; _fullPhone = phone; }
      else { _error = err; }
    });
  }

  // 第二步：驗證 SMS → 通過才建立帳號
  Future<void> _complete() async {
    if (_otpCtrl.text.trim().length < 4) { setState(() => _error = L.errEnterOtp); return; }
    setState(() { _busy = true; _error = null; });

    final ok = await VerificationService.checkForRegister(_fullPhone, _otpCtrl.text.trim());
    if (!mounted) return;
    if (!ok) { setState(() { _busy = false; _error = L.otpWrongOrExpired; }); return; }

    // SMS 通過 → 建立帳號
    final err = await AuthService.signUpWithEmail(
      email: _emailCtrl.text.trim(),
      password: _pwCtrl.text,
      phone: _fullPhone,
      displayName: _nameCtrl.text.trim(),
    );
    if (!mounted) return;
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L.registerSuccess), duration: const Duration(seconds: 2)));
      Navigator.pop(context, true);
    } else {
      setState(() { _busy = false; _error = err; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0.5,
        foregroundColor: const Color(0xFF111827),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF374151), size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(L.registerTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(L.registerSmsNote,
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), height: 1.5)),
          const SizedBox(height: 18),

          _label(L.displayNameLabel),
          _field(_nameCtrl, L.displayNameHint, enabled: !_sent),
          const SizedBox(height: 14),

          _label(L.emailLabel),
          _field(_emailCtrl, L.emailHint, keyboard: TextInputType.emailAddress, enabled: !_sent),
          const SizedBox(height: 14),

          _label(L.passwordLabel),
          _field(_pwCtrl, L.passwordHint, obscure: true, enabled: !_sent),
          const SizedBox(height: 14),

          _label(L.phoneNumber),
          _field(_phoneCtrl, '+852 1234 5678', keyboard: TextInputType.phone, enabled: !_sent),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(L.otherRegionNote,
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ),

          if (_sent) ...[
            const SizedBox(height: 14),
            _label(L.enterOtpHint),
            _field(_otpCtrl, '______', keyboard: TextInputType.number),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(L.otpSentTo(_fullPhone),
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF16A34A))),
            ),
          ],

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontSize: 12.5, color: Color(0xFFDC2626))),
          ],

          const SizedBox(height: 22),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _busy ? null : (_sent ? _complete : _sendCode),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8A52A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _busy
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_sent ? L.completeRegister : L.sendSmsCode,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),

          if (_sent) ...[
            const SizedBox(height: 10),
            Center(child: TextButton(
              onPressed: _busy ? null : () => setState(() { _sent = false; _otpCtrl.clear(); _error = null; }),
              child: Text(L.reenterNumber,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
            )),
          ],
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      );

  Widget _field(TextEditingController c, String hint,
      {bool obscure = false, bool enabled = true, TextInputType? keyboard}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      enabled: enabled,
      keyboardType: keyboard,
      style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        filled: true,
        fillColor: enabled ? const Color(0xFFF9FAFB) : const Color(0xFFEFF1F3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFE8A52A), width: 1)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}
