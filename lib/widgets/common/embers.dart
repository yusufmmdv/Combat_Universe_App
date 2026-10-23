import 'package:flutter/material.dart';

class StripesPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0x09FFFFFF)
      ..strokeWidth = 2;
    for (double x = -s.height; x < s.width + s.height; x += 20) {
      c.drawLine(Offset(x, 0), Offset(x - s.height * .47, s.height), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Летящие вверх искры (как в макете).
class Embers extends StatelessWidget {
  final Animation<double> a;
  final Color color;
  const Embers(this.a, this.color, {super.key});
  static const _x = [.12, .28, .46, .63, .80, .90];
  static const _p = [0.0, .25, .5, .13, .4, .67];
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: LayoutBuilder(
          builder: (_, bc) => AnimatedBuilder(
            animation: a,
            builder: (_, __) => Stack(children: [
              for (var i = 0; i < _x.length; i++)
                Builder(builder: (_) {
                  final p = (a.value + _p[i]) % 1.0;
                  return Positioned(
                    left: bc.maxWidth * _x[i] + 24 * p,
                    bottom: -10 + p * bc.maxHeight * .9,
                    child: Opacity(
                      opacity: (1 - p).clamp(0.0, 1.0),
                      child: Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, color: color,
                          boxShadow: [BoxShadow(color: color, blurRadius: 10)],
                        ),
                      ),
                    ),
                  );
                }),
            ]),
          ),
        ),
      );
}
