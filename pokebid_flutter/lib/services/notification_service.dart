import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'supabase_service.dart';

class AppNotification {
  final String id;
  final String userId;
  final String type;       // offer_received / offer_accepted / offer_rejected / message / wishlist_match / review_received
  final String title;
  final String? body;
  final String? listingId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.listingId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromRow(Map<String, dynamic> r) => AppNotification(
        id: r['id'] as String,
        userId: r['user_id'] as String,
        type: r['type'] as String? ?? '',
        title: r['title'] as String? ?? '',
        body: r['body'] as String?,
        listingId: r['listing_id'] as String?,
        isRead: r['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
      );
}

class NotificationService {
  static final _client = Supabase.instance.client;

  static Future<String> _myId() async => AuthService.isLoggedIn
      ? AuthService.userId
      : await SupabaseService.getUserId();

  /// 建立一則通知（發給指定 userId）並同時發送 Push Notification
  static Future<void> create({
    required String userId,
    required String type,
    required String title,
    String? body,
    String? listingId,
  }) async {
    if (userId.isEmpty) return;
    try {
      // 站內通知
      await _client.from('notifications').insert({
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'listing_id': listingId,
        'is_read': false,
      });

      // Push Notification（App 關閉時也能收到）
      _client.functions.invoke('send-push', body: {
        'user_id': userId,
        'title': title,
        'body': body ?? '',
        'data': {'type': type, if (listingId != null) 'listing_id': listingId},
      }).ignore(); // fire-and-forget，不阻塞主流程
    } catch (_) {}
  }

  /// 取得目前用戶的通知列表
  static Future<List<AppNotification>> getMine({int limit = 50}) async {
    try {
      final myId = await _myId();
      final res = await _client
          .from('notifications')
          .select()
          .eq('user_id', myId)
          .order('created_at', ascending: false)
          .limit(limit);
      return (res as List).map((r) => AppNotification.fromRow(r)).toList();
    } catch (_) {
      return [];
    }
  }

  /// 未讀數量
  static Future<int> unreadCount() async {
    try {
      final myId = await _myId();
      final res = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', myId)
          .eq('is_read', false)
          .count(CountOption.exact);
      return res.count;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> markRead(String id) async {
    try {
      await _client.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (_) {}
  }

  /// 將某些類型的未讀通知標記為已讀（如開啟訊息頁時清掉 message 紅點）
  static Future<void> markReadByTypes(List<String> types) async {
    if (types.isEmpty) return;
    try {
      final myId = await _myId();
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', myId)
          .eq('is_read', false)
          .inFilter('type', types);
    } catch (_) {}
  }

  static Future<void> markAllRead() async {
    try {
      final myId = await _myId();
      await _client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', myId)
          .eq('is_read', false);
    } catch (_) {}
  }

  /// Realtime 串流：目前用戶的通知（最新在前）
  static Stream<List<AppNotification>> streamMine() async* {
    final myId = await _myId();
    yield* _client
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', myId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map((r) => AppNotification.fromRow(r)).toList());
  }
}
