import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/card_model.dart';
import '../services/announcement_service.dart';
import '../services/admin_service.dart';
import 'card_detail_screen.dart';
import 'announcement_detail_screen.dart';
import 'nearby_shops_screen.dart';
import 'wishlist_screen.dart';
import '../widgets/pixel_icon.dart';
import 'admin/post_announcement_sheet.dart';
import 'conversations_list_screen.dart';
import '../widgets/notification_bell.dart';
import '../widgets/unread_dot.dart';
import '../widgets/no_image_placeholder.dart';
import '../services/notification_service.dart';
import '../services/recently_viewed_service.dart';
import '../services/listing_service.dart';
import '../i18n/strings.dart';

class HomeScreen extends StatefulWidget {
  final List<PokemonCard> listings;
  final bool loading;

  const HomeScreen({super.key, required this.listings, this.loading = false});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerCtrl = PageController(viewportFraction: 0.9);
  int _bannerPage = 0;

  List<Announcement> _announcements = [];
  List<Map<String, dynamic>> _recentlyViewed = [];
  bool _isAdmin = false;
  StreamSubscription<void>? _recentSub;

  // Fallback announcements shown while loading or if Supabase has none
  static const List<Map<String, dynamic>> _fallback = [
    {'colorHex': 'E8A52A', 'icon': '🎴'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    _checkAdmin();
    _loadRecentlyViewed();
    _recentSub = RecentlyViewedService.onChange.listen((_) => _loadRecentlyViewed());
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 4));
      if (!mounted) return false;
      final count = _announcements.isNotEmpty ? _announcements.length : _fallback.length;
      final next = (_bannerPage + 1) % count;
      if (_bannerCtrl.hasClients) {
        _bannerCtrl.animateToPage(next,
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeInOut);
      }
      return true;
    });
  }

  @override
  void dispose() {
    _recentSub?.cancel();
    _bannerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAnnouncements() async {
    final list = await AnnouncementService.getAnnouncements();
    if (mounted) setState(() => _announcements = list);
  }

  Future<void> _loadRecentlyViewed() async {
    final list = await RecentlyViewedService.getAll();
    if (mounted) setState(() => _recentlyViewed = list);
  }

  Future<void> _checkAdmin() async {
    final result = await AdminService.isAdmin();
    if (mounted) setState(() => _isAdmin = result);
  }

  void _openPostAnnouncement() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostAnnouncementSheet(
        onPosted: _loadAnnouncements,
      ),
    );
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
        titleSpacing: 16,
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
            children: [
              TextSpan(text: 'Poke'),
              TextSpan(text: 'Bid', style: TextStyle(color: Color(0xFFE8A52A))),
            ],
          ),
        ),
        actions: [
          if (_isAdmin)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: _openPostAnnouncement,
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8A52A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    const Icon(Icons.add, color: Colors.white, size: 14),
                    const SizedBox(width: 3),
                    Text(L.navPost, style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: Colors.white)),
                  ]),
                ),
              ),
            ),
          UnreadDot(
            types: const ['message'],
            child: IconButton(
              icon: const Icon(Icons.forum_outlined, color: Color(0xFF374151)),
              tooltip: L.messages,
              onPressed: () {
                NotificationService.markReadByTypes(['message']);
                Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const ConversationsListScreen()));
              },
            ),
          ),
          const NotificationBell(),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        children: [
          const SizedBox(height: 14),

          // ── Official Announcements Banner ──────────────────────────────
          SizedBox(
            height: 190,
            child: _announcements.isEmpty
                ? PageView(
                    controller: _bannerCtrl,
                    children: [
                      _FallbackBannerCard(data: _fallback.first),
                    ],
                  )
                : PageView.builder(
                    controller: _bannerCtrl,
                    itemCount: _announcements.length,
                    onPageChanged: (i) => setState(() => _bannerPage = i),
                    itemBuilder: (_, i) {
                      final a = _announcements[i];
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => AnnouncementDetailScreen(announcement: a),
                        )),
                        child: _BannerCard(announcement: a),
                      );
                    },
                  ),
          ),

          // Dots
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _announcements.isNotEmpty ? _announcements.length : 1,
                (i) {
                final active = i == _bannerPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFE8A52A) : const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 8),

          // ── 卡鋪 + 心願清單入口（平排，像素風）──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NearbyShopsScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
                  ),
                  child: Column(children: [
                    const PixelIcon(grid: kPixelShop, palette: kPixelPalette, size: 34),
                    const SizedBox(height: 8),
                    Text(L.nearbyShops,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    const SizedBox(height: 2),
                    Text(L.nearbyShopsSubtitle,
                        textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
                  ]),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WishlistScreen())),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
                  ),
                  child: Column(children: [
                    const PixelIcon(grid: kPixelHeart, palette: kPixelPalette, size: 34),
                    const SizedBox(height: 8),
                    Text(L.wishlistEntryTitle,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
                    const SizedBox(height: 2),
                    Text(L.wishlistEntrySubtitle,
                        textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
                  ]),
                ),
              )),
            ])),
          ),

          // ── 最近瀏覽 ────────────────────────────────────────────────────
          if (_recentlyViewed.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Row(children: [
                Text(L.recentlyViewed,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
                const Spacer(),
                GestureDetector(
                  onTap: () async {
                    await RecentlyViewedService.clear();
                    if (mounted) setState(() => _recentlyViewed = []);
                  },
                  child: Text(L.clear,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
                ),
              ]),
            ),
            SizedBox(
              height: 160,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                itemCount: _recentlyViewed.length,
                itemBuilder: (_, i) {
                  final item = _recentlyViewed[i];
                  return _RecentCard(
                    item: item,
                    formatPrice: _fmt,
                    onTap: () async {
                      final id = item['id'] as String?;
                      if (id == null) return;
                      final card = await ListingService.getListingById(id);
                      if (!mounted || card == null) return;
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CardDetailScreen(
                            card: card, isFavorited: false, onFavChanged: (_) {})));
                      _loadRecentlyViewed();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
          ],

          // ── Latest Listings ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(children: [
              Text(L.latestListings,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              const Spacer(),
              Text(L.viewAll,
                  style: const TextStyle(fontSize: 13, color: Color(0xFFE8A52A), fontWeight: FontWeight.w500)),
            ]),
          ),

          // 4-column grid
          if (widget.loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(
                  color: Color(0xFFE8A52A), strokeWidth: 2)),
            )
          else if (widget.listings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text(L.noListings,
                  style: const TextStyle(color: Color(0xFF9CA3AF)))),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: LayoutBuilder(builder: (ctx, c) {
                const infoH = 64.0; // 資訊區固定高度（名字+分級+價格）
                final cellW = (c.maxWidth - 10) / 2; // 扣間距
                final ar = cellW / (cellW + infoH);
                return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: ar,
                ),
                itemCount: widget.listings.take(6).length,
                itemBuilder: (_, i) {
                  final card = widget.listings[i];
                  return _GridListingCard(
                    card: card,
                    formatPrice: _fmt,
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(
                        builder: (_) => CardDetailScreen(
                            card: card, isFavorited: false, onFavChanged: (_) {})));
                      _loadRecentlyViewed();
                    },
                  );
                },
              );
              }),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// ── Banner Card ───────────────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  final Announcement announcement;

  const _BannerCard({required this.announcement});

  Color get _color {
    try {
      final hex = announcement.colorHex.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFFE8A52A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    final hasCover = announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty;

    // 有封面圖：整張用封面當背景 + 深色漸層 + 白字
    if (hasCover) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
        child: Stack(fit: StackFit.expand, children: [
          CachedNetworkImage(
            imageUrl: announcement.imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(color: color.withOpacity(0.1)),
            errorWidget: (_, __, ___) => Container(color: color.withOpacity(0.1)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.75), Colors.black.withOpacity(0.1), Colors.transparent],
              ),
            ),
          ),
          Positioned(
            left: 16, right: 16, bottom: 14,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Text(announcement.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Expanded(child: Text(announcement.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
              if (announcement.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(announcement.subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ]),
          ),
        ]),
      );
    }

    // 無封面：原本的色塊版
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(announcement.icon,
              style: const TextStyle(fontSize: 28))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(announcement.title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Text(announcement.subtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 20),
      ]),
    );
  }
}

class _FallbackBannerCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _FallbackBannerCard({required this.data});

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFFE8A52A);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
      ),
      child: Row(children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(child: Text(data['icon'] as String,
              style: const TextStyle(fontSize: 28))),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(L.welcomeTitle,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Text(L.welcomeSubtitle,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ]),
    );
  }
}

// ── Grid Listing Card (4宮格) ─────────────────────────────────────────────────

class _GridListingCard extends StatelessWidget {
  final PokemonCard card;
  final String Function(int) formatPrice;
  final VoidCallback onTap;

  const _GridListingCard({
    required this.card,
    required this.formatPrice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo area — 正方形
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: card.imageUrls.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: card.imageUrls.first,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _placeholder(card),
                        errorWidget: (_, __, ___) => _placeholder(card),
                      )
                    : _placeholder(card),
              ),
            ),

            // Info below
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 名字 + 分級標籤（同一行）
                    Row(children: [
                      Flexible(child: Text(card.name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                              color: Color(0xFF111827)),
                          maxLines: 1, overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 5),
                      _gradeChip(card.grade),
                    ]),
                    const SizedBox(height: 6),
                    Text('HK\$${formatPrice(card.price)}',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                            color: Color(0xFF16A34A)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gradeChip(String grade) {
    final g = grade.toUpperCase();
    final c = g.contains('10')
        ? const Color(0xFFE8A52A)
        : (g.contains('9') ? const Color(0xFF2980B9) : const Color(0xFF6B7280));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
      child: Text(grade, style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, color: c)),
    );
  }

  Widget _placeholder(PokemonCard card) => NoImagePlaceholder(
    background: card.type.bgColor,
    icon: Text(card.type.emoji, style: const TextStyle(fontSize: 28)),
  );
}

// ── Recently Viewed Card ──────────────────────────────────────────────────────

class _RecentCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(int) formatPrice;
  final VoidCallback onTap;

  const _RecentCard({required this.item, required this.formatPrice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = item['name'] as String? ?? '';
    final grade = item['grade'] as String? ?? '';
    final price = item['price'] as int? ?? 0;
    final image = item['image'] as String?;
    final isSold = item['isSold'] as bool? ?? false;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // 圖片區
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: Stack(fit: StackFit.expand, children: [
                image != null && image.isNotEmpty
                    ? CachedNetworkImage(imageUrl: image, fit: BoxFit.cover,
                        placeholder: (_, __) => const NoImagePlaceholder(
                            icon: Icon(Icons.style, color: Color(0xFFD1D5DB))),
                        errorWidget: (_, __, ___) => const NoImagePlaceholder(
                            icon: Icon(Icons.style, color: Color(0xFFD1D5DB))))
                    : const NoImagePlaceholder(
                        icon: Icon(Icons.style, color: Color(0xFFD1D5DB))),
                if (isSold)
                  Container(
                    color: Colors.black45,
                    alignment: Alignment.center,
                    child: Text(L.sold,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                  ),
              ]),
            ),
          ),
          // 資訊區
          Padding(
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              if (grade.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  margin: const EdgeInsets.only(bottom: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(3)),
                  child: Text(grade,
                      style: const TextStyle(fontSize: 8.5, color: Color(0xFF6B7280), fontWeight: FontWeight.w600)),
                ),
              Text('HK\$${formatPrice(price)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ]),
      ),
    );
  }
}
