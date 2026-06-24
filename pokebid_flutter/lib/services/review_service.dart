import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

class Review {
  final String id;
  final String sellerId;
  final String reviewerId;
  final String reviewerName;
  final String? listingId;
  final int rating;        // 1-5
  final String? comment;
  final String? deliveryMethod; // meetup / sf / other
  final String? role;           // buyer / seller
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.sellerId,
    required this.reviewerId,
    required this.reviewerName,
    this.listingId,
    required this.rating,
    this.comment,
    this.deliveryMethod,
    this.role,
    required this.createdAt,
  });

  factory Review.fromRow(Map<String, dynamic> r) => Review(
        id: r['id'] as String,
        sellerId: r['seller_id'] as String,
        reviewerId: r['reviewer_id'] as String,
        reviewerName: r['reviewer_name'] as String? ?? '用戶',
        listingId: r['listing_id'] as String?,
        rating: (r['rating'] as num).toInt(),
        comment: r['comment'] as String?,
        deliveryMethod: r['delivery_method'] as String?,
        role: r['role'] as String?,
        createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
      );
}

class SellerStats {
  final double avgRating;
  final int count;
  const SellerStats(this.avgRating, this.count);
}

class ReviewService {
  static final _client = Supabase.instance.client;

  static Future<String> _myId() async => AuthService.isLoggedIn
      ? AuthService.userId
      : await SupabaseService.getUserId();

  static String _myName() =>
      AuthService.isLoggedIn ? AuthService.displayName : '匿名用戶';

  /// 送出評價（同一筆交易/商品只能評一次 → upsert）
  static Future<bool> submitReview({
    required String sellerId,
    String? listingId,
    required int rating,
    String? comment,
    String? deliveryMethod,
    String? role,
  }) async {
    try {
      final myId = await _myId();
      await _client.from('reviews').upsert({
        'seller_id': sellerId,
        'reviewer_id': myId,
        'reviewer_name': _myName(),
        'listing_id': listingId,
        'rating': rating,
        'comment': comment,
        if (deliveryMethod != null) 'delivery_method': deliveryMethod,
        if (role != null) 'role': role,
      }, onConflict: 'reviewer_id,listing_id');

      // 通知賣家
      await NotificationService.create(
        userId: sellerId,
        type: 'review_received',
        title: '收到新評價 ⭐ $rating',
        body: '${_myName()} 給了你 $rating 星評價${comment != null && comment.isNotEmpty ? '：$comment' : ''}',
        listingId: listingId,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 取得賣家的所有評價
  static Future<List<Review>> getForSeller(String sellerId) async {
    try {
      final res = await _client
          .from('reviews')
          .select()
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);
      return (res as List).map((r) => Review.fromRow(r)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 賣家評分統計（平均、總數）
  static Future<SellerStats> statsForSeller(String sellerId) async {
    try {
      final res = await _client
          .from('reviews')
          .select('rating')
          .eq('seller_id', sellerId);
      final list = (res as List);
      if (list.isEmpty) return const SellerStats(0, 0);
      final sum = list.fold<int>(0, (s, r) => s + ((r['rating'] as num).toInt()));
      return SellerStats(sum / list.length, list.length);
    } catch (_) {
      return const SellerStats(0, 0);
    }
  }

  /// 我是否已對此商品評價過
  static Future<bool> hasReviewed(String listingId) async {
    try {
      final myId = await _myId();
      final res = await _client
          .from('reviews')
          .select('id')
          .eq('reviewer_id', myId)
          .eq('listing_id', listingId)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }
}
