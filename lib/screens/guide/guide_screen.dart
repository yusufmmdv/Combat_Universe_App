import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/state/app_state.dart';
import '../../models/game.dart';
import '../../models/guide.dart';
import '../../widgets/common/cu_card.dart';
import '../../widgets/common/logo.dart';
import '../character/character_screen.dart';

// ───────────────────────────── GUIDE VIEW ─────────────────────────────
class GuideScreen extends StatelessWidget {
  final Guide g;
  const GuideScreen(this.g, {super.key});
  @override
  Widget build(BuildContext context) => Rx((c) {
        final game = gameOf(g.gameId);
        final liked = app.liked.contains(g.id);
        final saved = app.saved.contains(g.id);
        final blocks = <Widget>[];
        for (final raw in g.body.split('\n')) {
          final line = raw.trim();
          if (line.isEmpty) continue;
          if (line.startsWith('[COMBO:') && line.endsWith(']')) {
            final id = line.substring(7, line.length - 1);
            final found = app.combos.where((x) => x.id == id);
            if (found.isNotEmpty) blocks.add(ComboCard(found.first, key: ValueKey('${g.id}$id')));
          } else if (line.startsWith('# ')) {
            blocks.add(Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Text(line.substring(2), style: hd(20)),
            ));
          } else {
            blocks.add(Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(line, style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFFD8D8E2))),
            ));
          }
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(game.name, style: const TextStyle(fontSize: 13, color: C.sub)),
            actions: [
              IconButton(
                  onPressed: () => app.toggle(app.liked, g.id),
                  icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? C.red : C.sub)),
              IconButton(
                  onPressed: () => app.toggle(app.saved, g.id),
                  icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, color: saved ? C.red : C.sub)),
            ],
          ),
          body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
            Text(g.title, style: hd(30, height: 1)),
            const SizedBox(height: 14),
            Row(children: [
              Avatar(g.author, size: 38),
              const SizedBox(width: 10),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g.author, style: const TextStyle(fontWeight: FontWeight.w800)),
                Text('@${g.author.toLowerCase()} · ${fmt(g.updated)}', style: const TextStyle(color: C.sub, fontSize: 12)),
              ]),
            ]),
            const Divider(height: 28, color: C.line),
            ...blocks,
          ]),
        );
      });
}
