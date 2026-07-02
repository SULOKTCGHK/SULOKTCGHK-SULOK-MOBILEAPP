import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/no_image_placeholder.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/login_required.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import 'dex_card_detail_screen.dart';
import 'dex_set_grid_screen.dart';
import 'pokemon_dex_screen.dart';
import '../i18n/strings.dart';

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
  Map<String, dynamic> _valueSeries = {};
  int _collectedCount = 0;
  bool _loadingSets = true;
  String? _error;
  bool _searching = false;
  bool _searchLoading = false;
  List<ApiCard> _searchResults = [];

  bool _sortNewestFirst = true;

  // 頂層模式切換
  String _dexMode = 'sets'; // 'sets' | 'pokemon'

  // 導覽：分支（'box' 卡盒 / 'promo'）與已選系列
  String? _branch;
  String? _selectedSeries;

  // 是否為 PROMO 系列（名稱含 promo）
  bool _isPromoSet(ApiSet s) =>
      s.name.toLowerCase().contains('promo') || s.id.toLowerCase().contains('-p-');

  // 是否為牌組/禮盒類（非擴充包）
  static final RegExp _deckPattern = RegExp(
      r'deck|starter|build.box|gift.box|trainer.box|special.set|special.deck|half.deck|kit|battle master|premium|construction|start decks|\bvs\b');
  bool _isDeckSet(ApiSet s) =>
      _deckPattern.hasMatch(('${s.id} ${s.name}').toLowerCase());

  // 分類：promo / deck / box
  String _category(ApiSet s) {
    if (_isPromoSet(s)) return 'promo';
    if (_isDeckSet(s)) return 'deck';
    return 'box';
  }

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

  ApiCard _rowToCard(Map<String, dynamic> r) => ApiCard(
    id: r['id'] as String, name: r['name'] as String,
    imageSmall: r['image_small'] as String?, imageLarge: r['image_large'] as String?,
    rarity: r['rarity'] as String?, setName: r['set_name'] as String?,
    setId: r['set_id'] as String?, number: r['number'] as String?,
    supertype: r['supertype'] as String?,
    types: (r['types'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
    variant: r['variant'] as String?,
  );

  @override
  void initState() {
    super.initState();
    _loadSets();
    _loadCollectionStats();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCollectionStats() async {
    final ids = await SupabaseService.getCollectedCardIds();
    final summary = await SupabaseService.getCollectionSummary();
    final series = await SupabaseService.getCollectionValueSeries();
    if (mounted) {
      setState(() {
      _collected = ids;
      _totalValue = ((summary['value'] as num?) ?? 0).round();
      _collectedCount = (summary['count'] as int?) ?? ids.length;
      _valueSeries = series;
    });
    }
  }

  Future<void> _loadSets() async {
    setState(() { _loadingSets = true; _error = null; });
    try {
      final cached = await SupabaseService.getCachedSets();
      if (mounted) {
        setState(() {
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
      }
    } catch (e) {
      if (mounted) setState(() { _error = L.dexLoadFailed('$e'); _loadingSets = false; });
    }
  }

  Timer? _searchDebounce;
  int _searchSeq = 0; // 防競態：慢的舊回應不可蓋掉新結果（如打 "sar" 時 "s"/"sa" 的回應後到）

  void _search(String q) {
    _searchDebounce?.cancel();
    _searchSeq++; // 讓在途的舊查詢作廢
    if (q.trim().isEmpty) {
      setState(() { _searching = false; _searchResults = []; _searchLoading = false; });
      return;
    }
    setState(() { _searching = true; _searchLoading = true; });
    // 停止輸入 250ms 才真正查詢
    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      final seq = _searchSeq;
      final rows = await SupabaseService.searchCachedCards(q.trim());
      if (!mounted || seq != _searchSeq) return; // 已有更新的查詢 → 丟棄
      setState(() {
        _searchResults = rows.map(_rowToCard).toList();
        _searchLoading = false;
      });
    });
  }

  String _fmt(int p) => p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  // 內嵌精靈圖鑑的返回控制：選中精靈時，左上角 AppBar 顯示返回鍵
  final GlobalKey<PokemonDexScreenState> _pokemonKey = GlobalKey();
  String? _pokemonName;

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
        leading: (_dexMode == 'pokemon' && _pokemonName != null)
            ? IconButton(
                icon: const Icon(Icons.chevron_left, color: Color(0xFF374151), size: 28),
                onPressed: () => _pokemonKey.currentState?.clearSelection(),
              )
            : (_branch != null || _selectedSeries != null)
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
        title: (_dexMode == 'pokemon' && _pokemonName != null)
            ? Text(_pokemonName!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)))
            : RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
                  children: [
                    const TextSpan(text: 'TCG'),
                    const TextSpan(text: 'spot', style: TextStyle(color: Color(0xFFE8A52A))),
                    TextSpan(text: L.dexTitleSuffix, style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280))),
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
          // 搜尋欄（只在系列模式顯示）
          if (_dexMode == 'sets')
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _search,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: L.searchCardHint,
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
          // 模式切換 Tab
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Row(children: [
              _modeTab('sets', L.tabSetDex),
              const SizedBox(width: 8),
              _modeTab('pokemon', L.tabPokemonDex),
            ]),
          ),
          Container(height: 0.5, color: const Color(0xFFE5E7EB)),
          Expanded(
            child: _dexMode == 'pokemon'
                ? PokemonDexScreen(
                    key: _pokemonKey,
                    embedded: true,
                    onSelectionChanged: (name) => setState(() => _pokemonName = name),
                  )
                : (_searching ? _buildSearchResults() : _buildMainContent()),
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
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.search_off, size: 48, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text(L.cardNotFound, style: const TextStyle(color: Color(0xFF9CA3AF))),
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
        _CollectionBanner(totalValue: _totalValue, collected: _collectedCount, formatPrice: _fmt,
            points: (_valueSeries['points'] as List?)?.cast<double>() ?? const [],
            chgPct: _valueSeries['chgPct'] as double?),
        const SizedBox(height: 12),
        ...List.generate(6, (_) => const _SetShimmer()),
      ]);
    }
    if (_error != null) {
      return ListView(children: [
        _CollectionBanner(totalValue: _totalValue, collected: _collectedCount, formatPrice: _fmt,
            points: (_valueSeries['points'] as List?)?.cast<double>() ?? const [],
            chgPct: _valueSeries['chgPct'] as double?),
        _ErrorWidget(message: _error!, onRetry: _loadSets),
      ]);
    }

    return ListView(
      children: [
        _CollectionBanner(totalValue: _totalValue, collected: _collectedCount, formatPrice: _fmt,
            points: (_valueSeries['points'] as List?)?.cast<double>() ?? const [],
            chgPct: _valueSeries['chgPct'] as double?),

        // ── 第一層：卡盒 / 牌組 / PROMO ─────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Row(children: [
            _branchCard('box',   '📦', '擴充盒'),
            const SizedBox(width: 10),
            _branchCard('deck',  '🎴', '禮盒'),
            const SizedBox(width: 10),
            _branchCard('promo', '✨', '特典卡'),
          ]),
        ),

        if (_branch == 'promo') ..._buildFlatLevel(_promoSets, L.promoSeriesCount(_promoSets.length), L.noPromoData)
        else if (_branch == 'box') ..._buildFlatLevel(_sortByDate(_boxSets), L.boxSetsCount(_boxSets.length), L.noBoxData)
        else if (_branch == 'deck') ..._buildFlatLevel(_sortByDate(_deckSets), L.deckSetsCount(_deckSets.length), L.noDeckData),

        const SizedBox(height: 100),
      ],
    );
  }

  // 直接列出所有系列方格（擴充盒／禮盒／特典卡 統一排版）
  List<Widget> _buildFlatLevel(List<ApiSet> sets, String header, String emptyMsg) {
    return [
      _sectionHeader(header),
      if (sets.isEmpty)
        _emptyHint(emptyMsg)
      else
        _setGrid(sets),
    ];
  }

  // 系列方格（卡盒圖 + 名字 + 年份），手機友善
  Widget _setGrid(List<ApiSet> sets) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: LayoutBuilder(builder: (ctx, c) {
        const infoH = 60.0;
        final cellW = (c.maxWidth - 10) / 2;
        final ar = cellW / (cellW + infoH);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: ar),
          itemCount: sets.length,
          itemBuilder: (_, i) => _SetCard(set: sets[i], onTap: () => _openSetGrid(sets[i])),
        );
      }),
    );
  }

  Widget _branchCard(String key, String icon, String label) {
    final active = _branch == key;
    // 每個分類用不同強調色
    final accent = key == 'box'
        ? const Color(0xFF4338CA)   // 靛藍
        : key == 'deck'
            ? const Color(0xFF0891B2) // 青藍
            : const Color(0xFF7C3AED); // 紫
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _branch = key;
          _selectedSeries = null;
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
          decoration: BoxDecoration(
            color: active ? accent : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: active ? accent : const Color(0xFFE5E7EB),
              width: active ? 0 : 0.5,
            ),
            boxShadow: active
                ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(children: [
            Text(icon, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 7),
            Text(label,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: active ? Colors.white : const Color(0xFF1F2937))),
          ]),
        ),
      ),
    );
  }

  Widget _modeTab(String mode, String label) {
    final active = _dexMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _dexMode = mode;
          if (mode == 'sets') { _searchCtrl.clear(); _search(''); }
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: active ? Colors.white : const Color(0xFF6B7280))),
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
          Text(_sortNewestFirst ? L.newestFirst : L.oldestFirst,
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
    if (add && !await requireLogin(context, action: '加入收藏')) return;
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
  final List<double> points;
  final double? chgPct;

  const _CollectionBanner({
    required this.totalValue, required this.collected, required this.formatPrice,
    this.points = const [], this.chgPct,
  });

  @override
  Widget build(BuildContext context) {
    final hasChange = chgPct != null;
    final isUp = hasChange && chgPct! >= 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1040), Color(0xFF2D2082), Color(0xFF4338CA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
          color: const Color(0xFF2D2082).withValues(alpha: 0.45),
          blurRadius: 18, offset: const Offset(0, 6),
        )],
      ),
      child: Stack(children: [
        // 背景裝飾圓
        Positioned(
          right: -20, top: -20,
          child: Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
        Positioned(
          right: 40, bottom: -30,
          child: Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // 頂部標題行
            Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.collections_bookmark_outlined, color: Colors.white, size: 15),
              ),
              const SizedBox(width: 8),
              Text(L.myCollectionValue,
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 0.5),
                ),
                child: Text(L.collectedCount(collected),
                    style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 14),
            // 金額 + 漲跌
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('HK\$', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(formatPrice(totalValue),
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800, height: 1)),
              ]),
              const Spacer(),
              if (hasChange)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: (isUp ? const Color(0xFF22C55E) : const Color(0xFFEF4444)).withValues(alpha: 0.4),
                      width: 0.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(isUp ? Icons.trending_up : Icons.trending_down,
                        size: 14, color: isUp ? const Color(0xFF4ADE80) : const Color(0xFFFCA5A5)),
                    const SizedBox(width: 4),
                    Text('${chgPct!.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                            color: isUp ? const Color(0xFF4ADE80) : const Color(0xFFFCA5A5),
                            fontSize: 12, fontWeight: FontWeight.w700)),
                  ]),
                ),
            ]),
            // 走勢圖
            if (points.length >= 2) ...[
              const SizedBox(height: 12),
              SizedBox(height: 36, width: double.infinity,
                  child: CustomPaint(painter: _SparklinePainter(points))),
            ],
            const SizedBox(height: 10),
            Text(points.length >= 2 ? L.trendDays(points.length) : L.marketRefPriceNote,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
          ]),
        ),
      ]),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  _SparklinePainter(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    double mn = values[0], mx = values[0];
    for (final v in values) { if (v < mn) mn = v; if (v > mx) mx = v; }
    final range = (mx - mn).abs() < 1 ? 1.0 : (mx - mn);
    double px(int i) => size.width * (i / (values.length - 1));
    double py(double v) => size.height * (1 - (v - mn) / range);
    final line = Path();
    final fill = Path()..moveTo(0, size.height);
    for (int i = 0; i < values.length; i++) {
      final x = px(i), y = py(values[i]);
      if (i == 0) { line.moveTo(x, y); fill.lineTo(x, y); }
      else { line.lineTo(x, y); fill.lineTo(x, y); }
    }
    fill..lineTo(size.width, size.height)..close();
    canvas.drawPath(fill, Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.white.withValues(alpha: 0.35), Colors.white.withValues(alpha: 0.0)]).createShader(Offset.zero & size));
    canvas.drawPath(line, Paint()
      ..color = Colors.white..strokeWidth = 2
      ..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round);
  }
  @override
  bool shouldRepaint(covariant _SparklinePainter old) => old.values != values;
}

// ── Set Tile ──────────────────────────────────────────────────────────────────

class _SetCard extends StatelessWidget {
  final ApiSet set;
  final VoidCallback onTap;

  const _SetCard({required this.set, required this.onTap});

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
    final year = (set.releaseDate ?? '').length >= 4 ? set.releaseDate!.substring(0, 4) : '';
    final hasLogo = set.logoImage != null && set.logoImage!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDEFF2), width: 1),
          boxShadow: [BoxShadow(color: const Color(0xFF111827).withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // 卡盒圖（正方形）
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(13)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                child: hasLogo
                    ? CachedNetworkImage(
                        imageUrl: set.logoImage!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => Center(child: _SetBadge(setId: set.id, color: color)),
                        errorWidget: (_, __, ___) => NoImagePlaceholder(
                            background: const Color(0xFFF9FAFB),
                            icon: _SetBadge(setId: set.id, color: color)),
                      )
                    : NoImagePlaceholder(
                        background: const Color(0xFFF9FAFB),
                        icon: _SetBadge(setId: set.id, color: color)),
              ),
            ),
          ),
          // 名字 + 年份
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 7, 9, 7),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(set.displayName,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827), height: 1.2),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(L.setYearCount(year, set.total),
                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
              ]),
            ),
          ),
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
                Text('HK\$ ${formatPrice(card.estimatedPriceNTD)}',
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
          colors: [color, color.withValues(alpha: 0.7)],
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
      Text(L.loadFailedTitle,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
      const SizedBox(height: 6),
      Text(message, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh, size: 16),
        label: Text(L.retry),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE8A52A), foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0,
        ),
      ),
    ]),
  );
}
