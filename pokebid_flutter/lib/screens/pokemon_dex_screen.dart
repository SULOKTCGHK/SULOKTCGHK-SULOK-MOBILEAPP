import 'package:flutter/material.dart';
import '../widgets/no_image_placeholder.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/supabase_service.dart';
import '../services/api_service.dart';
import 'dex_card_detail_screen.dart';
import '../i18n/strings.dart';

// 世代定義：name、id 範圍
const List<Map<String, dynamic>> _kGens = [
  {'label': '全部',  'min': 1,   'max': 9999},
  {'label': 'Gen 1 🔴', 'min': 1,   'max': 151},
  {'label': 'Gen 2 🌿', 'min': 152, 'max': 251},
  {'label': 'Gen 3 💎', 'min': 252, 'max': 386},
  {'label': 'Gen 4 💠', 'min': 387, 'max': 493},
  {'label': 'Gen 5 ⚡', 'min': 494, 'max': 649},
  {'label': 'Gen 6 🌸', 'min': 650, 'max': 721},
  {'label': 'Gen 7 🌺', 'min': 722, 'max': 809},
  {'label': 'Gen 8 ⚔️', 'min': 810, 'max': 905},
  {'label': 'Gen 9 🌙', 'min': 906, 'max': 9999},
];


class PokemonDexScreen extends StatefulWidget {
  final bool embedded;
  // 內嵌時：選中/取消精靈會通知父層（傳精靈名，null=取消），讓父層左上角 AppBar 顯示返回鍵
  final ValueChanged<String?>? onSelectionChanged;
  // 選卡模式（刊登頁用）：點卡時回傳卡片而非進詳情頁
  final ValueChanged<ApiCard>? onCardPicked;
  const PokemonDexScreen({super.key, this.embedded = false, this.onSelectionChanged, this.onCardPicked});

  @override
  State<PokemonDexScreen> createState() => PokemonDexScreenState();
}

class PokemonDexScreenState extends State<PokemonDexScreen> {
  /// 供父層（dex_screen 左上角返回鍵）呼叫，清除精靈選擇
  void clearSelection() {
    setState(() { _selectedPokemon = null; _cards = []; });
    widget.onSelectionChanged?.call(null);
  }

  final _searchCtrl = TextEditingController();
  String _query = '';
  int _genIndex = 0; // 0 = 全部
  String? _selectedPokemon;
  bool _cardLoading = false;
  List<ApiCard> _cards = [];

  // 精靈名稱由 Supabase pokemon_names 表載入（含本機快取）
  List<Map<String, dynamic>> _pokemonList = [];

  @override
  void initState() {
    super.initState();
    _loadPokemonNames();
  }

  Future<void> _loadPokemonNames() async {
    final list = await SupabaseService.getPokemonNames();
    if (mounted) setState(() => _pokemonList = list);
  }

  List<Map<String, dynamic>> get _filtered {
    final gen = _kGens[_genIndex];
    final min = gen['min'] as int;
    final max = gen['max'] as int;
    var list = _pokemonList.where((p) {
      final id = (p['id'] as num).toInt();
      return id >= min && id <= max;
    }).toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((p) =>
        p['en'].toString().toLowerCase().contains(q) ||
        p['zh'].toString().toLowerCase().contains(q) ||
        p['id'].toString() == q).toList();
    }
    return list;
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

  Future<void> _loadCards(String pokemonName) async {
    setState(() { _selectedPokemon = pokemonName; _cardLoading = true; _cards = []; });
    widget.onSelectionChanged?.call(pokemonName);
    // 用開頭搜尋抓最齊全的結果（Charizard → Charizard V, Charizard ex...）
    final rows = await SupabaseService.searchCardsByPokemon(pokemonName);
    if (mounted) setState(() {
      _cards = rows.map(_rowToCard).toList();
      _cardLoading = false;
    });
  }

  String _spriteUrl(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png';

  String _fmt(int p) => p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) {
      // 內嵌模式：無 Scaffold。
      // 父層（dex_screen）用 onSelectionChanged 在左上角 AppBar 接管返回；
      // 若父層未接管（如刊登頁選卡 sheet），則自己顯示返回列。
      final parentHandlesBack = widget.onSelectionChanged != null;
      if (_selectedPokemon != null && !parentHandlesBack) {
        return Column(children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(children: [
              GestureDetector(
                onTap: clearSelection,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.chevron_left, size: 20, color: Color(0xFFE8A52A)),
                  Text(L.pokemonBack, style: const TextStyle(fontSize: 13, color: Color(0xFFE8A52A))),
                ]),
              ),
              const SizedBox(width: 8),
              Text(_selectedPokemon!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ]),
          ),
          Expanded(child: _buildCards()),
        ]);
      }
      return _selectedPokemon != null ? _buildCards() : _buildPokemonGrid();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0.5,
        foregroundColor: const Color(0xFF111827),
        title: _selectedPokemon == null
            ? Text(L.pokemonDexTitle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))
            : Row(children: [
                GestureDetector(
                  onTap: () => setState(() { _selectedPokemon = null; _cards = []; }),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.chevron_left, size: 20, color: Color(0xFFE8A52A)),
                    Text(L.pokemonBack, style: const TextStyle(fontSize: 13, color: Color(0xFFE8A52A))),
                  ]),
                ),
                const SizedBox(width: 8),
                Text(_selectedPokemon!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ]),
        leading: _selectedPokemon != null ? const SizedBox.shrink() : null,
        automaticallyImplyLeading: _selectedPokemon == null,
      ),
      body: _selectedPokemon != null ? _buildCards() : _buildPokemonGrid(),
    );
  }

  Widget _buildPokemonGrid() {
    final list = _filtered;
    return Column(children: [
      // 搜尋欄
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _query = v),
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: L.searchPokemonHint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF), size: 20),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
                    onPressed: () { _searchCtrl.clear(); setState(() => _query = ''); })
                : null,
            filled: true, fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
      // 世代 Tab 橫向滾動
      Container(
        color: Colors.white,
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          itemCount: _kGens.length,
          itemBuilder: (_, i) {
            final active = _genIndex == i;
            return GestureDetector(
              onTap: () => setState(() { _genIndex = i; }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                alignment: Alignment.center,
                child: Text(i == 0 ? L.all : _kGens[i]['label'] as String,
                    style: TextStyle(
                      fontSize: 11.5, fontWeight: FontWeight.w600,
                      color: active ? Colors.white : const Color(0xFF6B7280))),
              ),
            );
          },
        ),
      ),
      // 精靈數量提示
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Row(children: [
          Text(L.pokemonCount(list.length),
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        ]),
      ),
      // 精靈格
      Expanded(
        child: list.isEmpty
            ? Center(child: Text(L.noPokemon, style: const TextStyle(color: Color(0xFF9CA3AF))))
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8,
                  childAspectRatio: 0.78),
                itemCount: list.length,
                itemBuilder: (_, i) => _pokemonTile(list[i]),
              ),
      ),
    ]);
  }

  Widget _pokemonTile(Map<String, dynamic> p) {
    return GestureDetector(
      onTap: () => _loadCards(p['en'] as String),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEDEFF2), width: 0.5)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          CachedNetworkImage(
            imageUrl: _spriteUrl(p['id'] as int),
            height: 56, width: 56, fit: BoxFit.contain,
            errorWidget: (_, __, ___) => const Icon(Icons.catching_pokemon,
                size: 32, color: Color(0xFFE8A52A)),
          ),
          const SizedBox(height: 2),
          Text('#${(p['id'] as int).toString().padLeft(3, '0')}',
              style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(L.pokemonName(p),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: Color(0xFF374151)),
                maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          ),
        ]),
      ),
    );
  }

  Widget _buildCards() {
    if (_cardLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2));
    }
    if (_cards.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.style_outlined, size: 48, color: Color(0xFFD1D5DB)),
        const SizedBox(height: 12),
        Text(L.noCardsForPokemon(_selectedPokemon ?? ''),
            style: const TextStyle(color: Color(0xFF9CA3AF))),
        const SizedBox(height: 6),
        Text(L.pokemonNotInDb,
            style: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB))),
      ]));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.66),
      itemCount: _cards.length,
      itemBuilder: (_, i) {
        final card = _cards[i];
        return GestureDetector(
          onTap: () {
            if (widget.onCardPicked != null) {
              widget.onCardPicked!(card);
              return;
            }
            Navigator.push(context, MaterialPageRoute(
              builder: (_) => DexCardDetailScreen(
                card: card, isCollected: false,
                onToggleCollect: (_) {},
                formatPrice: _fmt,
              ),
            ));
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEDEFF2), width: 0.5)),
            clipBehavior: Clip.antiAlias,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Expanded(
                child: (card.imageSmall != null && card.imageSmall!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: card.imageSmall!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                            child: SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFD1D5DB)))),
                        errorWidget: (_, __, ___) => const NoImagePlaceholder(
                            icon: Icon(Icons.image_not_supported_outlined,
                                size: 28, color: Color(0xFFD1D5DB))),
                      )
                    : const NoImagePlaceholder(
                        icon: Icon(Icons.image_not_supported_outlined,
                            size: 28, color: Color(0xFFD1D5DB))),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 3, 5, 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(card.name,
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (card.setName != null)
                    Text(card.setName!,
                        style: const TextStyle(fontSize: 8, color: Color(0xFF9CA3AF)),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
          ),
        );
      },
    );
  }
}
