import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_i18n.dart';
import '../../core/state/app_state.dart';
import '../../models/game.dart';
import '../../models/combo.dart';
import '../../widgets/common/cu_card.dart';
import '../../widgets/notation/notation_row.dart';

Widget dd(String value, List<String> items, ValueChanged<String?> on, {String Function(String)? label}) =>
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: C.surf, borderRadius: BorderRadius.circular(14), border: Border.all(color: C.line)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value, isExpanded: true, dropdownColor: C.surf2,
          items: [for (final i in items) DropdownMenuItem(value: i, child: Text(label?.call(i) ?? i, overflow: TextOverflow.ellipsis))],
          onChanged: on,
        ),
      ),
    );

class GameCharPicker extends StatelessWidget {
  final String game, char;
  final void Function(String g, String c) onChanged;
  const GameCharPicker({super.key, required this.game, required this.char, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(
          child: dd(game, [for (final g in games) g.id], (v) => onChanged(v!, gameOf(v).chars.first),
              label: (id) => gameOf(id).tag),
        ),
        const SizedBox(width: 10),
        Expanded(child: dd(char, gameOf(game).chars, (v) => onChanged(game, v!))),
      ]);
}

// ───────────── 3) COMBO STUDIO: токены + курсор + Undo/Redo + конфиг игры ─────────────
const _btns = <String, List<String>>{
  'mk1': ['FP', 'BP', 'FK', 'BK'],
  't8': ['T1', 'T2', 'T3', 'T4'],
  'sf6': ['LP', 'MP', 'HP', 'LK', 'MK', 'HK'],
};
const _motions = <String, List<String>>{
  'mk1': ['236', '214', '623', '41236'],
  'sf6': ['236', '214', '623', '41236', '63214'],
};
const _starters = ['DR', 'Heat']; // механики, которые начинают новое действие
const _seps = ['>', '+', '~', 'j.'];
const _quickTags = ['BnB', 'Corner', 'Wall', 'Meter', 'Easy', 'Medium', 'Hard', 'Punish', 'AA', 'Counter Hit'];

const _padAng = {'6': 0.0, '3': 45.0, '2': 90.0, '1': 135.0, '4': 180.0, '7': 225.0, '8': 270.0, '9': 315.0};
const _padOrder = ['6', '3', '2', '1', '4', '7', '8', '9'];

class _DirPadPainter extends CustomPainter {
  final String? hot;
  _DirPadPainter(this.hot);
  @override
  void paint(Canvas c, Size s) {
    final m = Offset(s.width / 2, s.height / 2);
    final r = s.width / 2;
    final base = Rect.fromCircle(center: m, radius: r * .97);
    c.drawCircle(m, r * .97, Paint()..color = C.red.withAlpha(40)..maskFilter = MaskFilter.blur(BlurStyle.normal, r * .1));
    c.drawCircle(m, r * .97,
        Paint()..shader = const RadialGradient(colors: [Color(0xFF2E2E3A), Color(0xFF0F0F15)]).createShader(base));
    c.drawCircle(m, r * .97, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0x30FFFFFF));
    if (hot != null && hot != '5') {
      final a = _padAng[hot]! * math.pi / 180;
      final wedge = Path()..moveTo(m.dx, m.dy)..arcTo(base, a - math.pi / 8, math.pi / 4, false)..close();
      c.drawPath(wedge, Paint()..color = C.red.withAlpha(150));
    }
    final div = Paint()..color = const Color(0x14FFFFFF)..strokeWidth = 1.2;
    for (var i = 0; i < 8; i++) {
      final a = (i * 45 + 22.5) * math.pi / 180;
      final v = Offset(math.cos(a), math.sin(a));
      c.drawLine(m + v * r * .3, m + v * r * .97, div);
    }
    for (final d in _padOrder) {
      final a = _padAng[d]! * math.pi / 180;
      final p = m + Offset(math.cos(a), math.sin(a)) * r * .65;
      final u = r * .11;
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(a);
      c.drawPath(
          Path()..moveTo(-u * .6, -u * .9)..lineTo(u * .7, 0)..lineTo(-u * .6, u * .9),
          Paint()
            ..style = PaintingStyle.stroke..strokeWidth = u * .55
            ..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round
            ..color = hot == d ? Colors.white : const Color(0xB3FFFFFF));
      c.restore();
    }
    final neutral = hot == '5';
    c.drawCircle(
        m, r * .26,
        Paint()..shader = RadialGradient(colors: [neutral ? C.red2 : const Color(0xFF5A5A66), const Color(0xFF1A1A22)])
            .createShader(Rect.fromCircle(center: m, radius: r * .26)));
    c.drawCircle(m, r * .26, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = const Color(0x55FFFFFF));
    c.drawCircle(m, r * .07, Paint()..color = Colors.white70);
  }

  @override
  bool shouldRepaint(covariant _DirPadPainter o) => o.hot != hot;
}

/// Круглый джойстик: 8 направлений + нейтраль (центр).
class DirPad extends StatefulWidget {
  final ValueChanged<String> onDir;
  final double size;
  const DirPad({super.key, required this.onDir, this.size = 132});
  @override
  State<DirPad> createState() => _DirPadState();
}

class _DirPadState extends State<DirPad> {
  String? hot;

  String _hit(Offset p) {
    final r = widget.size / 2;
    final d = p - Offset(r, r);
    if (d.distance < r * .3) return '5';
    var a = math.atan2(d.dy, d.dx) * 180 / math.pi;
    if (a < 0) a += 360;
    return _padOrder[((a + 22.5) % 360) ~/ 45];
  }

  void _release() => Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => hot = null);
      });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTapDown: (e) {
          final d = _hit(e.localPosition);
          setState(() => hot = d);
          HapticFeedback.selectionClick();
          widget.onDir(d);
        },
        onTapUp: (_) => _release(),
        onTapCancel: _release,
        child: CustomPaint(size: Size.square(widget.size), painter: _DirPadPainter(hot)),
      );
}

// ============================================================================
// ПОЛНОЕ УПРАВЛЕНИЕ ИГР (по официальным раскладкам по умолчанию)
// ============================================================================
class Act {
  final String id, label, btn; // btn — PlayStation-имя кнопки ('' если отдельной кнопки нет)
  final String? key; // клавиша на клавиатуре (только если точно известна)
  final String? ico; // чьей иконкой рисовать, если не id
  final List<String> tokens; // что добавляется в комбо (пусто = [id])
  const Act(this.id, this.label, this.btn, {this.key, this.ico, this.tokens = const []});
}

const gameActs = <String, List<Act>>{
  'mk1': [
    Act('THROW', 'Throw', 'L1', key: 'SPACE'),
    Act('BL', 'Block', 'R2', key: 'O'),
    Act('KAMEO', 'Kameo', 'R1', key: ';'),
    Act('FLIP', 'Flip Stance', 'L2'),
    Act('DASH', 'Dash', '', tokens: ['6', '6']),
  ],
  'sf6': [
    Act('DI', 'Drive Impact', 'L1'),
    Act('PARRY', 'Drive Parry', 'L2'),
    Act('DR', 'Drive Rush', ''),
    Act('THROW', 'Throw', '', tokens: ['LP', '+', 'LK']),
    Act('DASH', 'Dash', '', tokens: ['6', '6']),
  ],
  't8': [
    Act('Heat', 'Heat', 'R1'),
    Act('RAGE', 'Rage Art', 'R2'),
    Act('STYLE', 'Special Style', 'L1'),
    Act('THROW1', 'Throw 1+3', '', ico: 'THROW', tokens: ['T1', '+', 'T3']),
    Act('THROW2', 'Throw 2+4', '', ico: 'THROW', tokens: ['T2', '+', 'T4']),
    Act('DASH', 'Dash', '', tokens: ['6', '6']),
  ],
};

/// Клавиша клавиатуры (SPACE, O, ;).
class KeyCapBtn extends StatelessWidget {
  final String label;
  final double size;
  const KeyCapBtn(this.label, {super.key, required this.size});
  @override
  Widget build(BuildContext context) => Container(
        height: size,
        constraints: BoxConstraints(minWidth: size),
        padding: EdgeInsets.symmetric(horizontal: size * .22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: C.surf2,
          borderRadius: BorderRadius.circular(size * .22),
          border: Border.all(color: const Color(0xFFC9C9D6), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x33C9C9D6), blurRadius: 6)],
        ),
        child: Text(
          label,
          style: GoogleFonts.barlow(fontSize: size * .36, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
        ),
      );
}

/// Вся нижняя панель ввода.
class ComboPad extends StatelessWidget {
  final String game;
  final ValueChanged<String> onAdd;
  final VoidCallback onBack, onPaste;
  const ComboPad({super.key, required this.game, required this.onAdd, required this.onBack, required this.onPaste});

  Widget _tool(Widget child, VoidCallback f) => Material(
        color: C.surf2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: C.line)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: f,
          child: SizedBox(width: 44, height: 38, child: Center(child: child)),
        ),
      );

  Widget _cap(String t) => SizedBox(
        width: 64,
        child: Text(
          t,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(color: C.sub, fontSize: 9, fontWeight: FontWeight.w700),
        ),
      );

  Widget _key(String t) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onAdd(t);
        },
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          buttonIcon(t, 40),
          const SizedBox(height: 3),
          _cap(t),
        ]),
      );

  /// Действие: на геймпаде — его физическая кнопка (R1/RB/R…), на клавиатуре — клавиша, иначе значок.
  Widget _act(Act a) {
    final dev = app.device;
    final Widget icon = (dev == 'kb' && a.key != null)
        ? KeyCapBtn(a.key!, size: 40)
        : (dev != 'kb' && a.btn.isNotEmpty)
            ? ShoulderBtn(a.btn, dev, size: 40)
            : AtkBtn(a.ico ?? a.id, size: 40);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        for (final t in (a.tokens.isEmpty ? [a.id] : a.tokens)) {
          onAdd(t);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [icon, const SizedBox(height: 3), _cap(a.label)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final faces = _btns[game] ?? _btns['sf6']!;
    final mot = _motions[game] ?? const <String>[];
    final acts = gameActs[game] ?? const <Act>[];
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(color: C.surf, border: Border(top: BorderSide(color: C.line))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // устройство: иконки меняются сразу везде
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final d in devs)
            GestureDetector(
              onTap: () => app.update(() => app.device = d.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: app.device == d.id ? const Color(0x22E10613) : Colors.transparent,
                  border: Border.all(color: app.device == d.id ? C.red2 : C.line),
                ),
                child: DevIcon(d.id, size: 26, col: app.device == d.id ? C.red2 : C.sub),
              ),
            ),
        ]),
        const SizedBox(height: 8),
        // джойстик + кнопки ударов
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          DirPad(onDir: onAdd),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: [for (final k in faces) _key(k)],
            ),
          ),
        ]),
        const SizedBox(height: 8),
        // движения + плечевые кнопки / действия игры (прокрутка вбок)
        SizedBox(
          height: 64,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final m in mot)
              Padding(padding: const EdgeInsets.only(right: 8), child: Center(child: Pill(m, onTap: () => onAdd(m)))),
            for (final a in acts) Padding(padding: const EdgeInsets.only(right: 12), child: _act(a)),
          ]),
        ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          for (final s in _seps)
            _tool(Text(s, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)), () => onAdd(s)),
          _tool(const Icon(Icons.backspace_outlined, size: 20), onBack),
          _tool(const Icon(Icons.content_paste_rounded, size: 20), onPaste),
        ]),
      ]),
    );
  }
}

class ComboStudio extends StatefulWidget {
  final String game, char;
  const ComboStudio({super.key, required this.game, required this.char});
  @override
  State<ComboStudio> createState() => _ComboStudioState();
}

class _ComboStudioState extends State<ComboStudio> {
  late String game = widget.game, char = widget.char;
  final title = TextEditingController(), dmg = TextEditingController();
  final tags = <String>{};
  var steps = <String>[];
  int cur = 0; // курсор: вставка идёт перед steps[cur]
  final _undo = <List<String>>[], _redo = <List<String>>[];

  @override
  void dispose() {
    title.dispose();
    dmg.dispose();
    super.dispose();
  }

  bool _isDir(String s) => RegExp(r'^[1-9]+$').hasMatch(s);
  bool _isBtn(String s) => !_isDir(s) && !_seps.contains(s);
  void _snap() {
    _undo.add([...steps]);
    _redo.clear();
  }

  void _set(List<String> s, int c) => setState(() {
        steps = s;
        cur = c;
      });

  void add(String t) {
    HapticFeedback.selectionClick();
    _snap();
    final s = [...steps];
    var c = cur;
    // 2 → 3 → 6 склеивается в движение 236
    if (_isDir(t) && t.length == 1 && t != '5' && c > 0 && _isDir(s[c - 1]) && s[c - 1] != '5') {
      s[c - 1] = s[c - 1] + t;
      return _set(s, c);
    }
    // после кнопки новое действие начинается с авто-разделителя «>»
    if ((_isDir(t) || _starters.contains(t)) && c > 0 && _isBtn(s[c - 1])) {
      s.insert(c++, '>');
    }
    s.insert(c++, t);
    _set(s, c);
  }

  void back() {
    if (cur == 0) return;
    _snap();
    final s = [...steps];
    if (_isDir(s[cur - 1]) && s[cur - 1].length > 1) {
      s[cur - 1] = s[cur - 1].substring(0, s[cur - 1].length - 1);
      return _set(s, cur);
    }
    s.removeAt(cur - 1);
    _set(s, cur - 1);
  }

  void undo() {
    if (_undo.isEmpty) return;
    _redo.add([...steps]);
    final p = _undo.removeLast();
    _set(p, p.length);
  }

  void redo() {
    if (_redo.isEmpty) return;
    _undo.add([...steps]);
    final n = _redo.removeLast();
    _set(n, n.length);
  }

  /// Вставка текстом: «236HP > j.HK» → токены.
  Future<void> paste() async {
    final raw = ((await Clipboard.getData('text/plain'))?.text ?? '').trim();
    if (raw.isEmpty) return;
    final out = <String>[];
    for (final w in raw.split(RegExp(r'[\s,]+'))) {
      var t = w;
      if (t.isEmpty) continue;
      if (t.startsWith('j.') && t.length > 2) {
        out.add('j.');
        t = t.substring(2);
      }
      final m = RegExp(r'^([1-9]+)([A-Za-z][A-Za-z0-9]*)$').firstMatch(t);
      if (m != null) {
        out..add(m[1]!)..add(m[2]!);
      } else {
        out.add(t);
      }
    }
    _snap();
    _set([...steps]..insertAll(cur, out), cur + out.length);
  }

  void publish() {
    if (title.text.trim().isEmpty || steps.isEmpty) {
      toast(context, tr('fill'));
      return;
    }
    app.update(() => app.combos.insert(
        0,
        Combo(
          id: 'c_u_${DateTime.now().microsecondsSinceEpoch}', gameId: game, charId: char,
          title: title.text.trim(), notation: steps.join(' '), tags: tags.toList(),
          damage: int.tryParse(dmg.text) ?? 0, views: 0, likes: 0, author: meName, updated: DateTime.now(),
        )));
    toast(context, '${tr('publish')} ✓');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Rx((c) {
        final bar = Container(width: 2.5, height: 30, margin: const EdgeInsets.symmetric(horizontal: 2), color: C.red2);
        final strip = <Widget>[
          for (var i = 0; i < steps.length; i++) ...[
            if (cur == i) bar,
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => setState(() => cur = cur == i + 1 ? i : i + 1),
              child: Padding(padding: const EdgeInsets.all(3), child: NotationRow(steps[i], size: 30)),
            ),
          ],
          if (cur >= steps.length) bar,
        ];
        return Scaffold(
          appBar: AppBar(title: Text(tr('newCombo')), actions: [
            IconButton(onPressed: _undo.isEmpty ? null : undo, icon: const Icon(Icons.undo)),
            IconButton(onPressed: _redo.isEmpty ? null : redo, icon: const Icon(Icons.redo)),
            TextButton(
                onPressed: publish,
                child: Text(tr('publish'), style: const TextStyle(color: C.red2, fontWeight: FontWeight.w800))),
          ]),
          body: Column(children: [
            Expanded(
              child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), children: [
                GameCharPicker(
                  game: game, char: char,
                  onChanged: (g, ch) => setState(() {
                    if (g != game) {
                      steps = [];
                      cur = 0;
                      _undo.clear();
                      _redo.clear();
                    }
                    game = g;
                    char = ch;
                  }),
                ),
                const SizedBox(height: 12),
                TextField(controller: title, decoration: deco(tr('title'))),
                const SizedBox(height: 12),
                CuCard(
                  child: SizedBox(
                    width: double.infinity,
                    child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 4, children: strip),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(controller: dmg, keyboardType: TextInputType.number, decoration: deco(tr('damage'))),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final t in _quickTags)
                    Pill('#$t', selected: tags.contains(t), filled: true,
                        onTap: () => setState(() => tags.contains(t) ? tags.remove(t) : tags.add(t))),
                ]),
              ]),
            ),
            ComboPad(game: game, onAdd: add, onBack: back, onPaste: paste),
          ]),
        );
      });
}
