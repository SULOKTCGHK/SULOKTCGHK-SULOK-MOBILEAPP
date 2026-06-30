import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/notification_service.dart';

/// 通知的全域單一來源（Provider）。
///
/// 改前：每個 [UnreadDot] 各自開一條 Supabase realtime 訂閱（畫面上 N 個紅點 = N 條連線）。
/// 改後：整個 App 只開「一條」訂閱，所有紅點都從這裡讀，省連線、也保證一致。
///
/// 用法：
///   - 登入後呼叫 [start]（開始訂閱目前用戶的通知）
///   - 登出時呼叫 [stop]（清空並停止訂閱）
///   - 任何 widget：`context.watch<NotificationModel>().unreadOf(['message'])`
class NotificationModel extends ChangeNotifier {
  List<AppNotification> _items = [];
  StreamSubscription<List<AppNotification>>? _sub;

  List<AppNotification> get items => List.unmodifiable(_items);

  /// 未讀數量。[types] 為 null 代表所有類型；否則只算指定類型（如只看 message）。
  int unreadOf(List<String>? types) => _items
      .where((n) => !n.isRead && (types == null || types.contains(n.type)))
      .length;

  /// 開始訂閱目前登入用戶的通知（重複呼叫會先取消舊訂閱）。
  void start() {
    _sub?.cancel();
    _sub = NotificationService.streamMine().listen(
      (rows) {
        _items = rows;
        notifyListeners();
      },
      onError: (Object e) => debugPrint('NotificationModel stream error: $e'),
    );
  }

  /// 登出時：停止訂閱並清空（紅點全消失）。
  void stop() {
    _sub?.cancel();
    _sub = null;
    if (_items.isNotEmpty) {
      _items = [];
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
