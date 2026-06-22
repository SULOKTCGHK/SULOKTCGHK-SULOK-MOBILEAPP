import 'package:flutter/material.dart';
import '../services/verification_service.dart';

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
    if (phone.length < 8) { setState(() => _error = '請輸入有效電話號碼'); return; }
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
    if (_otpCtrl.text.trim().length < 4) { setState(() => _error = '請輸入驗證碼'); return; }
    setState(() { _busy = true; _error = null; });
    final ok = await VerificationService.check(_fullPhone, _otpCtrl.text.trim());
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp 認證成功 ✓'), duration: Duration(seconds: 2)));
      Navigator.pop(context, true);
    } else {
      setState(() { _busy = false; _error = '驗證碼錯誤或已過期'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0.5,
        foregroundColor: const Color(0xFF111827),
        title: const Text('WhatsApp 認證', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Icon(Icons.verified, size: 48, color: Color(0xFF25D366)),
          const SizedBox(height: 12),
          const Text('用 WhatsApp 認證電話',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const SizedBox(height: 6),
          const Text('驗證碼會透過 WhatsApp 發送。認證後，你的用戶名旁會顯示「已認證」標誌，提升交易信任度。',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5)),
          const SizedBox(height: 24),

          if (!_sent) ...[
            const Text('電話號碼', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
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
            const Text('其他地區請自行輸入 +國碼', style: TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
          ] else ...[
            Text('已透過 WhatsApp 發送驗證碼至 $_fullPhone',
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
            const SizedBox(height: 12),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '輸入 6 位數驗證碼',
                filled: true, fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 6),
            TextButton(onPressed: _busy ? null : () => setState(() { _sent = false; _otpCtrl.clear(); }),
                child: const Text('重新輸入號碼')),
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
                  : Text(_sent ? '確認驗證' : '發送驗證碼',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
