import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_i18n.dart';
import '../../core/state/app_state.dart';

// ───────────────────────────── NOTATION ENGINE ─────────────────────────────
class Dev {
  final String id, sub;
  final IconData icon;
  const Dev(this.id, this.icon, this.sub);
}

const devs = [
  Dev('ps', Icons.sports_esports, '□ △ ✕ ○'),
  Dev('xbox', Icons.videogame_asset, 'X Y A B'),
  Dev('switch', Icons.gamepad, 'Y X B A'),
  Dev('kb', Icons.keyboard, 'U I J K'),
  Dev('digits', Icons.pin, '1 2 3 4'),
];

String devName(String id) => switch (id) {
      'ps' => 'PlayStation',
      'xbox' => 'Xbox',
      'switch' => 'Nintendo Switch',
      'kb' => tr('devKb'),
      _ => tr('devDigits'),
    };

const _ang = {'6': 0.0, '3': 45.0, '2': 90.0, '1': 135.0, '4': 180.0, '7': 225.0, '8': 270.0, '9': 315.0};
const _dirW = {'f': '6', 'b': '4', 'd': '2', 'u': '8', 'df': '3', 'db': '1', 'uf': '9', 'ub': '7'};
const _slot = {'FP': 0, 'BP': 1, 'FK': 2, 'BK': 3, 'T1': 0, 'T2': 1, 'T3': 2, 'T4': 3};
const _lab = {
  'ps': ['□', '△', '✕', '○'],
  'xbox': ['X', 'Y', 'A', 'B'],
  'switch': ['Y', 'X', 'B', 'A'],
  'kb': ['U', 'I', 'J', 'K'],
  'digits': ['1', '2', '3', '4'],
};
const _col = {
  'ps': [Color(0xFFE08FD2), Color(0xFF3DDC84), Color(0xFF5A9BFF), Color(0xFFFF5A66)],
  'xbox': [Color(0xFF5A9BFF), Color(0xFFFFC61A), Color(0xFF3DDC84), Color(0xFFFF5A66)],
  'switch': [Color(0xFF6B6B7C), Color(0xFF6B6B7C), Color(0xFF6B6B7C), Color(0xFF6B6B7C)],
  'kb': [Color(0xFFC9C9D6), Color(0xFFC9C9D6), Color(0xFFC9C9D6), Color(0xFFC9C9D6)],
  'digits': [Color(0xFFE10613), Color(0xFFE10613), Color(0xFFE10613), Color(0xFFE10613)],
};

// ── Иконки устройств (геймпады PS / Xbox / Switch, клавиатура WASD, цифры) ──
class _PadPainter extends CustomPainter {
  final String id;
  final Color col;
  _PadPainter(this.id, this.col);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    Offset o(double x, double y) => Offset(w * x, h * y);
    final line = Paint()..style = PaintingStyle.stroke..strokeWidth = h * .035..color = col..strokeJoin = StrokeJoin.round;
    final thin = Paint()..style = PaintingStyle.stroke..strokeWidth = h * .025..color = col;
    final glow = Paint()
      ..style = PaintingStyle.stroke..strokeWidth = h * .07..color = col.withAlpha(90)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .05);
    void dot(Offset p, double r, Color k) => c.drawCircle(p, r, Paint()..color = k);
    void ring(Offset p, double r) {
      dot(p, r, const Color(0xFF0B0B11));
      c.drawCircle(p, r, thin);
      dot(p, r * .55, col.withAlpha(140));
    }

    void face(Offset p, Color t, Color l, Color r, Color b) {
      final d = h * .1, k = h * .045;
      dot(p.translate(0, -d), k, t);
      dot(p.translate(-d, 0), k, l);
      dot(p.translate(d, 0), k, r);
      dot(p.translate(0, d), k, b);
    }

    if (id == 'switch') {
      final l = RRect.fromRectAndRadius(Rect.fromLTWH(w * .14, h * .04, w * .28, h * .92), Radius.circular(w * .1));
      final r = RRect.fromRectAndRadius(Rect.fromLTWH(w * .58, h * .04, w * .28, h * .92), Radius.circular(w * .1));
      for (final e in [(l, const Color(0xFF00C3E3)), (r, const Color(0xFFFF4554))]) {
        c.drawRRect(e.$1, Paint()..color = e.$2.withAlpha(80)..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .06));
        c.drawRRect(e.$1, Paint()..color = e.$2.withAlpha(55));
        c.drawRRect(e.$1, Paint()..style = PaintingStyle.stroke..strokeWidth = h * .04..color = e.$2);
      }
      const wh = Color(0xCCFFFFFF);
      ring(o(.28, .28), w * .065);
      face(o(.28, .66), wh, wh, wh, wh);
      face(o(.72, .3), wh, wh, wh, wh);
      ring(o(.72, .68), w * .065);
      return;
    }

    void stick(Offset p, double r) {
      c.drawCircle(p, r * 1.18, Paint()..color = const Color(0xFF0A0A0F));
      c.drawCircle(
          p, r,
          Paint()..shader = const RadialGradient(colors: [Color(0xFF5A5A66), Color(0xFF1A1A22)])
              .createShader(Rect.fromCircle(center: p, radius: r)));
      c.drawCircle(p, r * .55, Paint()..style = PaintingStyle.stroke..strokeWidth = h * .015..color = const Color(0x55FFFFFF));
    }

    void txt(String t, Offset p, Color k, double fs) {
      final tp = TextPainter(
          text: TextSpan(text: t, style: TextStyle(color: k, fontSize: fs, fontWeight: FontWeight.w900)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(c, p - Offset(tp.width / 2, tp.height / 2));
    }

    void btn(Offset p, double r, Color bg) {
      dot(p, r, bg);
      c.drawCircle(p, r, Paint()..style = PaintingStyle.stroke..strokeWidth = h * .014..color = const Color(0x44FFFFFF));
    }

    final fillPaint = (List<Color> cs) => Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: cs)
          .createShader(Offset.zero & s);

    if (id == 'ps') {
      final body = Path()
        ..moveTo(w * .12, h * .07)
        ..quadraticBezierTo(w * .19, 0, w * .265, h * .05)
        ..lineTo(w * .735, h * .05)
        ..quadraticBezierTo(w * .81, 0, w * .88, h * .07)
        ..lineTo(w * .93, h * .17)
        ..cubicTo(w * .97, h * .28, w * .985, h * .5, w * .995, h * .6)
        ..cubicTo(w * 1.0, h * .78, w * .98, h * .95, w * .88, h)
        ..quadraticBezierTo(w * .82, h, w * .79, h * .88)
        ..lineTo(w * .745, h * .66)
        ..quadraticBezierTo(w * .68, h * .72, w * .59, h * .63)
        ..lineTo(w * .41, h * .63)
        ..quadraticBezierTo(w * .32, h * .72, w * .255, h * .66)
        ..lineTo(w * .21, h * .88)
        ..quadraticBezierTo(w * .18, h, w * .12, h)
        ..cubicTo(w * .02, h * .95, 0, h * .78, w * .005, h * .6)
        ..cubicTo(w * .015, h * .5, w * .03, h * .28, w * .07, h * .17)
        ..close();
      c.drawPath(body, glow);
      c.drawPath(body, fillPaint(const [Color(0xFF2A2A36), Color(0xFF1A1A22)]));
      c.drawPath(body, line);
      const wh = Color(0xFFF2F2F8);
      final tp = Path()
        ..moveTo(w * .36, h * .05)
        ..lineTo(w * .36, h * .29)
        ..quadraticBezierTo(w * .36, h * .34, w * .41, h * .34)
        ..lineTo(w * .59, h * .34)
        ..quadraticBezierTo(w * .64, h * .34, w * .64, h * .29)
        ..lineTo(w * .64, h * .05);
      c.drawPath(tp, Paint()..style = PaintingStyle.stroke..strokeWidth = h * .025..color = wh..strokeJoin = StrokeJoin.round);
      final q = Paint()..color = wh..strokeWidth = h * .08..strokeCap = StrokeCap.round;
      c.drawLine(o(.19, .29).translate(-h * .09, 0), o(.19, .29).translate(h * .09, 0), q);
      c.drawLine(o(.19, .29).translate(0, -h * .09), o(.19, .29).translate(0, h * .09), q);
      final f = o(.82, .28);
      final d = h * .11;
      for (final e in [Offset(0, -d), Offset(-d, 0), Offset(d, 0), Offset(0, d)]) {
        dot(f + e, h * .05, wh);
      }
      dot(o(.34, .53), h * .098, wh);
      dot(o(.66, .53), h * .098, wh);
    } else {
      final body = Path()
        ..moveTo(w * .20, h * .20)
        ..quadraticBezierTo(w * .26, h * .10, w * .36, h * .13)
        ..lineTo(w * .64, h * .13)
        ..quadraticBezierTo(w * .74, h * .10, w * .80, h * .20)
        ..cubicTo(w * .90, h * .32, w * .97, h * .62, w * .95, h * .84)
        ..quadraticBezierTo(w * .94, h * .99, w * .85, h * .96)
        ..quadraticBezierTo(w * .76, h * .92, w * .71, h * .76)
        ..quadraticBezierTo(w * .5, h * .72, w * .29, h * .76)
        ..quadraticBezierTo(w * .24, h * .92, w * .15, h * .96)
        ..quadraticBezierTo(w * .06, h * .99, w * .05, h * .84)
        ..cubicTo(w * .03, h * .62, w * .10, h * .32, w * .20, h * .20)
        ..close();
      c.drawPath(body, glow);
      c.drawPath(body, fillPaint(const [Color(0xFF2C2C34), Color(0xFF1B1B21)]));
      c.drawPath(body, line);
      final plate = Path()
        ..moveTo(w * .37, h * .13)
        ..lineTo(w * .63, h * .13)
        ..lineTo(w * .58, h * .31)
        ..lineTo(w * .42, h * .31)
        ..close();
      c.drawPath(plate, Paint()..color = const Color(0xFF3C3C45));
      dot(o(.5, .23), h * .06, const Color(0xFFF0F0F5));
      dot(o(.43, .375), h * .022, const Color(0xFF111116));
      dot(o(.57, .375), h * .022, const Color(0xFF111116));
      stick(o(.26, .375), h * .1);
      stick(o(.62, .57), h * .1);
      dot(o(.39, .57), h * .115, const Color(0xFF111116));
      final q = Paint()..color = const Color(0xFF5A5A66)..strokeWidth = h * .06..strokeCap = StrokeCap.round;
      c.drawLine(o(.39, .57).translate(-h * .06, 0), o(.39, .57).translate(h * .06, 0), q);
      c.drawLine(o(.39, .57).translate(0, -h * .06), o(.39, .57).translate(0, h * .06), q);
      final f = o(.74, .37);
      final d = h * .088;
      dot(f + Offset(0, -d), h * .044, const Color(0xFFFFC61A));
      dot(f + Offset(-d, 0), h * .044, const Color(0xFF3A8FD6));
      dot(f + Offset(d, 0), h * .044, const Color(0xFFE0453A));
      dot(f + Offset(0, d), h * .044, const Color(0xFF2DB873));
    }
  }

  @override
  bool shouldRepaint(covariant _PadPainter o) => o.id != id || o.col != col;
}

/// Иконка устройства: id = ps | xbox | switch | kb | digits.
class DevIcon extends StatelessWidget {
  final String id;
  final double size;
  final Color col;
  const DevIcon(this.id, {super.key, this.size = 56, this.col = Colors.white});

  Widget _k(String t, double s, Color k) => Container(
        width: s, height: s, alignment: Alignment.center,
        decoration: BoxDecoration(
          color: C.surf2, borderRadius: BorderRadius.circular(s * .22),
          border: Border.all(color: k, width: 1.5),
          boxShadow: [BoxShadow(color: k.withAlpha(60), blurRadius: 6)],
        ),
        child: Text(t, style: GoogleFonts.barlowCondensed(fontSize: s * .55, fontWeight: FontWeight.w800, color: k, height: 1)),
      );

  @override
  Widget build(BuildContext context) {
    final box = (Widget ch) => SizedBox(width: size * 1.5, height: size, child: ch);
    if (id == 'kb') {
      final s = size * .32;
      return box(Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _k('W', s, col),
          const SizedBox(height: 3),
          Row(mainAxisSize: MainAxisSize.min, children: [
            _k('A', s, col), const SizedBox(width: 3), _k('S', s, col), const SizedBox(width: 3), _k('D', s, col),
          ]),
        ]),
      ));
    }
    if (id == 'digits') {
      final s = size * .34;
      return box(Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [_k('1', s, C.red2), const SizedBox(width: 3), _k('2', s, C.red2)]),
          const SizedBox(height: 3),
          Row(mainAxisSize: MainAxisSize.min, children: [_k('3', s, C.red2), const SizedBox(width: 3), _k('4', s, C.red2)]),
        ]),
      ));
    }
    return box(CustomPaint(painter: _PadPainter(id, col)));
  }
}

// ── PlayStation: □ △ ✕ ○ — контурные символы со свечением ──
class _GlyphPainter extends CustomPainter {
  final int k; // 0 □, 1 △, 2 ✕, 3 ○
  final Color col;
  _GlyphPainter(this.k, this.col);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final path = Path();
    switch (k) {
      case 0:
        path.addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .27, w * .27, w * .46, w * .46), Radius.circular(w * .05)));
      case 1:
        path..moveTo(w * .5, w * .24)..lineTo(w * .76, w * .7)..lineTo(w * .24, w * .7)..close();
      case 2:
        path..moveTo(w * .3, w * .3)..lineTo(w * .7, w * .7)..moveTo(w * .7, w * .3)..lineTo(w * .3, w * .7);
      default:
        path.addOval(Rect.fromCircle(center: Offset(w / 2, w / 2), radius: w * .24));
    }
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    c.drawPath(path, p..color = col.withAlpha(160)..maskFilter = MaskFilter.blur(BlurStyle.normal, w * .06));
    c.drawPath(path, p..color = col..maskFilter = null);
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter o) => o.k != k || o.col != col;
}

// ── Буквы A B X Y рисуются линиями: ровные, по центру, без шрифта ──
class _LetterPainter extends CustomPainter {
  final String l;
  final Color k;
  _LetterPainter(this.l, this.k);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final p = Path();
    switch (l) {
      case 'A':
        p..moveTo(w * .3, w * .74)..lineTo(w * .5, w * .26)..lineTo(w * .7, w * .74)
          ..moveTo(w * .37, w * .6)..lineTo(w * .63, w * .6);
      case 'B':
        p..moveTo(w * .36, w * .74)..lineTo(w * .36, w * .26)..lineTo(w * .52, w * .26)
          ..cubicTo(w * .7, w * .26, w * .7, w * .5, w * .52, w * .5)..lineTo(w * .36, w * .5)
          ..moveTo(w * .52, w * .5)..cubicTo(w * .76, w * .5, w * .76, w * .74, w * .52, w * .74)
          ..lineTo(w * .36, w * .74);
      case 'X':
        p..moveTo(w * .3, w * .28)..lineTo(w * .7, w * .72)..moveTo(w * .7, w * .28)..lineTo(w * .3, w * .72);
      default: // Y
        p..moveTo(w * .3, w * .27)..lineTo(w * .5, w * .52)..lineTo(w * .7, w * .27)
          ..moveTo(w * .5, w * .52)..lineTo(w * .5, w * .75);
    }
    c.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .1
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = k);
  }

  @override
  bool shouldRepaint(covariant _LetterPainter o) => o.l != l || o.k != k;
}

// ── Кнопка контроллера: PS / Xbox / Switch / клавиатура / цифры ──
class PadBtn extends StatelessWidget {
  final String dev;
  final int slot;
  final double size;
  const PadBtn(this.dev, this.slot, {super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final col = (_col[dev] ?? _col['digits']!)[slot];
    final label = (_lab[dev] ?? _lab['digits']!)[slot];
    final round = dev != 'kb';
    final filled = dev == 'digits';
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: round ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: round ? null : BorderRadius.circular(size * .26),
        gradient: RadialGradient(
          center: const Alignment(-.3, -.4),
          radius: 1,
          colors: filled
              ? [col, Color.lerp(col, Colors.black, .45)!]
              : [Color.lerp(col, Colors.black, .6)!, const Color(0xFF0B0B11)],
        ),
        border: Border.all(color: col, width: 1.8),
        boxShadow: [BoxShadow(color: col.withAlpha(90), blurRadius: 8)],
      ),
      child: dev == 'ps'
          ? CustomPaint(size: Size.square(size), painter: _GlyphPainter(slot, col))
          : (dev == 'xbox' || dev == 'switch')
              ? CustomPaint(
                  size: Size.square(size),
                  painter: _LetterPainter(label, dev == 'switch' ? const Color(0xFFF0F0F5) : col))
              : Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: size * .54,
                    fontWeight: FontWeight.w800,
                    color: filled ? Colors.white : col,
                    height: 1,
                  ),
                ),
    );
  }
}

// ── Спец-кнопки файтингов: иконка + цвет ──
const _spec = <String, (IconData, Color)>{
  'DR': (Icons.keyboard_double_arrow_right_rounded, C.cyan), // Drive Rush
  'DI': (Icons.security_rounded, C.cyan), // Drive Impact
  'PARRY': (Icons.sync_rounded, C.cyan), // Drive Parry
  'Heat': (Icons.local_fire_department_rounded, Color(0xFFFF9F1C)),
  'AMP': (Icons.bolt_rounded, Color(0xFFB388FF)), // Amplify
  'RAGE': (Icons.whatshot_rounded, Color(0xFFFF5A66)),
  'THROW': (Icons.back_hand_rounded, Color(0xFFFFC61A)),
  'BL': (Icons.shield_outlined, C.sub), // Block
  'DASH': (Icons.fast_forward_rounded, Colors.white),
  'JUMP': (Icons.keyboard_double_arrow_up_rounded, Colors.white),
  'ASSIST': (Icons.group_add_rounded, Color(0xFF3DDC84)),
  'TAG': (Icons.swap_horiz_rounded, Color(0xFF3DDC84)),
  'SUPER': (Icons.star_rounded, Color(0xFFFFC61A)),
  'TAUNT': (Icons.chat_bubble_rounded, C.sub),
};

// Названия с других устройств приводятся к PlayStation-именам
const _alias = {'LB': 'L1', 'RB': 'R1', 'LT': 'L2', 'RT': 'R2', 'ZL': 'L2', 'ZR': 'R2', 'LS': 'L3', 'RS': 'R3'};

String shoulderLabel(String dev, String code) {
  const x = {'L1': 'LB', 'R1': 'RB', 'L2': 'LT', 'R2': 'RT', 'L3': 'LS', 'R3': 'RS'};
  const n = {'L1': 'L', 'R1': 'R', 'L2': 'ZL', 'R2': 'ZR', 'L3': 'LS', 'R3': 'RS'};
  return dev == 'xbox' ? x[code]! : dev == 'switch' ? n[code]! : code;
}

// ── Бамперы (L1/R1, LB/RB, L/R) и триггеры (L2/R2, LT/RT, ZL/ZR) ──
class _ShoulderPainter extends CustomPainter {
  final bool trig, left;
  final Color col;
  _ShoulderPainter(this.trig, this.left, this.col);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    double x(double v) => left ? w * v : w * (1 - v);
    final path = Path();
    if (!trig) {
      path.addRRect(RRect.fromRectAndCorners(Rect.fromLTWH(w * .03, h * .06, w * .94, h * .88),
          topLeft: Radius.circular(left ? h * .8 : h * .25), topRight: Radius.circular(left ? h * .25 : h * .8),
          bottomLeft: Radius.circular(h * .25), bottomRight: Radius.circular(h * .25)));
    } else {
      path
        ..moveTo(x(.04), h * .95)..lineTo(x(.04), h * .5)
        ..quadraticBezierTo(x(.04), h * .06, x(.5), h * .05)
        ..lineTo(x(.96), h * .05)..lineTo(x(.96), h * .95)..close();
    }
    c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = h * .14..color = col.withAlpha(80)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, h * .08));
    c.drawPath(path, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Color(0xFF3A3A46), Color(0xFF14141C)]).createShader(Offset.zero & s));
    c.drawPath(path, Paint()..style = PaintingStyle.stroke..strokeWidth = h * .06..strokeJoin = StrokeJoin.round..color = col);
  }

  @override
  bool shouldRepaint(covariant _ShoulderPainter o) => o.trig != trig || o.left != left || o.col != col;
}

class ShoulderBtn extends StatelessWidget {
  final String code, dev;
  final double size;
  const ShoulderBtn(this.code, this.dev, {super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final trig = code.endsWith('2');
    final label = shoulderLabel(dev, code);
    final bw = size * (label.length > 2 ? 1.5 : 1.3), bh = size * (trig ? .86 : .62);
    return SizedBox(
      width: bw, height: bh,
      child: CustomPaint(
        painter: _ShoulderPainter(trig, code.startsWith('L'), trig ? const Color(0xFF8F9BFF) : const Color(0xFFC9C9D6)),
        child: Center(
          child: Text(label,
              style: GoogleFonts.barlow(fontSize: bh * .46, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
        ),
      ),
    );
  }
}

// ── Системные кнопки: Start/Options, Select/Share, Home, Touchpad, нажатие стика L3/R3 ──
class _SysPainter extends CustomPainter {
  final String code, dev;
  _SysPainter(this.code, this.dev);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width, h = s.height;
    const edge = Color(0xFF8A8A98);
    final fill = Paint()..color = const Color(0xFF1C1C26);
    final border = Paint()..style = PaintingStyle.stroke..strokeWidth = h * .06..color = edge;
    final ln = Paint()..style = PaintingStyle.stroke..strokeWidth = h * .09..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = Colors.white;
    if (code == 'HOME') {
      final m = Offset(w / 2, h / 2);
      c.drawCircle(m, h * .48, fill);
      c.drawCircle(m, h * .48, border);
      c.drawCircle(m, h * .26, ln);
      c.drawCircle(m, h * .09, Paint()..color = Colors.white);
      return;
    }
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(w * .03, h * .06, w * .94, h * .88), Radius.circular(h * .44));
    c.drawRRect(r, fill);
    c.drawRRect(r, border);
    switch (code) {
      case 'TOUCH':
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .24, h * .28, w * .52, h * .44), Radius.circular(h * .1)), ln);
      case 'START':
        if (dev == 'switch') {
          c.drawLine(Offset(w * .36, h * .5), Offset(w * .64, h * .5), ln);
          c.drawLine(Offset(w * .5, h * .3), Offset(w * .5, h * .7), ln);
        } else {
          for (final y in [.32, .5, .68]) {
            c.drawLine(Offset(w * .34, h * y), Offset(w * .66, h * y), ln);
          }
        }
      default: // SELECT
        if (dev == 'switch') {
          c.drawLine(Offset(w * .36, h * .5), Offset(w * .64, h * .5), ln);
        } else if (dev == 'xbox') {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .3, h * .3, w * .24, h * .26), Radius.circular(h * .05)), ln);
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .44, h * .44, w * .24, h * .26), Radius.circular(h * .05)), ln);
        } else {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .33, h * .32, w * .34, h * .38), Radius.circular(h * .08)), ln);
          c.drawLine(Offset(w * .43, h * .2), Offset(w * .57, h * .2), ln);
        }
    }
  }

  @override
  bool shouldRepaint(covariant _SysPainter o) => o.code != code || o.dev != dev;
}

class SysBtn extends StatelessWidget {
  final String code, dev;
  final double size;
  const SysBtn(this.code, this.dev, {super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    if (code == 'L3' || code == 'R3') {
      return Container(
        width: size, height: size, alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(colors: [Color(0xFF5A5A66), Color(0xFF1A1A22)]),
          border: Border.all(color: const Color(0xFF8A8A98), width: 1.8),
        ),
        child: Text(shoulderLabel(dev, code),
            style: GoogleFonts.barlow(fontSize: size * .34, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
      );
    }
    final home = code == 'HOME';
    return SizedBox(
        width: home ? size : size * 1.15, height: home ? size : size * .7,
        child: CustomPaint(painter: _SysPainter(code, dev)));
  }
}

// ── Удары: L/M/H (сила — точками), P = красный, K = синий, спец-механики — иконкой ──
class AtkBtn extends StatelessWidget {
  final String t;
  final double size;
  const AtkBtn(this.t, {super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final sp = _spec[t];
    final p = sp == null && t.endsWith('P'), k = sp == null && t.endsWith('K');
    final col = sp?.$2 ?? (p ? const Color(0xFFFF5A66) : k ? const Color(0xFF5A9BFF) : C.sub);
    final pips = (p || k) ? (const {'L': 1, 'M': 2, 'H': 3}[t[0]] ?? 0) : 0;
    final icon = sp?.$1;
    return Container(
      height: size,
      constraints: BoxConstraints(minWidth: size),
      padding: EdgeInsets.symmetric(horizontal: size * .22),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .34),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [col.withAlpha(70), col.withAlpha(18)],
        ),
        border: Border.all(color: col, width: 1.8),
        boxShadow: [BoxShadow(color: col.withAlpha(80), blurRadius: 8)],
      ),
      child: icon != null
          ? Icon(icon, size: size * .58, color: col)
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t,
                  style: GoogleFonts.barlowCondensed(
                    fontSize: size * .46,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
                if (pips > 0) ...[
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < pips; i++)
                        Container(
                          width: size * .10,
                          height: size * .10,
                          margin: const EdgeInsets.symmetric(horizontal: 0.8),
                          decoration: BoxDecoration(color: col, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

// ── Направление в комбо: стрелка с ровной центровкой ──
class _ArrowPainter extends CustomPainter {
  final String d;
  _ArrowPainter(this.d);

  @override
  void paint(Canvas c, Size s) {
    final m = Offset(s.width / 2, s.height / 2);
    final u = s.height;
    if (d == '5') {
      c.drawCircle(m, u * .12, Paint()..color = C.sub);
      return;
    }
    c.save();
    c.translate(m.dx, m.dy);
    c.rotate(_ang[d]! * math.pi / 180);
    final path = Path()
      ..moveTo(-u * .22, 0)
      ..lineTo(u * .22, 0)
      ..moveTo(0, -u * .20)
      ..lineTo(u * .22, 0)
      ..lineTo(0, u * .20);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = u * .12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    c.drawPath(path, p..color = C.red.withAlpha(150)..maskFilter = MaskFilter.blur(BlurStyle.normal, u * .06));
    c.drawPath(path, p..color = Colors.white..maskFilter = null);
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _ArrowPainter o) => o.d != d;
}

class DirIcon extends StatelessWidget {
  final String d;
  final double size;
  const DirIcon(this.d, {super.key, this.size = 30});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: _ArrowPainter(d)));
}

// ── Джойстик (вид сверху): сбалансированный шарик ──
class _StickPainter extends CustomPainter {
  final String d;
  _StickPainter(this.d);

  @override
  void paint(Canvas c, Size s) {
    final m = Offset(s.width / 2, s.height / 2);
    final r = s.width * .42;
    c.drawCircle(m, r, Paint()..color = const Color(0x14FFFFFF));
    c.drawCircle(m, r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = const Color(0x40FFFFFF));
    final neutral = d == '5';
    final a = neutral ? 0.0 : _ang[d]! * math.pi / 180;
    final ball = neutral ? m : m + Offset(math.cos(a), math.sin(a)) * r * .58;
    c.drawLine(m, ball, Paint()..color = C.sub..strokeWidth = s.width * .08..strokeCap = StrokeCap.round);
    final col = neutral ? C.sub : C.red2;
    c.drawCircle(ball, s.width * .19, Paint()..color = col.withAlpha(140)..maskFilter = MaskFilter.blur(BlurStyle.normal, s.width * .1));
    c.drawCircle(ball, s.width * .16, Paint()..color = col);
  }

  @override
  bool shouldRepaint(covariant _StickPainter o) => o.d != d;
}

class StickIcon extends StatelessWidget {
  final String d;
  final double size;
  const StickIcon(this.d, {super.key, this.size = 30});

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: _StickPainter(d)));
}

/// Клавиша направления для Combo Studio.
Widget dirKey(String d, VoidCallback f) => Material(
      color: C.surf2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: C.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: f,
        child: SizedBox(width: 46, height: 40, child: Center(child: StickIcon(d, size: 28))),
      ),
    );

Widget buttonIcon(String raw, double size) {
  final t = _alias[raw] ?? raw;
  final slot = _slot[t];
  if (slot != null) return PadBtn(app.device, slot, size: size);
  if (const ['L1', 'R1', 'L2', 'R2'].contains(t)) return ShoulderBtn(t, app.device, size: size);
  if (const ['START', 'SELECT', 'HOME', 'TOUCH', 'L3', 'R3'].contains(t)) return SysBtn(t, app.device, size: size);
  return AtkBtn(t, size: size);
}

// ── Лента комбо со строгим выравниванием в одну горизонтальную линию ──
class NotationRow extends StatelessWidget {
  final String notation;
  final double size;
  const NotationRow(this.notation, {super.key, this.size = 32});

  Widget _txt(String t) => SizedBox(
        height: size,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Text(
              t,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * .48,
                height: 1,
              ),
            ),
          ),
        ),
      );

  Widget _dot() => SizedBox(
        height: size,
        child: Center(
          child: Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(
              color: C.red2,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: C.red, blurRadius: 6)],
            ),
          ),
        ),
      );

  Widget _btn(String raw) {
    final t = _alias[raw] ?? raw;
    final slot = _slot[t];
    if (slot != null) return PadBtn(app.device, slot, size: size);
    if (const ['L1', 'R1', 'L2', 'R2'].contains(t)) return ShoulderBtn(t, app.device, size: size);
    if (const ['START', 'SELECT', 'HOME', 'TOUCH', 'L3', 'R3'].contains(t)) return SysBtn(t, app.device, size: size);
    return AtkBtn(t, size: size);
  }

  @override
  Widget build(BuildContext context) {
    final out = <Widget>[];
    for (final raw in notation.trim().split(RegExp(r'\s+'))) {
      if (raw.isEmpty) continue;
      if (raw == '>') {
        out.add(_dot());
        continue;
      }
      if (raw == '+' || raw == '~' || raw == '/') {
        out.add(_txt(raw));
        continue;
      }
      var t = raw;
      if (t.startsWith('j.')) {
        out.add(_txt('j.'));
        t = t.substring(2);
        if (t.isEmpty) continue;
      }
      if (RegExp(r'^[1-9]+$').hasMatch(t)) {
        for (final ch in t.split('')) {
          out.add(DirIcon(ch, size: size));
        }
      } else if (_dirW.containsKey(t)) {
        out.add(DirIcon(_dirW[t]!, size: size));
      } else {
        out.add(_btn(t));
      }
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (var i = 0; i < out.length; i++) ...[
            if (i > 0) const SizedBox(width: 3),
            out[i],
          ],
        ],
      ),
    );
  }
}
