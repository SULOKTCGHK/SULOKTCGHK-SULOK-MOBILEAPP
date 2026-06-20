import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';

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
  List<Map<String, dynamic>> _transactions = [];
  bool _showAddTx = false;

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
      _showSnack('請輸入有效金額', error: true);
      return;
    }
    await SupabaseService.insertTransaction({
      'card_id': widget.card.id,
      'card_name': widget.card.name,
      'grade': _gradeCtrl.text.trim().isEmpty ? 'Raw' : _gradeCtrl.text.trim(),
      'price_ntd': price,
      'buyer': _buyerCtrl.text.trim().isEmpty ? '匿名' : _buyerCtrl.text.trim(),
      'date': _dateCtrl.text.trim().isEmpty ? _todayStr() : _dateCtrl.text.trim(),
    });
    _gradeCtrl.clear();
    _priceCtrl.clear();
    _buyerCtrl.clear();
    _dateCtrl.text = _todayStr();
    setState(() => _showAddTx = false);
    _loadTransactions();
    _showSnack('成交紀錄已儲存');
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
    final setId = widget.card.setId?.toUpperCase() ?? '';
    final number = widget.card.number ?? '';
    final query = '$setId $number'.trim();
    final url = Uri.parse(
      'https://snkrdunk.com/search?keywords=${Uri.encodeComponent(query)}',
    );
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
          GestureDetector(
            onTap: () {
              setState(() => _collected = !_collected);
              widget.onToggleCollect(_collected);
            },
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
                    _collected ? '已收藏' : '加入收藏',
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
                      errorWidget: (_, __, ___) => Container(
                        height: 280,
                        color: const Color(0xFFF9FAFB),
                        child: const Icon(Icons.broken_image, size: 64, color: Color(0xFFD1D5DB)),
                      ),
                    )
                  : Container(
                      height: 280,
                      color: const Color(0xFFF9FAFB),
                      child: const Icon(Icons.style, size: 64, color: Color(0xFFD1D5DB)),
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
                  card.name,
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
                      const Text(
                        '成交價格統計',
                        style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                      const SizedBox(height: 8),
                      if (_transactions.isEmpty)
                        const Text(
                          '尚無成交紀錄，點下方「新增」記錄成交',
                          style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                        )
                      else ...[
                        Text(
                          'NT\$ ${_fmt(_avgPrice)}',
                          style: const TextStyle(
                            fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF16A34A)),
                        ),
                        const Text(
                          '平均成交價',
                          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(child: _statBox('最高', _highPrice, const Color(0xFFE74C3C))),
                            const SizedBox(width: 8),
                            Expanded(child: _statBox('平均', _avgPrice, const Color(0xFFE8A52A))),
                            const SizedBox(width: 8),
                            Expanded(child: _statBox('最低', _lowPrice, const Color(0xFF2980B9))),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // SNKRDUNK 跳轉按鈕
                GestureDetector(
                  onTap: _openSnkrdunk,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text('🔍', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SNKRDUNK 市場成交參考',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '點擊查看日本市場近期成交價格',
                                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.open_in_new, size: 16, color: Color(0xFF9CA3AF)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 成交紀錄 header
                Row(
                  children: [
                    const Text(
                      '近期成交紀錄',
                      style: TextStyle(
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
                        '${_transactions.length} 筆',
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
                              _showAddTx ? '取消' : '新增',
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
                    child: const Center(
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 36, color: Color(0xFFD1D5DB)),
                          SizedBox(height: 8),
                          Text('暫無成交紀錄',
                              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                          SizedBox(height: 4),
                          Text('點「新增」記錄你的成交',
                              style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 11)),
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
                                    'NT\$ ${_fmt(price)}',
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
        Text('NT\$ ${_fmt(price)}',
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
          const Text('新增成交紀錄',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF111827))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _field(gradeCtrl, '評級（如 PSA 10）')),
              const SizedBox(width: 8),
              Expanded(child: _field(priceCtrl, '成交金額 NT\$', isNumber: true)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _field(buyerCtrl, '買家（選填）')),
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
              child: const Text('儲存',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
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
