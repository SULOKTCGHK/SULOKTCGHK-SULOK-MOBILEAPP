import 'package:flutter/material.dart';
import '../i18n/strings.dart';

/// 已認證標誌（電話認證通過後顯示在用戶名旁）
class VerifiedBadge extends StatelessWidget {
  final double size;
  final bool showLabel;
  const VerifiedBadge({super.key, this.size = 15, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    final icon = Icon(Icons.verified, size: size, color: const Color(0xFF2980B9));
    if (!showLabel) return icon;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      icon,
      const SizedBox(width: 3),
      Text(L.phoneVerify,
          style: TextStyle(fontSize: size * 0.8, fontWeight: FontWeight.w600, color: const Color(0xFF2980B9))),
    ]);
  }
}
