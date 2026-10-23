import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_i18n.dart';
import '../../core/state/app_state.dart';
import '../../widgets/common/cu_card.dart';
import '../../widgets/notation/notation_row.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) => Rx((c) => Scaffold(
        appBar: AppBar(title: Text(tr('settings'))),
        body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
          Text(tr('language'), style: hd(18)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final e in langs.entries)
              Pill(e.value, selected: app.lang == e.key, filled: true, onTap: () => app.update(() => app.lang = e.key)),
          ]),
          const SizedBox(height: 24),
          Text(tr('device'), style: hd(18)),
          const SizedBox(height: 10),
          for (final d in devs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: CuCard(
                selected: app.device == d.id,
                onTap: () => app.update(() => app.device = d.id),
                child: Row(children: [
                  DevIcon(d.id, size: 46, col: app.device == d.id ? C.red2 : C.sub),
                  const SizedBox(width: 12),
                  Expanded(child: Text(devName(d.id), style: const TextStyle(fontWeight: FontWeight.w800))),
                  const NotationRow('FP BP FK BK', size: 24),
                ]),
              ),
            ),
        ]),
      ));
}
