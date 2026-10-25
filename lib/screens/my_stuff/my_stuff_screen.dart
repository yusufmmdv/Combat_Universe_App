import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_i18n.dart';
import '../../core/state/app_state.dart';
import '../../core/social/cu_social.dart';
import '../../models/game.dart';
import '../../widgets/common/cu_card.dart';
import '../character/character_screen.dart';
import '../studio/combo_studio.dart';
import '../studio/guide_studio.dart';

class MyStuffScreen extends StatelessWidget {
  const MyStuffScreen({super.key});
  @override
  Widget build(BuildContext context) => Rx((c) {
        final combos = app.combos.where((x) => x.author == meName).toList();
        final gds = app.guides.where((x) => x.author == meName).toList();
        return Scaffold(
          appBar: AppBar(title: Text(tr('myStuff'))),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
            Row(children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: C.red, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(48)),
                  onPressed: () {
                    if (requireAuth(c)) go(c, ComboStudio(game: games.first.id, char: games.first.chars.first));
                  },
                  icon: const Icon(Icons.add), label: Text(tr('newCombo')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: C.text, side: const BorderSide(color: C.line), minimumSize: const Size.fromHeight(48)),
                  onPressed: () {
                    if (requireAuth(c)) go(c, GuideStudio(game: games.first.id, char: games.first.chars.first));
                  },
                  icon: const Icon(Icons.edit_note), label: Text(tr('newGuide')),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            Text(tr('combos'), style: hd(18)),
            const SizedBox(height: 8),
            for (final x in combos) ComboCard(x, key: ValueKey('m${x.id}')),
            const SizedBox(height: 8),
            Text(tr('builds'), style: hd(18)),
            const SizedBox(height: 8),
            for (final g in gds) GuideTile(g),
          ]),
        );
      });
}
