import 'package:flutter/material.dart';
import '../services/wishlist_service.dart';
import '../services/api_service.dart';

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
      Text('在掛售區用篩選條件加入想要的卡',
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
              Text('預算上限 NT\$${w.maxPrice}',
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
