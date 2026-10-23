import 'package:flutter/material.dart';
import '../../models/game.dart';
import '../../models/combo.dart';
import '../../models/guide.dart';

const meName = 'Yusuf';

const _tpl = <String, List<List<String>>>{
  'mk1': [
    ['BnB Starter', 'FP BP FK > 2 BK', 'BnB,Simple,Mid Screen', '264'],
    ['Corner Carry', 'BP FK BK > 236 FP', 'Corner,Meter,Medium', '310'],
    ['Anti-Air Punish', 'j.FK > FP BP > 214 BK', 'AA,Punish,Easy', '228'],
  ],
  't8': [
    ['Wall Carry', 'df T2 > T1 T2 T3', 'Wall,Carry,Easy', '58'],
    ['Heat Launcher', 'f T2 > Heat > T1 T2 T3 T4', 'Heat,Launcher,Medium', '72'],
    ['Pressure String', 'T1 T2 T3', 'Pressure,Simple,Low', '31'],
  ],
  'sf6': [
    ['Bread & Butter', '2 MK > 236 MK', 'BnB,Simple,Mid Screen', '1800'],
    ['Drive Rush Confirm', 'MP > DR > 2 MK > 623 HP', 'Drive,Meter,Medium', '2450'],
    ['Super Art', '2 MK > 236 MK > 236 236 HP', 'SA,Meter,Hard', '3100'],
  ],
};

const _authors = ['Kazuya_M', 'ComboKing', 'Rin', 'Alex_FGC', 'Sora', meName];

// ───────────────────────────── APP STATE ─────────────────────────────
class AppState extends ChangeNotifier {
  String lang = 'ru';
  String device = '';
  bool premium = false;
  final saved = <String>{};
  final liked = <String>{};
  final reported = <String>{};
  final reports = <Map<String, String>>[]; // жалобы; потом отправлять на бэкенд
  final combos = <Combo>[];
  final guides = <Guide>[];

  bool report(String id, String reason) {
    if (reported.contains(id)) return false;
    update(() {
      reported.add(id);
      reports.add({'id': id, 'reason': reason, 'by': meName, 'at': DateTime.now().toIso8601String()});
    });
    return true;
  }

  AppState() {
    _seed();
  }

  void update(VoidCallback f) {
    f();
    notifyListeners();
  }

  void toggle(Set<String> s, String id) => update(() {
        if (!s.remove(id)) s.add(id);
      });

  void _seed() {
    for (final g in games) {
      for (var ci = 0; ci < g.chars.length; ci++) {
        final ids = <String>[];
        final tp = _tpl[g.id]!;
        for (var ti = 0; ti < tp.length; ti++) {
          final t = tp[ti];
          final id = 'c_${g.id}_${ci}_$ti';
          ids.add(id);
          combos.add(Combo(
            id: id, gameId: g.id, charId: g.chars[ci], title: t[0], notation: t[1],
            tags: t[2].split(','),
            damage: int.parse(t[3]) + ((ci * 7 + ti * 11) % 25) * (g.id == 'sf6' ? 10 : 1),
            views: 300 + (ci * 913 + ti * 271) % 9000,
            likes: 10 + (ci * 31 + ti * 17) % 400,
            author: _authors[(ci + ti) % _authors.length],
            updated: DateTime(2026, 10, 1 + (ci + ti) % 8),
          ));
        }
        const titles = ['Ranked Guide', 'Pro Strategy'];
        for (var gi = 0; gi < 2; gi++) {
          guides.add(Guide(
            id: 'g_${g.id}_${ci}_$gi', gameId: g.id, charId: g.chars[ci], title: titles[gi],
            author: _authors[(ci + gi + 2) % _authors.length],
            updated: DateTime(2026, 10, 2 + (ci + gi) % 7),
            likes: 5 + (ci * 13 + gi * 29) % 300,
            body: '# Overview\nShort breakdown of ${g.chars[ci]}: neutral, pressure and punish.\n\n'
                '[COMBO:${ids[0]}]\n\n# Pro tip\nStart rounds with safe pokes and confirm with the combo below.\n\n'
                '[COMBO:${ids[gi + 1]}]',
          ));
        }
      }
    }
  }
}

final app = AppState();

// ───────────────────────────── HELPERS ─────────────────────────────
String fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
String compact(int n) => n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}K' : '$n';

/// Переход: плавное появление + лёгкий сдвиг снизу.
void go(BuildContext c, Widget w) => Navigator.of(c).push(PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (_, __, ___) => w,
      transitionsBuilder: (_, a, __, child) {
        final cv = CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: cv,
          child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, .05), end: Offset.zero).animate(cv),
              child: child),
        );
      },
    ));

void toast(BuildContext c, String m) => ScaffoldMessenger.of(c)
  ..hideCurrentSnackBar()
  ..showSnackBar(SnackBar(
    content: Text(m),
    behavior: SnackBarBehavior.floating,
    backgroundColor: const Color(0xF21C1C26),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  ));
