import 'package:flutter/material.dart';
import '../services/offer_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';
import '../i18n/strings.dart';

class ReceivedOffersScreen extends StatefulWidget {
  const ReceivedOffersScreen({super.key});

  @override
  State<ReceivedOffersScreen> createState() => _ReceivedOffersScreenState();
}

class _ReceivedOffersScreenState extends State<ReceivedOffersScreen> {
  List<Offer> _offers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final offers = await OfferService.getMyReceivedOffers();
    if (mounted) setState(() { _offers = offers; _loading = false; });
  }

  Future<void> _accept(Offer offer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(L.acceptOffer, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(L.acceptAmountConfirm(_fmt(offer.amount))),
          const SizedBox(height: 8),
          Text(L.acceptOfferDetail,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text(L.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(L.confirmAccept),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    await OfferService.acceptOffer(offer);
    await _load();

    // Open chat with buyer automatically
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L.offerAcceptedToast),
        backgroundColor: const Color(0xFF16A34A),
      ));
      _openChatWithBuyer(offer);
    }
  }

  // 賣家聯絡買家：以正確的 買家/賣家 角色取得對話
  Future<void> _openChatWithBuyer(Offer offer) async {
    final myId = await ChatService.myId();
    final convId = await ChatService.getOrCreateConversationFor(
      buyerId: offer.buyerId,
      sellerId: myId,
      cardId: offer.listingId,
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
  }

  Future<void> _reject(Offer offer) async {
    await OfferService.rejectOffer(offer.id);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L.offerRejected)));
    }
  }

  String _fmt(int p) => p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

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
        title: Text(L.receivedOffers,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                color: Color(0xFF111827))),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Color(0xFF374151)),
              onPressed: _load),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFFE8A52A), strokeWidth: 2))
          : _offers.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_offer_outlined, size: 48, color: Color(0xFFD1D5DB)),
                const SizedBox(height: 12),
                Text(L.noReceivedOffers,
                    style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15)),
              ]))
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _offers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final offer = _offers[i];
                return _OfferCard(
                  offer: offer,
                  formatPrice: _fmt,
                  onAccept: () => _accept(offer),
                  onReject: () => _reject(offer),
                  onChat: () => _openChatWithBuyer(offer),
                );
              },
            ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Offer offer;
  final String Function(int) formatPrice;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onChat;

  const _OfferCard({
    required this.offer,
    required this.formatPrice,
    required this.onAccept,
    required this.onReject,
    required this.onChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Buyer info
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6), shape: BoxShape.circle),
            child: Center(child: Text(
              offer.buyerName.substring(0, 1).toUpperCase(),
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                  color: Color(0xFF374151)))),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text(offer.buyerName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: Color(0xFF111827))),
            Text(_timeAgo(offer.createdAt),
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ])),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF9EC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(L.pendingReply, style: const TextStyle(fontSize: 11,
                fontWeight: FontWeight.w500, color: Color(0xFFE8A52A))),
          ),
        ]),

        const SizedBox(height: 12),
        const Divider(height: 1, color: Color(0xFFF3F4F6)),
        const SizedBox(height: 12),

        // Offer amount
        Row(children: [
          Text(L.offerAmount, style: const TextStyle(fontSize: 12,
              color: Color(0xFF9CA3AF))),
          const Spacer(),
          Text('HK\$${formatPrice(offer.amount)}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                  color: Color(0xFF16A34A))),
        ]),

        const SizedBox(height: 14),

        // Action buttons
        Row(children: [
          // Chat
          GestureDetector(
            onTap: onChat,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2980B9).withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.chat_bubble_outline,
                  color: Color(0xFF2980B9), size: 18),
            ),
          ),
          const SizedBox(width: 8),

          // Reject
          Expanded(
            child: GestureDetector(
              onTap: onReject,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE74C3C).withValues(alpha: 0.4)),
                ),
                child: Center(child: Text(L.rejectOffer,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: Color(0xFFE74C3C)))),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Accept
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: onAccept,
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: Text(L.acceptOffer,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: Colors.white))),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return L.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return L.hoursAgo(diff.inHours);
    return L.daysAgo(diff.inDays);
  }
}
