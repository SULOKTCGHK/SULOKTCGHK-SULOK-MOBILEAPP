import 'package:flutter/material.dart';

/// 用像素格子畫像素風圖示。grid 每個字元對應 palette 的一個顏色；
/// '.' 或 palette 沒有的字元 = 透明。opacity 用來表示選中/未選（未選變暗）。
class PixelIcon extends StatelessWidget {
  final List<String> grid;
  final Map<String, Color> palette;
  final double size;
  final double opacity;
  const PixelIcon({
    super.key,
    required this.grid,
    required this.palette,
    this.size = 22,
    this.opacity = 1,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PixelPainter(grid, palette, opacity)),
      );
}

class _PixelPainter extends CustomPainter {
  final List<String> grid;
  final Map<String, Color> palette;
  final double opacity;
  _PixelPainter(this.grid, this.palette, this.opacity);

  @override
  void paint(Canvas canvas, Size size) {
    final rows = grid.length;
    if (rows == 0) return;
    final cols = grid[0].length;
    if (cols == 0) return;
    final cw = size.width / cols;
    final ch = size.height / rows;
    final paint = Paint()..isAntiAlias = false;
    for (int y = 0; y < rows; y++) {
      final line = grid[y];
      for (int x = 0; x < cols && x < line.length; x++) {
        final c = palette[line[x]];
        if (c == null) continue;
        paint.color = opacity >= 1 ? c : c.withOpacity(c.opacity * opacity);
        // 稍微 overdraw 避免方塊之間出現縫隙
        canvas.drawRect(Rect.fromLTWH(x * cw, y * ch, cw + 0.6, ch + 0.6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelPainter old) =>
      old.opacity != opacity || old.grid != grid || old.palette != palette;
}

// ── 調色盤（字元 → 顏色）─────────────────────────────────────────────────────────
const kPixelPalette = <String, Color>{
  'R': Color(0xFFE74C3C), // 紅（屋頂/袋身）
  'O': Color(0xFFEAD2B0), // 米色（牆）
  'K': Color(0xFF6B4A2B), // 深棕（門/提把）
  'B': Color(0xFF3B82F6), // 藍（書封）
  'W': Color(0xFFF1F5F9), // 淺白（書名線）
  'S': Color(0xFFF2C99B), // 膚色（頭）
  'G': Color(0xFF22C55E), // 綠（衣服）
  'D': Color(0xFF4B5563), // 深灰（卡帶 / 十字鍵）
  'L': Color(0xFFAEB4BB), // 淺灰（Game Boy 機身）
  'N': Color(0xFF8BAC0F), // 墨綠（Game Boy 螢幕）
  'M': Color(0xFF8E244D), // 暗紅（AB 鈕）
};

// ── 底部導航的像素圖示（11x11，多色）──────────────────────────────────────────────
const kPixelHome = [
  '.....R.....',
  '....RRR....',
  '...RRRRR...',
  '..RRRRRRR..',
  '.RRRRRRRRR.',
  'RRRRRRRRRRR',
  '.OOOOOOOOO.',
  '.OO.KKK.OO.',
  '.OO.K.K.OO.',
  '.OO.K.K.OO.',
  '.OOOOOOOOO.',
];

const kPixelMarket = [
  '...K...K...',
  '..KKK.KKK..',
  '..K.K.K.K..',
  '.RRRRRRRRR.',
  '.RRRRRRRRR.',
  '.RRRRRRRRR.',
  '.RRRRRRRRR.',
  '.RRRRRRRRR.',
  '.RRRRRRRRR.',
  '.RRRRRRRRR.',
  '.RRRRRRRRR.',
];

// 復古 Game Boy：灰機身 + 墨綠螢幕 + 十字鍵 / AB 鈕
const kPixelDex = [
  '..LLLLLLL..',
  '..LNNNNNL..',
  '..LNNNNNL..',
  '..LNNNNNL..',
  '..LLLLLLL..',
  '..L.....L..',
  '..LD...ML..',
  '..LDD..ML..',
  '..LD...ML..',
  '..LLLLLLL..',
  '...........',
];

// 卡鋪：像素店面（紅遮陽棚 + 米色店身 + 白窗 + 棕門）
const kPixelShop = [
  '...........',
  '.RRRRRRRRR.',
  '.OOOOOOOOO.',
  'OOOOOOOOOOO',
  'O.WWW.KKK.O',
  'O.WWW.KKK.O',
  'O.....KKK.O',
  'O.....KKK.O',
  'OOOOOOOOOOO',
  '...........',
  '...........',
];

// 心願清單：像素愛心（紅）
const kPixelHeart = [
  '...........',
  '..RR...RR..',
  '.RRRR.RRRR.',
  '.RRRRRRRRR.',
  '.RRRRRRRRR.',
  '..RRRRRRR..',
  '...RRRRR...',
  '....RRR....',
  '.....R.....',
  '...........',
  '...........',
];

// 發佈鍵：像素十字鍵（D-pad），白色（放在紅圈上）
const kPixelDpad = [
  '...WWW...',
  '...WWW...',
  '...WWW...',
  'WWWWWWWWW',
  'WWWWWWWWW',
  'WWWWWWWWW',
  '...WWW...',
  '...WWW...',
  '...WWW...',
];

const kPixelMe = [
  '....SSS....',
  '...SSSSS...',
  '...SSSSS...',
  '....SSS....',
  '...........',
  '..GGGGGGG..',
  '.GGGGGGGGG.',
  '.GGGGGGGGG.',
  '.GGGGGGGGG.',
  '.GGGGGGGGG.',
  '...........',
];
