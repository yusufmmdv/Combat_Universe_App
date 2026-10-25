import 'package:flutter/material.dart';
import '../../core/auth/cu_auth.dart';
import '../../core/state/app_state.dart';
import '../my_stuff/my_stuff_screen.dart';
import '../premium/premium_screen.dart';

// ───────────────────────────── PROFILE TAB ─────────────────────────────
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(
      onMyContent: () => go(context, const MyStuffScreen()),
      onPremium: () => go(context, const PremiumScreen()),
    );
  }
}
