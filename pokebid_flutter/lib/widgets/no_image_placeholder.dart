import 'package:flutter/material.dart';
import '../i18n/strings.dart';

/// 卡片／系列沒有圖片時的佔位元件:顯示圖示 + 「暫時未提供該卡圖」。
/// 在過小的容器(如小縮圖)中會自動隱藏文字,只留圖示,避免溢出。
class NoImagePlaceholder extends StatelessWidget {
  final Color background;
  final Widget? icon;

  const NoImagePlaceholder({
    super.key,
    this.background = const Color(0xFFF3F4F6),
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: background,
      child: LayoutBuilder(
        builder: (context, c) {
          // 容器太小(小縮圖)就只顯示圖示,不顯示文字以免溢出
          final showText = c.maxHeight >= 70 && c.maxWidth >= 70;
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) icon!,
                if (showText) ...[
                  SizedBox(height: icon != null ? 8 : 0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      L.imageNotAvailable,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
