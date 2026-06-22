import 'package:supabase_flutter/supabase_flutter.dart';

/// WhatsApp 電話認證（呼叫 whatsapp-verify Edge Function）
class VerificationService {
  static final _client = Supabase.instance.client;

  static String? get _token => _client.auth.currentSession?.accessToken;

  /// 發送 WhatsApp 驗證碼；回傳 null=成功，否則錯誤訊息
  static Future<String?> send(String phone) async {
    final token = _token;
    if (token == null) return '請先登入';
    try {
      final res = await _client.functions.invoke(
        'whatsapp-verify',
        body: {'action': 'send', 'phone': phone},
      );
      if (res.status == 200 && (res.data?['ok'] == true)) return null;
      return (res.data?['error'] as String?) ?? '發送失敗 (${res.status})';
    } on FunctionException catch (e) {
      final d = e.details;
      if (d is Map && d['error'] != null) return '${d['error']} (${e.status})';
      return '發送失敗 (${e.status})';
    } catch (e) {
      return '發送失敗：$e';
    }
  }

  /// 驗證碼檢查；成功回 true（後端會設定 phone_verified）
  static Future<bool> check(String phone, String code) async {
    try {
      final res = await _client.functions.invoke(
        'whatsapp-verify',
        body: {'action': 'check', 'phone': phone, 'code': code},
      );
      return res.status == 200 && (res.data?['verified'] == true);
    } catch (_) {
      return false;
    }
  }
}
