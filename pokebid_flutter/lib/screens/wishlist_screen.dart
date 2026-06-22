import 'package:flutter/material.dart';
import '../services/wishlist_service.dart';
import '../services/api_service.dart';
import '../widgets/login_required.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  List<WishlistItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await WishlistService.getMine();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  Future<void> _remove(WishlistItem w) async {
    await WishlistService.remove(w.id);
    _load();
  }

  Future<void> _addWish() async {
    if (!await requireLogin(context, action: '新增願望')) return;
    if (!mounted) return;
    final kwCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('新增願望', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('輸入想要的卡片關鍵字（卡名），有符合的新上架會通知你。',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          const SizedBox(height: 12),
          TextField(controller: kwCtrl, autofocus: true,
            decoration: const InputDecoration(labelText: '關鍵字（卡名）', hintText: '例：Umbreon ex', isDense: true)),
          const SizedBox(height: 10),
          TextField(controller: priceCtrl, keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: '預算上限（選填）', prefixText: 'HK\$ ', isDense: true)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8A52A)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('加入', style: TextStyle(color: Colors.white))),
        ],
      ),
    );
    if (ok != true) return;
    final kw = kwCtrl.text.trim();
    if (kw.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('請輸入關鍵字')));
      return;
    }
    await WishlistService.add(keyword: kw, maxPrice: int.tryParse(priceCtrl.text.trim()));
    _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已加入願望清單'), duration: Duration(seconds: 2)));
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
        title: const Text('願望清單',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE8A52A),
        onPressed: _addWish,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('新增願望', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8A52A), strokeWidth: 2))
          : _items.isEmpty
              ? _empty()
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _tile(_items[i]),
                ),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
      Icon(Icons.favorite_border, size: 56, color: Color(0xFFD1D5DB)),
      SizedBox(height: 12),
      Text('願望清單是空的',
          style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
      SizedBox(height: 4),
      Text('點右下「＋新增願望」加入想要的卡',
          style: TextStyle(fontSize: 12, color: Color(0xFFD1D5DB))),
    ]),
  );

  Widget _tile(WishlistItem w) {
    // 優先用 zh-tw 系列名稱顯示
    final setLabel = (w.setId != null && w.setId!.isNotEmpty)
        ? PokemonApiService.zhTwSetName(w.setId!)
        : null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.favorite, size: 18, color: Color(0xFFE74C3C)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (w.keyword != null && w.keyword!.isNotEmpty)
                _tag(w.keyword!, const Color(0xFF111827)),
              if (setLabel != null) _tag(setLabel, const Color(0xFFB45309)),
              if (w.cardNumber != null && w.cardNumber!.isNotEmpty)
                _tag('#${w.cardNumber}', const Color(0xFF374151)),
            ]),
            if (w.maxPrice != null) ...[
              const SizedBox(height: 4),
              Text('預算上限 HK\$${w.maxPrice}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 2),
            const Text('有新上架符合時會通知你',
                style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFD1D5DB)),
          onPressed: () => _remove(w),
        ),
      ]),
    );
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(text,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
  );
}
