import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import 'dex_card_detail_screen.dart';

class DexSetGridScreen extends StatefulWidget {
  final ApiSet set;
  final Set<String> collected;
  final String Function(int) formatPrice;
  final ValueChanged<ApiCard> onToggleCollect;

  const DexSetGridScreen({
    super.key,
    required this.set,
    required this.collected,
    required this.formatPrice,
    required this.onToggleCollect,
  });

  @override
  State<DexSetGridScreen> createState() => _DexSetGridScreenState();
}

enum _SortMode { numAsc, numDesc, rarity }

class _DexSetGridScreenState extends State<DexSetGridScreen> {
  List<ApiCard> _cards = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  static const int _pageSize = 30;

  late Set<String> _collected;

  // Filter & sort
  _SortMode _sort = _SortMode.numAsc;
  String? _rarityFilter; // null = all

  // 日版稀有度由低至高
  static const _rarityOrder = ['C', 'U', 'R', 'RR', 'AR', 'SAR', 'SR', 'SSR', 'UR', 'K'];

  List<ApiCard> get _sorted {
    var list = List<ApiCard>.from(_cards);
    if (_rarityFilter != null) {
      list = list.where((c) =>
          (c.rarity ?? '').toLowerCase() == _rarityFilter!.toLowerCase()).toList();
    }
    switch (_sort) {
      case _SortMode.numAsc:
        list.sort((a, b) => _numVal(a.number).compareTo(_numVal(b.number)));
      case _SortMode.numDesc:
        list.sort((a, b) => _numVal(b.number).compareTo(_numVal(a.number)));
      case _SortMode.rarity:
        list.sort((a, b) {
          final ai = _rarityOrder.indexOf(a.rarity ?? '');
          final bi = _rarityOrder.indexOf(b.rarity ?? '');
          // 高稀有度在前（index 大 = 稀有度高）
          final aVal = ai == -1 ? -1 : ai;
          final bVal = bi == -1 ? -1 : bi;
          return bVal.compareTo(aVal);
        });
    }
    return list;
  }

  int _numVal(String? n) => int.tryParse(n?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? 9999;

  List<String> get _availableRarities {
    final rarities = _cards
        .map((c) => c.rarity ?? '')
        .where((r) => r.isNotEmpty)
        .toSet()
        .toList();
    rarities.sort((a, b) {
      final ai = _rarityOrder.indexWhere((r) => r.toLowerCase() == a.toLowerCase());
      final bi = _rarityOrder.indexWhere((r) => r.toLowerCase() == b.toLowerCase());
      return (ai == -1 ? 99 : ai).compareTo(bi == -1 ? 99 : bi);
    });
    return rarities;
  }

  @override
  void initState() {
    super.initState();
    _collected = Set.from(widget.collected);
    _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    setState(() { _loading = true; _cards = []; });
    // 全部從 Supabase 讀（資料由 JustTCG 抓取批次灌入）
    final cached = await SupabaseService.getCachedCardsForSet(widget.set.id);
    final cards = cached.map(_rowToCard).toList();
    _hasMore = false;
    if (mounted) setState(() { _cards = cards; _loading = false; });
  }

  ApiCard _rowToCard(Map<String, dynamic> r) => ApiCard(
    id: r['id'] as String, name: r['name'] as String,
    imageSmall: r['image_small'] as String?, imageLarge: r['image_large'] as String?,
    rarity: r['rarity'] as String?, setName: r['set_name'] as String?,
    setId: r['set_id'] as String?, number: r['number'] as String?,
    supertype: r['supertype'] as String?,
    types: (r['types'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
    variant: r['variant'] as String?,
  );

  void _openCard(ApiCard card) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => DexCardDetailScreen(
        card: card,
        isCollected: _collected.contains(card.id),
        onToggleCollect: (v) {
          setState(() {
            if (v) { _collected.add(card.id); } else { _collected.remove(card.id); }
          });
          widget.onToggleCollect(card);
        },
        formatPrice: widget.formatPrice,
      ),
    ));
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
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFFE5E7EB)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: Color(0xFF374151), size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.set.displayName,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                  color: Color(0xFF111827))),
          Text('${widget.set.total} 張 · ${widget.set.releaseDate ?? ''}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ]),
      ),
      body: _loading
          ? _buildShimmer()
          : _cards.isEmpty
          ? _buildEmpty()
          : Column(
              children: [
                // ── Filter bar ──────────────────────────────────────
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      // Sort chips
                      _sortChip('編號 ↑', _SortMode.numAsc),
                      const SizedBox(width: 6),
                      _sortChip('編號 ↓', _SortMode.numDesc),
                      const SizedBox(width: 6),
                      _sortChip('稀有度', _SortMode.rarity),
                      // Divider
                      Container(
                        width: 1, height: 20,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        color: const Color(0xFFE5E7EB),
                      ),
                      // Rarity filter chips
                      _rarityChip(null, '全部'),
                      ..._availableRarities.map((r) =>
                          Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: _rarityChip(r, _shortRarity(r)),
                          )),
                    ]),
                  ),
                ),
                Container(height: 0.5, color: const Color(0xFFE5E7EB)),

                // ── Grid ────────────────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    color: const Color(0xFFE8A52A),
                    onRefresh: _loadFirstPage,
                    child: NotificationListener<ScrollNotification>(
              onNotification: (n) => false,
              child: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.72,
                ),
                itemCount: _sorted.length + (_loadingMore ? 3 : 0),
                itemBuilder: (_, i) {
                  if (i >= _sorted.length) return _GridShimmerItem();
                  final card = _sorted[i];
                  return _CardGridItem(
                    card: card,
                    isCollected: _collected.contains(card.id),
                    onTap: () => _openCard(card),
                    onToggle: () {
                      widget.onToggleCollect(card);
                      setState(() {
                        if (_collected.contains(card.id)) {
                          _collected.remove(card.id);
                        } else {
                          _collected.add(card.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sortChip(String label, _SortMode mode) {
    final active = _sort == mode;
    return GestureDetector(
      onTap: () => setState(() => _sort = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500,
              color: active ? Colors.white : const Color(0xFF6B7280),
            )),
      ),
    );
  }

  Widget _rarityChip(String? rarity, String label) {
    final active = _rarityFilter == rarity;
    return GestureDetector(
      onTap: () => setState(() => _rarityFilter = rarity),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF8E44AD).withOpacity(0.15) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? const Color(0xFF8E44AD) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500,
              color: active ? const Color(0xFF8E44AD) : const Color(0xFF6B7280),
            )),
      ),
    );
  }

  String _shortRarity(String r) => r; // 日版稀有度本身已是縮寫

  Widget _buildEmpty() => RefreshIndicator(
    color: const Color(0xFFE8A52A),
    onRefresh: _loadFirstPage,
    child: ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9EC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE8A52A).withOpacity(0.3), width: 1.5),
              ),
              child: const Center(child: Text('🃏', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 20),
            const Text('此系列暫無卡牌資料',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            Text(
              '${widget.set.id} 尚未抓取或仍在更新中。\n下拉可重新載入。',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), height: 1.6),
            ),
          ]),
        ),
      ],
    ),
  );

  Widget _buildShimmer() => GridView.builder(
    padding: const EdgeInsets.all(12),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.72,
    ),
    itemCount: 12,
    itemBuilder: (_, __) => _GridShimmerItem(),
  );
}

// ── Grid Card Item ────────────────────────────────────────────────────────────

class _CardGridItem extends StatelessWidget {
  final ApiCard card;
  final bool isCollected;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  const _CardGridItem({
    required this.card, required this.isCollected,
    required this.onTap, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCollected ? const Color(0xFFE8A52A) : const Color(0xFFE5E7EB),
            width: isCollected ? 1.5 : 0.5,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: card.imageSmall != null
                    ? CachedNetworkImage(
                        imageUrl: card.imageSmall!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: const Color(0xFFF3F4F6),
                            child: const Center(child: Icon(Icons.style, color: Color(0xFFD1D5DB), size: 24))),
                        errorWidget: (_, __, ___) => Container(color: const Color(0xFFF3F4F6),
                            child: const Center(child: Icon(Icons.style, color: Color(0xFFD1D5DB), size: 24))),
                      )
                    : Container(color: const Color(0xFFF3F4F6),
                        child: const Center(child: Icon(Icons.style, color: Color(0xFFD1D5DB), size: 24))),
              ),
            ),
            // Card name + collect button
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(card.cleanName,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500,
                        color: Color(0xFF111827)),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (variantLabelZh(card.variant).isNotEmpty) ...[
                  const SizedBox(height: 2),
                  _VariantBadge(label: variantLabelZh(card.variant)),
                ],
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onToggle,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isCollected ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Icon(
                        isCollected ? Icons.bookmark : Icons.bookmark_border,
                        size: 13,
                        color: isCollected ? Colors.white : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// 球種/花紋小徽章
class _VariantBadge extends StatelessWidget {
  final String label;
  const _VariantBadge({required this.label});

  Color get _color {
    switch (label) {
      case '精靈球': return const Color(0xFFE74C3C);
      case '大師球': return const Color(0xFF8E44AD);
      case '超級球': return const Color(0xFF2980B9);
      case '高級球': return const Color(0xFFD4A017);
      case '速度球': return const Color(0xFF16A34A);
      case '愛心球': return const Color(0xFFC0397A);
      default: return const Color(0xFF6B7280);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
      color: _color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text('● $label',
        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: _color),
        maxLines: 1, overflow: TextOverflow.ellipsis),
  );
}

class _GridShimmerItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: const Color(0xFFE5E7EB),
    highlightColor: const Color(0xFFF9FAFB),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(12)),
    ),
  );
}
