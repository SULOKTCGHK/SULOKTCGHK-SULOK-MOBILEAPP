import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/card_model.dart';
import '../widgets/card_type_icon.dart';
import '../widgets/no_image_placeholder.dart';
import '../services/offer_service.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import '../services/supabase_service.dart';
import '../services/recently_viewed_service.dart';
import '../services/api_service.dart';
import '../widgets/login_required.dart';
import 'chat_screen.dart';
import 'offer_sheet.dart';
import 'seller_profile_screen.dart';
import 'image_viewer_screen.dart';
import 'review_sheet.dart';
import '../i18n/strings.dart';
import '../widgets/report_sheet.dart';

class CardDetailScreen extends StatefulWidget {
  final PokemonCard card;
  final bool isFavorited;
  final ValueChanged<bool> onFavChanged;

  const CardDetailScreen({
    super.key,
    required this.card,
    required this.isFavorited,
    required this.onFavChanged,
  });

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late bool _faved;
  late int _price;
  Offer? _myOffer;
  bool _hasReviewed = false;
  Map<String, dynamic>? _psaPop;
  Map<String, dynamic>? _snkr;
  bool _snkrLoading = false;

  String get _sellerIg => 'pokebid_official';

  // 是否為自己的商品（不能向自己出價/聊天）
  bool get _isMyListing =>
      widget.card.seller.id != null &&
      AuthService.isLoggedIn &&
      widget.card.seller.id == AuthService.userId;

  // 商品已成交（其他用戶看不到，但買賣雙方仍可查看內容）
  bool get _isSold => widget.card.isSold;

  @override
  void initState() {
    super.initState();
    _faved = widget.isFavorited;
    _price = widget.card.price;
    if (!_isMyListing) _loadMyOffer();
    if (_isSold && !_isMyListing) _loadReviewStatus();
    _loadPsaPop();
    _recordView();
    if (_canShowSnkrdunk) _loadSnkr();
  }

  void _recordView() {
    final card = widget.card;
    if (card.supabaseId == null) return;
    RecentlyViewedService.record({
      'id': card.supabaseId!,
      'name': card.name,
      'grade': card.grade,
      'price': card.price,
      'image': card.imageUrls.isNotEmpty ? card.imageUrls.first : null,
      'condition': card.condition,
      'isSold': card.isSold,
    });
  }

  Future<void> _loadSnkr() async {
    final card = widget.card;
    setState(() => _snkrLoading = true);
    // 用 setId+cardNumber 作 cache key（同一張卡複用快取）
    final cacheKey = '${card.setId ?? ''}_${card.cardNumber ?? ''}';
    final data = await PokemonApiService.getSnkrdunkPrice(
      cacheKey,
      card.name,
      card.cardNumber,
    );
    if (mounted) setState(() { _snkr = data; _snkrLoading = false; });
  }

  Future<void> _loadPsaPop() async {
    final card = widget.card;
    if (card.condition != 'Graded') return;
    final pop = await SupabaseService.getPsaPopForListing(
      psaSpecId: card.psaSpecId,
      psaCert: card.psaCert,
    );
    if (mounted && pop != null) setState(() => _psaPop = pop);
  }

  Future<void> _loadReviewStatus() async {
    if (widget.card.supabaseId == null) return;
    final done = await ReviewService.hasReviewed(widget.card.supabaseId!);
    if (mounted) setState(() => _hasReviewed = done);
  }

  void _openReview() async {
    if (widget.card.seller.id == null) return;
    if (!await requireLogin(context, action: L.writeReview)) return;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewSheet(
        sellerId: widget.card.seller.id!,
        sellerName: widget.card.seller.name,
        listingId: widget.card.supabaseId,
        onSubmitted: () => setState(() => _hasReviewed = true),
      ),
    );
  }

  Future<void> _loadMyOffer() async {
    if (widget.card.supabaseId == null) return;
    final offer = await OfferService.myOfferForListing(widget.card.supabaseId!);
    if (mounted) setState(() => _myOffer = offer);
  }

  void _openOffer() async {
    if (widget.card.supabaseId == null || widget.card.seller.id == null) return;
    if (!await requireLogin(context, action: L.makeOfferAction)) return;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OfferSheet(
        card: widget.card,
        onSent: _loadMyOffer,
      ),
    );
  }

  void _openSellerProfile() {
    if (widget.card.seller.id == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => SellerProfileScreen(
        sellerId: widget.card.seller.id!,
        sellerName: widget.card.seller.name,
      ),
    ));
  }

  String _formatPrice(int price) => price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );

  Future<void> _openIG() async {
    final url = Uri.parse('https://www.instagram.com/$_sellerIg/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // 是否可顯示 SNKRDUNK 參考（賣家有正確填寫系列＋編號）
  bool get _canShowSnkrdunk =>
      widget.card.setId != null &&
      widget.card.setId!.trim().isNotEmpty &&
      widget.card.cardNumber != null &&
      widget.card.cardNumber!.trim().isNotEmpty;

  Future<void> _openSnkrdunk() async {
    final setId = widget.card.setId?.toUpperCase() ?? '';
    final number = widget.card.cardNumber ?? '';
    final query = '$setId $number'.trim();
    final url = Uri.parse(
      'https://snkrdunk.com/search?keywords=${Uri.encodeComponent(query)}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _openChat() async {
    if (!await requireLogin(context, action: L.contactSeller)) return;
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          sellerName: widget.card.seller.name,
          sellerAvatar: widget.card.seller.name.substring(0, 2).toUpperCase(),
          sellerIg: _sellerIg,
          sellerId: widget.card.seller.id,
          card: widget.card,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;

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
        title: Text(L.productDetail,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
        actions: [
          if (!_isMyListing && card.supabaseId != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF374151)),
              onSelected: (v) {
                if (v == 'report') {
                  showReportSheet(context, targetType: 'listing', targetId: card.supabaseId!);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'report', child: Row(children: [
                  const Icon(Icons.flag_outlined, size: 18, color: Color(0xFF6B7280)),
                  const SizedBox(width: 10), Text(L.report),
                ])),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card image area — tappable, supports multiple images
            _ImageCarousel(card: card),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name & type
                  Row(children: [
                    Expanded(
                      child: Text(card.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                              color: Color(0xFF111827))),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: card.type.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: card.type.color.withValues(alpha: 0.3), width: 0.5),
                      ),
                      child: Text(card.type.label,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                              color: card.type.color)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text('${card.grade} · ${card.condition}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                  const SizedBox(height: 16),

                  // Price box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(L.buyPrice, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                      const SizedBox(height: 4),
                      Text('HK\$ ${_formatPrice(_price)}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A))),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // 卡號 badge
                  if (card.cardNumber != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('#${card.cardNumber}',
                          style: const TextStyle(fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151))),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // SNKRDUNK 日本市場成交價
                  if (_canShowSnkrdunk) ...[
                    _SnkrPriceCard(
                      loading: _snkrLoading,
                      data: _snkr,
                      onTap: _openSnkrdunk,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Meta grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 2.8,
                    children: [
                      _metaItem(L.metaGrade, card.grade),
                      _metaItem(L.metaType, card.type.label),
                      _metaItem(L.metaCondition, card.condition),
                      _metaItem(L.metaListedTime, card.timeInfo),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // PSA Pop（鑑定卡才顯示）
                  if (_psaPop != null) _PsaPopCard(pop: _psaPop!),
                  if (_psaPop != null) const SizedBox(height: 12),

                  // 面交地點
                  if (card.meetupLocations.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFFE8A52A)),
                          const SizedBox(width: 4),
                          Text(L.preferredMeetup, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
                        ]),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: card.meetupLocations.map((loc) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFCD34D)),
                            ),
                            child: Text(loc, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFB45309))),
                          )).toList(),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Seller row
                  GestureDetector(
                    onTap: _openSellerProfile,
                    child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
                    ),
                    child: Row(children: [
                      // Avatar
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9EC),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFDE68A), width: 0.5),
                        ),
                        child: Center(
                          child: Text(
                            card.seller.name.substring(0, 2).toUpperCase(),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                color: Color(0xFFE8A52A)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Text(card.seller.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                                  color: Color(0xFF111827))),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 14, color: Color(0xFF9CA3AF)),
                        ]),
                        Row(children: [
                          const Icon(Icons.star, size: 12, color: Color(0xFFE8A52A)),
                          const SizedBox(width: 3),
                          Text(L.sellerStats('${card.seller.rating}', card.seller.sales),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                        ]),
                      ])),

                      // IG button
                      GestureDetector(
                        onTap: _openIG,
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE1306C), Color(0xFFF77737), Color(0xFF833AB4)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
                        ),
                      ),

                      // Message button (隱藏於自己的商品)
                      if (!_isMyListing)
                        GestureDetector(
                          onTap: _openChat,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F4FD),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF2980B9).withValues(alpha: 0.3), width: 0.5),
                            ),
                            child: const Icon(Icons.chat_bubble_outline,
                                color: Color(0xFF2980B9), size: 18),
                          ),
                        ),
                    ]),
                  ),
                  ),

                  // 已成交提示
                  if (_isSold) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD1D5DB)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle, size: 18, color: Color(0xFF6B7280)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          L.soldNotice,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                        )),
                      ]),
                    ),
                  ],

                  // 自己的商品提示
                  if (_isMyListing) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9EC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE8A52A).withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.storefront_outlined, size: 18, color: Color(0xFFE8A52A)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          L.myListingNotice,
                          style: const TextStyle(fontSize: 13, color: Color(0xFFB45309)),
                        )),
                      ]),
                    ),
                  ],

                  // My offer status banner
                  if (!_isMyListing && _myOffer != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _myOffer!.status == 'accepted'
                            ? const Color(0xFFF0FDF4)
                            : _myOffer!.status == 'rejected'
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFFEF9EC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _myOffer!.status == 'accepted'
                              ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                              : _myOffer!.status == 'rejected'
                              ? const Color(0xFFE74C3C).withValues(alpha: 0.3)
                              : const Color(0xFFE8A52A).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(children: [
                        Icon(
                          _myOffer!.status == 'accepted'
                              ? Icons.check_circle_outline
                              : _myOffer!.status == 'rejected'
                              ? Icons.cancel_outlined
                              : Icons.access_time,
                          size: 18,
                          color: _myOffer!.status == 'accepted'
                              ? const Color(0xFF16A34A)
                              : _myOffer!.status == 'rejected'
                              ? const Color(0xFFE74C3C)
                              : const Color(0xFFE8A52A),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(
                          _myOffer!.status == 'accepted'
                              ? L.offerAcceptedBanner(_formatPrice(_myOffer!.amount))
                              : _myOffer!.status == 'rejected'
                              ? L.offerRejectedBanner(_formatPrice(_myOffer!.amount))
                              : L.offerPendingBanner(_formatPrice(_myOffer!.amount)),
                          style: TextStyle(
                            fontSize: 13,
                            color: _myOffer!.status == 'accepted'
                                ? const Color(0xFF16A34A)
                                : _myOffer!.status == 'rejected'
                                ? const Color(0xFFE74C3C)
                                : const Color(0xFFE8A52A),
                          ),
                        )),
                      ]),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom bar
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
          ),
          child: _buildBottomBar(),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    // 自己的商品：不顯示購買/出價/聊天
    if (_isMyListing) {
      return SizedBox(
        height: 50,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.storefront_outlined, size: 18, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Text(L.thisIsYourListing,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                  color: Color(0xFF9CA3AF))),
        ]),
      );
    }

    // 已成交：聯絡賣家 + 評價賣家
    if (_isSold) {
      return Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: _openChat,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8A52A), width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.chat_bubble_outline, color: Color(0xFFE8A52A), size: 16),
                  const SizedBox(width: 6),
                  Text(L.contactSellerBtn,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: Color(0xFFE8A52A))),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: _hasReviewed ? null : _openReview,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: _hasReviewed ? const Color(0xFFF3F4F6) : const Color(0xFFE8A52A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_hasReviewed ? Icons.check : Icons.star_outline,
                      color: _hasReviewed ? const Color(0xFF9CA3AF) : Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(_hasReviewed ? L.reviewed : L.reviewSeller,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                          color: _hasReviewed ? const Color(0xFF9CA3AF) : Colors.white)),
                ],
              ),
            ),
          ),
        ),
      ]);
    }

    // 一般狀態
    return Row(children: [
      // Fav button
      GestureDetector(
        onTap: () {
          setState(() => _faved = !_faved);
          widget.onFavChanged(_faved);
        },
        child: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD1D5DB), width: 0.5),
          ),
          child: Icon(
            _faved ? Icons.favorite : Icons.favorite_border,
            color: _faved ? const Color(0xFFE74C3C) : const Color(0xFF374151),
          ),
        ),
      ),
      const SizedBox(width: 8),

      // Chat
      Expanded(
        child: GestureDetector(
          onTap: _openChat,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8A52A), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.chat_bubble_outline, color: Color(0xFFE8A52A), size: 16),
                const SizedBox(width: 5),
                Text(L.contactShort, style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w500, color: Color(0xFFE8A52A))),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(width: 8),

      // Make offer
      Expanded(
        child: GestureDetector(
          onTap: _myOffer?.status == 'pending' ? null : _openOffer,
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: _myOffer?.status == 'pending'
                  ? const Color(0xFFF3F4F6)
                  : const Color(0xFF8E44AD).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _myOffer?.status == 'pending'
                    ? const Color(0xFFE5E7EB)
                    : const Color(0xFF8E44AD).withValues(alpha: 0.4),
              ),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.local_offer_outlined, size: 16,
                  color: _myOffer?.status == 'pending'
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF8E44AD)),
              const SizedBox(width: 5),
              Text(_myOffer?.status == 'pending' ? L.offering : L.makeOfferShort,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                      color: _myOffer?.status == 'pending'
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF8E44AD))),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 8),

      // Buy now
      Expanded(
        flex: 2,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE8A52A),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: Text('HK\$${_formatPrice(_price)}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }

  Widget _metaItem(String label, String value) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
              overflow: TextOverflow.ellipsis),
        ]),
  );
}

// ── SNKRDUNK 日本市場成交價 ──────────────────────────────────────────────────
class _SnkrPriceCard extends StatelessWidget {
  final bool loading;
  final Map<String, dynamic>? data;
  final VoidCallback onTap;

  const _SnkrPriceCard({required this.loading, required this.data, required this.onTap});

  String _yen(num? v) => v == null ? '—'
      : '¥${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Colors.white],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8A52A).withValues(alpha: 0.35), width: 0.8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // header
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFFE8A52A), borderRadius: BorderRadius.circular(9)),
            child: const Center(child: Text('🇯🇵', style: TextStyle(fontSize: 18)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(L.snkrTitle,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            Text(L.snkrSubtitle,
                style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
          ])),
          GestureDetector(
            onTap: onTap,
            child: const Icon(Icons.open_in_new, size: 16, color: Color(0xFFE8A52A))),
        ]),
        const SizedBox(height: 12),
        if (loading)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(L.snkrLoading, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))))
        else if (data == null)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(L.snkrNoData,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))))
        else ...[
          Row(children: [
            Expanded(child: _gradeBox('PSA 10', data!['psa10'], const Color(0xFFE8A52A))),
            const SizedBox(width: 8),
            Expanded(child: _gradeBox('PSA 9', data!['psa9'], const Color(0xFF2980B9))),
            const SizedBox(width: 8),
            Expanded(child: _gradeBox(L.rawCard, data!['raw'], const Color(0xFF6B7280))),
          ]),
          if (data!['psa10'] is Map &&
              (((data!['psa10'] as Map)['daily'] as List?)?.length ?? 0) >= 2)
            _SnkrChart(
              daily: (data!['psa10'] as Map)['daily'] as List,
              chg7: (data!['psa10'] as Map)['chg7'] as num?,
              chg30: (data!['psa10'] as Map)['chg30'] as num?,
            ),
          ..._recentList(),
        ],
      ]),
    );
  }

  Widget _gradeBox(String label, dynamic g, Color color) {
    final m = g as Map<String, dynamic>?;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(m == null ? '—' : _yen(m['avg'] as num?),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(m == null ? L.noSales : L.salesCount(m['count']),
            style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
      ]),
    );
  }

  List<Widget> _recentList() {
    final psa10 = data!['psa10'] as Map<String, dynamic>?;
    final recent = (psa10?['recent'] as List?) ?? [];
    if (recent.isEmpty) return [];
    return [
      const SizedBox(height: 12),
      Text(L.snkrRecent,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
      const SizedBox(height: 6),
      ...recent.take(5).map((r) {
        final item = r as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Expanded(child: Text('${item['date']}',
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)))),
            Text(_yen(item['price'] as num?),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: Color(0xFFE8A52A))),
          ]),
        );
      }),
    ];
  }
}

// ── SNKRDUNK PSA10 走勢圖 ─────────────────────────────────────────────────────
class _SnkrChart extends StatefulWidget {
  final List daily;
  final num? chg7;
  final num? chg30;
  const _SnkrChart({required this.daily, this.chg7, this.chg30});
  @override
  State<_SnkrChart> createState() => _SnkrChartState();
}

class _SnkrChartState extends State<_SnkrChart> {
  bool _show30 = false;

  String _chgStr(num? v) => v == null ? '—'
      : '${v >= 0 ? '▲' : '▼'} ${v.abs().toStringAsFixed(1)}%';
  Color _chgColor(num? v) =>
      v == null ? const Color(0xFF9CA3AF) : v >= 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final pts = widget.daily
        .map((e) => (e as Map)['price'] as num? ?? 0)
        .map((v) => v.toDouble())
        .toList();
    final show = _show30 ? pts : pts.take(7).toList();
    final chg = _show30 ? widget.chg30 : widget.chg7;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 12),
      Row(children: [
        Text(L.snkrTrend,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        const Spacer(),
        _tab(L.days7, !_show30), const SizedBox(width: 6), _tab(L.days30, _show30),
        const SizedBox(width: 8),
        Text(_chgStr(chg),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _chgColor(chg))),
      ]),
      const SizedBox(height: 6),
      SizedBox(height: 50, child: CustomPaint(painter: _MiniLinePainter(show), size: Size.infinite)),
    ]);
  }

  Widget _tab(String label, bool active) => GestureDetector(
    onTap: () => setState(() => _show30 = label == L.days30),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(
          fontSize: 10, fontWeight: FontWeight.w600,
          color: active ? Colors.white : const Color(0xFF6B7280))),
    ),
  );
}

class _MiniLinePainter extends CustomPainter {
  final List<double> points;
  _MiniLinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final mn = points.reduce((a, b) => a < b ? a : b);
    final mx = points.reduce((a, b) => a > b ? a : b);
    final range = (mx - mn).clamp(1.0, double.infinity);
    final dx = size.width / (points.length - 1);
    final paint = Paint()
      ..color = const Color(0xFFE8A52A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = i * dx;
      final y = size.height - (points[i] - mn) / range * size.height;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_MiniLinePainter old) => old.points != points;
}

// ── Image carousel with tap-to-zoom ──────────────────────────────────────────
class _ImageCarousel extends StatefulWidget {
  final PokemonCard card;
  const _ImageCarousel({required this.card});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  int _current = 0;

  void _openViewer(int index) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ImageViewerScreen(
        imageUrls: widget.card.imageUrls,
        initialIndex: index,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final urls = widget.card.imageUrls;
    if (urls.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity, height: 240,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
          ),
          child: Center(child: CardTypeIcon(type: widget.card.type, size: 120)),
        ),
      );
    }

    return Column(children: [
      // Main image
      GestureDetector(
        onTap: () => _openViewer(_current),
        child: Container(
          width: double.infinity, height: 260,
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(children: [
              Hero(
                tag: urls[_current],
                child: CachedNetworkImage(
                  imageUrl: urls[_current],
                  width: double.infinity, height: 260,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => NoImagePlaceholder(
                      background: widget.card.type.bgColor,
                      icon: CardTypeIcon(type: widget.card.type, size: 80)),
                  errorWidget: (_, __, ___) => NoImagePlaceholder(
                      background: widget.card.type.bgColor,
                      icon: CardTypeIcon(type: widget.card.type, size: 80)),
                ),
              ),
              // Zoom hint
              Positioned(
                bottom: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.zoom_in, color: Colors.white, size: 16),
                ),
              ),
            ]),
          ),
        ),
      ),

      // Thumbnail strip (if multiple images)
      if (urls.length > 1) ...[
        const SizedBox(height: 10),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: urls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => GestureDetector(
              onTap: () => setState(() => _current = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 60, height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: i == _current
                        ? const Color(0xFFE8A52A)
                        : const Color(0xFFE5E7EB),
                    width: i == _current ? 2 : 1,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: CachedNetworkImage(
                    imageUrl: urls[i],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: const Color(0xFFF3F4F6)),
                    errorWidget: (_, __, ___) =>
                        Container(color: const Color(0xFFF3F4F6)),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      const SizedBox(height: 8),
    ]);
  }
}

class _PsaPopCard extends StatelessWidget {
  final Map<String, dynamic> pop;
  const _PsaPopCard({required this.pop});

  @override
  Widget build(BuildContext context) {
    final fetchedAt = pop['fetched_at'] as String?;
    final dateStr = fetchedAt != null
        ? DateTime.tryParse(fetchedAt)?.toLocal().toString().substring(0, 10) ?? ''
        : '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF2980B9),
              borderRadius: BorderRadius.circular(6)),
            child: const Text('PSA Pop', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
          const SizedBox(width: 8),
          if (pop['card_name'] != null)
            Expanded(child: Text(pop['card_name'] as String,
                style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                overflow: TextOverflow.ellipsis)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _PopCell('PSA 10', pop['pop_10'] as int? ?? 0, const Color(0xFF2980B9)),
          const SizedBox(width: 6),
          _PopCell('PSA 9', pop['pop_9'] as int? ?? 0, const Color(0xFF27AE60)),
          const SizedBox(width: 6),
          _PopCell('PSA 8', pop['pop_8'] as int? ?? 0, const Color(0xFF8E44AD)),
          const SizedBox(width: 6),
          _PopCell('Auth', pop['pop_auth'] as int? ?? 0, const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          _PopCell('Total', pop['total'] as int? ?? 0, const Color(0xFFE8A52A)),
        ]),
        if (dateStr.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(L.psaUpdated(dateStr),
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ],
      ]),
    );
  }
}

class _PopCell extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _PopCell(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50), width: 0.5),
      ),
      child: Column(children: [
        Text('$count', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280))),
      ]),
    ));
  }
}
