import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/listing_service.dart';
import 'card_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<AppNotification> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await NotificationService.getMine();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  Future<void> _markAllRead() async {
    await NotificationService.markAllRead();
    _load();
  }

  Future<void> _onTap(AppNotification n) async {
    if (!n.isRead) await NotificationService.markRead(n.id);
    // 有關聯商品 → 開啟商品詳情
    if (n.listingId != null) {
      final card = await ListingService.getListingById(n.listingId!);
      if (card != null && mounted) {
        await Navigator.push(context, MaterialPageRoute(
          builder: (_) => CardDetailScreen(
            card: card, isFavorited: false, onFavChanged: (_) {},
          ),
        ));
      }
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE5E7EB)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF374151), size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('通知',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
        actions: [
          if (_items.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllRead,
              child: const Text('全部已讀',
                  style: TextStyle(fontSize: 13, color: Color(0xFFE8A52A), fontWeight: FontWeight.w500)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2))
          : _items.isEmpty
              ? _empty()
              : RefreshIndicator(
                  color: const Color(0xFFE8A52A),
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _tile(_items[i]),
                  ),
                ),
    );
  }

  Widget _empty() => ListView(children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        const Icon(Icons.notifications_none, size: 56, color: Color(0xFFD1D5DB)),
        const SizedBox(height: 12),
        const Center(child: Text('目前沒有通知',
            style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)))),
      ]);

  Widget _tile(AppNotification n) {
    final (icon, color) = _style(n.type);
    return GestureDetector(
      onTap: () => _onTap(n),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: n.isRead ? const Color(0xFFE5E7EB) : const Color(0xFFE8A52A).withOpacity(0.3),
            width: 0.5,
          ),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(n.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                ),
                if (!n.isRead)
                  Container(width: 8, height: 8,
                      decoration: const BoxDecoration(color: Color(0xFFE74C3C), shape: BoxShape.circle)),
              ]),
              if (n.body != null) ...[
                const SizedBox(height: 3),
                Text(n.body!,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B7280), height: 1.4)),
              ],
              const SizedBox(height: 4),
              Text(_timeAgo(n.createdAt),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
            ]),
          ),
        ]),
      ),
    );
  }

  (IconData, Color) _style(String type) {
    switch (type) {
      case 'offer_received': return (Icons.local_offer, const Color(0xFF8E44AD));
      case 'offer_accepted': return (Icons.check_circle, const Color(0xFF16A34A));
      case 'offer_rejected': return (Icons.cancel, const Color(0xFFE74C3C));
      case 'message': return (Icons.chat_bubble, const Color(0xFF2980B9));
      case 'wishlist_match': return (Icons.favorite, const Color(0xFFE74C3C));
      case 'review_received': return (Icons.star, const Color(0xFFE8A52A));
      default: return (Icons.notifications, const Color(0xFF6B7280));
    }
  }

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return '剛剛';
    if (d.inMinutes < 60) return '${d.inMinutes} 分鐘前';
    if (d.inHours < 24) return '${d.inHours} 小時前';
    if (d.inDays < 7) return '${d.inDays} 天前';
    return '${dt.month}/${dt.day}';
  }
}
