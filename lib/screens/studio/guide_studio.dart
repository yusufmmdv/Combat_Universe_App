import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_i18n.dart';
import '../../core/state/app_state.dart';
import '../../models/guide.dart';
import '../../widgets/common/cu_card.dart';
import '../../widgets/notation/notation_row.dart';
import 'combo_studio.dart';

class GuideStudio extends StatefulWidget {
  final String game, char;
  const GuideStudio({super.key, required this.game, required this.char});
  @override
  State<GuideStudio> createState() => _GuideStudioState();
}

class _GuideStudioState extends State<GuideStudio> {
  late String game = widget.game, char = widget.char;
  final title = TextEditingController();
  final body = TextEditingController();

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    super.dispose();
  }

  void insertCombo() {
    final list = app.combos.where((x) => x.gameId == game && x.charId == char).toList();
    showModalBottomSheet(
      context: context,
      backgroundColor: C.surf,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * .7,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Text(tr('insertCombo'), style: hd(20)),
          const SizedBox(height: 12),
          for (final x in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CuCard(
                onTap: () {
                  setState(() => body.text = '${body.text}\n\n[COMBO:${x.id}]\n');
                  Navigator.pop(ctx);
                },
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${x.title} · ${x.damage}', style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  NotationRow(x.notation, size: 28),
                ]),
              ),
            ),
        ]),
      ),
    );
  }

  void publish() {
    if (title.text.trim().isEmpty || body.text.trim().isEmpty) {
      toast(context, tr('fill'));
      return;
    }
    app.update(() => app.guides.insert(
        0,
        Guide(
          id: 'g_u_${DateTime.now().microsecondsSinceEpoch}', gameId: game, charId: char,
          title: title.text.trim(), author: meName, body: body.text.trim(), likes: 0, updated: DateTime.now(),
        )));
    toast(context, '${tr('publish')} ✓');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Rx((c) => Scaffold(
        appBar: AppBar(title: Text(tr('newGuide'))),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 32), children: [
          GameCharPicker(game: game, char: char, onChanged: (g, ch) => setState(() {
            game = g;
            char = ch;
          })),
          const SizedBox(height: 12),
          TextField(controller: title, decoration: deco(tr('title'))),
          const SizedBox(height: 12),
          TextField(controller: body, minLines: 8, maxLines: 16, decoration: deco(tr('guideBody'))),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(foregroundColor: C.text, side: const BorderSide(color: C.line), minimumSize: const Size.fromHeight(48)),
            onPressed: insertCombo,
            icon: const Icon(Icons.add_link),
            label: Text(tr('insertCombo')),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: C.red, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              onPressed: publish,
              child: Text(tr('publish'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ]),
      ));
}
