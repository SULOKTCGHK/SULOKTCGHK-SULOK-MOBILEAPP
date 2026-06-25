import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// 檢舉服務。target_type: 'listing' | 'user' | 'message' | 'review'
class ReportService {
  static final _client = Supabase.instance.client;

  static Future<bool> submit({
    required String targetType,
    required String targetId,
    required String reason,
    String? details,
  }) async {
    if (!AuthService.isLoggedIn) return false;
    try {
      await _client.from('reports').insert({
        'reporter_id': AuthService.userId,
        'target_type': targetType,
        'target_id': targetId,
        'reason': reason,
        'details': (details != null && details.trim().isNotEmpty) ? details.trim() : null,
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
