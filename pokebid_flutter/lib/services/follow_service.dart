import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class FollowService {
  static final _client = Supabase.instance.client;

  static Future<String> _myId() async => AuthService.isLoggedIn
      ? AuthService.userId
      : await SupabaseService.getUserId();

  // ── Follow a seller ───────────────────────────────────────────────────────
  static Future<void> follow(String sellerId) async {
    final myId = await _myId();
    await _client.from('follows').upsert({
      'follower_id': myId,
      'seller_id': sellerId,
    }, onConflict: 'follower_id,seller_id');
  }

  // ── Unfollow a seller ─────────────────────────────────────────────────────
  static Future<void> unfollow(String sellerId) async {
    final myId = await _myId();
    await _client.from('follows')
        .delete()
        .eq('follower_id', myId)
        .eq('seller_id', sellerId);
  }

  // ── Check if following ────────────────────────────────────────────────────
  static Future<bool> isFollowing(String sellerId) async {
    final myId = await _myId();
    final res = await _client
        .from('follows')
        .select('seller_id')
        .eq('follower_id', myId)
        .eq('seller_id', sellerId)
        .maybeSingle();
    return res != null;
  }

  // ── Get follower count for a seller ──────────────────────────────────────
  static Future<int> followerCount(String sellerId) async {
    final res = await _client
        .from('follows')
        .select()
        .eq('seller_id', sellerId);
    return (res as List).length;
  }

  // ── Get listings of followed sellers (for notifications/feed) ─────────────
  static Future<List<String>> followedSellerIds() async {
    final myId = await _myId();
    final res = await _client
        .from('follows')
        .select('seller_id')
        .eq('follower_id', myId);
    return (res as List).map((r) => r['seller_id'] as String).toList();
  }

  // ── 我追蹤的賣家（含名稱/頭像）────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> followedSellers() async {
    final ids = await followedSellerIds();
    if (ids.isEmpty) return [];
    Map<String, Map<String, dynamic>> profiles = {};
    try {
      final res = await _client
          .from('profiles')
          .select('id, username, display_name, avatar_emoji')
          .inFilter('id', ids);
      for (final p in (res as List)) {
        profiles[p['id'] as String] = Map<String, dynamic>.from(p);
      }
    } catch (_) {}
    // 沒有 profile 的賣家也保留，用預設名
    return ids.map((id) {
      final p = profiles[id];
      final name = (p?['display_name'] as String?)?.trim().isNotEmpty == true
          ? p!['display_name'] as String
          : (p?['username'] as String?) ?? '賣家';
      return {
        'id': id,
        'name': name,
        'avatar': (p?['avatar_emoji'] as String?) ?? '🎴',
      };
    }).toList();
  }
}
