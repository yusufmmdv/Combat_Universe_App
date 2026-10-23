import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ───────────────────────────── THEME ─────────────────────────────
class C {
  static const bg = Color(0xFF08080C);
  static const surf = Color(0xFF14141C);
  static const surf2 = Color(0xFF1C1C26);
  static const line = Color(0x1AFFFFFF);
  static const card = Color(0x0EFFFFFF);
  static const red = Color(0xFFE10613);
  static const red2 = Color(0xFFFF3B47);
  static const cyan = Color(0xFF00E5FF);
  static const text = Color(0xFFF4F4F8);
  static const sub = Color(0xFF9A9AAB);
  static const gold = Color(0xFFF5B700);
}

/// Заголовочный шрифт: Barlow Condensed Italic (как в макете экрана персонажа).
TextStyle hd(double s,
        {Color color = C.text, FontWeight w = FontWeight.w800, double? height, double ls = .5}) =>
    GoogleFonts.barlowCondensed(
        fontSize: s * 1.28, fontWeight: w, fontStyle: FontStyle.italic,
        color: color, height: height, letterSpacing: ls);

ThemeData buildTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: C.bg,
    colorScheme: const ColorScheme.dark(
        primary: C.red, secondary: C.red2, surface: C.surf, onSurface: C.text),
    textTheme: GoogleFonts.barlowTextTheme(base.textTheme)
        .apply(bodyColor: C.text, displayColor: C.text),
    appBarTheme: AppBarTheme(
      backgroundColor: C.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: hd(18, ls: 1),
    ),
  );
}

InputDecoration deco(String hint, {IconData? icon}) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: C.sub),
      prefixIcon: icon == null ? null : Icon(icon, color: C.sub),
      filled: true,
      fillColor: C.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.line)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: C.line)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: C.red2, width: 1.5)),
    );
