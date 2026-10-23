import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_i18n.dart';
import '../../core/state/app_state.dart';
import '../../models/game.dart';
import '../../widgets/common/cu_card.dart';
import '../../widgets/common/logo.dart';
import '../../widgets/common/fields.dart';
import '../../widgets/common/embers.dart';
import '../roster/roster_screen.dart';

// ───────────── 1) HOME: только список игр ─────────────
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  String q = '';
  @override
  Widget build(BuildContext context) => Rx((c) {
        final gs = games.where((g) => g.name.toLowerCase().contains(q.toLowerCase())).toList();
        return SafeArea(
          bottom: false,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 24), children: [
            Row(children: [const Logo(size: 20), const Spacer(), const Avatar(meName, size: 34)]),
            const SizedBox(height: 16),
            SearchField(tr('searchGame'), (v) => setState(() => q = v)),
            const SizedBox(height: 20),
            Text(tr('pickGame'), style: hd(22)),
            const SizedBox(height: 12),
            for (var i = 0; i < gs.length; i++)
              Appear(i: i, child: Padding(padding: const EdgeInsets.only(bottom: 14), child: HeroCard(gs[i]))),
          ]),
        );
      });
}

class HeroCard extends StatelessWidget {
  final Game g;
  const HeroCard(this.g, {super.key});
  @override
  Widget build(BuildContext context) => ClipPath(
        clipper: CutClipper(),
        child: SizedBox(
          height: 190,
          child: Stack(children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight, colors: g.colors)),
              ),
            ),
            Positioned(
              right: -50, top: -60,
              child: Container(
                width: 240, height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [g.colors[1].withAlpha(200), Colors.transparent]),
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: StripesPainter())),
            Positioned(right: -20, bottom: -26, child: Icon(g.icon, size: 170, color: Colors.white.withAlpha(34))),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withAlpha(160)]),
                ),
              ),
            ),
            Positioned(
              left: 18, bottom: 16, right: 80,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(g.tag, style: const TextStyle(color: C.red2, fontWeight: FontWeight.w700, letterSpacing: 3, fontSize: 11)),
                const SizedBox(height: 2),
                Text(g.name, style: hd(26, color: Colors.white, height: 1)),
                const SizedBox(height: 4),
                Text('${g.chars.length} • ${app.combos.where((x) => x.gameId == g.id).length} ${tr('combos').toLowerCase()}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
            Positioned(
              right: 16, bottom: 16,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: C.red, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: C.red.withAlpha(140), blurRadius: 16)],
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.white),
              ),
            ),
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(onTap: () => go(context, RosterScreen(g))),
              ),
            ),
          ]),
        ),
      );
}
