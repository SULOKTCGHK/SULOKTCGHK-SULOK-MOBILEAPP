import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

/// 封鎖服務。封鎖後對方的掛售與對話會被隱藏。
class BlockService {
  static final _client = Supabase.instance.client;

  // 記憶體快取被封鎖的 id（過濾列表用，避免每次查 DB）
  static Set<String> _cache = {};
  static bool _loaded = false;

  static Future<void> block(String userId) async {
    if (!AuthService.isLoggedIn) return;
    try {
      await _client.from('blocks').upsert({
        'blocker_id': AuthService.userId,
        'blocked_id': userId,
      }, onConflict: 'blocker_id,blocked_id');
      _cache.add(userId);
    } catch (_) {}
  }

  static Future<void> unblock(String userId) async {
    if (!AuthService.isLoggedIn) return;
    try {
      await _client.from('blocks')
          .delete()
          .eq('blocker_id', AuthService.userId)
          .eq('blocked_id', userId);
      _cache.remove(userId);
    } catch (_) {}
  }

  static Future<bool> isBlocked(String userId) async {
    final ids = await blockedIds();
    return ids.contains(userId);
  }

  /// 我封鎖的所有 id（含快取）
  static Future<Set<String>> blockedIds({bool force = false}) async {
    if (_loaded && !force) return _cache;
    if (!AuthService.isLoggedIn) { _loaded = true; return _cache; }
    try {
      final res = await _client
          .from('blocks')
          .select('blocked_id')
          .eq('blocker_id', AuthService.userId);
      _cache = (res as List).map((r) => r['blocked_id'] as String).toSet();
      _loaded = true;
    } catch (_) {}
    return _cache;
  }

  /// 同步取得已快取的封鎖清單（過濾列表用，不發網路）
  static Set<String> cachedBlockedIds() => _cache;

  /// 登出時清掉快取，避免換帳號殘留
  static void reset() { _cache = {}; _loaded = false; }

  /// 我封鎖的用戶（含名稱/頭像，給設定頁管理）
  static Future<List<Map<String, dynamic>>> blockedUsers() async {
    final ids = (await blockedIds(force: true)).toList();
    if (ids.isEmpty) return [];
    final Map<String, Map<String, dynamic>> profiles = {};
    try {
      final res = await _client
          .from('profiles')
          .select('id, username, display_name, avatar_emoji')
          .inFilter('id', ids);
      for (final p in (res as List)) {
        profiles[p['id'] as String] = Map<String, dynamic>.from(p);
      }
    } catch (_) {}
    return ids.map((id) {
      final p = profiles[id];
      final name = (p?['display_name'] as String?)?.trim().isNotEmpty == true
          ? p!['display_name'] as String
          : (p?['username'] as String?) ?? '';
      return {
        'id': id,
        'name': name,
        'avatar': (p?['avatar_emoji'] as String?) ?? '🎴',
      };
    }).toList();
  }
}
