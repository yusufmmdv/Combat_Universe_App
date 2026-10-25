// ============================================================================
// CombatUniverse (cu_app) v2
// Точка входа в приложение.
// ============================================================================
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_theme.dart';
import 'core/i18n/app_i18n.dart';
import 'core/state/app_state.dart';
import 'widgets/common/cu_card.dart';
import 'widgets/common/logo.dart';
import 'widgets/notation/notation_row.dart';
import 'screens/home/home_tab.dart';
import 'screens/news/news_screen.dart';
import 'screens/saved/saved_tab.dart';
import 'screens/profile/profile_tab.dart';

void main() => runApp(const CUApp());

// ───────────────────────────── APP ROOT ─────────────────────────────
class CUApp extends StatelessWidget {
  const CUApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CombatUniverse',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: ListenableBuilder(
          listenable: app,
          builder: (_, __) => app.device.isEmpty ? const DeviceScreen() : const Shell(),
        ),
      );
}

// ───────────────────────────── ONBOARDING: DEVICE ─────────────────────────────
class DeviceScreen extends StatefulWidget {
  const DeviceScreen({super.key});
  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  String? sel;
  @override
  Widget build(BuildContext context) => Rx((c) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Center(child: CULogo(size: 84)),
              const SizedBox(height: 14),
              SizedBox(
                height: 38,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final e in langs.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Pill(e.value,
                          selected: app.lang == e.key, filled: true,
                          onTap: () => app.update(() => app.lang = e.key)),
                    ),
                ]),
              ),
              const SizedBox(height: 18),
              Text(tr('pickDev'), style: hd(26)),
              const SizedBox(height: 6),
              Text(tr('pickDevSub'), style: const TextStyle(color: C.sub)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(children: [
                  for (final d in devs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: CuCard(
                        selected: sel == d.id,
                        onTap: () => setState(() => sel = d.id),
                        child: Row(children: [
                          DevIcon(d.id, size: 46, col: sel == d.id ? C.red2 : C.sub),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(devName(d.id), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          ),
                          if (sel == d.id) const Icon(Icons.check_circle, color: C.red),
                        ]),
                      ),
                    ),
                ]),
              ),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: C.red, foregroundColor: Colors.white,
                    disabledBackgroundColor: C.surf2, disabledForegroundColor: C.sub,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: sel == null ? null : () => app.update(() => app.device = sel!),
                  child: Text(tr('cont'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                ),
              ),
            ]),
          ),
        ),
      ));
}

// ───────────────────────────── SHELL (bottom nav) ─────────────────────────────
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  final _navKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  Widget _buildTabNavigator(int index, Widget root) => Navigator(
        key: _navKeys[index],
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 380),
          reverseTransitionDuration: const Duration(milliseconds: 260),
          pageBuilder: (_, __, ___) => root,
          transitionsBuilder: (_, a, __, child) {
            final cv = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
            return FadeTransition(
              opacity: cv,
              child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, .05), end: Offset.zero).animate(cv),
                  child: child),
            );
          },
        ),
      );

  @override
  Widget build(BuildContext context) => Rx((c) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
                center: Alignment(1, -1), radius: 1.2,
                colors: [Color(0xFF2A0508), C.bg], stops: [0, .6]),
          ),
          child: IndexedStack(
            index: i,
            children: [
              _buildTabNavigator(0, const HomeTab()),
              _buildTabNavigator(1, const NewsTab()),
              _buildTabNavigator(2, const SavedTab()),
              _buildTabNavigator(3, const ProfileTab()),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: GlassNav(
              index: i,
              onTap: (v) {
                if (i == v) {
                  _navKeys[v].currentState?.popUntil((route) => route.isFirst);
                } else {
                  setState(() => i = v);
                }
              },
            ),
          ),
        ),
      ));
}

/// Плавающая стеклянная панель навигации.
class GlassNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const GlassNav({super.key, required this.index, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded, tr('home')),
      (Icons.newspaper_rounded, tr('news')),
      (Icons.bookmark_rounded, tr('saved')),
      (Icons.person_rounded, tr('profile')),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xB814141C),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: C.line),
          ),
          child: Row(children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onTap(i);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: i == index ? const LinearGradient(colors: [C.red, Color(0xFF8E030A)]) : null,
                      boxShadow: i == index ? [BoxShadow(color: C.red.withAlpha(128), blurRadius: 18)] : null,
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      AnimatedScale(
                        scale: i == index ? 1.15 : 1,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutBack,
                        child: Icon(items[i].$1, size: 22, color: i == index ? Colors.white : C.sub),
                      ),
                      const SizedBox(height: 2),
                      Text(items[i].$2.toUpperCase(),
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .5,
                              color: i == index ? Colors.white : C.sub)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}
