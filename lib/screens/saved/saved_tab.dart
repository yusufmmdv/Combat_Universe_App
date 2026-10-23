import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_i18n.dart';
import '../../core/state/app_state.dart';
import '../../models/game.dart';
import '../../widgets/common/cu_card.dart';
import '../character/character_screen.dart';

// ───────────────────────────── SAVED ─────────────────────────────
class SavedTab extends StatefulWidget {
  const SavedTab({super.key});
  @override
  State<SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends State<SavedTab> {
  String? game;
  @override
  Widget build(BuildContext context) => Rx((c) {
        final combos = app.combos.where((x) => game != null && x.gameId == game && app.saved.contains(x.id)).toList();
        final gds = app.guides.where((x) => game != null && x.gameId == game && app.saved.contains(x.id)).toList();
        final empty = combos.isEmpty && gds.isEmpty;
        return SafeArea(
          bottom: false,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
            Text(tr('savedTitle'), style: hd(26)),
            const SizedBox(height: 4),
            Text(tr('savedSub'), style: const TextStyle(color: C.sub)),
            const SizedBox(height: 14),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final g in games)
                Pill(g.tag, selected: game == g.id, filled: true, onTap: () => setState(() => game = g.id)),
            ]),
            const SizedBox(height: 18),
            if (game == null || empty)
              Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Column(children: [
                  Icon(Icons.bookmark_border, size: 64, color: C.sub.withAlpha(110)),
                  const SizedBox(height: 12),
                  Text(tr('noSaved'), textAlign: TextAlign.center, style: const TextStyle(color: C.sub)),
                ]),
              )
            else ...[
              for (final x in combos) ComboCard(x, key: ValueKey('s${x.id}')),
              for (final x in gds) GuideTile(x),
            ],
          ]),
        );
      });
}
