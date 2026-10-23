import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_i18n.dart';
import '../../core/state/app_state.dart';
import '../../models/game.dart';
import '../../models/news_item.dart';
import '../../widgets/common/cu_card.dart';

// ───────────────────────────── NEWS ─────────────────────────────
class NewsTab extends StatefulWidget {
  const NewsTab({super.key});
  @override
  State<NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<NewsTab> {
  String? game;
  @override
  Widget build(BuildContext context) => Rx((c) {
        final list = newsList.where((n) => game == null || n.game == game).toList();
        return SafeArea(
          bottom: false,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
            Text(tr('news'), style: hd(26)),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView(scrollDirection: Axis.horizontal, children: [
                Pill('ALL', selected: game == null, filled: true, onTap: () => setState(() => game = null)),
                for (final g in games) ...[
                  const SizedBox(width: 8),
                  Pill(g.tag, selected: game == g.id, filled: true, onTap: () => setState(() => game = g.id)),
                ],
              ]),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < list.length; i++)
              Appear(
                i: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: CuCard(
                    onTap: () => go(c, NewsScreen(list[i])),
                    child: Row(children: [
                      Container(
                        width: 70, height: 70,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            gradient: LinearGradient(colors: gameOf(list[i].game).colors)),
                        child: Icon(gameOf(list[i].game).icon, color: Colors.white70),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(gameOf(list[i].game).tag,
                              style: const TextStyle(color: C.red2, fontWeight: FontWeight.w800, fontSize: 12)),
                          const SizedBox(height: 2),
                          Text(list[i].title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(fmt(list[i].date), style: const TextStyle(color: C.sub, fontSize: 12)),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
          ]),
        );
      });
}

class NewsScreen extends StatelessWidget {
  final NewsItem n;
  const NewsScreen(this.n, {super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(gameOf(n.game).tag)),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Container(
            height: 170,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18), gradient: LinearGradient(colors: gameOf(n.game).colors)),
            child: Icon(gameOf(n.game).icon, size: 80, color: Colors.white54),
          ),
          const SizedBox(height: 16),
          Text(n.title, style: hd(26)),
          const SizedBox(height: 6),
          Text(fmt(n.date), style: const TextStyle(color: C.sub)),
          const SizedBox(height: 14),
          Text(n.body, style: const TextStyle(fontSize: 15, height: 1.5)),
        ]),
      );
}
