import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../services/currency_service.dart';
import '../services/wishlist_service.dart';
import '../widgets/login_required.dart';
import '../widgets/no_image_placeholder.dart';
import '../i18n/strings.dart';

class DexCardDetailScreen extends StatefulWidget {
  final ApiCard card;
  final bool isCollected;
  final ValueChanged<bool> onToggleCollect;
  final String Function(int) formatPrice;

  const DexCardDetailScreen({
    super.key,
    required this.card,
    required this.isCollected,
    required this.onToggleCollect,
    required this.formatPrice,
  });

  @override
  State<DexCardDetailScreen> createState() => _DexCardDetailScreenState();
}

class _DexCardDetailScreenState extends State<DexCardDetailScreen> {
  late bool _collected;
  bool _wished = false;
  List<Map<String, dynamic>> _transactions = [];
  bool _showAddTx = false;

  // SNKRDUNK 日本市場成交價
  Map<String, dynamic>? _snkr;
  bool _snkrLoading = true;

  // PSA Pop
  Map<String, dynamic>? _psaPop;

  final _gradeCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _buyerCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _collected = widget.isCollected;
    _loadTransactions();
    _dateCtrl.text = _todayStr();
    _loadSnkr();
    _loadPsaPop();
    _loadWished();
  }

  Future<void> _loadWished() async {
    final w = await WishlistService.isWishlisted(widget.card.id);
    if (mounted) setState(() => _wished = w);
  }

  // 願望清單：加入/移除這張卡
  Future<void> _toggleWish() async {
    if (!await requireLogin(context, action: L.addToWishlist)) return;
    final next = !_wished;
    setState(() => _wished = next);
    if (next) {
      await WishlistService.add(
        cardId: widget.card.id,
        cardName: widget.card.cleanName,
        imageUrl: widget.card.imageSmall,
        setId: widget.card.setId,
        setName: widget.card.setName,
        cardNumber: widget.card.number,
      );
    } else {
      await WishlistService.removeCard(widget.card.id);
    }
  }

  Future<void> _loadSnkr() async {
    setState(() => _snkrLoading = true);
    final data = await PokemonApiService.getSnkrdunkPrice(widget.card.id, widget.card.name, widget.card.number);
    if (mounted) setState(() { _snkr = data; _snkrLoading = false; });
  }

  Future<void> _loadPsaPop() async {
    final pop = await SupabaseService.getPsaPopForDexCard(
      cachedCardId: widget.card.id,
      setId: widget.card.setId,
      cardNumber: widget.card.number,
    );
    if (mounted && pop != null) setState(() => _psaPop = pop);
  }

  Map<String, dynamic> _cardMap() => {
        'card_id': widget.card.id,
        'card_name': widget.card.cleanName,
        'image_small': widget.card.imageSmall,
        'rarity': widget.card.rarity,
        'set_name': widget.card.setName,
      };

  // 把某分級（含成本價）加入收藏
  Future<void> _addGradeToCollection(String gradeCode, String label, num marketJpy) async {
    if (!await requireLogin(context, action: L.addToCollection)) return;
    if (!mounted) return;
    final rate = await CurrencyService.jpyToHkd();
    final marketHkd = (marketJpy * rate).round();
    final costCtrl = TextEditingController(text: marketHkd > 0 ? '$marketHkd' : '');
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(L.collectCardTitle(widget.card.cleanName), style: const TextStyle(fontSize: 15)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFE8A52A).withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFB8860B))),
          ),
          const SizedBox(height: 10),
          Text(L.currentMarket('$marketHkd', marketJpy.toStringAsFixed(0)),
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          TextField(
            controller: costCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: L.yourCost, prefixText: 'HK\$ ', isDense: true),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(L.cancel)),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(L.addToCollectionBtn)),
        ],
      ),
    );
    if (ok != true) return;
    final cost = num.tryParse(costCtrl.text.trim()) ?? 0;
    await SupabaseService.addGradedToCollection(_cardMap(),
        grade: gradeCode, costHkd: cost, marketJpy: marketJpy);
    if (mounted) {
      setState(() => _collected = true);
      widget.onToggleCollect(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L.collectedToast(label, widget.card.cleanName)), duration: const Duration(seconds: 2)));
    }
  }

  // 各分級的最新成交價（沒有 latest 用 avg）
  num _latestFor(String gradeKey) {
    final m = _snkr?[gradeKey] as Map<String, dynamic>?;
    return ((m?['latest'] as num?) ?? (m?['avg'] as num?) ?? 0);
  }

  // 右上角「加入收藏」→ 先選分級（PSA10 / PSA9 / 生卡），再填入手價
  Future<void> _showGradePicker() async {
    if (!await requireLogin(context, action: L.addToCollection)) return;
    if (!mounted) return;
    final grades = <(String, String, String, Color)>[
      ('PSA10', 'PSA 10', 'psa10', const Color(0xFFE8A52A)),
      ('PSA9', 'PSA 9', 'psa9', const Color(0xFF2980B9)),
      ('RAW', L.rawCard, 'raw', const Color(0xFF6B7280)),
    ];
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 2),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(L.chooseGradeTitle,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(L.latestSalePrice,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF))),
            ),
          ),
          for (final g in grades)
            Builder(builder: (_) {
              final m = _snkr?[g.$3] as Map<String, dynamic>?;
              final price = _latestFor(g.$3);
              return ListTile(
                leading: Container(width: 10, height: 10,
                    decoration: BoxDecoration(color: g.$4, shape: BoxShape.circle)),
                title: Text(g.$2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                trailing: Text(m == null ? L.noSales : '¥${price.toStringAsFixed(0)}',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: g.$4)),
                onTap: () {
                  Navigator.pop(ctx);
                  _addGradeToCollection(g.$1, g.$2, price);
                },
              );
            }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _gradeCtrl.dispose();
    _priceCtrl.dispose();
    _buyerCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  String _todayStr() {
    final n = DateTime.now();
    return '${n.year}/${n.month.toString().padLeft(2, '0')}/${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadTransactions() async {
    final txs = await SupabaseService.getTransactionsForCard(widget.card.id);
    if (mounted) setState(() => _transactions = txs);
  }

  Future<void> _saveTransaction() async {
    final price = int.tryParse(_priceCtrl.text);
    if (price == null || price <= 0) {
      _showSnack(L.invalidAmount, error: true);
      return;
    }
    await SupabaseService.insertTransaction({
      'card_id': widget.card.id,
      'card_name': widget.card.name,
      'grade': _gradeCtrl.text.trim().isEmpty ? 'Raw' : _gradeCtrl.text.trim(),
      'price_ntd': price,
      'buyer': _buyerCtrl.text.trim().isEmpty ? L.anonymous : _buyerCtrl.text.trim(),
      'date': _dateCtrl.text.trim().isEmpty ? _todayStr() : _dateCtrl.text.trim(),
    });
    _gradeCtrl.clear();
    _priceCtrl.clear();
    _buyerCtrl.clear();
    _dateCtrl.text = _todayStr();
    setState(() => _showAddTx = false);
    _loadTransactions();
    _showSnack(L.txSaved);
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? const Color(0xFFE74C3C) : const Color(0xFF16A34A),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  String _fmt(int p) => widget.formatPrice(p);

  int get _avgPrice {
    if (_transactions.isEmpty) return 0;
    final sum = _transactions.fold<int>(0, (s, t) => s + ((t['price_ntd'] as int?) ?? 0));
    return sum ~/ _transactions.length;
  }

  int get _highPrice => _transactions.isEmpty
      ? 0
      : _transactions.map((t) => (t['price_ntd'] as int?) ?? 0).reduce((a, b) => a > b ? a : b);

  int get _lowPrice => _transactions.isEmpty
      ? 0
      : _transactions.map((t) => (t['price_ntd'] as int?) ?? 0).reduce((a, b) => a < b ? a : b);

  Future<void> _openSnkrdunk() async {
    // 有配對到就直連該卡，否則用搜尋
    String urlStr = _snkr?['snkrUrl'] as String? ?? '';
    if (urlStr.isEmpty) {
      final setId = widget.card.setId?.toUpperCase() ?? '';
      final number = widget.card.number ?? '';
      final query = '$setId $number'.trim();
      urlStr = 'https://snkrdunk.com/search?keywords=${Uri.encodeComponent(query)}';
    }
    final url = Uri.parse(urlStr);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;

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
        title: Text(
          card.name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827)),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(_wished ? Icons.favorite : Icons.favorite_border,
                color: _wished ? const Color(0xFFE74C3C) : const Color(0xFF6B7280), size: 22),
            onPressed: _toggleWish,
          ),
          GestureDetector(
            onTap: _showGradePicker,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _collected ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _collected ? const Color(0xFFE8A52A) : const Color(0xFFD1D5DB),
                  width: 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _collected ? Icons.bookmark : Icons.bookmark_border,
                    size: 14,
                    color: _collected ? Colors.white : const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _collected ? L.collected : L.addToCollectionBtn,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _collected ? Colors.white : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // 卡牌圖片
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: card.imageLarge != null || card.imageSmall != null
                  ? CachedNetworkImage(
                      imageUrl: card.imageLarge ?? card.imageSmall!,
                      height: 280,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => Container(
                        height: 280,
                        color: const Color(0xFFF9FAFB),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE8A52A), strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, __, ___) => const SizedBox(
                        height: 280,
                        child: NoImagePlaceholder(
                          background: Color(0xFFF9FAFB),
                          icon: Icon(Icons.broken_image, size: 56, color: Color(0xFFD1D5DB)),
                        ),
                      ),
                    )
                  : const SizedBox(
                      height: 280,
                      child: NoImagePlaceholder(
                        background: Color(0xFFF9FAFB),
                        icon: Icon(Icons.style, size: 56, color: Color(0xFFD1D5DB)),
                      ),
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 卡名
                Text(
                  card.cleanName,
                  style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
                ),
                const SizedBox(height: 4),
                Text(
                  card.displaySet,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 12),

                // 標籤
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (card.supertype != null)
                      _chip(card.supertype!, const Color(0xFF6B7280)),
                    if (card.types.isNotEmpty)
                      _chip(card.types.first, _typeColor(card.types.first)),
                    if (card.rarity != null)
                      _chip(card.rarity!, _rarityColor(card.rarity)),
                    if (card.number != null)
                      _chip('No.${card.number}', const Color(0xFF374151)),
                    if (variantLabelZh(card.variant).isNotEmpty)
                      _chip('● ${variantLabelZh(card.variant)}', const Color(0xFF8E44AD)),
                  ],
                ),
                const SizedBox(height: 16),

                // 成交價格統計
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        L.priceStats,
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(height: 8),
                      if (_transactions.isEmpty)
                        Text(
                          L.noTxHintAdd,
                          style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                        )
                      else ...[
                        Text(
                          'HK\$ ${_fmt(_avgPrice)}',
                          style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                        ),
                        Text(
                          L.avgSalePrice,
                          style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _statBox(L.statHigh, _highPrice, const Color(0xFFE74C3C))),
                            const SizedBox(width: 8),
                            Expanded(child: _statBox(L.statAvg, _avgPrice, const Color(0xFFE8A52A))),
                            const SizedBox(width: 8),
                            Expanded(child: _statBox(L.statLow, _lowPrice, const Color(0xFF2980B9))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // SNKRDUNK 日本市場成交價（PSA10/PSA9/生卡）
                _SnkrPriceCard(
                  loading: _snkrLoading,
                  data: _snkr,
                  onTap: _openSnkrdunk,
                  onAddGrade: _addGradeToCollection,
                ),
                const SizedBox(height: 12),

                // PSA Pop 數量
                if (_psaPop != null) _PsaPopCard(pop: _psaPop!),
                const SizedBox(height: 20),

                // 成交紀錄 header
                Row(
                  children: [
                    Text(
                      L.recentTx,
                      style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        L.recordsCount(_transactions.length),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _showAddTx = !_showAddTx),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8A52A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showAddTx ? Icons.close : Icons.add,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _showAddTx ? L.cancel : L.add,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (_showAddTx) ...[
                  const SizedBox(height: 12),
                  _AddTxForm(
                    gradeCtrl: _gradeCtrl,
                    priceCtrl: _priceCtrl,
                    buyerCtrl: _buyerCtrl,
                    dateCtrl: _dateCtrl,
                    onSave: _saveTransaction,
                  ),
                ],
                const SizedBox(height: 10),

                // 成交紀錄列表
                if (_transactions.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFFD1D5DB)),
                          const SizedBox(height: 8),
                          Text(L.noTxRecords,
                              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(L.noTxHintTap,
                              style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 11)),
                        ],
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
                    ),
                    child: Column(
                      children: _transactions.asMap().entries.map((e) {
                        final i = e.key;
                        final tx = e.value;
                        final isLast = i == _transactions.length - 1;
                        final price = (tx['price_ntd'] as int?) ?? 0;
                        final avg = _avgPrice;
                        final above = avg > 0 && price > avg;
                        final priceColor =
                            above ? const Color(0xFFE74C3C) : const Color(0xFF16A34A);

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: isLast
                                ? null
                                : const Border(
                                    bottom: BorderSide(color: Color(0xFFF3F4F6), width: 0.5)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  tx['grade'] as String? ?? 'Raw',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx['buyer'] as String? ?? '匿名',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF111827),
                                      ),
                                    ),
                                    Text(
                                      tx['date'] as String? ?? '',
                                      style: const TextStyle(
                                          fontSize: 11, color: Color(0xFF9CA3AF)),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    above ? Icons.trending_up : Icons.trending_down,
                                    size: 14,
                                    color: priceColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'HK\$ ${_fmt(price)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: priceColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () async {
                                  await SupabaseService.deleteTransaction(tx['id'].toString());
                                  _loadTransactions();
                                },
                                child: const Icon(Icons.delete_outline,
                                    size: 16, color: Color(0xFFD1D5DB)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withOpacity(0.3), width: 0.5),
    ),
    child: Text(label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
  );

  Widget _statBox(String label, int price, Color color) => Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        Text('HK\$ ${_fmt(price)}',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color),
            overflow: TextOverflow.ellipsis),
      ],
    ),
  );

  Color _typeColor(String type) {
    const map = {
      'Fire': Color(0xFFE74C3C), 'Water': Color(0xFF2980B9),
      'Grass': Color(0xFF27AE60), 'Lightning': Color(0xFFD4A017),
      'Psychic': Color(0xFF8E44AD), 'Fighting': Color(0xFFC0392B),
      'Darkness': Color(0xFF374151), 'Metal': Color(0xFF6B7280),
      'Dragon': Color(0xFF1A6FA8), 'Fairy': Color(0xFFC0397A),
      'Colorless': Color(0xFF9CA3AF),
    };
    return map[type] ?? const Color(0xFF6B7280);
  }

  Color _rarityColor(String? rarity) {
    if (rarity == null) return const Color(0xFF6B7280);
    if (rarity.contains('★★★') || rarity.contains('SR') || rarity.contains('UR')) {
      return const Color(0xFFE74C3C);
    }
    if (rarity.contains('★★') || rarity.contains('RR')) return const Color(0xFFE8A52A);
    if (rarity.contains('★') || rarity.contains('R')) return const Color(0xFF8E44AD);
    if (rarity.contains('◆◆') || rarity.contains('U')) return const Color(0xFF2980B9);
    return const Color(0xFF6B7280);
  }
}

// ── PSA Pop 數量卡片 ──────────────────────────────────────────────────────────

class _PsaPopCard extends StatelessWidget {
  final Map<String, dynamic> pop;
  const _PsaPopCard({required this.pop});

  @override
  Widget build(BuildContext context) {
    final fetchedAt = pop['fetched_at'] as String?;
    final dateStr = fetchedAt != null
        ? fetchedAt.substring(0, 10)
        : '';
    final grades = [
      {'label': 'PSA 10', 'key': 'pop_10', 'color': const Color(0xFF16A34A)},
      {'label': 'PSA 9',  'key': 'pop_9',  'color': const Color(0xFF2980B9)},
      {'label': 'PSA 8',  'key': 'pop_8',  'color': const Color(0xFF6B7280)},
      {'label': 'PSA 7',  'key': 'pop_7',  'color': const Color(0xFF9CA3AF)},
      {'label': 'Auth',   'key': 'pop_auth','color': const Color(0xFFB8860B)},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(L.psaPopCount,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
          const Spacer(),
          if (dateStr.isNotEmpty)
            Text(L.psaUpdated(dateStr),
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ]),
        const SizedBox(height: 12),
        Row(children: grades.map((g) {
          final count = (pop[g['key']] as num?)?.toInt() ?? 0;
          return Expanded(child: _PopCell(
            label: g['label'] as String,
            count: count,
            color: g['color'] as Color,
          ));
        }).toList()),
        const SizedBox(height: 8),
        Row(children: [
          Text(L.total, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          Text(L.totalCards((pop['total'] as num?)?.toInt() ?? 0),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        ]),
      ]),
    );
  }
}

class _PopCell extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _PopCell({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text('$count',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
    ]);
  }
}

// ── SNKRDUNK 日本市場成交價 ───────────────────────────────────────────────────
class _SnkrPriceCard extends StatelessWidget {
  final bool loading;
  final Map<String, dynamic>? data;
  final VoidCallback onTap;
  final void Function(String gradeCode, String label, num marketJpy)? onAddGrade;

  const _SnkrPriceCard({required this.loading, required this.data, required this.onTap, this.onAddGrade});

  String _yen(num? v) => v == null ? '—' : '¥${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFBEB), Colors.white],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8A52A).withOpacity(0.35), width: 0.8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // header
        Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: const Color(0xFFE8A52A), borderRadius: BorderRadius.circular(9)),
            child: const Center(child: Text('🇯🇵', style: TextStyle(fontSize: 18)))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(L.snkrTitle, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF111827))),
            Text(L.snkrSubtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF9CA3AF))),
          ])),
          GestureDetector(onTap: onTap, child: const Icon(Icons.open_in_new, size: 16, color: Color(0xFFE8A52A))),
        ]),
        const SizedBox(height: 12),

        if (loading)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(L.snkrLoading, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))))
        else if (data == null)
          Padding(padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(L.snkrNoData, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))))
        else ...[
          // 三種分級價格
          Row(children: [
            Expanded(child: _gradeBox('PSA 10', 'PSA10', data!['psa10'], const Color(0xFFE8A52A))),
            const SizedBox(width: 8),
            Expanded(child: _gradeBox('PSA 9', 'PSA9', data!['psa9'], const Color(0xFF2980B9))),
            const SizedBox(width: 8),
            Expanded(child: _gradeBox(L.rawCard, 'RAW', data!['raw'], const Color(0xFF6B7280))),
          ]),
          // PSA10 價格走勢圖（7日/30日）
          if (data!['psa10'] is Map &&
              (((data!['psa10'] as Map)['daily'] as List?)?.length ?? 0) >= 2)
            _SnkrChart(
              daily: (data!['psa10'] as Map)['daily'] as List,
              chg7: (data!['psa10'] as Map)['chg7'] as num?,
              chg30: (data!['psa10'] as Map)['chg30'] as num?,
            ),
          // 近期成交列表（PSA10 優先）
          ...(_recentList()),
        ],
      ]),
    );
  }

  Widget _gradeBox(String label, String gradeCode, dynamic g, Color color) {
    final m = g as Map<String, dynamic>?;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(m == null ? '—' : _yen(m['avg']),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color),
            maxLines: 1, overflow: TextOverflow.ellipsis),
        Text(m == null ? L.noSales : L.salesCount(m['count']),
            style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF))),
        if (m != null && onAddGrade != null) ...[
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => onAddGrade!(gradeCode, label, (m['avg'] as num?) ?? 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
              child: Text(L.addCollectShort, textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ]),
    );
  }

  List<Widget> _recentList() {
    final psa10 = data!['psa10'] as Map<String, dynamic>?;
    final recent = (psa10?['recent'] as List?) ?? [];
    if (recent.isEmpty) return [];
    return [
      const SizedBox(height: 12),
      Text(L.snkrRecent, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
      const SizedBox(height: 6),
      ...recent.take(5).map((r) {
        final item = r as Map<String, dynamic>;
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(children: [
            Expanded(child: Text('${item['date']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)))),
            Text(_yen(item['price'] as num?),
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFE8A52A))),
          ]),
        );
      }),
    ];
  }
}

// ── SNKRDUNK PSA10 價格走勢圖（7日 / 30日）──────────────────────────────────
class _SnkrChart extends StatefulWidget {
  final List daily;
  final num? chg7;
  final num? chg30;
  const _SnkrChart({required this.daily, this.chg7, this.chg30});
  @override
  State<_SnkrChart> createState() => _SnkrChartState();
}

class _SnkrChartState extends State<_SnkrChart> {
  int _range = 30;

  List<Map<String, dynamic>> _points() {
    final cutoff = DateTime.now().subtract(Duration(days: _range + 1));
    final out = <Map<String, dynamic>>[];
    for (final e in widget.daily) {
      final m = (e as Map).cast<String, dynamic>();
      final d = DateTime.tryParse(m['d'] as String? ?? '');
      if (d != null && d.isAfter(cutoff)) out.add(m);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final pts = _points();
    if (pts.length < 2) return const SizedBox.shrink();
    final chg = _range == 7 ? widget.chg7 : widget.chg30;
    final values = pts.map((p) => (p['avg'] as num).toDouble()).toList();
    final labels = pts.map((p) => (p['d'] as String).substring(5).replaceAll('-', '/')).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 14),
      Row(children: [
        Text(L.psaPriceTrend,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280))),
        const SizedBox(width: 8),
        if (chg != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF374151).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6)),
            child: Text('${chg >= 0 ? '▲' : '▼'} ${chg.abs()}%',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                    color: Color(0xFF374151))),
          ),
        const Spacer(),
        _rangeBtn(7), const SizedBox(width: 4), _rangeBtn(30),
      ]),
      const SizedBox(height: 10),
      SizedBox(height: 110, width: double.infinity,
          child: CustomPaint(painter: _LinePainter(values, labels))),
    ]);
  }

  Widget _rangeBtn(int d) {
    final sel = _range == d;
    return GestureDetector(
      onTap: () => setState(() => _range = d),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF111827) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6)),
        child: Text(L.daysShort(d),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: sel ? Colors.white : const Color(0xFF6B7280))),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  _LinePainter(this.values, this.labels);

  String _yen(double v) => '¥${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  TextPainter _tp(String s, Color c) {
    final t = TextPainter(
        text: TextSpan(text: s, style: TextStyle(fontSize: 9, color: c)),
        textDirection: TextDirection.ltr)..layout();
    return t;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const lPad = 4.0, rPad = 4.0, tPad = 12.0, bPad = 14.0;
    final w = size.width - lPad - rPad;
    final h = size.height - tPad - bPad;
    double minV = values[0], maxV = values[0];
    for (final v in values) { if (v < minV) minV = v; if (v > maxV) maxV = v; }
    final range = (maxV - minV).abs() < 1 ? 1.0 : (maxV - minV);
    double px(int i) => lPad + w * (i / (values.length - 1));
    double py(double v) => tPad + h * (1 - (v - minV) / range);

    final line = Path();
    final fill = Path()..moveTo(px(0), tPad + h)..lineTo(px(0), py(values[0]));
    for (int i = 0; i < values.length; i++) {
      final x = px(i), y = py(values[i]);
      if (i == 0) { line.moveTo(x, y); } else { line.lineTo(x, y); fill.lineTo(x, y); }
    }
    fill..lineTo(px(values.length - 1), tPad + h)..close();

    canvas.drawPath(fill, Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Color(0x22111827), Color(0x00111827)]).createShader(Rect.fromLTWH(0, tPad, size.width, h)));
    canvas.drawPath(line, Paint()
      ..color = const Color(0xFF111827)..strokeWidth = 2
      ..style = PaintingStyle.stroke..strokeJoin = StrokeJoin.round..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(px(values.length - 1), py(values.last)), 3, Paint()..color = const Color(0xFF111827));

    // 高/低價標籤（左上角堆疊）
    _tp(_yen(maxV), const Color(0xFF9CA3AF)).paint(canvas, const Offset(lPad, 0));
    final lo = _tp(_yen(minV), const Color(0xFF9CA3AF));
    lo.paint(canvas, Offset(lPad, tPad + h - 8));
    // 起訖日期（底部）
    _tp(labels.first, const Color(0xFFB6BCC6)).paint(canvas, Offset(lPad, tPad + h + 2));
    final last = _tp(labels.last, const Color(0xFFB6BCC6));
    last.paint(canvas, Offset(size.width - rPad - last.width, tPad + h + 2));
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) => old.values != values;
}

// ── Add Transaction Form ──────────────────────────────────────────────────────

class _AddTxForm extends StatelessWidget {
  final TextEditingController gradeCtrl;
  final TextEditingController priceCtrl;
  final TextEditingController buyerCtrl;
  final TextEditingController dateCtrl;
  final VoidCallback onSave;

  const _AddTxForm({
    required this.gradeCtrl,
    required this.priceCtrl,
    required this.buyerCtrl,
    required this.dateCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8A52A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(L.addTxTitle,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _field(gradeCtrl, L.gradeFieldHint)),
              const SizedBox(width: 8),
              Expanded(child: _field(priceCtrl, L.amountFieldHint, isNumber: true)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field(buyerCtrl, L.buyerFieldHint)),
              const SizedBox(width: 8),
              Expanded(child: _field(dateCtrl, 'YYYY/MM/DD')),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE8A52A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(L.save,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String hint, {bool isNumber = false}) =>
      TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontSize: 13, color: Color(0xFF111827)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE8A52A), width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      );
}
