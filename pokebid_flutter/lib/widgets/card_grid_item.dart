import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/card_model.dart';
import 'card_type_icon.dart';
import 'no_image_placeholder.dart';
import '../i18n/strings.dart';

class CardGridItem extends StatefulWidget {
  final PokemonCard card;
  final bool isFavorited;
  final VoidCallback onTap;
  final VoidCallback onFavToggle;
  final VoidCallback? onChat;

  const CardGridItem({
    super.key,
    required this.card,
    required this.isFavorited,
    required this.onTap,
    required this.onFavToggle,
    this.onChat,
  });

  @override
  State<CardGridItem> createState() => _CardGridItemState();
}

class _CardGridItemState extends State<CardGridItem> {
  @override
  Widget build(BuildContext context) {
    final isAuction = widget.card.listingType == ListingType.auction;
    final typeColor = widget.card.type.color;

    final gc = _gradeColor(widget.card.grade);
    final priceColor = isAuction ? const Color(0xFFE8A52A) : const Color(0xFF16A34A);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFEDEFF2), width: 1),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF111827).withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.card.imageUrls.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: widget.card.imageUrls.first,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => _noImage(),
                            errorWidget: (_, __, ___) => _noImage(),
                          )
                        : _noImage(),
                    // 底部漸層（讓疊加的標籤更清楚）
                    Positioned(
                      left: 0, right: 0, bottom: 0,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter, end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.45), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    // 競標/直購 標籤（右下）
                    Positioned(
                      right: 8, bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(isAuction ? Icons.gavel : Icons.bolt,
                              size: 11, color: priceColor),
                          const SizedBox(width: 3),
                          Text(isAuction ? L.auction : L.buyNow,
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: priceColor)),
                        ]),
                      ),
                    ),
                    // Type badge
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(widget.card.type.label,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: typeColor)),
                      ),
                    ),
                    // Favorite button
                    Positioned(
                      top: 8, left: 8,
                      child: GestureDetector(
                        onTap: widget.onFavToggle,
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)],
                          ),
                          child: Icon(
                            widget.isFavorited ? Icons.favorite : Icons.favorite_border,
                            size: 15,
                            color: widget.isFavorited ? const Color(0xFFE74C3C) : const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Card body
            Expanded(
              child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 名字 + 分級標籤（同一行）
                  Row(children: [
                    Flexible(child: Text(
                      widget.card.name,
                      style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w700,
                        color: Color(0xFF111827), height: 1.3,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    )),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: gc.withOpacity(0.12), borderRadius: BorderRadius.circular(5)),
                      child: Text(widget.card.grade,
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: gc)),
                    ),
                  ]),
                  // 不展示系列標籤（仍保留卡號，方便辨識）
                  if (widget.card.cardNumber != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        _badge('#${widget.card.cardNumber!}', const Color(0xFF6B7280)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  // 價格
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic, children: [
                    Text('HK\$',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: priceColor.withOpacity(0.8))),
                    const SizedBox(width: 2),
                    Text(_formatPrice(widget.card.price),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: priceColor, height: 1)),
                  ]),
                  if (isAuction) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.access_time, size: 11, color: Color(0xFFE8A52A)),
                      const SizedBox(width: 3),
                      Text(L.bidsCount(widget.card.timeInfo, widget.card.bids),
                          style: const TextStyle(fontSize: 10, color: Color(0xFFE8A52A))),
                    ]),
                  ],
                ],
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noImage() => NoImagePlaceholder(
        background: widget.card.type.bgColor,
        icon: CardTypeIcon(type: widget.card.type, size: 48),
      );

  Color _gradeColor(String grade) {
    final g = grade.toUpperCase();
    if (g.contains('10')) return const Color(0xFFE8A52A); // PSA10 金
    if (g.contains('PSA 9') || g.contains('PSA9') || g.contains('9')) return const Color(0xFF2980B9);
    return const Color(0xFF6B7280); // Raw / 生卡 灰
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.25), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _formatPrice(int price) {
    if (price >= 1000) {
      return price.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    }
    return price.toString();
  }
}
