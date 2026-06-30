import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../i18n/strings.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  static Future<bool> shouldShow() async {
    return true; // 測試中：次次都顯示
    // final prefs = await SharedPreferences.getInstance();
    // return prefs.getBool('onboarding_done') != true;
  }

  static Future<void> markDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
  }

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  List<_PageData> get _pages => [
    _PageData(
      emoji: '👋',
      title: L.obWelcomeTitle,
      subtitle: L.obWelcomeSubtitle,
      body: L.obWelcomeBody,
      color: const Color(0xFF1A1040),
      accent: const Color(0xFF4338CA),
    ),
    _PageData(
      emoji: '🛒',
      title: L.obMarketTitle,
      subtitle: L.obMarketSubtitle,
      body: L.obMarketBody,
      color: const Color(0xFF064E3B),
      accent: const Color(0xFF10B981),
    ),
    _PageData(
      emoji: '📤',
      title: L.obPostTitle,
      subtitle: L.obPostSubtitle,
      body: L.obPostBody,
      color: const Color(0xFF7C2D12),
      accent: const Color(0xFFEA580C),
    ),
    _PageData(
      emoji: '📖',
      title: L.obDexTitle,
      subtitle: L.obDexSubtitle,
      body: L.obDexBody,
      color: const Color(0xFF1E3A5F),
      accent: const Color(0xFF3B82F6),
    ),
  ];

  void _next() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  void _finish() async {
    await OnboardingScreen.markDone();
    widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = _pages[_page];
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        color: data.color,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // 跳過按鈕
          Align(
            alignment: Alignment.topRight,
            child: TextButton(
              onPressed: _finish,
              child: Text(L.obSkip, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            ),
          ),

          // 主內容（固定高度）
          SizedBox(
            height: 340,
            child: PageView.builder(
              controller: _ctrl,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: _pages.length,
              itemBuilder: (_, i) => _PageContent(data: _pages[i]),
            ),
          ),

          // 底部：dots + 按鈕
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(children: [
              // 點點指示器
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: i == _page ? 20 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _page ? Colors.white : Colors.white30,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              )),
              const SizedBox(height: 16),
              // 主按鈕
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: data.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    _page == _pages.length - 1 ? L.obStart : L.obNext,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  final _PageData data;
  const _PageContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 大 emoji
          Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
              border: Border.all(color: Colors.white24, width: 1.5),
            ),
            child: Center(
              child: Text(data.emoji, style: const TextStyle(fontSize: 52)),
            ),
          ),
          const SizedBox(height: 36),
          Text(data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(data.subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 15, fontWeight: FontWeight.w500)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(data.body,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14, height: 1.6)),
          ),
        ],
      ),
    );
  }
}

class _PageData {
  final String emoji;
  final String title;
  final String subtitle;
  final String body;
  final Color color;
  final Color accent;
  const _PageData({
    required this.emoji, required this.title, required this.subtitle,
    required this.body, required this.color, required this.accent,
  });
}
