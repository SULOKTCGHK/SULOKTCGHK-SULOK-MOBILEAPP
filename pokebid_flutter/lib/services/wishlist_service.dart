import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_model.dart';
import 'auth_service.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

class WishlistItem {
  final String id;
  final String userId;
  final String? setId;
  final String? cardNumber;
  final String? keyword;
  final int? maxPrice;
  final DateTime createdAt;

  const WishlistItem({
    required this.id,
    required this.userId,
    this.setId,
    this.cardNumber,
    this.keyword,
    this.maxPrice,
    required this.createdAt,
  });

  factory WishlistItem.fromRow(Map<String, dynamic> r) => WishlistItem(
        id: r['id'] as String,
        userId: r['user_id'] as String,
        setId: r['set_id'] as String?,
        cardNumber: r['card_number'] as String?,
        keyword: r['keyword'] as String?,
        maxPrice: r['max_price'] as int?,
        createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
      );

  String get label {
    final parts = <String>[];
    if (keyword != null && keyword!.isNotEmpty) parts.add(keyword!);
    if (setId != null && setId!.isNotEmpty) parts.add(setId!.toUpperCase());
    if (cardNumber != null && cardNumber!.isNotEmpty) parts.add('#$cardNumber');
    var s = parts.isEmpty ? '任意卡片' : parts.join(' ');
    if (maxPrice != null) s += '　≤ HK\$$maxPrice';
    return s;
  }
}

class WishlistService {
  static final _client = Supabase.instance.client;

  static Future<String> _myId() async => AuthService.isLoggedIn
      ? AuthService.userId
      : await SupabaseService.getUserId();

  static Future<void> add({
    String? setId,
    String? cardNumber,
    String? keyword,
    int? maxPrice,
  }) async {
    try {
      final myId = await _myId();
      await _client.from('wishlist').insert({
        'user_id': myId,
        'set_id': setId,
        'card_number': cardNumber,
        'keyword': keyword,
        'max_price': maxPrice,
      });
    } catch (_) {}
  }

  static Future<void> remove(String id) async {
    try {
      await _client.from('wishlist').delete().eq('id', id);
    } catch (_) {}
  }

  static Future<List<WishlistItem>> getMine() async {
    try {
      final myId = await _myId();
      final res = await _client
          .from('wishlist')
          .select()
          .eq('user_id', myId)
          .order('created_at', ascending: false);
      return (res as List).map((r) => WishlistItem.fromRow(r)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 判斷一張新上架商品是否符合某個願望項目
  static bool _matches(WishlistItem w, PokemonCard card) {
    if (w.setId != null && w.setId!.isNotEmpty) {
      if (card.setId?.toLowerCase() != w.setId!.toLowerCase()) return false;
    }
    if (w.cardNumber != null && w.cardNumber!.isNotEmpty) {
      if (card.cardNumber?.toLowerCase() != w.cardNumber!.toLowerCase()) return false;
    }
    if (w.keyword != null && w.keyword!.isNotEmpty) {
      if (!card.name.toLowerCase().contains(w.keyword!.toLowerCase())) return false;
    }
    if (w.maxPrice != null && card.price > w.maxPrice!) return false;
    // 至少要有一個有效條件，否則不算 match（避免空條件全中）
    final hasCond = (w.setId?.isNotEmpty ?? false) ||
        (w.cardNumber?.isNotEmpty ?? false) ||
        (w.keyword?.isNotEmpty ?? false);
    return hasCond;
  }

  /// 新商品上架後呼叫：找出所有符合的願望清單擁有者並發通知
  /// （賣家本人不會收到自己商品的通知）
  static Future<void> notifyMatchesForNewListing(PokemonCard card) async {
    try {
      final res = await _client.from('wishlist').select();
      final items = (res as List).map((r) => WishlistItem.fromRow(r)).toList();
      final notified = <String>{};
      for (final w in items) {
        if (w.userId == card.seller.id) continue; // 不通知賣家自己
        if (notified.contains(w.userId)) continue; // 同一人只通知一次
        if (_matches(w, card)) {
          notified.add(w.userId);
          await NotificationService.create(
            userId: w.userId,
            type: 'wishlist_match',
            title: '你的願望清單有新上架 🎯',
            body: '「${card.name}」HK\$${card.price} 符合你想要的卡片',
            listingId: card.supabaseId,
          );
        }
      }
    } catch (_) {}
  }
}
