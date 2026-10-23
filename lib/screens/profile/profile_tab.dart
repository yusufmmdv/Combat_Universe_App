import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/i18n/app_i18n.dart';
import '../../core/state/app_state.dart';
import '../../widgets/common/cu_card.dart';
import '../../widgets/common/logo.dart';
import '../my_stuff/my_stuff_screen.dart';
import '../settings/settings_screen.dart';
import '../premium/premium_screen.dart';

// ───────────────────────────── PROFILE / SETTINGS / PREMIUM ─────────────────────────────
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});
  @override
  Widget build(BuildContext context) => Rx((c) {
        final mine = app.combos.where((x) => x.author == meName).toList();
        final likes = mine.fold<int>(0, (s, x) => s + x.likes);
        final views = mine.fold<int>(0, (s, x) => s + x.views);
        Widget stat(String v, String l) => Expanded(
              child: Column(children: [
                Text(v, style: hd(20)),
                const SizedBox(height: 2),
                Text(l, textAlign: TextAlign.center, style: const TextStyle(color: C.sub, fontSize: 11)),
              ]),
            );
        Widget menu(IconData i, Color col, String t, VoidCallback f) => ListTile(
              onTap: f,
              leading: Icon(i, color: col),
              title: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: const Icon(Icons.chevron_right, color: C.sub),
            );
        return SafeArea(
          bottom: false,
          child: ListView(padding: const EdgeInsets.fromLTRB(16, 24, 16, 24), children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: app.premium ? C.gold : C.red, width: 2)),
                child: const Avatar(meName, size: 96),
              ),
            ),
            const SizedBox(height: 12),
            Center(child: Text(meName, style: hd(24))),
            const Center(child: Text('@yusuf', style: TextStyle(color: C.sub))),
            const SizedBox(height: 8),
            const Center(child: Text('FGC grinder · MK1 / T8 / SF6', style: TextStyle(color: C.sub))),
            const SizedBox(height: 20),
            CuCard(
              child: Row(children: [
                stat('128', tr('following')),
                stat('2.4K', tr('followers')),
                stat(compact(likes), tr('likes')),
                stat(compact(views), tr('views')),
              ]),
            ),
            const SizedBox(height: 14),
            CuCard(
              padding: EdgeInsets.zero,
              child: Column(children: [
                menu(Icons.folder_special_outlined, C.text, tr('myStuff'), () => go(c, const MyStuffScreen())),
                const Divider(height: 1, color: C.line),
                menu(Icons.star_rounded, C.gold, tr('premium'), () => go(c, const PremiumScreen())),
                const Divider(height: 1, color: C.line),
                menu(Icons.settings_outlined, C.text, tr('settings'), () => go(c, const SettingsScreen())),
              ]),
            ),
          ]),
        );
      });
}
