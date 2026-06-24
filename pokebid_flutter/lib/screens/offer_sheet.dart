import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/card_model.dart';
import '../services/offer_service.dart';
import '../i18n/strings.dart';

class OfferSheet extends StatefulWidget {
  final PokemonCard card;
  final VoidCallback? onSent;

  const OfferSheet({super.key, required this.card, this.onSent});

  @override
  State<OfferSheet> createState() => _OfferSheetState();
}

class _OfferSheetState extends State<OfferSheet> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  String _fmt(int p) => p.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Future<void> _send() async {
    final amount = int.tryParse(_ctrl.text.replaceAll(',', '').trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(L.invalidAmount), backgroundColor: const Color(0xFFE74C3C)));
      return;
    }
    if (amount >= widget.card.price) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(L.offerTooHigh(_fmt(widget.card.price))),
          backgroundColor: const Color(0xFFE74C3C)));
      return;
    }
    setState(() => _sending = true);
    try {
      await OfferService.makeOffer(
        listingId: widget.card.supabaseId!,
        sellerId: widget.card.seller.id!,
        amount: amount,
        listingName: widget.card.name,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onSent?.call();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(L.offerSent),
          backgroundColor: const Color(0xFF16A34A),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(L.offerFailed('$e')),
            backgroundColor: const Color(0xFFE74C3C)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(
          child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2))),
        ),
        const SizedBox(height: 16),

        Text(L.makeOfferTitle, style: const TextStyle(fontSize: 18,
            fontWeight: FontWeight.w700, color: Color(0xFF111827))),
        const SizedBox(height: 16),

        // Card info
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: card.type.bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(card.type.emoji,
                  style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(card.name, style: const TextStyle(fontSize: 14,
                  fontWeight: FontWeight.w600, color: Color(0xFF111827))),
              Text(L.sellerPriceLine(card.grade, _fmt(card.price)),
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            ])),
          ]),
        ),
        const SizedBox(height: 20),

        Text(L.yourOffer,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: Color(0xFF374151))),
        const SizedBox(height: 8),

        TextField(
          controller: _ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          onChanged: (_) => setState(() {}),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
              color: Color(0xFF111827)),
          decoration: InputDecoration(
            prefixText: 'HK\$ ',
            prefixStyle: const TextStyle(fontSize: 18, color: Color(0xFF6B7280)),
            hintText: '0',
            hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE8A52A), width: 1.5)),
          ),
        ),

        const SizedBox(height: 8),
        Builder(builder: (_) {
          final amount = int.tryParse(_ctrl.text.replaceAll(',', '').trim());
          final tooHigh = amount != null && amount >= card.price;
          return Text(
            tooHigh
                ? L.offerTooHigh(_fmt(card.price))
                : L.offerHint(_fmt(card.price)),
            style: TextStyle(
                fontSize: 12,
                color: tooHigh ? const Color(0xFFE74C3C) : const Color(0xFF9CA3AF)),
          );
        }),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: Builder(builder: (_) {
            final amount = int.tryParse(_ctrl.text.replaceAll(',', '').trim());
            final valid = amount != null && amount > 0 && amount < card.price;
            return ElevatedButton(
            onPressed: (_sending || !valid) ? null : _send,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE8A52A),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _sending
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : Text(L.submitOffer,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          );
          }),
        ),
      ]),
    );
  }
}
