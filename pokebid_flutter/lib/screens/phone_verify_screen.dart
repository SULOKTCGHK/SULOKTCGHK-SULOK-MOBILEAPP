import 'package:flutter/material.dart';
import '../services/verification_service.dart';
import '../i18n/strings.dart';

class PhoneVerifyScreen extends StatefulWidget {
  const PhoneVerifyScreen({super.key});

  @override
  State<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends State<PhoneVerifyScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _sent = false;
  bool _busy = false;
  String? _error;
  String _fullPhone = '';

  String _normalize(String raw) {
    var p = raw.trim().replaceAll(RegExp(r'[\s-]'), '');
    if (p.startsWith('+')) return p;
    // 預設香港 +852
    return '+852$p';
  }

  Future<void> _send() async {
    final phone = _normalize(_phoneCtrl.text);
    if (phone.length < 8) { setState(() => _error = L.errInvalidPhone); return; }
    setState(() { _busy = true; _error = null; });
    final err = await VerificationService.send(phone);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (err == null) { _sent = true; _fullPhone = phone; }
      else { _error = err; }
    });
  }

  Future<void> _verify() async {
    if (_otpCtrl.text.trim().length < 4) { setState(() => _error = L.errEnterOtp); return; }
    setState(() { _busy = true; _error = null; });
    final ok = await VerificationService.check(_fullPhone, _otpCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.whatsappVerifySuccess), duration: const Duration(seconds: 2)));
      Navigator.pop(context, true);
    } else {
      setState(() { _busy = false; _error = L.otpWrongOrExpired; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0.5,
        foregroundColor: const Color(0xFF111827),
        title: Text(L.whatsappVerify, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.verified, size: 48, color: Color(0xFF25D366)),
          const SizedBox(height: 12),
          Text(L.verifyPhoneTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          Text(L.verifyPhoneDesc,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5)),
          const SizedBox(height: 24),

          if (!_sent) ...[
            Text(L.phoneNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixText: '+852 ', hintText: '92345678',
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 4),
            Text(L.otherRegionNote, style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
          ] else ...[
            Text(L.otpSentTo(_fullPhone),
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
            const SizedBox(height: 12),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: L.enterOtpHint,
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(onPressed: _busy ? null : () => setState(() { _sent = false; _otpCtrl.clear(); }),
                child: Text(L.reenterNumber)),
          ],

          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity, height: 46,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8A52A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _busy ? null : (_sent ? _verify : _send),
              child: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_sent ? L.confirmVerify : L.sendOtp,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
