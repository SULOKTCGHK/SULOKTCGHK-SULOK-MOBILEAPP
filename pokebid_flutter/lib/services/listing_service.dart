import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_model.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../services/wishlist_service.dart';

class ListingService {
  static final _client = Supabase.instance.client;

  // ── Fetch all active listings ─────────────────────────────────────────────
  static Future<List<PokemonCard>> getListings() async {
    try {
      final res = await _client
          .from('listings')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (res as List).map((row) => _fromRow(row)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Insert a new listing ──────────────────────────────────────────────────
  static Future<bool> insertListing({
    required String name,
    required String grade,
    required String condition,
    required int price,
    String? description,
    List<String> imageUrls = const [],
    String? setId,
    String? cardNumber,
    String? psaCert,
    String? cachedCardId,
  }) async {
    try {
      final sellerId = AuthService.isLoggedIn
          ? AuthService.userId
          : await SupabaseService.getUserId();
      final sellerName = AuthService.isLoggedIn
          ? AuthService.displayName
          : '匿名賣家';

      final inserted = await _client.from('listings').insert({
        'name': name,
        'grade': grade,
        'card_type': 'normal',
        'price': price,
        'condition': condition,
        'listing_type': 'fixedPrice',
        'description': description ?? '',
        'image_urls': imageUrls,
        'seller_id': sellerId,
        'seller_name': sellerName,
        'seller_rating': 5.0,
        'seller_sales': 0,
        'is_active': true,
        if (setId != null && setId.isNotEmpty) 'set_id': setId,
        if (cardNumber != null && cardNumber.isNotEmpty) 'card_number': cardNumber,
        if (psaCert != null && psaCert.isNotEmpty) 'psa_cert': psaCert,
        if (cachedCardId != null && cachedCardId.isNotEmpty) 'cached_card_id': cachedCardId,
      }).select().maybeSingle();

      // 通知所有願望清單符合此新商品的用戶
      if (inserted != null) {
        await WishlistService.notifyMatchesForNewListing(_fromRow(inserted));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Get listings by seller ────────────────────────────────────────────────
  static Future<List<PokemonCard>> getMyListings(String sellerId) async {
    try {
      final res = await _client
          .from('listings')
          .select()
          .eq('seller_id', sellerId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      return (res as List).map((r) => _fromRow(r)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Get a single listing by id (incl. sold/inactive) ─────────────────────
  static Future<PokemonCard?> getListingById(String id) async {
    try {
      final res = await _client
          .from('listings')
          .select()
          .eq('id', id)
          .maybeSingle();
      return res != null ? _fromRow(res) : null;
    } catch (_) {
      return null;
    }
  }

  // ── Update listing price ──────────────────────────────────────────────────
  static Future<void> updateListingPrice(String id, int price) async {
    try {
      await _client.from('listings').update({'price': price}).eq('id', id);
    } catch (_) {}
  }

  // ── Deactivate (soft delete) a listing ───────────────────────────────────
  static Future<void> deactivateListing(String id) async {
    try {
      await _client
          .from('listings')
          .update({'is_active': false})
          .eq('id', id);
    } catch (_) {}
  }

  // ── Public row mapper (used by seller profile) ───────────────────────────
  static PokemonCard fromRowPublic(Map<String, dynamic> row) => _fromRow(row);

  // ── Map Supabase row → PokemonCard ────────────────────────────────────────
  static PokemonCard _fromRow(Map<String, dynamic> row) {
    return PokemonCard(
      id: _stableId(row['id'] as String),
      name: row['name'] as String,
      grade: row['grade'] as String,
      type: _parseType(row['card_type'] as String? ?? 'normal'),
      price: row['price'] as int,
      condition: row['condition'] as String,
      seller: Seller(
        id: row['seller_id'] as String?,
        name: row['seller_name'] as String,
        rating: (row['seller_rating'] as num).toDouble(),
        sales: row['seller_sales'] as int,
      ),
      listingType: (row['listing_type'] as String?) == 'auction'
          ? ListingType.auction
          : ListingType.fixedPrice,
      bids: row['bids'] as int? ?? 0,
      timeInfo: _timeAgo(row['created_at'] as String?),
      supabaseId: row['id'] as String,
      imageUrls: (row['image_urls'] as List?)?.cast<String>() ?? [],
      isSold: (row['status'] as String?) == 'sold' ||
          (row['is_active'] as bool? ?? true) == false,
      setId: row['set_id'] as String?,
      cardNumber: row['card_number'] as String?,
      psaCert: row['psa_cert'] as String?,
      psaSpecId: row['psa_spec_id'] as String?,
    );
  }

  static int _stableId(String uuid) => uuid.hashCode.abs();

  static String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分鐘前';
    if (diff.inHours < 24) return '${diff.inHours} 小時前';
    if (diff.inDays < 7) return '${diff.inDays} 天前';
    return '${dt.month}/${dt.day}';
  }

  static CardType _parseType(String t) {
    switch (t) {
      case 'fire': return CardType.fire;
      case 'water': return CardType.water;
      case 'grass': return CardType.grass;
      case 'electric': return CardType.electric;
      case 'psychic': return CardType.psychic;
      case 'dragon': return CardType.dragon;
      case 'dark': return CardType.dark;
      case 'fairy': return CardType.fairy;
      case 'rock': return CardType.rock;
      default: return CardType.normal;
    }
  }
}
