import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/card_model.dart';
import '../widgets/card_type_icon.dart';
import '../services/offer_service.dart';
import '../services/auth_service.dart';
import '../services/review_service.dart';
import '../widgets/login_required.dart';
import '../data/set_name_zh.dart';
import 'chat_screen.dart';
import 'offer_sheet.dart';
import 'seller_profile_screen.dart';
import 'image_viewer_screen.dart';
import 'review_sheet.dart';

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
  }

  Future<void> _loadReviewStatus() async {
    if (widget.card.supabaseId == null) return;
    final done = await ReviewService.hasReviewed(widget.card.supabaseId!);
    if (mounted) setState(() => _hasReviewed = done);
  }

  void _openReview() async {
    if (widget.card.seller.id == null) return;
    if (!await requireLogin(context, action: '撰寫評價')) return;
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
    if (!await requireLogin(context, action: '出價')) return;
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
    if (!await requireLogin(context, action: '聯絡賣家')) return;
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
        title: const Text('商品詳情',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF374151)),
            onPressed: () {},
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
                        color: card.type.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: card.type.color.withOpacity(0.3), width: 0.5),
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
                      const Text('直購價', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
                      const SizedBox(height: 4),
                      Text('HK\$ ${_formatPrice(_price)}',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A))),
                    ]),
                  ),
                  const SizedBox(height: 12),

                  // 系列 + 卡號 badge（有資料才顯示）
                  if (card.setId != null || card.cardNumber != null) ...[
                    Wrap(spacing: 8, runSpacing: 8, children: [
                      if (card.setId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF9EC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE8A52A).withOpacity(0.4)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Icon(Icons.collections_bookmark_outlined,
                                size: 13, color: Color(0xFFE8A52A)),
                            const SizedBox(width: 5),
                            Text(
                              '${kSetNameZh[card.setId!.toLowerCase()] ?? card.setId!.toUpperCase()}'
                              ' (${card.setId!.toUpperCase()})',
                              style: const TextStyle(fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFB45309)),
                            ),
                          ]),
                        ),
                      if (card.cardNumber != null)
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
                    ]),
                    const SizedBox(height: 12),
                  ],

                  // SNKRDUNK 市場參考（賣家有正確填寫系列＋編號才顯示）
                  if (_canShowSnkrdunk) ...[
                    _SnkrdunkRefCard(
                      setLabel: kSetNameZh[card.setId!.toLowerCase()] ?? card.setId!.toUpperCase(),
                      cardNumber: card.cardNumber!,
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
                      _metaItem('評級', card.grade),
                      _metaItem('類型', card.type.label),
                      _metaItem('狀況', card.condition),
                      _metaItem('上架時間', card.timeInfo),
                    ],
                  ),
                  const SizedBox(height: 12),

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
                          Text('${card.seller.rating} · ${card.seller.sales} 筆成交',
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
                              border: Border.all(color: const Color(0xFF2980B9).withOpacity(0.3), width: 0.5),
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
                      child: const Row(children: [
                        Icon(Icons.check_circle, size: 18, color: Color(0xFF6B7280)),
                        SizedBox(width: 8),
                        Expanded(child: Text(
                          '此商品已成交，僅買賣雙方可查看',
                          style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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
                        border: Border.all(color: const Color(0xFFE8A52A).withOpacity(0.3)),
                      ),
                      child: const Row(children: [
                        Icon(Icons.storefront_outlined, size: 18, color: Color(0xFFE8A52A)),
                        SizedBox(width: 8),
                        Expanded(child: Text(
                          '這是你的商品，可在「我的 → 我的掛售」管理',
                          style: TextStyle(fontSize: 13, color: Color(0xFFB45309)),
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
                              ? const Color(0xFF16A34A).withOpacity(0.3)
                              : _myOffer!.status == 'rejected'
                              ? const Color(0xFFE74C3C).withOpacity(0.3)
                              : const Color(0xFFE8A52A).withOpacity(0.3),
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
                              ? '賣家已接受你的出價 HK\$${_formatPrice(_myOffer!.amount)}！請前往聊天室溝通交易'
                              : _myOffer!.status == 'rejected'
                              ? '你的出價 HK\$${_formatPrice(_myOffer!.amount)} 已被拒絕'
                              : '你已出價 HK\$${_formatPrice(_myOffer!.amount)}，等待賣家回覆',
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
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Icon(Icons.storefront_outlined, size: 18, color: Color(0xFF9CA3AF)),
          SizedBox(width: 8),
          Text('這是你的商品',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, color: Color(0xFFE8A52A), size: 16),
                  SizedBox(width: 6),
                  Text('聯絡賣家',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
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
                  Text(_hasReviewed ? '已評價' : '評價賣家',
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
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat_bubble_outline, color: Color(0xFFE8A52A), size: 16),
                SizedBox(width: 5),
                Text('聯絡', style: TextStyle(fontSize: 13,
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
                  : const Color(0xFF8E44AD).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _myOffer?.status == 'pending'
                    ? const Color(0xFFE5E7EB)
                    : const Color(0xFF8E44AD).withOpacity(0.4),
              ),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.local_offer_outlined, size: 16,
                  color: _myOffer?.status == 'pending'
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF8E44AD)),
              const SizedBox(width: 5),
              Text(_myOffer?.status == 'pending' ? '出價中' : '出價',
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

// ── SNKRDUNK 市場參考卡片 ─────────────────────────────────────────────────────
class _SnkrdunkRefCard extends StatelessWidget {
  final String setLabel;
  final String cardNumber;
  final VoidCallback onTap;

  const _SnkrdunkRefCard({
    required this.setLabel,
    required this.cardNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFFBEB), Color(0xFFFFFFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE8A52A).withOpacity(0.35), width: 0.8),
        ),
        child: Row(children: [
          // Icon badge
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFE8A52A),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE8A52A).withOpacity(0.3),
                  blurRadius: 8, offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(child: Text('🇯🇵', style: TextStyle(fontSize: 20))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('SNKRDUNK 日本市場行情',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700,
                        color: Color(0xFF111827))),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8A52A).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('參考',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309))),
                ),
              ]),
              const SizedBox(height: 3),
              Text('查 $setLabel #$cardNumber 的日拍成交價',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: const Color(0xFFE8A52A).withOpacity(0.1),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.open_in_new, size: 15, color: Color(0xFFE8A52A)),
          ),
        ]),
      ),
    );
  }
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
                  placeholder: (_, __) =>
                      Center(child: CardTypeIcon(type: widget.card.type, size: 100)),
                  errorWidget: (_, __, ___) =>
                      Center(child: CardTypeIcon(type: widget.card.type, size: 100)),
                ),
              ),
              // Zoom hint
              Positioned(
                bottom: 8, right: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
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
