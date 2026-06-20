import 'package:flutter/material.dart';
import '../models/card_model.dart';

class CardTypeIcon extends StatelessWidget {
  final CardType type;
  final double size;

  const CardTypeIcon({super.key, required this.type, this.size = 72});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: type.bgColor,
        border: Border.all(color: type.color.withOpacity(0.3), width: 1.5),
      ),
      child: Center(
        child: Text(
          type.emoji,
          style: TextStyle(fontSize: size * 0.32),
        ),
      ),
    );
  }
}
