import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/wishlist_service.dart';
import '../services/api_service.dart';
import '../widgets/no_image_placeholder.dart';
import '../i18n/strings.dart';
import 'dex_card_detail_screen.dart';

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

  String _fmtPrice(int p) => p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  void _openCard(WishlistItem w) {
    final card = ApiCard(
      id: w.cardId,
      name: w.cardName,
      imageSmall: w.imageUrl,
      setId: w.setId,
      setName: w.setName,
      number: w.cardNumber,
      types: const [],
    );
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => DexCardDetailScreen(
        card: card, isCollected: false, onToggleCollect: (_) {},
        formatPrice: _fmtPrice,
      ),
    )).then((_) => _load());
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
        title: Text(L.wishlistTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF111827))),
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
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.favorite_border, size: 56, color: Color(0xFFD1D5DB)),
      const SizedBox(height: 12),
      Text(L.wishlistEmpty,
          style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
      const SizedBox(height: 4),
      Text(L.wishlistEmptyHint2,
          style: const TextStyle(fontSize: 12, color: Color(0xFFD1D5DB))),
    ]),
  );

  Widget _tile(WishlistItem w) {
    return GestureDetector(
      onTap: () => _openCard(w),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
        ),
        child: Row(children: [
          // 卡圖縮圖
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 44, height: 60,
              child: (w.imageUrl != null && w.imageUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: w.imageUrl!, fit: BoxFit.contain,
                      placeholder: (_, __) => const ColoredBox(color: Color(0xFFF3F4F6)),
                      errorWidget: (_, __, ___) => const NoImagePlaceholder(
                          icon: Icon(Icons.image_not_supported_outlined,
                              size: 20, color: Color(0xFFD1D5DB))),
                    )
                  : const NoImagePlaceholder(
                      icon: Icon(Icons.image_not_supported_outlined,
                          size: 20, color: Color(0xFFD1D5DB))),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(w.cardName,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                      color: Color(0xFF111827)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Wrap(spacing: 6, runSpacing: 4, children: [
                if (w.setName != null && w.setName!.isNotEmpty)
                  _tag(w.setName!, const Color(0xFFB45309)),
                if (w.cardNumber != null && w.cardNumber!.isNotEmpty)
                  _tag('#${w.cardNumber}', const Color(0xFF374151)),
              ]),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.favorite, size: 20, color: Color(0xFFE74C3C)),
            onPressed: () => _remove(w),
          ),
        ]),
      ),
    );
  }

  Widget _tag(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(text,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
        maxLines: 1, overflow: TextOverflow.ellipsis),
  );
}
