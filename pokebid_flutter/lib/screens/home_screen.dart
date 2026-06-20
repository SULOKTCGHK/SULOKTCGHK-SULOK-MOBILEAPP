import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/card_model.dart';
import '../services/announcement_service.dart';
import '../services/admin_service.dart';
import 'card_detail_screen.dart';
import 'announcement_detail_screen.dart';
import 'admin/post_announcement_sheet.dart';
import 'conversations_list_screen.dart';
import '../widgets/notification_bell.dart';
import '../widgets/unread_dot.dart';
import '../services/notification_service.dart';

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
  bool _isAdmin = false;

  // Fallback announcements shown while loading or if Supabase has none
  static const List<Map<String, dynamic>> _fallback = [
    {'title': '歡迎來到 PokeBid', 'subtitle': '日本寶可夢卡牌交易平台', 'colorHex': 'E8A52A', 'icon': '🎴'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
    _checkAdmin();
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

  Future<void> _loadAnnouncements() async {
    final list = await AnnouncementService.getAnnouncements();
    if (mounted) setState(() => _announcements = list);
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

  @override
  void dispose() {
    _bannerCtrl.dispose();
    super.dispose();
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
                  child: const Row(children: [
                    Icon(Icons.add, color: Colors.white, size: 14),
                    SizedBox(width: 3),
                    Text('發佈', style: TextStyle(
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
              tooltip: '訊息',
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

          // ── Latest Listings ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Row(children: [
              const Text('最新上架',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              const Spacer(),
              const Text('查看全部',
                  style: TextStyle(fontSize: 13, color: Color(0xFFE8A52A), fontWeight: FontWeight.w500)),
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
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: Text('目前沒有上架商品',
                  style: TextStyle(color: Color(0xFF9CA3AF)))),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.75,
                ),
                itemCount: widget.listings.take(6).length,
                itemBuilder: (_, i) {
                  final card = widget.listings[i];
                  return _GridListingCard(
                    card: card,
                    formatPrice: _fmt,
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => CardDetailScreen(
                          card: card, isFavorited: false, onFavChanged: (_) {}))),
                  );
                },
              ),
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
              Text(data['title'] as String,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 5),
              Text(data['subtitle'] as String,
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
            // Photo area — takes most of the space
            Expanded(
              flex: 5,
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
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(card.name,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                            color: Color(0xFF111827)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(card.grade,
                        style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('NT\$${formatPrice(card.price)}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
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

  Widget _placeholder(PokemonCard card) => Container(
    color: card.type.bgColor,
    child: Center(child: Text(card.type.emoji,
        style: const TextStyle(fontSize: 28))),
  );
}
