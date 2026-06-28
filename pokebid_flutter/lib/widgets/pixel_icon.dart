import 'package:flutter/material.dart';

/// 用像素格子（'1' = 填滿）畫出像素風圖示，可上色。
class PixelIcon extends StatelessWidget {
  final List<String> grid;
  final double size;
  final Color color;
  const PixelIcon({super.key, required this.grid, this.size = 22, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _PixelPainter(grid, color)),
      );
}

class _PixelPainter extends CustomPainter {
  final List<String> grid;
  final Color color;
  _PixelPainter(this.grid, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final rows = grid.length;
    if (rows == 0) return;
    final cols = grid[0].length;
    if (cols == 0) return;
    final cw = size.width / cols;
    final ch = size.height / rows;
    final paint = Paint()
      ..color = color
      ..isAntiAlias = false;
    for (int y = 0; y < rows; y++) {
      final line = grid[y];
      for (int x = 0; x < cols && x < line.length; x++) {
        if (line[x] == '1') {
          // 稍微 overdraw 避免方塊之間出現縫隙
          canvas.drawRect(Rect.fromLTWH(x * cw, y * ch, cw + 0.6, ch + 0.6), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelPainter old) => old.color != color || old.grid != grid;
}

// ── 底部導航的像素圖示（11x11）─────────────────────────────────────────────────
const kPixelHome = [
  '.....1.....',
  '....111....',
  '...11111...',
  '..1111111..',
  '.111111111.',
  '11111111111',
  '.1.......1.',
  '.1..111..1.',
  '.1..1.1..1.',
  '.1..1.1..1.',
  '.111111111.',
];

const kPixelMarket = [
  '...1...1...',
  '..111.111..',
  '..1.1.1.1..',
  '.111111111.',
  '.1.......1.',
  '.1.......1.',
  '.1.......1.',
  '.1.......1.',
  '.1.......1.',
  '.1.......1.',
  '.111111111.',
];

const kPixelDex = [
  '.111111111.',
  '.1.......1.',
  '.1.11111.1.',
  '.1.......1.',
  '.1.11111.1.',
  '.1.......1.',
  '.1.11111.1.',
  '.1.......1.',
  '.1.......1.',
  '.111111111.',
  '...........',
];

const kPixelMe = [
  '....111....',
  '...11111...',
  '...11111...',
  '....111....',
  '...........',
  '..1111111..',
  '.111111111.',
  '.111111111.',
  '.111111111.',
  '.111111111.',
  '...........',
];
