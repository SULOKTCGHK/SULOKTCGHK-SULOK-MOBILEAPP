import 'package:flutter/material.dart';
import '../services/review_service.dart';
import '../i18n/strings.dart';

/// 評價底部彈窗（買賣雙方共用一致準則：星等 + 交收方式 + 留言）
class ReviewSheet extends StatefulWidget {
  final String sellerId;     // 被評價者
  final String sellerName;
  final String? listingId;
  final bool amISeller;      // 我是賣家在評買家 → role=seller，否則 buyer
  final VoidCallback? onSubmitted;

  const ReviewSheet({
    super.key,
    required this.sellerId,
    required this.sellerName,
    this.listingId,
    this.amISeller = false,
    this.onSubmitted,
  });

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  int _rating = 5;
  String? _delivery; // meetup / sf / other
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  static List<(String, String, IconData)> get _deliveryOptions => [
        ('meetup', L.deliveryMeetup, Icons.handshake_outlined),
        ('sf', L.deliverySf, Icons.local_shipping_outlined),
        ('other', L.deliveryOther, Icons.swap_horiz),
      ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final ok = await ReviewService.submitReview(
      sellerId: widget.sellerId,
      listingId: widget.listingId,
      rating: _rating,
      comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim(),
      deliveryMethod: _delivery,
      role: widget.amISeller ? 'seller' : 'buyer',
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      widget.onSubmitted?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(L.reviewSubmitted),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 36, height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(L.reviewTitle(widget.sellerName),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
            const SizedBox(height: 16),

            // 星等
            Text(L.rating, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            Row(children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: const Color(0xFFE8A52A), size: 36),
              ),
            ))),
            const SizedBox(height: 16),

            // 交收方式
            Text(L.deliveryMethod, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            Row(children: _deliveryOptions.map((opt) {
              final (val, label, icon) = opt;
              final sel = _delivery == val;
              return Expanded(child: GestureDetector(
                onTap: () => setState(() => _delivery = sel ? null : val),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: sel ? const Color(0xFFE8A52A) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? const Color(0xFFE8A52A) : const Color(0xFFE5E7EB)),
                  ),
                  child: Column(children: [
                    Icon(icon, size: 20, color: sel ? Colors.white : const Color(0xFF6B7280)),
                    const SizedBox(height: 4),
                    Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        color: sel ? Colors.white : const Color(0xFF374151))),
                  ]),
                ),
              ));
            }).toList()),
            const SizedBox(height: 16),

            // 留言
            Text(L.commentOptional, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 3,
              maxLength: 200,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: L.commentHint,
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE8A52A), width: 1)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8A52A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(L.submitReview,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
