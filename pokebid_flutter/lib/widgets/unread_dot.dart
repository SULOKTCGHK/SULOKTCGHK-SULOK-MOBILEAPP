import 'package:flutter/material.dart';
import '../services/notification_service.dart';

/// 在 child 右上角疊一個紅點（有未讀通知時顯示）。
/// 可用 [types] 篩選只看特定通知類型（如只看 message），null = 所有未讀。
class UnreadDot extends StatelessWidget {
  final Widget child;
  final List<String>? types;
  final double top;
  final double right;
  final bool showCount;

  const UnreadDot({
    super.key,
    required this.child,
    this.types,
    this.top = 6,
    this.right = 6,
    this.showCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppNotification>>(
      stream: NotificationService.streamMine(),
      builder: (context, snap) {
        final all = snap.data ?? [];
        final unread = all.where((n) =>
            !n.isRead && (types == null || types!.contains(n.type))).length;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (unread > 0)
              Positioned(
                top: top,
                right: right,
                child: Container(
                  padding: showCount
                      ? const EdgeInsets.symmetric(horizontal: 4, vertical: 1)
                      : EdgeInsets.zero,
                  constraints: showCount
                      ? const BoxConstraints(minWidth: 16, minHeight: 16)
                      : const BoxConstraints(minWidth: 9, minHeight: 9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C),
                    borderRadius: BorderRadius.circular(showCount ? 8 : 5),
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  child: showCount
                      ? Text(unread > 99 ? '99+' : '$unread',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 9.5,
                              fontWeight: FontWeight.w700, color: Colors.white))
                      : null,
                ),
              ),
          ],
        );
      },
    );
  }
}
