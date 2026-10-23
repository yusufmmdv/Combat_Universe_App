import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_i18n.dart';
import '../../core/state/app_state.dart';
import '../../models/game.dart';
import '../../widgets/common/cu_card.dart';
import '../../widgets/common/fields.dart';
import '../character/character_screen.dart';

// ───────────────────────────── ROSTER ─────────────────────────────
class RosterScreen extends StatefulWidget {
  final Game g;
  const RosterScreen(this.g, {super.key});
  @override
  State<RosterScreen> createState() => _RosterScreenState();
}

class _RosterScreenState extends State<RosterScreen> {
  String q = '';
  bool grid = true;
  @override
  Widget build(BuildContext context) => Rx((c) {
        final g = widget.g;
        final list = g.chars.where((n) => n.toLowerCase().contains(q.toLowerCase())).toList();
        return Scaffold(
          appBar: AppBar(
            title: Text(g.name),
            actions: [
              IconButton(
                  onPressed: () => setState(() => grid = !grid),
                  icon: Icon(grid ? Icons.view_list : Icons.grid_view, color: C.sub)),
            ],
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: SearchField(tr('searchChar'), (v) => setState(() => q = v)),
            ),
            Expanded(
              child: grid
                  ? GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.3),
                      itemCount: list.length,
                      itemBuilder: (_, i) => Appear(i: i > 6 ? 6 : i, child: CharTile(g, list[i])),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: list.length,
                      itemBuilder: (_, i) => Appear(
                          i: i > 6 ? 6 : i,
                          child: Padding(padding: const EdgeInsets.only(bottom: 10), child: CharTile(g, list[i]))),
                    ),
            ),
          ]),
        );
      });
}

class CharTile extends StatelessWidget {
  final Game g;
  final String name;
  const CharTile(this.g, this.name, {super.key});
  @override
  Widget build(BuildContext context) {
    final n = app.combos.where((x) => x.gameId == g.id && x.charId == name).length;
    return CuCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: () => go(context, CharacterScreen(g, name)),
      child: Row(children: [
        Container(
          width: 42, height: 42, alignment: Alignment.center,
          decoration: BoxDecoration(
              shape: BoxShape.circle, gradient: LinearGradient(colors: g.colors),
              border: Border.all(color: C.line)),
          child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: .5)),
            Text('$n ${tr('combos').toLowerCase()}', style: const TextStyle(color: C.sub, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}
