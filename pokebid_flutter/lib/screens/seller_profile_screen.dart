import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/card_model.dart';
import '../services/listing_service.dart';
import '../services/follow_service.dart';
import '../services/profile_service.dart';
import '../widgets/login_required.dart';
import '../widgets/verified_badge.dart';
import '../widgets/ig_link.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../services/review_service.dart';
import 'card_detail_screen.dart';
import 'chat_screen.dart';
import '../i18n/strings.dart';
import '../services/block_service.dart';
import '../widgets/report_sheet.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  List<PokemonCard> _listings = [];
  String _condFilter = 'all'; // 'all' | 'graded' | 'raw'
  List<PokemonCard> get _shownListings => _condFilter == 'all'
      ? _listings
      : _listings.where((c) =>
          _condFilter == 'graded' ? c.condition == 'Graded' : c.condition == 'Raw').toList();
  bool _loading = true;
  bool _following = false;
  int _followerCount = 0;
  bool _followLoading = false;
  String? _myId;
  SellerStats _stats = const SellerStats(0, 0);
  List<Review> _reviews = [];
  bool _sellerVerified = false;
  String _sellerIg = '';
  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _myId = AuthService.isLoggedIn
        ? AuthService.userId
        : await SupabaseService.getUserId();

    final results = await Future.wait([
      _loadListings(),
      FollowService.isFollowing(widget.sellerId),
      FollowService.followerCount(widget.sellerId),
      ReviewService.statsForSeller(widget.sellerId),
      ReviewService.getForSeller(widget.sellerId),
      ProfileService.getProfile(widget.sellerId),
    ]);

    if (mounted) {
      setState(() {
        _following = results[1] as bool;
        _followerCount = results[2] as int;
        _stats = results[3] as SellerStats;
        _reviews = results[4] as List<Review>;
        final sp = results[5] as UserProfile?;
        _sellerVerified = sp?.phoneVerified ?? false;
        _sellerIg = sp?.igHandle ?? '';
        _loading = false;
      });
    }
    final blocked = await BlockService.isBlocked(widget.sellerId);
    if (mounted) setState(() => _isBlocked = blocked);
  }

  Future<void> _toggleBlock() async {
    if (!await requireLogin(context, action: L.blockNeedLogin)) return;
    if (!mounted) return;
    if (_isBlocked) {
      await BlockService.unblock(widget.sellerId);
      if (mounted) {
        setState(() => _isBlocked = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L.unblocked)));
      }
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(L.block, style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Text(L.blockConfirm(widget.sellerName)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(L.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE74C3C), foregroundColor: Colors.white),
            child: Text(L.block),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await BlockService.block(widget.sellerId);
    if (mounted) {
      setState(() => _isBlocked = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L.blocked)));
    }
  }

  Future<List<PokemonCard>> _loadListings() async {
    try {
      final res = await Supabase.instance.client
          .from('listings')
          .select()
          .eq('seller_id', widget.sellerId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      final cards = (res as List).map((r) => ListingService.fromRowPublic(r)).toList();
      if (mounted) setState(() => _listings = cards);
      return cards;
    } catch (_) {
      return [];
    }
  }

  Future<void> _toggleFollow() async {
    if (_myId == widget.sellerId) return;
    if (!await requireLogin(context, action: L.followSeller)) return;
    setState(() => _followLoading = true);
    try {
      if (_following) {
        await FollowService.unfollow(widget.sellerId);
        setState(() { _following = false; _followerCount--; });
      } else {
        await FollowService.follow(widget.sellerId);
        setState(() { _following = true; _followerCount++; });
      }
    } finally {
      if (mounted) setState(() => _followLoading = false);
    }
  }

  String _fmt(int p) => p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Widget _condTab(String key, String label) {
    final active = _condFilter == key;
    final count = key == 'all'
        ? _listings.length
        : _listings.where((c) =>
            key == 'graded' ? c.condition == 'Graded' : c.condition == 'Raw').length;
    return GestureDetector(
      onTap: () => setState(() => _condFilter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('$label ($count)',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600,
                color: active ? Colors.white : const Color(0xFF6B7280))),
      ),
    );
  }

  bool get _isSelf => _myId == widget.sellerId;

  @override
  Widget build(BuildContext context) {
    final initials = widget.sellerName.length >= 2
        ? widget.sellerName.substring(0, 2).toUpperCase()
        : widget.sellerName.toUpperCase();

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
        title: Text(L.sellerHome,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500,
                color: Color(0xFF111827))),
        actions: [
          if (!_isSelf)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF374151)),
              onSelected: (v) {
                if (v == 'report') {
                  showReportSheet(context, targetType: 'user', targetId: widget.sellerId);
                } else if (v == 'block') {
                  _toggleBlock();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'report', child: Row(children: [
                  const Icon(Icons.flag_outlined, size: 18, color: Color(0xFF6B7280)),
                  const SizedBox(width: 10), Text(L.report),
                ])),
                PopupMenuItem(value: 'block', child: Row(children: [
                  Icon(_isBlocked ? Icons.lock_open_outlined : Icons.block,
                      size: 18, color: const Color(0xFFE74C3C)),
                  const SizedBox(width: 10),
                  Text(_isBlocked ? L.unblock : L.block,
                      style: const TextStyle(color: Color(0xFFE74C3C))),
                ])),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFFE8A52A), strokeWidth: 2))
          : CustomScrollView(
              slivers: [
                // ── Profile header ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(children: [
                      // Avatar
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF9EC),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFDE68A), width: 2),
                        ),
                        child: Center(child: Text(initials,
                            style: const TextStyle(fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE8A52A)))),
                      ),
                      const SizedBox(height: 12),

                      Row(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
                        Flexible(child: Text(widget.sellerName,
                            style: const TextStyle(fontSize: 18,
                                fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                        if (_sellerVerified) ...[
                          const SizedBox(width: 5),
                          const VerifiedBadge(size: 17),
                        ],
                        if (_sellerIg.trim().isNotEmpty) ...[
                          const SizedBox(width: 5),
                          IgLink(handle: _sellerIg, size: 15),
                        ],
                      ]),
                      const SizedBox(height: 4),

                      // Stats row
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _stat('$_followerCount', L.followers),
                        _divider(),
                        _stat('${_listings.length}', L.listingActive),
                        _divider(),
                        _stat(
                          _stats.count > 0 ? _stats.avgRating.toStringAsFixed(1) : '—',
                          L.ratingCount(_stats.count),
                          star: _stats.count > 0,
                        ),
                      ]),
                      const SizedBox(height: 16),

                      // Action buttons
                      if (!_isSelf) Row(children: [
                        // Follow button
                        Expanded(
                          child: GestureDetector(
                            onTap: _followLoading ? null : _toggleFollow,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              height: 44,
                              decoration: BoxDecoration(
                                color: _following
                                    ? const Color(0xFFF3F4F6)
                                    : const Color(0xFFE8A52A),
                                borderRadius: BorderRadius.circular(12),
                                border: _following
                                    ? Border.all(color: const Color(0xFFE5E7EB))
                                    : null,
                              ),
                              child: Center(
                                child: _followLoading
                                    ? const SizedBox(width: 18, height: 18,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFFE8A52A)))
                                    : Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(
                                          _following
                                              ? Icons.person_remove_outlined
                                              : Icons.person_add_outlined,
                                          size: 16,
                                          color: _following
                                              ? const Color(0xFF6B7280)
                                              : Colors.white,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(_following ? L.following : L.follow,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _following
                                                  ? const Color(0xFF6B7280)
                                                  : Colors.white,
                                            )),
                                      ]),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Message button
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              sellerName: widget.sellerName,
                              sellerAvatar: initials,
                              sellerId: widget.sellerId,
                            ),
                          )),
                          child: Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F4FD),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: const Color(0xFF2980B9).withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.chat_bubble_outline,
                                color: Color(0xFF2980B9), size: 20),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // ── Reviews section ─────────────────────────────────────
                if (_reviews.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                      child: Text(L.buyerReviews(_reviews.length),
                          style: const TextStyle(fontSize: 15,
                              fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 130,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _reviews.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => _reviewCard(_reviews[i]),
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],

                // ── Listings section header ─────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Text(L.sellerListings(_listings.length),
                        style: const TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                  ),
                ),

                // ── 分類：全部 / 鑑定卡 / Raw ────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                    child: Row(children: [
                      _condTab('all', '全部'),
                      const SizedBox(width: 8),
                      _condTab('graded', '鑑定卡'),
                      const SizedBox(width: 8),
                      _condTab('raw', 'Raw'),
                    ]),
                  ),
                ),

                // ── Listings grid ───────────────────────────────────────
                _shownListings.isEmpty
                    ? SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Center(child: Text(L.noListings,
                              style: const TextStyle(color: Color(0xFF9CA3AF)))),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) {
                              final card = _shownListings[i];
                              return GestureDetector(
                                onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) =>
                                        CardDetailScreen(card: card,
                                            isFavorited: false,
                                            onFavChanged: (_) {}))),
                                child: _ListingGridItem(
                                    card: card, formatPrice: _fmt,
                                    compact: _condFilter == 'raw'),
                              );
                            },
                            childCount: _shownListings.length,
                          ),
                          // raw 分類：像圖鑑一行 4 張；其他 2 張
                          gridDelegate: _condFilter == 'raw'
                              ? const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 4,
                                  crossAxisSpacing: 6,
                                  mainAxisSpacing: 6,
                                  childAspectRatio: 0.56,
                                )
                              : const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.72,
                                ),
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _reviewCard(Review r) => Container(
    width: 240,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        ...List.generate(5, (i) => Icon(
          i < r.rating ? Icons.star : Icons.star_border,
          size: 14, color: const Color(0xFFE8A52A))),
        const Spacer(),
        Text('${r.createdAt.month}/${r.createdAt.day}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
      ]),
      const SizedBox(height: 8),
      Expanded(
        child: Text(
          r.comment?.isNotEmpty == true ? r.comment! : L.noTextReview,
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF374151), height: 1.4),
          maxLines: 3, overflow: TextOverflow.ellipsis,
        ),
      ),
      const SizedBox(height: 6),
      Text('— ${r.reviewerName}',
          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
    ]),
  );

  Widget _divider() => Container(width: 1, height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: const Color(0xFFE5E7EB));

  Widget _stat(String value, String label, {bool star = false}) => Column(children: [
    Row(mainAxisSize: MainAxisSize.min, children: [
      if (star) ...[
        const Icon(Icons.star, size: 15, color: Color(0xFFE8A52A)),
        const SizedBox(width: 2),
      ],
      Text(value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              color: Color(0xFF111827))),
    ]),
    Text(label,
        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
  ]);
}

class _ListingGridItem extends StatelessWidget {
  final PokemonCard card;
  final String Function(int) formatPrice;
  final bool compact; // 4 欄 raw：縮小字級/間距

  const _ListingGridItem({required this.card, required this.formatPrice, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // 圖片吃掉剩餘空間
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            child: card.imageUrls.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: card.imageUrls.first,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _placeholder(),
                    errorWidget: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
        ),
        // 資訊區：內容自適應高度（無多餘留白）
        Padding(
          padding: compact
              ? const EdgeInsets.fromLTRB(5, 4, 5, 6)
              : const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(child: Text(card.name,
                    style: TextStyle(fontSize: compact ? 10 : 12,
                        fontWeight: FontWeight.w700, color: const Color(0xFF111827)),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 4),
                _gradeChip(card.grade),
              ]),
              SizedBox(height: compact ? 2 : 4),
              Text('HK\$${formatPrice(card.price)}',
                  style: TextStyle(fontSize: compact ? 11 : 14,
                      fontWeight: FontWeight.w800, color: const Color(0xFF16A34A))),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _gradeChip(String grade) {
    final g = grade.trim();
    final gu = g.toUpperCase();
    // raw 品相：A/B/C/流通品/Raw；鑑定卡：PSA/CGC 10/9…
    const rawColors = {
      'A': Color(0xFF16A34A),   // 綠
      'B': Color(0xFF2980B9),   // 藍
      'C': Color(0xFFE8A52A),   // 橙
      '流通品': Color(0xFF6B7280), // 灰
      'RAW': Color(0xFF6B7280),
    };
    final Color c;
    final String label;
    if (rawColors.containsKey(g) || rawColors.containsKey(gu)) {
      c = rawColors[g] ?? rawColors[gu]!;
      label = gu == 'RAW' ? 'Raw' : g; // 品相
    } else if (gu.contains('10')) {
      c = const Color(0xFFE8A52A);
      label = grade;
    } else if (gu.contains('9')) {
      c = const Color(0xFF2980B9);
      label = grade;
    } else {
      c = const Color(0xFF6B7280);
      label = grade;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(label,
          style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: c)),
    );
  }

  Widget _placeholder() => Container(
    color: card.type.bgColor,
    child: Center(child: Text(card.type.emoji,
        style: const TextStyle(fontSize: 32))),
  );
}
