import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class SearchField extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const SearchField(this.hint, this.onChanged, {super.key});
  @override
  Widget build(BuildContext context) =>
      TextField(onChanged: onChanged, decoration: deco(hint, icon: Icons.search));
}
