import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

class AdminService {
  static final _client = Supabase.instance.client;
  static bool? _cached;

  static Future<bool> isAdmin() async {
    if (!AuthService.isLoggedIn) return false;
    if (_cached != null) return _cached!;
    try {
      final res = await _client
          .from('admins')
          .select('user_id')
          .eq('user_id', AuthService.userId)
          .maybeSingle();
      _cached = res != null;
      return _cached!;
    } catch (_) {
      return false;
    }
  }

  // Call on logout so cache is cleared
  static void clearCache() => _cached = null;

  // ── 帳號管理（讀取）────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> listProfiles({String? search}) async {
    try {
      var q = _client.from('profiles').select(
          'id, username, display_name, avatar_emoji, phone_verified, ig_handle, created_at');
      if (search != null && search.trim().isNotEmpty) {
        final s = '%${search.trim()}%';
        q = q.or('username.ilike.$s,display_name.ilike.$s');
      }
      final res = await q.order('created_at', ascending: false).limit(200);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  // ── 檢舉管理 ───────────────────────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> listReports({String status = 'pending'}) async {
    try {
      var q = _client.from('reports').select();
      if (status != 'all') q = q.eq('status', status);
      final res = await q.order('created_at', ascending: false).limit(200);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      return [];
    }
  }

  static Future<bool> setReportStatus(String id, String status) async {
    try {
      await _client.from('reports').update({'status': status}).eq('id', id);
      return true;
    } catch (_) {
      return false;
    }
  }
}
