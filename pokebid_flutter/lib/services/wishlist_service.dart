import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

/// 願望清單項目 = 用戶想要的某一張具體卡片
class WishlistItem {
  final String id;
  final String userId;
  final String cardId;
  final String cardName;
  final String? imageUrl;
  final String? setId;
  final String? setName;
  final String? cardNumber;
  final DateTime createdAt;

  const WishlistItem({
    required this.id,
    required this.userId,
    required this.cardId,
    required this.cardName,
    this.imageUrl,
    this.setId,
    this.setName,
    this.cardNumber,
    required this.createdAt,
  });

  factory WishlistItem.fromRow(Map<String, dynamic> r) => WishlistItem(
        id: r['id'] as String,
        userId: r['user_id'] as String,
        cardId: r['card_id'] as String? ?? '',
        cardName: r['card_name'] as String? ?? '',
        imageUrl: r['image_url'] as String?,
        setId: r['set_id'] as String?,
        setName: r['set_name'] as String?,
        cardNumber: r['card_number'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
      );
}

class WishlistService {
  static final _client = Supabase.instance.client;

  static Future<String> _myId() async => AuthService.isLoggedIn
      ? AuthService.userId
      : await SupabaseService.getUserId();

  /// 加入一張具體卡片到願望清單（同一張卡只會有一筆）
  static Future<void> add({
    required String cardId,
    required String cardName,
    String? imageUrl,
    String? setId,
    String? setName,
    String? cardNumber,
  }) async {
    if (cardId.isEmpty) return;
    try {
      final myId = await _myId();
      await _client.from('wishlist').upsert({
        'user_id': myId,
        'card_id': cardId,
        'card_name': cardName,
        'image_url': imageUrl,
        'set_id': setId,
        'set_name': setName,
        'card_number': cardNumber,
      }, onConflict: 'user_id,card_id');
    } catch (_) {}
  }

  /// 依卡片 id 移除
  static Future<void> removeCard(String cardId) async {
    try {
      final myId = await _myId();
      await _client
          .from('wishlist')
          .delete()
          .eq('user_id', myId)
          .eq('card_id', cardId);
    } catch (_) {}
  }

  /// 依列 id 移除（清單頁滑動刪除用）
  static Future<void> remove(String id) async {
    try {
      await _client.from('wishlist').delete().eq('id', id);
    } catch (_) {}
  }

  /// 該卡是否已在願望清單
  static Future<bool> isWishlisted(String cardId) async {
    if (cardId.isEmpty) return false;
    try {
      final myId = await _myId();
      final res = await _client
          .from('wishlist')
          .select('id')
          .eq('user_id', myId)
          .eq('card_id', cardId)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  static Future<List<WishlistItem>> getMine() async {
    try {
      final myId = await _myId();
      final res = await _client
          .from('wishlist')
          .select()
          .eq('user_id', myId)
          .not('card_id', 'is', null)
          .order('created_at', ascending: false);
      return (res as List).map((r) => WishlistItem.fromRow(r)).toList();
    } catch (_) {
      return [];
    }
  }
}
