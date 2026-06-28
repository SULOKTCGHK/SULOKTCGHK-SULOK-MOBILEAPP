import 'package:flutter/material.dart';
import '../widgets/login_required.dart';
import '../widgets/pixel_icon.dart';
import 'splash_screen.dart';
import 'home_screen.dart';
import 'marketplace_screen.dart';
import 'post_listing_sheet.dart';
import 'dex_screen.dart';
import 'profile_screen.dart';
import '../models/card_model.dart';
import '../services/listing_service.dart';
import '../services/block_service.dart';
import '../widgets/unread_dot.dart';
import '../i18n/strings.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  List<PokemonCard> _listings = [];
  bool _loadingListings = true;
  bool _splashDone = false;

  final _postBtnKey = GlobalKey();

  bool get _showSplash => !_splashDone;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    final data = await ListingService.getListings();
    // 過濾掉被封鎖賣家的掛售
    final blocked = await BlockService.blockedIds();
    final filtered = blocked.isEmpty
        ? data
        : data.where((c) => c.seller.id == null || !blocked.contains(c.seller.id)).toList();
    if (mounted) setState(() { _listings = filtered; _loadingListings = false; });
  }


  void _openPost() async {
    if (!await requireLogin(context, action: L.postProduct)) return;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostListingSheet(
        onSubmit: (_) {
          _loadListings(); // refresh from Supabase
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(L.listingPosted),
              backgroundColor: const Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) return SplashScreen(
      onComplete: () {
        if (!mounted) return;
        setState(() => _splashDone = true);
      },
    );

    final pages = [
      HomeScreen(listings: _listings, loading: false),
      MarketplaceScreen(listings: _listings, loading: false),
      const SizedBox.shrink(), // placeholder for post
      const DexScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex == 2 ? 0 : _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                _navItem(0, kPixelHome, L.navHome),
                _navItem(1, kPixelMarket, L.navMarket),
                // Post button (centre)
                Expanded(
                  child: GestureDetector(
                    onTap: _openPost,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          key: _postBtnKey,
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE74C3C),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Color(0x33E74C3C),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: PixelIcon(grid: kPixelDpad, palette: kPixelPalette, size: 24),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(L.navPost,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                ),
                _navItem(3, kPixelDex, L.navDex),
                _navItem(4, kPixelMe, L.navMe, showUnread: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, List<String> grid, String label, {bool showUnread = false, Key? key}) {
    final active = _currentIndex == index;
    final iconWidget = PixelIcon(grid: grid, palette: kPixelPalette, size: 22,
        opacity: active ? 1.0 : 0.4);
    return Expanded(
      child: GestureDetector(
        key: key,
        onTap: () => setState(() => _currentIndex = index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            showUnread
                ? UnreadDot(top: -2, right: -4, child: iconWidget)
                : iconWidget,
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                  color: active ? const Color(0xFFE8A52A) : const Color(0xFF9CA3AF),
                )),
          ],
        ),
      ),
    );
  }
}

