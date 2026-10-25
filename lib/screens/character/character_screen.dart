import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_i18n.dart';
import '../../core/state/app_state.dart';
import '../../core/social/cu_social.dart';
import '../../models/game.dart';
import '../../models/combo.dart';
import '../../models/guide.dart';
import '../../widgets/common/cu_card.dart';
import '../../widgets/common/logo.dart';
import '../../widgets/common/buttons.dart';
import '../../widgets/common/fields.dart';
import '../../widgets/common/embers.dart';
import '../../widgets/notation/notation_row.dart';
import '../guide/guide_screen.dart';
import '../studio/combo_studio.dart';

// ───────────────────────────── CHARACTER (Комбо / Сборки) ─────────────────────────────
class CharacterScreen extends StatefulWidget {
  final Game g;
  final String name;
  const CharacterScreen(this.g, this.name, {super.key});
  @override
  State<CharacterScreen> createState() => _CharacterScreenState();
}

class _CharacterScreenState extends State<CharacterScreen> {
  int tab = 0;
  @override
  Widget build(BuildContext context) => Rx((c) {
        final g = widget.g, name = widget.name;
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                  center: Alignment(1, -1), radius: 1.2,
                  colors: [Color(0xFF2A0508), C.bg], stops: [0, .6]),
            ),
            child: ListView(padding: const EdgeInsets.only(bottom: 48), children: [
              CharHero(g, name),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  children: [
                    for (final d in devs)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Pill(devName(d.id),
                            selected: app.device == d.id, glow: C.cyan,
                            onTap: () => app.update(() => app.device = d.id)),
                      ),
                  ],
                ),
              ),
              TabSwitch(tab: tab, labels: [tr('combos'), tr('builds')], onChanged: (v) => setState(() => tab = v)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                transitionBuilder: (ch, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(.08, 0), end: Offset.zero).animate(a),
                      child: ch),
                ),
                child: KeyedSubtree(
                  key: ValueKey(tab),
                  child: tab == 0 ? ComboList(g, name) : BuildList(g, name),
                ),
              ),
            ]),
          ),
        );
      });
}

/// Hero-шапка персонажа: пульсирующее свечение, полосы, контурное имя, искры, стеклянные кнопки.
class CharHero extends StatefulWidget {
  final Game g;
  final String name;
  const CharHero(this.g, this.name, {super.key});
  @override
  State<CharHero> createState() => _CharHeroState();
}

class _CharHeroState extends State<CharHero> with SingleTickerProviderStateMixin {
  late final AnimationController ctl =
      AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  @override
  void dispose() {
    ctl.dispose();
    super.dispose();
  }

  Widget chip(String v, String l) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
                color: const Color(0x14FFFFFF), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: C.line)),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '$v ', style: const TextStyle(color: C.cyan, fontWeight: FontWeight.w700, fontSize: 12)),
              TextSpan(text: l, style: const TextStyle(color: C.text, fontSize: 12)),
            ])),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final g = widget.g, name = widget.name;
    final top = MediaQuery.of(context).padding.top;
    final accent = g.colors[1];
    final cs = app.combos.where((x) => x.gameId == g.id && x.charId == name).toList();
    final nG = app.guides.where((x) => x.gameId == g.id && x.charId == name).length;
    final views = cs.fold<int>(0, (s, x) => s + x.views);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: SizedBox(
        height: 200 + top,
        child: Stack(children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: const Alignment(-.6, -1), end: const Alignment(.6, 1),
                    colors: [Color.lerp(accent, Colors.black, .82)!, const Color(0xFF0B0B11)],
                    stops: const [0, .7]),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: ctl,
            builder: (_, __) => Positioned(
              right: -60, top: -40,
              child: Transform.scale(
                scale: 1 + .08 * math.sin(ctl.value * 2 * math.pi),
                child: Container(
                  width: 340, height: 340,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                        colors: [accent.withAlpha(215), accent.withAlpha(64), Colors.transparent],
                        stops: const [0, .45, .7]),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: StripesPainter())),
          Positioned(
            right: -14, top: 70 + top * .3,
            child: RotatedBox(
              quarterTurns: 1,
              child: Text(
                name.toUpperCase(),
                softWrap: false,
                style: GoogleFonts.barlowCondensed(
                  fontSize: 120, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, letterSpacing: 4,
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = 1.5
                    ..color = const Color(0x24FFFFFF),
                ),
              ),
            ),
          ),
          Positioned.fill(child: Embers(ctl, Color.lerp(accent, Colors.white, .3)!)),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [C.bg, Color(0x8C08080C), Colors.transparent], stops: [.02, .45, 1]),
              ),
            ),
          ),
          Positioned(
            left: 16, right: 16, top: top + 10,
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              GlassBtn(Icons.arrow_back_rounded, () => Navigator.pop(context)),
              const HexLogo(),
              GlassBtn(Icons.add_rounded, () {
                if (requireAuth(context)) go(context, ComboStudio(game: g.id, char: name));
              }),
            ]),
          ),
          Positioned(
            left: 18, right: 18, bottom: 12,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(g.name, style: const TextStyle(color: C.red2, letterSpacing: 3, fontWeight: FontWeight.w700, fontSize: 11)),
              ShaderMask(
                shaderCallback: (r) => const LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFFF9AA0)], stops: [.4, 1],
                ).createShader(r),
                child: Text(name.toUpperCase(), style: hd(36, color: Colors.white, height: .95, ls: 1)),
              ),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 8, children: [
                chip('${cs.length}', tr('combos').toLowerCase()),
                chip('$nG', tr('builds').toLowerCase()),
                chip(compact(views), tr('views').toLowerCase()),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class ComboList extends StatefulWidget {
  final Game g;
  final String char;
  const ComboList(this.g, this.char, {super.key});
  @override
  State<ComboList> createState() => _ComboListState();
}

class _ComboListState extends State<ComboList> {
  String q = '';
  int mode = 0; // 0 popular, 1 new, 2 mine
  String? tag;

  void _filter(BuildContext c, List<Combo> base) {
    final tags = {for (final x in base) ...x.tags}.toList()..sort();
    showModalBottomSheet(
      context: c,
      backgroundColor: C.surf,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('filter'), style: hd(20)),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final t in tags)
              Pill('#$t', selected: tag == t, filled: true, onTap: () {
                setState(() => tag = tag == t ? null : t);
                Navigator.pop(ctx);
              }),
          ]),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Rx((c) {
        final base = app.combos.where((x) => x.gameId == widget.g.id && x.charId == widget.char).toList();
        var list = [...base];
        final ql = q.toLowerCase();
        if (ql.isNotEmpty) {
          list = list
              .where((x) =>
                  x.title.toLowerCase().contains(ql) ||
                  x.notation.toLowerCase().contains(ql) ||
                  x.tags.any((t) => t.toLowerCase().contains(ql)))
              .toList();
        }
        if (tag != null) list = list.where((x) => x.tags.contains(tag)).toList();
        if (mode == 2) list = list.where((x) => x.author == meName).toList();
        list.sort(mode == 1
            ? (a, b) => b.updated.compareTo(a.updated)
            : (a, b) => b.views.compareTo(a.views));
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(children: [
            SearchField('${tr('title')} / ${tr('combos')}…', (v) => setState(() => q = v)),
            const SizedBox(height: 8),
            SizedBox(
              height: 36,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                Pill(tag == null ? tr('filter') : '#$tag', selected: true, filled: true, onTap: () => _filter(c, base)),
                const SizedBox(width: 8),
                Pill(tr('popular'), selected: mode == 0, onTap: () => setState(() => mode = 0)),
                const SizedBox(width: 8),
                Pill(tr('fresh'), selected: mode == 1, onTap: () => setState(() => mode = 1)),
                const SizedBox(width: 8),
                Pill(tr('mine'), selected: mode == 2, onTap: () => setState(() => mode = 2)),
              ]),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < list.length; i++)
              Appear(i: i > 6 ? 6 : i, child: ComboCard(list[i], key: ValueKey(list[i].id))),
          ]),
        );
      });
}

void showReport(BuildContext c, Combo x) {
  if (app.reported.contains(x.id)) {
    toast(c, tr('reportDup'));
    return;
  }
  showModalBottomSheet(
    context: c,
    backgroundColor: C.surf,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(tr('report'), style: hd(20)),
        const SizedBox(height: 4),
        Text(tr('reportWhy'), style: const TextStyle(color: C.sub)),
        const SizedBox(height: 8),
        for (final r in tr('reasons').split('|'))
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag_outlined, color: C.red2),
            title: Text(r, style: const TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              app.report(x.id, r);
              Navigator.pop(ctx);
              toast(c, tr('reportSent'));
            },
          ),
      ]),
    ),
  );
}

// ───────────── 2) КОМПАКТНАЯ КАРТОЧКА КОМБО (~130px вместо ~230px) ─────────────
class ComboCard extends StatefulWidget {
  final Combo x;
  const ComboCard(this.x, {super.key});
  @override
  State<ComboCard> createState() => _ComboCardState();
}

class _ComboCardState extends State<ComboCard> {
  bool open = false;
  @override
  Widget build(BuildContext context) => Rx((c) {
        final x = widget.x;
        final liked = app.liked.contains(x.id);
        final saved = app.saved.contains(x.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CuCard(
            accent: true,
            radius: 16,
            padding: const EdgeInsets.fromLTRB(12, 10, 6, 4),
            onTap: () => setState(() => open = !open),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: NotationRow(x.notation, size: 26)),
                const SizedBox(width: 8),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: x.damage.toDouble()),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (_, v, __) => Text(
                    '${v.round()}${x.gameId == 'mk1' ? '%' : ''}',
                    style: hd(24, color: C.cyan).copyWith(shadows: const [Shadow(color: Color(0x9900E5FF), blurRadius: 14)]),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(
                  child: Text(x.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                const Icon(Icons.visibility_outlined, size: 13, color: C.sub),
                const SizedBox(width: 3),
                Text(compact(x.views), style: const TextStyle(color: C.sub, fontSize: 11)),
                const SizedBox(width: 6),
              ]),
              const SizedBox(height: 4),
              SizedBox(
                height: 22,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final t in x.tags)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: const Color(0x29E10613), borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x4DE10613))),
                      child: Text('#$t', style: const TextStyle(color: Color(0xFFFF7A82), fontSize: 11)),
                    ),
                ]),
              ),
              Row(children: [
                Expanded(
                  child: AuthorChip(
                    author: AuthorRef(
                      id: 'u_${x.author}',
                      name: x.author,
                      handle: x.author.toLowerCase(),
                    ),
                  ),
                ),
                LikeButton(itemId: x.id, baseCount: x.likes),
                SaveButton(itemId: x.id),
                if (x.author != meName)
                  IconTap(app.reported.contains(x.id) ? Icons.flag : Icons.flag_outlined,
                      app.reported.contains(x.id) ? C.gold : C.sub, () => showReport(c, x)),
              ]),
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: open
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(0, 6, 6, 8),
                        child: Container(
                          height: 110, width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: C.line),
                            gradient: const RadialGradient(
                                center: Alignment(.4, -.4), radius: 1.1,
                                colors: [Color(0xFF5A0A10), Color(0xFF0C0C12)]),
                          ),
                          child: const Center(child: PulsePlay()),
                        ),
                      )
                    : const SizedBox(width: double.infinity),
              ),
            ]),
          ),
        );
      });
}

class BuildList extends StatefulWidget {
  final Game g;
  final String char;
  const BuildList(this.g, this.char, {super.key});
  @override
  State<BuildList> createState() => _BuildListState();
}

class _BuildListState extends State<BuildList> {
  String q = '';
  @override
  Widget build(BuildContext context) => Rx((c) {
        final list = app.guides
            .where((x) =>
                x.gameId == widget.g.id &&
                x.charId == widget.char &&
                x.author.toLowerCase().contains(q.toLowerCase()))
            .toList()
          ..sort((a, b) => b.updated.compareTo(a.updated));
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Column(children: [
            SearchField(tr('searchAuthor'), (v) => setState(() => q = v)),
            const SizedBox(height: 14),
            for (var i = 0; i < list.length; i++) Appear(i: i, child: GuideTile(list[i])),
          ]),
        );
      });
}

class GuideTile extends StatelessWidget {
  final Guide g;
  const GuideTile(this.g, {super.key});
  @override
  Widget build(BuildContext context) => Rx((c) {
        final game = gameOf(g.gameId);
        final liked = app.liked.contains(g.id);
        final saved = app.saved.contains(g.id);
        final initials = g.title.split(' ').where((w) => w.isNotEmpty).map((w) => w[0]).take(2).join().toUpperCase();
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CuCard(
            accent: true,
            padding: const EdgeInsets.all(14),
            onTap: () => go(c, GuideScreen(g)),
            child: Row(children: [
              Container(
                width: 74, height: 74, alignment: Alignment.center,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [game.colors[1], game.colors[0]])),
                child: Text(initials, style: hd(22, color: Colors.white70)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  const SizedBox(height: 2),
                  Text('${g.charId} · ${g.author}', maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: C.red2, fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('${g.comboCount} ${tr('combos').toLowerCase()} · ${tr('updated')}: ${fmt(g.updated)}',
                      style: const TextStyle(color: C.sub, fontSize: 11)),
                ]),
              ),
              Column(children: [
                IconTap(liked ? Icons.favorite : Icons.favorite_border, liked ? C.red : C.sub,
                    () => app.toggle(app.liked, g.id), label: '${g.likes + (liked ? 1 : 0)}'),
                IconTap(saved ? Icons.bookmark : Icons.bookmark_border, saved ? C.red : C.sub,
                    () => app.toggle(app.saved, g.id)),
              ]),
            ]),
          ),
        );
      });
}
