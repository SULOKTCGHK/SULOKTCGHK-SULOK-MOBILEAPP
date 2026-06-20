import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

class Offer {
  final String id;
  final String listingId;
  final String buyerId;
  final String buyerName;
  final int amount;
  final String status; // pending / accepted / rejected
  final DateTime createdAt;

  const Offer({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.buyerName,
    required this.amount,
    required this.status,
    required this.createdAt,
  });

  factory Offer.fromRow(Map<String, dynamic> r) => Offer(
    id: r['id'] as String,
    listingId: r['listing_id'] as String,
    buyerId: r['buyer_id'] as String,
    buyerName: r['buyer_name'] as String? ?? '買家',
    amount: r['amount'] as int,
    status: r['status'] as String,
    createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
  );
}

class OfferService {
  static final _client = Supabase.instance.client;

  static Future<String> _myId() async => AuthService.isLoggedIn
      ? AuthService.userId
      : await SupabaseService.getUserId();

  static String _myName() => AuthService.isLoggedIn
      ? AuthService.displayName
      : '訪客買家';

  // ── Send an offer ─────────────────────────────────────────────────────────
  static Future<void> makeOffer({
    required String listingId,
    required String sellerId,
    required int amount,
  }) async {
    final myId = await _myId();
    await _client.from('offers').insert({
      'listing_id': listingId,
      'seller_id': sellerId,
      'buyer_id': myId,
      'buyer_name': _myName(),
      'amount': amount,
      'status': 'pending',
    });

    // 通知賣家收到出價
    await NotificationService.create(
      userId: sellerId,
      type: 'offer_received',
      title: '收到新出價 💰',
      body: '${_myName()} 出價 NT\$$amount',
      listingId: listingId,
    );
  }

  // ── Get offers received by seller (for a listing) ────────────────────────
  static Future<List<Offer>> getOffersForListing(String listingId) async {
    final res = await _client
        .from('offers')
        .select()
        .eq('listing_id', listingId)
        .order('created_at', ascending: false);
    return (res as List).map((r) => Offer.fromRow(r)).toList();
  }

  // ── Get all pending offers received by current seller ────────────────────
  static Future<List<Offer>> getMyReceivedOffers() async {
    final myId = await _myId();
    final res = await _client
        .from('offers')
        .select()
        .eq('seller_id', myId)
        .eq('status', 'pending')
        .order('created_at', ascending: false);
    return (res as List).map((r) => Offer.fromRow(r)).toList();
  }

  // ── Accept offer: mark listing as sold, reject other offers ─────────────
  static Future<void> acceptOffer(Offer offer) async {
    // Mark this offer accepted
    await _client.from('offers')
        .update({'status': 'accepted'})
        .eq('id', offer.id);

    // Reject all other pending offers on same listing
    await _client.from('offers')
        .update({'status': 'rejected'})
        .eq('listing_id', offer.listingId)
        .neq('id', offer.id)
        .eq('status', 'pending');

    // Mark listing as sold (not active)
    await _client.from('listings')
        .update({'is_active': false, 'status': 'sold'})
        .eq('id', offer.listingId);

    // 通知買家：出價被接受
    await NotificationService.create(
      userId: offer.buyerId,
      type: 'offer_accepted',
      title: '出價被接受了 🎉',
      body: '你的出價 NT\$${offer.amount} 已被賣家接受，請前往聊天室完成交易',
      listingId: offer.listingId,
    );
  }

  // ── Reject single offer ───────────────────────────────────────────────────
  static Future<void> rejectOffer(String offerId) async {
    // 先取得買家資訊以便通知
    final row = await _client.from('offers')
        .select('buyer_id, listing_id, amount')
        .eq('id', offerId)
        .maybeSingle();

    await _client.from('offers')
        .update({'status': 'rejected'})
        .eq('id', offerId);

    if (row != null) {
      await NotificationService.create(
        userId: row['buyer_id'] as String,
        type: 'offer_rejected',
        title: '出價未被接受',
        body: '你的出價 NT\$${row['amount']} 已被婉拒',
        listingId: row['listing_id'] as String?,
      );
    }
  }

  // ── Check if current user already made an offer ───────────────────────────
  static Future<Offer?> myOfferForListing(String listingId) async {
    final myId = await _myId();
    final res = await _client
        .from('offers')
        .select()
        .eq('listing_id', listingId)
        .eq('buyer_id', myId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return res != null ? Offer.fromRow(res) : null;
  }
}
