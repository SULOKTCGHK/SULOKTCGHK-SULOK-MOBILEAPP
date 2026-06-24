import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/listing_service.dart';
import '../services/offer_service.dart';
import '../services/chat_service.dart';
import 'card_detail_screen.dart';
import 'chat_screen.dart';
import '../i18n/strings.dart';

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

    // 出價被接受：買家點通知 → 進聊天室
    if (n.type == 'offer_accepted' && n.listingId != null) {
      final myId = await ChatService.myId();
      // 找到這個 listing 的 accepted offer 以取得賣家 ID
      final offers = await OfferService.getOffersForListing(n.listingId!);
      final accepted = offers.where((o) => o.status == 'accepted' && o.buyerId == myId).toList();
      if (accepted.isNotEmpty && mounted) {
        final offer = accepted.first;
        final convId = await ChatService.getOrCreateConversationFor(
          buyerId: myId,
          sellerId: offer.listingId, // 用 listing 找 seller
          cardId: offer.listingId,
        );
        // 取得賣家名稱：從 listing 取
        final card = await ListingService.getListingById(n.listingId!);
        if (!mounted) return;
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChatScreen(
            sellerName: card?.seller.name ?? L.sellerFallback,
            sellerAvatar: (card?.seller.name ?? L.sellerFallback).substring(0, 1).toUpperCase(),
            sellerId: card?.seller.id,
            conversationId: convId,
          ),
        ));
      }
      _load();
      return;
    }

    // 其他通知：開商品詳情
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

  Future<void> _acceptOffer(AppNotification n) async {
    if (n.listingId == null) {
      _showErr(L.notifMissingListing);
      return;
    }
    try {
      final offers = await OfferService.getOffersForListing(n.listingId!);
      final pending = offers.where((o) => o.status == 'pending').toList();
      if (pending.isEmpty) {
        _showErr(L.noPendingOfferMaybeHandled);
        return;
      }
      final offer = pending.reduce((a, b) => a.amount >= b.amount ? a : b);
      if (!mounted) return;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(L.acceptOffer, style: const TextStyle(fontWeight: FontWeight.w700)),
          content: Text(L.acceptOfferConfirm(offer.buyerName, offer.amount)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(L.cancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
              child: Text(L.confirmAccept),
            ),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
      await OfferService.acceptOffer(offer);
      await NotificationService.markRead(n.id);
      _load();
      if (!mounted) return;
      final myId = await ChatService.myId();
      final convId = await ChatService.getOrCreateConversationFor(
        buyerId: offer.buyerId,
        sellerId: myId,
        cardId: offer.listingId,
        forceNew: true,
      );
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ChatScreen(
          sellerName: offer.buyerName,
          sellerAvatar: offer.buyerName.substring(0, 1).toUpperCase(),
          sellerId: offer.buyerId,
          conversationId: convId,
        ),
      ));
    } catch (e) {
      _showErr(L.actionFailed('$e'));
    }
  }

  void _showErr(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFE74C3C)),
    );
  }

  Future<void> _rejectOffer(AppNotification n) async {
    if (n.listingId == null) return;
    try {
      final offers = await OfferService.getOffersForListing(n.listingId!);
      final pending = offers.where((o) => o.status == 'pending').toList();
      if (pending.isEmpty) { _showErr(L.noPendingOffer); return; }
      for (final o in pending) {
        await OfferService.rejectOffer(o.id);
      }
      await NotificationService.markRead(n.id);
      _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.offerRejected), backgroundColor: const Color(0xFF6B7280)),
      );
    } catch (e) {
      _showErr(L.actionFailed('$e'));
    }
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
        title: Text(L.notifications,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
        actions: [
          if (_items.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllRead,
              child: Text(L.markAllRead,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFE8A52A), fontWeight: FontWeight.w500)),
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
        Center(child: Text(L.noNotifications,
            style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)))),
      ]);

  Widget _tile(AppNotification n) {
    final (icon, color) = _style(n.type);
    final isOffer = n.type == 'offer_received';
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
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          // 查看商品連結
          if (isOffer && n.listingId != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _onTap(n),
              child: Row(children: [
                Text(L.viewProduct, style: const TextStyle(fontSize: 12, color: Color(0xFF8E44AD), fontWeight: FontWeight.w600)),
                const SizedBox(width: 3),
                const Icon(Icons.arrow_forward_ios, size: 10, color: Color(0xFF8E44AD)),
              ]),
            ),
          ],
          // 出價操作按鈕（僅未讀的 offer_received 才顯示）
          if (isOffer && !n.isRead) ...[
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectOffer(n),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(L.rejectOffer, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptOffer(n),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: Text(L.acceptOffer, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ],
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
    if (d.inMinutes < 1) return L.justNow;
    if (d.inMinutes < 60) return L.minutesAgo(d.inMinutes);
    if (d.inHours < 24) return L.hoursAgo(d.inHours);
    if (d.inDays < 7) return L.daysAgo(d.inDays);
    return '${dt.month}/${dt.day}';
  }
}
