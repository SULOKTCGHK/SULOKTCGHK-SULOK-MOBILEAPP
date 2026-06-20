import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import 'dex_card_detail_screen.dart';
import 'dex_set_grid_screen.dart';

class DexScreen extends StatefulWidget {
  const DexScreen({super.key});

  @override
  State<DexScreen> createState() => _DexScreenState();
}

class _DexScreenState extends State<DexScreen> {
  final _searchCtrl = TextEditingController();
  List<ApiSet> _sets = [];
  Set<String> _collected = {};
  int _totalValue = 0;
  int _collectedCount = 0;
  bool _loadingSets = true;
  String? _error;
  bool _searching = false;
  bool _searchLoading = false;
  List<ApiCard> _searchResults = [];

  bool _sortNewestFirst = true;

  // 導覽：分支（'box' 卡盒 / 'promo'）與已選系列
  String? _branch;
  String? _selectedSeries;

  // 系列前綴 → 顯示名稱
  static const Map<String, String> _seriesNames = {
    'm': 'Mega 系列',
    'sv': '朱＆紫系列',
    's': '劍＆盾系列',
    'sp': '劍盾特別系列',
    'sm': '太陽＆月亮系列',
    'xy': 'XY 系列',
    'cp': 'XY 概念包系列',
    'bw': '黑＆白系列',
    'dp': '鑽石＆珍珠系列',
    'pt': '白金系列',
    'l': 'LEGEND 系列',
    'adv': 'ADV 系列',
  };

  // 前綴別名 → 正規化（把同世代的不同代號併成一組）
  static const Map<String, String> _seriesAlias = {
    'ptm': 'pt', 'pts': 'pt', 'ptr': 'pt',   // 白金 LV.X 收藏包
    'll': 'l',                                // LEGEND（Lost Link）
    'xyc': 'cp',                              // XY 概念包
    'smp': 'sm', 'sml': 'sm', 'snp': 'sm',    // 太陽月亮 家庭/特別包
    'sh': 's',                               // 劍盾 家庭包
  };

  // 是否為 PROMO 系列（名稱含 promo）
  bool _isPromoSet(ApiSet s) =>
      s.name.toLowerCase().contains('promo') || s.id.toLowerCase().contains('-p-');

  // 是否為牌組/禮盒類（非擴充包）
  static final RegExp _deckPattern = RegExp(
      r'deck|starter|build.box|gift.box|trainer.box|special.set|special.deck|half.deck|kit|battle master|premium|construction|start decks|\bvs\b');
  bool _isDeckSet(ApiSet s) =>
      _deckPattern.hasMatch((s.id + ' ' + s.name).toLowerCase());

  // 分類：promo / deck / box
  String _category(ApiSet s) {
    if (_isPromoSet(s)) return 'promo';
    if (_isDeckSet(s)) return 'deck';
    return 'box';
  }

  // 從 set id 推導系列 key（m5-abyss-eye → m, sv8a-... → sv）
  String _seriesKey(ApiSet s) {
    final id = s.id.toLowerCase().replaceAll('-pokemon-japan', '');
    final first = id.split('-').first;
    final pre = RegExp(r'^[a-z]+').firstMatch(first)?.group(0) ?? 'other';
    return _seriesAlias[pre] ?? pre;
  }

  String _seriesName(String key) => _seriesNames[key] ?? '其他系列';

  List<ApiSet> _sortByDate(List<ApiSet> list) {
    list.sort((a, b) {
      final da = DateTime.tryParse(a.releaseDate?.replaceAll('/', '-') ?? '') ?? DateTime(0);
      final db = DateTime.tryParse(b.releaseDate?.replaceAll('/', '-') ?? '') ?? DateTime(0);
      return _sortNewestFirst ? db.compareTo(da) : da.compareTo(db);
    });
    return list;
  }

  // 各分類的系列
  List<ApiSet> get _boxSets => _sets.where((s) => _category(s) == 'box').toList();
  List<ApiSet> get _deckSets => _sets.where((s) => _category(s) == 'deck').toList();
  List<ApiSet> get _promoSets => _sortByDate(_sets.where((s) => _category(s) == 'promo').toList());

  // 將一組 set 依系列分組，並依最新發售日排序
  List<MapEntry<String, List<ApiSet>>> _seriesGroups(List<ApiSet> sets) {
    final map = <String, List<ApiSet>>{};
    for (final s in sets) {
      map.putIfAbsent(_seriesKey(s), () => []).add(s);
    }
    final entries = map.entries.toList();
    entries.sort((a, b) {
      String latest(List<ApiSet> l) => l
          .map((s) => s.releaseDate ?? '')
          .fold('', (p, n) => n.compareTo(p) > 0 ? n : p);
      return latest(b.value).compareTo(latest(a.value));
    });
    return entries;
  }

  ApiCard _rowToCard(Map<String, dynamic> r) => ApiCard(
    id: r['id'] as String, name: r['name'] as String,
    imageSmall: r['image_small'] as String?, imageLarge: r['image_large'] as String?,
    rarity: r['rarity'] as String?, setName: r['set_name'] as String?,
    setId: r['set_id'] as String?, number: r['number'] as String?,
    supertype: r['supertype'] as String?,
    types: (r['types'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
  );

  @override
  void initState() {
    super.initState();
    _loadSets();
    _loadCollectionStats();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCollectionStats() async {
    final ids = await SupabaseService.getCollectedCardIds();
    final value = await SupabaseService.getCollectionTotalValue();
    if (mounted) setState(() {
      _collected = ids;
      _totalValue = value;
      _collectedCount = ids.length;
    });
  }

  Future<void> _loadSets() async {
    setState(() { _loadingSets = true; _error = null; });
    try {
      final cached = await SupabaseService.getCachedSets();
      if (mounted) setState(() {
        _sets = cached.map((r) {
          final rd = r['release_date'] as String?;
          return ApiSet(
            id: r['id'] as String,
            name: r['name'] as String? ?? r['id'] as String,
            series: r['series'] as String?,
            seriesId: r['series_id'] as String?,
            releaseDate: (rd != null && rd.length >= 10) ? rd.substring(0, 10) : rd,
            symbolImage: r['symbol_image'] as String?,
            logoImage: r['logo_image'] as String?,
            total: r['total'] as int? ?? 0,
          );
        }).toList();
        _loadingSets = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = '載入失敗：$e'; _loadingSets = false; });
    }
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _searching = false; _searchResults = []; _searchLoading = false; });
      return;
    }
    setState(() { _searching = true; _searchLoading = true; });
    final rows = await SupabaseService.searchCachedCards(q.trim());
    if (mounted) setState(() {
      _searchResults = rows.map(_rowToCard).toList();
      _searchLoading = false;
    });
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
        automaticallyImplyLeading: false,
        leading: (_branch != null || _selectedSeries != null)
            ? IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFF374151), size: 28),
                onPressed: () => setState(() {
                  if (_selectedSeries != null) {
                    _selectedSeries = null;       // 回系列清單
                  } else {
                    _branch = null;               // 回分支選擇
                  }
                }),
              )
            : null,
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
            children: [
              TextSpan(text: 'Poke'),
              TextSpan(text: 'Bid', style: TextStyle(color: Color(0xFFE8A52A))),
              TextSpan(text: ' 圖鑑', style: TextStyle(fontSize: 15, color: Color(0xFF6B7280))),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF374151)),
            onPressed: _loadSets,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _search,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: '搜尋卡牌名稱...',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
                        onPressed: () { _searchCtrl.clear(); _search(''); })
                    : null,
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: _searching ? _buildSearchResults() : _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2));
    }
    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.search_off, size: 48, color: Color(0xFFD1D5DB)),
          SizedBox(height: 12),
          Text('找不到卡牌', style: TextStyle(color: Color(0xFF9CA3AF))),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (_, i) => _SearchCardTile(
        card: _searchResults[i],
        isCollected: _collected.contains(_searchResults[i].id),
        onTap: () => _openCardDetail(_searchResults[i]),
        onToggle: () => _toggleCollect(_searchResults[i]),
        formatPrice: _fmt,
      ),
    );
  }

  Widget _buildMainContent() {
    if (_loadingSets) {
      return ListView(children: [
        _CollectionBanner(totalValue: _totalValue, collected: _collectedCount, formatPrice: _fmt),
        const SizedBox(height: 12),
        ...List.generate(6, (_) => const _SetShimmer()),
      ]);
    }
    if (_error != null) {
      return ListView(children: [
        _CollectionBanner(totalValue: _totalValue, collected: _collectedCount, formatPrice: _fmt),
        _ErrorWidget(message: _error!, onRetry: _loadSets),
      ]);
    }

    return ListView(
      children: [
        _CollectionBanner(totalValue: _totalValue, collected: _collectedCount, formatPrice: _fmt),

        // ── 第一層：卡盒 / 牌組 / PROMO ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(children: [
            _branchCard('box', '📦', '卡盒', '擴充包'),
            const SizedBox(width: 8),
            _branchCard('deck', '🎴', '牌組', 'Deck / 禮盒'),
            const SizedBox(width: 8),
            _branchCard('promo', '🌟', 'PROMO', '特典卡'),
          ]),
        ),

        if (_branch == 'promo') ..._buildPromoLevel()
        else if (_branch == 'box') ..._buildSeriesBranch(_boxSets, '尚無卡盒資料')
        else if (_branch == 'deck') ..._buildSeriesBranch(_deckSets, '尚無牌組資料'),

        const SizedBox(height: 100),
      ],
    );
  }

  // PROMO：直接列出所有 promo 系列
  List<Widget> _buildPromoLevel() {
    final sets = _promoSets;
    return [
      _sectionHeader('PROMO 系列（${sets.length}）'),
      if (sets.isEmpty)
        _emptyHint('尚無 PROMO 資料')
      else
        ...sets.map((s) => _SetTile(set: s, collected: _collected,
            onTap: () => _openSetGrid(s), formatPrice: _fmt)),
    ];
  }

  // 卡盒/牌組：先選系列，再列出該系列的彈
  List<Widget> _buildSeriesBranch(List<ApiSet> branchSets, String emptyMsg) {
    if (_selectedSeries == null) {
      final groups = _seriesGroups(branchSets);
      return [
        _sectionHeader('選擇系列'),
        if (groups.isEmpty)
          _emptyHint(emptyMsg)
        else
          ...groups.map((e) => _SeriesTile(
                name: _seriesName(e.key),
                count: e.value.length,
                latestDate: e.value.map((s) => s.releaseDate ?? '')
                    .fold('', (p, n) => n.compareTo(p) > 0 ? n : p),
                onTap: () => setState(() => _selectedSeries = e.key),
              )),
      ];
    }
    final sets = _sortByDate(branchSets.where((s) => _seriesKey(s) == _selectedSeries).toList());
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(children: [
          GestureDetector(
            onTap: () => setState(() => _selectedSeries = null),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.chevron_left, size: 18, color: Color(0xFFE8A52A)),
              Text('系列', style: TextStyle(fontSize: 13, color: Color(0xFFE8A52A))),
            ]),
          ),
          const SizedBox(width: 8),
          Text(_seriesName(_selectedSeries!),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
        ]),
      ),
      ...sets.map((s) => _SetTile(set: s, collected: _collected,
          onTap: () => _openSetGrid(s), formatPrice: _fmt)),
    ];
  }

  Widget _branchCard(String key, String icon, String label, String desc) {
    final active = _branch == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _branch = key;
          _selectedSeries = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFEF9EC) : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? const Color(0xFFE8A52A) : const Color(0xFFE5E7EB),
              width: active ? 1.5 : 0.5,
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 6),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: active ? const Color(0xFFE8A52A) : const Color(0xFF374151))),
            Text(desc, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
    child: Row(children: [
      Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
      const Spacer(),
      GestureDetector(
        onTap: () => setState(() => _sortNewestFirst = !_sortNewestFirst),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(_sortNewestFirst ? Icons.arrow_downward : Icons.arrow_upward,
              size: 12, color: const Color(0xFFE8A52A)),
          const SizedBox(width: 4),
          Text(_sortNewestFirst ? '最新在前' : '最舊在前',
              style: const TextStyle(fontSize: 11, color: Color(0xFFE8A52A))),
        ]),
      ),
    ]),
  );

  Widget _emptyHint(String msg) => Padding(
    padding: const EdgeInsets.all(32),
    child: Center(child: Text(msg, style: const TextStyle(color: Color(0xFF9CA3AF)))),
  );

  void _openSetGrid(ApiSet set) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => DexSetGridScreen(
        set: set,
        collected: _collected,
        formatPrice: _fmt,
        onToggleCollect: _toggleCollect,
      ),
    ));
    _loadCollectionStats();
  }

  void _openCardDetail(ApiCard card) async {
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => DexCardDetailScreen(
        card: card,
        isCollected: _collected.contains(card.id),
        onToggleCollect: (v) => _toggleCollectById(card, v),
        formatPrice: _fmt,
      ),
    ));
    _loadCollectionStats();
  }

  Future<void> _toggleCollect(ApiCard card) async =>
      _toggleCollectById(card, !_collected.contains(card.id));

  Future<void> _toggleCollectById(ApiCard card, bool add) async {
    if (add) {
      await SupabaseService.addToCollection({
        'card_id': card.id,
        'card_name': card.name,
        'set_name': card.setName,
        'image_small': card.imageSmall,
        'rarity': card.rarity,
        'estimated_price_ntd': card.estimatedPriceNTD,
      });
    } else {
      await SupabaseService.removeFromCollection(card.id);
    }
    _loadCollectionStats();
  }
}

// ── Collection Banner ─────────────────────────────────────────────────────────

class _CollectionBanner extends StatelessWidget {
  final int totalValue;
  final int collected;
  final String Function(int) formatPrice;

  const _CollectionBanner({required this.totalValue, required this.collected, required this.formatPrice});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE8A52A), Color(0xFFF5C842)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
          color: const Color(0xFFE8A52A).withOpacity(0.3),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.collections_bookmark_outlined, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            const Text('我的收藏總價值',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('已收 $collected 張',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
            ),
          ]),
          const SizedBox(height: 10),
          Text('NT\$ ${formatPrice(totalValue)}',
              style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('以市場參考價計算',
              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12)),
        ],
      ),
    );
  }
}

// ── Set Tile ──────────────────────────────────────────────────────────────────

class _SetTile extends StatelessWidget {
  final ApiSet set;
  final Set<String> collected;
  final VoidCallback onTap;
  final String Function(int) formatPrice;

  const _SetTile({
    required this.set, required this.collected,
    required this.onTap, required this.formatPrice,
  });

  Color _seriesColor(ApiSet s) {
    // 優先用 seriesId，再 fallback 到名稱關鍵字
    const idMap = {
      'sv': Color(0xFFE74C3C),
      'ss': Color(0xFF2980B9),
      'sm': Color(0xFFE8A52A),
      'xy': Color(0xFF27AE60),
      'bw': Color(0xFF374151),
      'dp': Color(0xFF8E44AD),
      'hgss': Color(0xFFD4A017),
    };
    if (s.seriesId != null && idMap.containsKey(s.seriesId!.toLowerCase())) {
      return idMap[s.seriesId!.toLowerCase()]!;
    }
    // fallback: 名稱關鍵字
    final name = (s.series ?? '').toLowerCase();
    if (name.contains('scarlet') || name.contains('violet') || name.contains('朱') || name.contains('紫')) return const Color(0xFFE74C3C);
    if (name.contains('sword') || name.contains('shield') || name.contains('劍') || name.contains('盾')) return const Color(0xFF2980B9);
    if (name.contains('sun') || name.contains('moon') || name.contains('太陽') || name.contains('月亮')) return const Color(0xFFE8A52A);
    if (name.contains('xy')) return const Color(0xFF27AE60);
    if (name.contains('black') || name.contains('white') || name.contains('黑') || name.contains('白')) return const Color(0xFF374151);
    return const Color(0xFF6B7280);
  }

  @override
  Widget build(BuildContext context) {
    final color = _seriesColor(set);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
              child: _SetBadge(setId: set.id, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(set.id.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(set.displayName,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                        overflow: TextOverflow.ellipsis),
                  ),
                ]),
                const SizedBox(height: 2),
                Text('${set.releaseDate ?? ''} · ${set.total} 張',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              ]),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
          ]),
        ),
      ),
    );
  }
}


// ── Series Tile ───────────────────────────────────────────────────────────────

class _SeriesTile extends StatelessWidget {
  final String name;
  final int count;
  final String latestDate;
  final VoidCallback onTap;

  const _SeriesTile({required this.name, required this.count,
      required this.latestDate, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8A52A), Color(0xFFF5C842)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.folder_special, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            const SizedBox(height: 2),
            Text('$count 個系列${latestDate.length >= 10 ? ' · 最新 ${latestDate.substring(0, 10)}' : ''}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ])),
          const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF), size: 20),
        ]),
      ),
    );
  }
}

// ── Search Card Tile ──────────────────────────────────────────────────────────

class _SearchCardTile extends StatelessWidget {
  final ApiCard card;
  final bool isCollected;
  final VoidCallback onTap;
  final VoidCallback onToggle;
  final String Function(int) formatPrice;

  const _SearchCardTile({required this.card, required this.isCollected,
      required this.onTap, required this.onToggle, required this.formatPrice});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
        ),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: card.imageSmall != null
                ? CachedNetworkImage(imageUrl: card.imageSmall!, width: 54, height: 76, fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(width: 54, height: 76, color: const Color(0xFFF3F4F6)))
                : Container(width: 54, height: 76, color: const Color(0xFFF3F4F6),
                    child: const Icon(Icons.style, color: Color(0xFFD1D5DB))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(card.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              const SizedBox(height: 3),
              Text(card.displaySet, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
              if (card.rarity != null)
                Text(card.rarity!, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
              if (card.estimatedPriceNTD > 0)
                Text('NT\$ ${formatPrice(card.estimatedPriceNTD)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF16A34A))),
            ]),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isCollected ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(isCollected ? Icons.bookmark : Icons.bookmark_border, size: 18,
                  color: isCollected ? Colors.white : const Color(0xFF9CA3AF)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Set Badge ─────────────────────────────────────────────────────────────────

class _SetBadge extends StatelessWidget {
  final String setId;
  final Color color;

  const _SetBadge({required this.setId, required this.color});

  // Extract prefix letters e.g. "SV8a" → "SV", "PMCG1" → "PM", "A1" → "A"
  String get _label {
    final letters = RegExp(r'^[A-Za-z]+').stringMatch(setId) ?? setId;
    return letters.length > 3 ? letters.substring(0, 3).toUpperCase() : letters.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          _label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _SetShimmer extends StatelessWidget {
  const _SetShimmer();
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: const Color(0xFFE5E7EB), highlightColor: const Color(0xFFF9FAFB),
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10), height: 72,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    ),
  );
}

// ── Error Widget ──────────────────────────────────────────────────────────────

class _ErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(children: [
      const Icon(Icons.wifi_off, size: 48, color: Color(0xFFD1D5DB)),
      const SizedBox(height: 12),
      const Text('無法載入資料',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh, size: 16),
        label: const Text('重試'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8A52A), foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0,
        ),
      ),
    ]),
  );
}
