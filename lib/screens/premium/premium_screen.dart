import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_i18n.dart';
import '../../core/state/app_state.dart';
import '../../widgets/common/cu_card.dart';
import '../../widgets/common/logo.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});
  @override
  Widget build(BuildContext context) => Rx((c) => Scaffold(
        appBar: AppBar(title: const Text('PREMIUM')),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
          const Center(child: Icon(Icons.star_rounded, size: 96, color: C.gold)),
          const SizedBox(height: 6),
          const Center(child: Logo(size: 22)),
          const SizedBox(height: 4),
          const Center(child: Text('PREMIUM', style: TextStyle(color: C.gold, fontWeight: FontWeight.w900, letterSpacing: 4))),
          const SizedBox(height: 22),
          for (final p in tr('perks').split('|'))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                const Icon(Icons.check_circle, color: C.gold, size: 20),
                const SizedBox(width: 12),
                Text(p, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
            ),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: _plan(c, '1 мес / month', '\$4.99', false)),
            const SizedBox(width: 10),
            Expanded(child: _plan(c, '12 мес / year', '\$39.99', true)),
          ]),
          if (app.premium)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: Text('ACTIVE', style: TextStyle(color: C.gold, fontWeight: FontWeight.w900, letterSpacing: 3))),
            ),
        ]),
      ));

  Widget _plan(BuildContext c, String t, String price, bool best) => CuCard(
        selected: best,
        onTap: () {
          app.update(() => app.premium = true);
          toast(c, tr('soon'));
        },
        child: Column(children: [
          Text(t, style: const TextStyle(color: C.sub, fontSize: 12)),
          const SizedBox(height: 6),
          Text(price, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: C.gold)),
          const SizedBox(height: 8),
          Text(tr('buy'), style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
      );
}
