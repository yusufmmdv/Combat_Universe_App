import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'cu_card.dart';

class HexLogo extends StatelessWidget {
  const HexLogo({super.key});
  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: HexClipper(),
        child: Container(
          width: 42, height: 46, alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [Color(0xFF111111), Color(0xFF111111), C.red, C.red],
                stops: [0, .5, .5, 1]),
          ),
          child: Text('CU', style: hd(14, ls: 1)),
        ),
      );
}

class Logo extends StatelessWidget {
  final double size;
  const Logo({super.key, this.size = 20});
  @override
  Widget build(BuildContext context) => Text.rich(TextSpan(children: [
        TextSpan(text: 'COMBAT ', style: hd(size, ls: 1.5)),
        TextSpan(text: 'UNIVERSE', style: hd(size, color: C.red, ls: 1.5)),
      ]));
}

class CULogo extends StatelessWidget {
  final double size;
  const CULogo({super.key, this.size = 80});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Image.asset(
          'assets/images/cu_logo.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
              child: Transform.scale(scale: size / 46, child: const HexLogo())),
        ),
      );
}

class Avatar extends StatelessWidget {
  final String name;
  final double size;
  const Avatar(this.name, {super.key, this.size = 36});
  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF444450), Color(0xFF222228)]),
          border: Border.all(color: C.red, width: 2),
        ),
        child: Text(name.isEmpty ? '?' : name.substring(0, name.length < 2 ? 1 : 2),
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: size * .34, color: Colors.white)),
      );
}
