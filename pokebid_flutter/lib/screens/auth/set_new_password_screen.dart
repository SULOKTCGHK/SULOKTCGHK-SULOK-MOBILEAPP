import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../i18n/strings.dart';

/// 收到重設連結、進入 recovery session 後，設定新密碼
class SetNewPasswordScreen extends StatefulWidget {
  const SetNewPasswordScreen({super.key});

  @override
  State<SetNewPasswordScreen> createState() => _SetNewPasswordScreenState();
}

class _SetNewPasswordScreenState extends State<SetNewPasswordScreen> {
  final _pwCtrl = TextEditingController();
  final _pw2Ctrl = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pwCtrl.dispose();
    _pw2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pw = _pwCtrl.text;
    if (pw.length < 6) { setState(() => _error = L.errEnterPassword); return; }
    if (pw != _pw2Ctrl.text) { setState(() => _error = L.errPasswordMismatch); return; }
    setState(() { _busy = true; _error = null; });
    final err = await AuthService.updatePassword(pw);
    if (!mounted) return;
    if (err == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L.passwordUpdated), duration: const Duration(seconds: 2)));
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
        automaticallyImplyLeading: false,
        title: Text(L.setNewPasswordTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _label(L.newPasswordLabel),
          _field(_pwCtrl, L.passwordHint),
          const SizedBox(height: 14),
          _label(L.confirmPasswordLabel),
          _field(_pw2Ctrl, L.passwordHint),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontSize: 12.5, color: Color(0xFFDC2626))),
          ],
          const SizedBox(height: 22),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _busy ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8A52A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _busy
                  ? const SizedBox(width: 22, height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(L.saveBtn, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      );

  Widget _field(TextEditingController c, String hint) => TextField(
        controller: c,
        obscureText: true,
        style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
          filled: true, fillColor: const Color(0xFFF9FAFB),
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
