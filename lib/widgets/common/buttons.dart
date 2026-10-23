import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// Иконка с «пружинным» всплеском при нажатии (лайк, закладка).
class IconTap extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String? label;
  const IconTap(this.icon, this.color, this.onTap, {super.key, this.label});
  @override
  State<IconTap> createState() => _IconTapState();
}

class _IconTapState extends State<IconTap> with SingleTickerProviderStateMixin {
  late final AnimationController ctl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
  late final Animation<double> scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 1.5, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 65),
  ]).animate(ctl);

  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final glow = widget.color == C.red;
    return InkResponse(
      onTap: () {
        ctl.forward(from: 0);
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          ScaleTransition(
            scale: scale,
            child: Icon(widget.icon, size: 22, color: widget.color,
                shadows: glow ? const [Shadow(color: C.red, blurRadius: 12)] : null),
          ),
          if (widget.label != null) ...[
            const SizedBox(width: 4),
            Text(widget.label!,
                style: const TextStyle(color: C.sub, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ]),
      ),
    );
  }
}

class GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const GlassBtn(this.icon, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: const Color(0x1AFFFFFF), shape: BoxShape.circle,
                  border: Border.all(color: C.line)),
              child: Icon(icon, size: 20, color: Colors.white),
            ),
          ),
        ),
      );
}

/// Кнопка play с расходящимся кольцом.
class PulsePlay extends StatefulWidget {
  const PulsePlay({super.key});
  @override
  State<PulsePlay> createState() => _PulsePlayState();
}

class _PulsePlayState extends State<PulsePlay> with SingleTickerProviderStateMixin {
  late final AnimationController ctl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: ctl,
        builder: (_, __) => Container(
          width: 54, height: 54,
          decoration: BoxDecoration(
            color: C.red, shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: C.red.withAlpha(((1 - ctl.value) * 150).round()), spreadRadius: 22 * ctl.value),
            ],
          ),
          child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
        ),
      );
}

/// Переключатель вкладок со скользящим индикатором (пружина).
class TabSwitch extends StatelessWidget {
  final int tab;
  final List<String> labels;
  final ValueChanged<int> onChanged;
  const TabSwitch({super.key, required this.tab, required this.labels, required this.onChanged});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        padding: const EdgeInsets.all(4),
        height: 54,
        decoration: BoxDecoration(
            color: C.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: C.line)),
        child: Stack(children: [
          AnimatedAlign(
            alignment: tab == 0 ? Alignment.centerLeft : Alignment.centerRight,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutBack,
            child: FractionallySizedBox(
              widthFactor: 1 / labels.length,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(colors: [C.red, Color(0xFF8E030A)]),
                  boxShadow: [BoxShadow(color: C.red.withAlpha(115), blurRadius: 18, offset: const Offset(0, 6))],
                ),
              ),
            ),
          ),
          Row(children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: Center(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 1.5,
                          color: tab == i ? Colors.white : C.sub),
                      child: Text(labels[i].toUpperCase()),
                    ),
                  ),
                ),
              ),
          ]),
        ]),
      );
}
