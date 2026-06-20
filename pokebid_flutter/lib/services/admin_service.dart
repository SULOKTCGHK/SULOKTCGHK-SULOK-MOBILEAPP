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
}
