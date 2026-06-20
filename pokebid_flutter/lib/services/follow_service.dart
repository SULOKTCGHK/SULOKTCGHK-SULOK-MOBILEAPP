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
}
