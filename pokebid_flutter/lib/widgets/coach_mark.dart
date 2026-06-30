import 'package:flutter/material.dart';
import '../i18n/strings.dart';

// 每個引導步驟的資料
class CoachStep {
  final String title;
  final String desc;
  final GlobalKey targetKey; // 要高亮的元素
  final CoachShape shape;

  const CoachStep({
    required this.title,
    required this.desc,
    required this.targetKey,
    this.shape = CoachShape.circle,
  });
}

enum CoachShape { circle, rect }

// 主 CoachMark 控制器
class CoachMarkController {
  final List<CoachStep> steps;
  final VoidCallback onDone;
  OverlayEntry? _entry;
  int _current = 0;

  CoachMarkController({required this.steps, required this.onDone});

  void start(BuildContext context) {
    _current = 0;
    _show(context);
  }

  void _show(BuildContext context) {
    _entry?.remove();
    if (_current >= steps.length) {
      _entry = null;
      onDone();
      return;
    }
    final step = steps[_current];
    _entry = OverlayEntry(builder: (_) => _CoachOverlay(
      step: step,
      stepIndex: _current,
      totalSteps: steps.length,
      onNext: () {
        _current++;
        _show(context);
      },
      onSkip: () {
        _entry?.remove();
        _entry = null;
        onDone();
      },
    ));
    Overlay.of(context).insert(_entry!);
  }

  void dispose() {
    _entry?.remove();
    _entry = null;
  }
}

class _CoachOverlay extends StatefulWidget {
  final CoachStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _CoachOverlay({
    required this.step, required this.stepIndex, required this.totalSteps,
    required this.onNext, required this.onSkip,
  });

  @override
  State<_CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<_CoachOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  Rect? _targetRect;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureTarget();
      _ctrl.forward();
    });
  }

  void _measureTarget() {
    final ctx = widget.step.targetKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    setState(() => _targetRect = pos & box.size);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rect = _targetRect;
    final size = MediaQuery.of(context).size;

    // 判斷 tooltip 要顯示在目標上方還是下方
    final showAbove = rect != null && rect.center.dy > size.height / 2;

    return FadeTransition(
      opacity: _fade,
      child: Stack(children: [
        // 遮罩層
        if (rect != null)
          CustomPaint(
            size: size,
            painter: _SpotlightPainter(rect: rect, shape: widget.step.shape),
          )
        else
          Container(color: Colors.black54),

        // 吸收點擊（讓目標區可以互動）
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {}, // 攔截背景點擊
          ),
        ),

        // Tooltip 卡片
        if (rect != null)
          Positioned(
            left: 16,
            right: 16,
            top: showAbove ? null : rect.bottom + 16,
            bottom: showAbove ? size.height - rect.top + 16 : null,
            child: _TooltipCard(
              step: widget.step,
              stepIndex: widget.stepIndex,
              totalSteps: widget.totalSteps,
              onNext: widget.onNext,
              onSkip: widget.onSkip,
              showAbove: showAbove,
            ),
          ),
      ]),
    );
  }
}

// 打洞遮罩
class _SpotlightPainter extends CustomPainter {
  final Rect rect;
  final CoachShape shape;
  _SpotlightPainter({required this.rect, required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.72);
    final full = Offset.zero & size;

    final path = Path()..addRect(full);

    const pad = 10.0;
    final highlight = rect.inflate(pad);

    if (shape == CoachShape.circle) {
      final r = (highlight.width > highlight.height ? highlight.width : highlight.height) / 2;
      path.addOval(Rect.fromCircle(center: highlight.center, radius: r));
    } else {
      path.addRRect(RRect.fromRectAndRadius(highlight, const Radius.circular(12)));
    }

    canvas.drawPath(path.transform(
      Matrix4.identity().storage,
    ), paint..blendMode = BlendMode.srcOver);

    // 用 Even-Odd 挖洞
    final holePath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(full);
    if (shape == CoachShape.circle) {
      final r = (highlight.width > highlight.height ? highlight.width : highlight.height) / 2;
      holePath.addOval(Rect.fromCircle(center: highlight.center, radius: r));
    } else {
      holePath.addRRect(RRect.fromRectAndRadius(highlight, const Radius.circular(12)));
    }
    canvas.drawPath(holePath, Paint()..color = Colors.black.withValues(alpha: 0.72));
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) => old.rect != rect;
}

class _TooltipCard extends StatelessWidget {
  final CoachStep step;
  final int stepIndex;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final bool showAbove;

  const _TooltipCard({
    required this.step, required this.stepIndex, required this.totalSteps,
    required this.onNext, required this.onSkip, required this.showAbove,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = stepIndex == totalSteps - 1;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        // 步驟指示 + 跳過
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE8A52A).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(L.coachStep(stepIndex + 1, totalSteps),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFB45309))),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSkip,
            child: Text(L.coachSkip, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          ),
        ]),
        const SizedBox(height: 10),
        Text(step.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827))),
        const SizedBox(height: 6),
        Text(step.desc,
            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5)),
        const SizedBox(height: 14),
        // 進度條
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (stepIndex + 1) / totalSteps,
            backgroundColor: const Color(0xFFF3F4F6),
            color: const Color(0xFFE8A52A),
            minHeight: 4,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: isLast ? const Color(0xFF16A34A) : const Color(0xFFE8A52A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              isLast ? L.coachDone : L.coachNext,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ]),
    );
  }
}
