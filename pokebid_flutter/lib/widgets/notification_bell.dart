import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../screens/notifications_screen.dart';

/// 鈴鐺圖示 + 未讀數徽章（透過 Supabase realtime 即時更新）
class NotificationBell extends StatelessWidget {
  final Color iconColor;
  const NotificationBell({super.key, this.iconColor = const Color(0xFF374151)});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppNotification>>(
      stream: NotificationService.streamMine(),
      builder: (context, snap) {
        final unread = (snap.data ?? []).where((n) => !n.isRead).length;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none, color: iconColor),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: 6, top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE74C3C),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1.2),
                  ),
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
