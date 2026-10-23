import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';

class Rx extends StatelessWidget {
  final Widget Function(BuildContext) b;
  const Rx(this.b, {super.key});
  @override
  Widget build(BuildContext c) =>
      ListenableBuilder(listenable: app, builder: (ctx, _) => b(ctx));
}

// ───────────────────────────── UI KIT ─────────────────────────────
/// Стеклянная карточка: градиент, тонкая обводка, «пружинное» нажатие, красная полоса слева (accent).
class CuCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool selected, accent;
  final EdgeInsets padding;
  final double radius;
  final Color glow;
  const CuCard({
    super.key, required this.child, this.onTap, this.selected = false, this.accent = false,
    this.padding = const EdgeInsets.all(14), this.radius = 18, this.glow = C.red,
  });
  @override
  State<CuCard> createState() => _CuCardState();
}

class _CuCardState extends State<CuCard> {
  bool down = false;
  @override
  Widget build(BuildContext context) {
    final w = widget;
    final r = BorderRadius.circular(w.radius);
    return AnimatedScale(
      scale: down ? .975 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: r,
          boxShadow: w.selected ? [BoxShadow(color: w.glow.withAlpha(90), blurRadius: 20)] : null,
        ),
        child: Material(
          color: Colors.transparent,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: r,
            side: BorderSide(color: w.selected ? w.glow : C.line, width: w.selected ? 1.5 : 1),
          ),
          child: Ink(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0x17FFFFFF), Color(0x08FFFFFF)]),
            ),
            child: InkWell(
              onTap: w.onTap,
              onHighlightChanged: (v) {
                if (w.onTap != null) setState(() => down = v);
              },
              child: Stack(fit: StackFit.passthrough, children: [
                if (w.accent)
                  Positioned(
                    left: 0, top: 16, bottom: 16,
                    child: Container(
                      width: 4,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.horizontal(right: Radius.circular(4)),
                        gradient: LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [C.red2, Colors.transparent]),
                      ),
                    ),
                  ),
                Padding(
                  padding: w.accent ? w.padding.copyWith(left: w.padding.left + 6) : w.padding,
                  child: w.child,
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Чип/пилюля: при выборе — свечение (glow). filled = красный градиент.
class Pill extends StatelessWidget {
  final String label;
  final bool selected, filled;
  final VoidCallback? onTap;
  final Color glow;
  const Pill(this.label,
      {super.key, this.selected = false, this.filled = false, this.onTap, this.glow = C.red2});
  @override
  Widget build(BuildContext context) {
    final red = selected && filled;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: red ? null : C.card,
        gradient: red ? const LinearGradient(colors: [C.red, Color(0xFFA30410)]) : null,
        border: Border.all(color: red ? Colors.transparent : (selected ? glow : C.line)),
        boxShadow: selected ? [BoxShadow(color: (red ? C.red : glow).withAlpha(95), blurRadius: 14)] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13,
                  color: selected ? Colors.white : C.sub),
              child: Text(label),
            ),
          ),
        ),
      ),
    );
  }
}

class Appear extends StatelessWidget {
  final int i;
  final Widget child;
  const Appear({super.key, required this.i, required this.child});
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: 420 + i * 80),
        curve: Curves.easeOutCubic,
        builder: (_, v, ch) => Opacity(
          opacity: v,
          child: Transform.translate(
              offset: Offset(0, 22 * (1 - v)),
              child: Transform.scale(scale: .96 + .04 * v, child: ch)),
        ),
        child: child,
      );
}

class CutClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    const c = 22.0;
    return Path()
      ..moveTo(0, 0)
      ..lineTo(s.width - c, 0)
      ..lineTo(s.width, c)
      ..lineTo(s.width, s.height)
      ..lineTo(c, s.height)
      ..lineTo(0, s.height - c)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}

class HexClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(s.width * .5, 0)
    ..lineTo(s.width, s.height * .25)
    ..lineTo(s.width, s.height * .75)
    ..lineTo(s.width * .5, s.height)
    ..lineTo(0, s.height * .75)
    ..lineTo(0, s.height * .25)
    ..close();
  @override
  bool shouldReclip(covariant CustomClipper<Path> old) => false;
}
