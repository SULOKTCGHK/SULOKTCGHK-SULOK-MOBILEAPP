import 'package:flutter/material.dart';
import '../services/review_service.dart';

/// 評價賣家的底部彈窗
class ReviewSheet extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String? listingId;
  final VoidCallback? onSubmitted;

  const ReviewSheet({
    super.key,
    required this.sellerId,
    required this.sellerName,
    this.listingId,
    this.onSubmitted,
  });

  @override
  State<ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<ReviewSheet> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

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
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (ok) {
      widget.onSubmitted?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('評價已送出，感謝你的回饋！'),
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
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('評價 ${widget.sellerName}',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: Color(0xFF111827))),
          const SizedBox(height: 4),
          const Text('你的評價會幫助其他買家',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          const SizedBox(height: 20),

          // 星等選擇
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  i < _rating ? Icons.star : Icons.star_border,
                  size: 38,
                  color: const Color(0xFFE8A52A),
                ),
              ),
            )),
          ),
          const SizedBox(height: 20),

          // 文字評論
          TextField(
            controller: _commentCtrl,
            maxLines: 3,
            maxLength: 200,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: '分享你的交易體驗（選填）',
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE8A52A), width: 1),
              ),
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
                  : const Text('送出評價',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}
