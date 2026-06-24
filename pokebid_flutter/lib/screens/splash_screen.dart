import 'dart:async';
import 'package:flutter/material.dart';
import '../i18n/strings.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const SplashScreen({super.key, required this.onComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // 0=黑, 1=閃爍, 2=boot文字, 3=logo, 4=淡出
  int _phase = 0;
  int _visibleLines = 0;
  bool _fadeOut = false;
  bool _screenOn = false;

  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  static const _bootLines = [
    'POKEBID SYSTEM v1.0',
    '--------------------',
    'Loading card database...',
    'Connecting to market...',
    '--------------------',
    'READY.',
  ];

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _logoScale = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeIn));
    _runSequence();
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSequence() async {
    // Phase 0: 全黑停頓
    await Future.delayed(const Duration(milliseconds: 200));

    // Phase 1: 屏幕閃爍
    if (!mounted) return;
    setState(() => _phase = 1);
    for (var i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (!mounted) return;
      setState(() => _screenOn = !_screenOn);
    }
    setState(() => _screenOn = true);
    await Future.delayed(const Duration(milliseconds: 100));

    // Phase 2: Boot 文字逐行出現
    if (!mounted) return;
    setState(() => _phase = 2);
    for (var i = 0; i < _bootLines.length; i++) {
      final delay = i < 2 ? 50 : 120;
      await Future.delayed(Duration(milliseconds: delay));
      if (!mounted) return;
      setState(() => _visibleLines = i + 1);
    }
    await Future.delayed(const Duration(milliseconds: 200));

    // Phase 3: Logo 彈出
    if (!mounted) return;
    setState(() => _phase = 3);
    _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 800));

    // Phase 4: 淡出
    if (!mounted) return;
    setState(() => _fadeOut = true);
    await Future.delayed(const Duration(milliseconds: 400));
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _fadeOut ? 0 : 1,
      duration: const Duration(milliseconds: 600),
      child: Scaffold(
        backgroundColor: const Color(0xFF111111),
        body: SafeArea(child: Center(child: _buildPokedex())),
      ),
    );
  }

  Widget _buildPokedex() {
    return SizedBox(
      width: 280,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── 上蓋（含圓形鏡頭） ────────────────────────────────────────
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(children: [
            // 大藍圓（主鏡頭）
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF333333),
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 3))],
              ),
              child: Center(
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF666666),
                    border: Border.all(color: Colors.white54, width: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // 三個小指示燈
            Column(children: [
              Row(children: [
                _dot(const Color(0xFFAAAAAA)),
                const SizedBox(width: 5),
                _dot(const Color(0xFF777777)),
                const SizedBox(width: 5),
                _dot(const Color(0xFFFFFFFF)),
              ]),
              const SizedBox(height: 6),
              // 橫線裝飾
              Container(height: 2, width: 60, color: Colors.black26, margin: const EdgeInsets.only(bottom: 2)),
              Container(height: 2, width: 50, color: Colors.black26),
            ]),
          ]),
        ),

        // ── 中間折頁分隔線 ─────────────────────────────────────────────
        Container(
          height: 8, width: 280,
          color: const Color(0xFF000000),
        ),

        // ── 下蓋（含屏幕） ─────────────────────────────────────────────
        Container(
          width: 280,
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A2A),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(children: [
            // 屏幕
            _buildScreen(),
            const SizedBox(height: 14),
            // 底部按鈕組
            _buildButtons(),
          ]),
        ),
      ]),
    );
  }

  Widget _dot(Color c) => AnimatedContainer(
    duration: const Duration(milliseconds: 200),
    width: 11, height: 11,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: (_phase >= 2) ? c : c.withOpacity(0.3),
      boxShadow: (_phase >= 2)
          ? [BoxShadow(color: c.withOpacity(0.6), blurRadius: 4)]
          : null,
    ),
  );

  Widget _buildScreen() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: _screenOn || _phase == 0 ? const Color(0xFF0D1117) : Colors.black,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF1a1a1a), width: 3),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 3)),
          if (_screenOn && _phase >= 2)
            BoxShadow(color: const Color(0xFF00FF41).withOpacity(0.08), blurRadius: 12, spreadRadius: 1),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: SizedBox(
          height: 160,
          child: _buildScreenContent(),
        ),
      ),
    );
  }

  Widget _buildScreenContent() {
    if (_phase == 0) {
      return const SizedBox.shrink();
    }
    if (_phase == 1) {
      return AnimatedOpacity(
        opacity: _screenOn ? 1 : 0,
        duration: const Duration(milliseconds: 60),
        child: Container(
          color: const Color(0xFF001100),
          child: const Center(
            child: Text('▮', style: TextStyle(color: Color(0xFF00FF41), fontSize: 12)),
          ),
        ),
      );
    }
    if (_phase == 2) {
      return Container(
        color: const Color(0xFF0D1117),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ..._bootLines.take(_visibleLines).map((line) {
              final isHeader = line.startsWith('----') || line == _bootLines[0];
              final isReady = line.contains('READY');
              return Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  line,
                  style: TextStyle(
                    color: isReady
                        ? const Color(0xFFFFFFFF)
                        : isHeader
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF00CC33),
                    fontSize: isReady ? 11 : 9.5,
                    fontFamily: 'monospace',
                    fontWeight: isHeader || isReady ? FontWeight.w900 : FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              );
            }),
            // 游標閃爍
            if (_visibleLines == _bootLines.length)
              const _BlinkingCursor(),
          ],
        ),
      );
    }
    // Phase 3: Logo
    return Container(
      color: const Color(0xFF0D1117),
      child: Center(
        child: AnimatedBuilder(
          animation: _logoCtrl,
          builder: (_, __) => Opacity(
            opacity: _logoFade.value,
            child: Transform.scale(
              scale: _logoScale.value,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // 像素風格圓形 Logo
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF00FF41), width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF00FF41).withOpacity(0.15),
                        border: Border.all(color: const Color(0xFF00FF41), width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: 2,
                      fontFamily: 'monospace',
                    ),
                    children: [
                      TextSpan(text: 'Poke', style: TextStyle(color: Color(0xFF00FF41))),
                      TextSpan(text: 'Bid', style: TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  L.splashTagline,
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 9,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Row(children: [
      // 十字鍵
      SizedBox(
        width: 56,
        height: 56,
        child: Stack(alignment: Alignment.center, children: [
          // 垂直
          Positioned(top: 0, child: _dpadKey(height: 56, width: 18)),
          // 水平
          Positioned(left: 0, child: _dpadKey(height: 18, width: 56)),
          // 中心點
          Container(width: 18, height: 18, color: const Color(0xFF111111)),
        ]),
      ),
      const Spacer(),
      // 中間 SELECT / START
      Column(children: [
        Row(children: [
          _smallBtn('SEL'),
          const SizedBox(width: 8),
          _smallBtn('STA'),
        ]),
      ]),
      const Spacer(),
      // 右側 A/B 按鈕
      Column(children: [
        Row(children: [
          _circleBtn(const Color(0xFF555555), 'B'),
          const SizedBox(width: 10),
          _circleBtn(const Color(0xFF333333), 'A'),
        ]),
      ]),
    ]);
  }

  Widget _dpadKey({required double height, required double width}) => Container(
    width: width, height: height,
    decoration: BoxDecoration(
      color: const Color(0xFF111111),
      borderRadius: BorderRadius.circular(2),
    ),
  );

  Widget _smallBtn(String label) => Container(
    width: 28, height: 10,
    decoration: BoxDecoration(
      color: const Color(0xFF111111),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Center(
      child: Text(label, style: const TextStyle(
          color: Colors.white54, fontSize: 5, fontWeight: FontWeight.w700)),
    ),
  );

  Widget _circleBtn(Color color, String label) => Container(
    width: 28, height: 28,
    decoration: BoxDecoration(
      shape: BoxShape.circle, color: color,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 3, offset: const Offset(0, 2))],
    ),
    child: Center(
      child: Text(label, style: const TextStyle(
          color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900)),
    ),
  );
}

// 游標閃爍效果
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();
  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _ctrl,
    builder: (_, __) => Opacity(
      opacity: _ctrl.value > 0.5 ? 1 : 0,
      child: const Text('▮', style: TextStyle(color: Color(0xFF00FF41), fontSize: 10)),
    ),
  );
}
