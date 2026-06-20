import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'marketplace_screen.dart';
import 'post_listing_sheet.dart';
import 'dex_screen.dart';
import 'profile_screen.dart';
import '../models/card_model.dart';
import '../services/listing_service.dart';
import '../widgets/unread_dot.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  List<PokemonCard> _listings = [];
  bool _loadingListings = true;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    final data = await ListingService.getListings();
    if (mounted) setState(() { _listings = data; _loadingListings = false; });
  }

  void _openPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PostListingSheet(
        onSubmit: (_) {
          _loadListings(); // refresh from Supabase
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('商品已上架！'),
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
    final pages = [
      HomeScreen(listings: _listings, loading: _loadingListings),
      MarketplaceScreen(listings: _listings, loading: _loadingListings),
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
                _navItem(0, Icons.home_outlined, Icons.home, '首頁'),
                _navItem(1, Icons.sell_outlined, Icons.sell, '掛售區'),
                // Post button (centre)
                Expanded(
                  child: GestureDetector(
                    onTap: _openPost,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
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
                          child: const Icon(Icons.add, color: Colors.white, size: 26),
                        ),
                        const SizedBox(height: 2),
                        const Text('發佈',
                            style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                ),
                _navItem(3, Icons.menu_book_outlined, Icons.menu_book, '圖鑑'),
                _navItem(4, Icons.person_outline, Icons.person, '我的', showUnread: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label,
      {bool showUnread = false}) {
    final active = _currentIndex == index;
    final iconWidget = Icon(active ? activeIcon : icon, size: 22,
        color: active ? const Color(0xFFE8A52A) : const Color(0xFF9CA3AF));
    return Expanded(
      child: GestureDetector(
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
