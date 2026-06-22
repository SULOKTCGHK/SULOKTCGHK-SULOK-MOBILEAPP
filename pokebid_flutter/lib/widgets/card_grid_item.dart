import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/card_model.dart';
import '../services/api_service.dart';
import 'card_type_icon.dart';

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

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                children: [
                  widget.card.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: CachedNetworkImage(
                            imageUrl: widget.card.imageUrls.first,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (_, __) => Container(color: widget.card.type.bgColor,
                                child: Center(child: CardTypeIcon(type: widget.card.type, size: 60))),
                            errorWidget: (_, __, ___) => Container(color: widget.card.type.bgColor,
                                child: Center(child: CardTypeIcon(type: widget.card.type, size: 60))),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: widget.card.type.bgColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Center(child: CardTypeIcon(type: widget.card.type, size: 60)),
                        ),
                  // Type badge
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: typeColor.withOpacity(0.4), width: 0.5),
                      ),
                      child: Text(
                        widget.card.type.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: typeColor,
                        ),
                      ),
                    ),
                  ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    left: 8,
                    child: GestureDetector(
                      onTap: widget.onFavToggle,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFE5E7EB), width: 0.5),
                        ),
                        child: Icon(
                          widget.isFavorited ? Icons.favorite : Icons.favorite_border,
                          size: 14,
                          color: widget.isFavorited ? const Color(0xFFE74C3C) : const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Card body
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.card.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF111827),
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Set / card number badges
                  if (widget.card.setId != null || widget.card.cardNumber != null) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      children: [
                        if (widget.card.setId != null)
                          _badge(
                            PokemonApiService.zhTwSetName(widget.card.setId!),
                            const Color(0xFF6366F1),
                          ),
                        if (widget.card.cardNumber != null)
                          _badge('#${widget.card.cardNumber!}', const Color(0xFF6B7280)),
                      ],
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    widget.card.grade,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAuction ? '現在出價' : '直購',
                    style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'HK\$ ${_formatPrice(widget.card.price)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isAuction ? const Color(0xFFE8A52A) : const Color(0xFF16A34A),
                    ),
                  ),
                  if (isAuction) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 11, color: Color(0xFFE8A52A)),
                        const SizedBox(width: 3),
                        Text(
                          '${widget.card.timeInfo} · ${widget.card.bids} bids',
                          style: const TextStyle(fontSize: 10, color: Color(0xFFE8A52A)),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: widget.onChat,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFF2980B9).withOpacity(0.25), width: 0.5),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 13, color: Color(0xFF2980B9)),
                          SizedBox(width: 4),
                          Text('聯絡賣家',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2980B9))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
