import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  // 當前用戶
  static User? get currentUser => _client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;

  static String get userId =>
      currentUser?.id ?? '';

  static String get displayName =>
      currentUser?.userMetadata?['full_name'] as String? ??
      currentUser?.userMetadata?['name'] as String? ??
      currentUser?.email?.split('@').first ??
      '用戶';

  static String get email =>
      currentUser?.email ?? '';

  static String get avatarUrl =>
      currentUser?.userMetadata?['avatar_url'] as String? ?? '';

  // Google 登入（Web / iOS / Android）
  static Future<bool> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        // Web: null → Supabase 自動用目前頁面 URL 做 redirect
        // iOS/Android: 用自訂 URL scheme
        redirectTo: kIsWeb ? null : 'io.supabase.pokebid://login-callback/',
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  // 登出
  static Future<void> signOut() async {
    await _client.auth.signOut();
    // 清除本地快取的 user_id
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  // 監聽登入狀態變化
  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  // 取得用戶頭像首字
  static String get avatarInitials {
    final name = displayName;
    if (name.isEmpty) return '?';
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
  }
}
