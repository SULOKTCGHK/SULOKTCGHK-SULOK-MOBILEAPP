import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../widgets/card_grid_item.dart';
import '../services/api_service.dart';
import '../widgets/notification_bell.dart';
import 'card_detail_screen.dart';
import 'chat_screen.dart';
import 'wishlist_screen.dart';
import '../i18n/strings.dart';

enum SortFilter { latest, priceLow, priceHigh }

class MarketplaceScreen extends StatefulWidget {
  final List<PokemonCard> listings;
  final bool loading;

  const MarketplaceScreen({super.key, required this.listings, this.loading = false});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  SortFilter _filter = SortFilter.latest;
  final Set<int> _favorites = {};
  final _searchCtrl = TextEditingController();
  String _query = '';

  // 進階篩選
  int? _minPrice;
  int? _maxPrice;
  final Set<String> _gradeFilter = {};
  String? _setFilter;

  bool get _hasActiveFilters =>
      _minPrice != null || _maxPrice != null || _gradeFilter.isNotEmpty || _setFilter != null;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PokemonCard> get _sorted {
    var cards = List<PokemonCard>.from(widget.listings);
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase().trim();
      cards = cards.where((c) {
        if (c.name.toLowerCase().contains(q)) return true;
        if (c.seller.name.toLowerCase().contains(q)) return true;
        if (c.setId != null && c.setId!.toLowerCase().contains(q)) return true;
        if (c.cardNumber != null && c.cardNumber!.toLowerCase().contains(q)) return true;
        // 搜尋中文系列名稱（優先 API cache → 靜態 map）
        if (c.setId != null) {
          final zhName = PokemonApiService.zhTwSetName(c.setId!);
          if (zhName.contains(q)) return true;
        }
        return false;
      }).toList();
    }
    // 進階篩選
    if (_minPrice != null) cards = cards.where((c) => c.price >= _minPrice!).toList();
    if (_maxPrice != null) cards = cards.where((c) => c.price <= _maxPrice!).toList();
    if (_gradeFilter.isNotEmpty) {
      cards = cards.where((c) => _gradeFilter.contains(c.grade)).toList();
    }
    if (_setFilter != null) {
      cards = cards.where((c) => c.setId == _setFilter).toList();
    }
    switch (_filter) {
      case SortFilter.priceLow:
        cards.sort((a, b) => a.price.compareTo(b.price));
      case SortFilter.priceHigh:
        cards.sort((a, b) => b.price.compareTo(a.price));
      case SortFilter.latest:
        break;
    }
    return cards;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(height: 0.5, color: const Color(0xFFE5E7EB)),
            // 常駐搜尋欄
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: TextField(
                controller: _searchCtrl,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: L.searchHint,
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Color(0xFF9CA3AF)),
                          onPressed: () => setState(() {
                            _searchCtrl.clear();
                            _query = '';
                          }),
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF3F4F6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ]),
        ),
        titleSpacing: 16,
        title: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500,
                color: Color(0xFF111827)),
            children: [
              const TextSpan(text: 'Poke'),
              const TextSpan(text: 'Bid', style: TextStyle(color: Color(0xFFE8A52A))),
              TextSpan(text: L.marketTitleSuffix,
                  style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Color(0xFF374151)),
            tooltip: L.wishlist,
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const WishlistScreen())),
          ),
          const NotificationBell(),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(children: [
                GestureDetector(
                  onTap: _openFilterSheet,
                  child: Stack(clipBehavior: Clip.none, children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: _hasActiveFilters ? const Color(0xFFFEF9EC) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _hasActiveFilters
                              ? const Color(0xFFE8A52A)
                              : const Color(0xFFD1D5DB),
                          width: _hasActiveFilters ? 1 : 0.5,
                        ),
                      ),
                      child: Icon(Icons.tune, size: 16,
                          color: _hasActiveFilters
                              ? const Color(0xFFE8A52A)
                              : const Color(0xFF6B7280)),
                    ),
                    if (_hasActiveFilters)
                      Positioned(
                        right: -1, top: -1,
                        child: Container(width: 9, height: 9,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE74C3C),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.2),
                            )),
                      ),
                  ]),
                ),
                const SizedBox(width: 8),
                _chip(L.sortLatest, SortFilter.latest),
                const SizedBox(width: 8),
                _chip(L.sortPriceLow, SortFilter.priceLow),
                const SizedBox(width: 8),
                _chip(L.sortPriceHigh, SortFilter.priceHigh),
              ]),
            ),
          ),

          // Count
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(children: [
              Text(
                _query.isNotEmpty
                    ? L.searchCount(_query, _sorted.length)
                    : L.totalCount(_sorted.length),
                style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            ]),
          ),

          // Grid
          Expanded(
            child: widget.loading
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFFE8A52A), strokeWidth: 2))
                : _sorted.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 48, color: Color(0xFFD1D5DB)),
                      const SizedBox(height: 12),
                      Text(_query.isNotEmpty ? L.noSearchResult(_query) : L.noMarketListings,
                          style: const TextStyle(color: Color(0xFF9CA3AF))),
                    ]))
                : LayoutBuilder(builder: (ctx, c) {
                    // 圖片正方形 + 資訊區固定高度 → 適配不同手機寬度
                    const infoH = 92.0;
                    final cellW = (c.maxWidth - 32 - 10) / 2; // 扣左右padding(16+16)與間距(10)
                    final ar = cellW / (cellW + infoH);
                    return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: ar,
                    ),
                    itemCount: _sorted.length,
                    itemBuilder: (_, i) {
                      final card = _sorted[i];
                      return CardGridItem(
                        card: card,
                        isFavorited: _favorites.contains(card.id),
                        onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => CardDetailScreen(
                            card: card,
                            isFavorited: _favorites.contains(card.id),
                            onFavChanged: (v) => setState(() {
                              if (v) _favorites.add(card.id);
                              else _favorites.remove(card.id);
                            }),
                          ),
                        )),
                        onFavToggle: () => setState(() {
                          if (_favorites.contains(card.id)) _favorites.remove(card.id);
                          else _favorites.add(card.id);
                        }),
                        onChat: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            sellerName: card.seller.name,
                            sellerAvatar: card.seller.name.substring(0, 2).toUpperCase(),
                            sellerId: card.seller.id,
                            card: card,
                          ),
                        )),
                      );
                    },
                  );
                  }),
          ),
        ],
      ),
    );
  }

  void _openFilterSheet() {
    final minCtrl = TextEditingController(text: _minPrice?.toString() ?? '');
    final maxCtrl = TextEditingController(text: _maxPrice?.toString() ?? '');
    final localGrades = Set<String>.from(_gradeFilter);
    String? localSet = _setFilter;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(L.filterTitle,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                      color: Color(0xFF111827))),
              const SizedBox(height: 16),

              // 價格區間
              Text(L.priceRange,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: Color(0xFF374151))),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _priceField(minCtrl, L.priceMin)),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('—', style: TextStyle(color: Color(0xFF9CA3AF)))),
                Expanded(child: _priceField(maxCtrl, L.priceMax)),
              ]),
              const SizedBox(height: 16),

              // 評級（固定：PSA10 / PSA9 / CGC10）
              Text(L.grade,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: Color(0xFF374151))),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: const <(String, String)>[
                ('PSA 10', 'PSA10'),
                ('PSA 9', 'PSA9'),
                ('CGC 10', 'CGC10'),
              ].map((g) {
                final on = localGrades.contains(g.$1);
                return GestureDetector(
                  onTap: () => setSheet(() {
                    if (on) { localGrades.remove(g.$1); } else { localGrades.add(g.$1); }
                  }),
                  child: _filterChip(g.$2, on),
                );
              }).toList()),
              const SizedBox(height: 20),

              // 套用 / 重設
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _minPrice = null; _maxPrice = null;
                        _gradeFilter.clear(); _setFilter = null;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(L.reset,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280)))),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _minPrice = int.tryParse(minCtrl.text.trim());
                        _maxPrice = int.tryParse(maxCtrl.text.trim());
                        _gradeFilter
                          ..clear()
                          ..addAll(localGrades);
                        _setFilter = localSet;
                      });
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8A52A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(L.applyFilter,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                              color: Colors.white))),
                    ),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _priceField(TextEditingController ctrl, String hint) => TextField(
    controller: ctrl,
    keyboardType: TextInputType.number,
    style: const TextStyle(fontSize: 14),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE8A52A), width: 1)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
  );

  Widget _filterChip(String label, bool active) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: active ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: active ? const Color(0xFFE8A52A) : Colors.transparent, width: 1),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500,
            color: active ? Colors.white : const Color(0xFF6B7280))),
  );

  Widget _chip(String label, SortFilter filter) {
    final active = _filter == filter;
    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8A52A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFFE8A52A) : const Color(0xFFD1D5DB),
            width: 0.5,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: active ? Colors.white : const Color(0xFF6B7280),
            )),
      ),
    );
  }
}
