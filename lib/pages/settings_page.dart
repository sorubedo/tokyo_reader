import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokyo_palette.dart';
import '../core/tokyo_theme.dart';
import '../providers/theme_provider.dart';

/// 设置页：目前仅提供主题选择。
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final palette = Theme.of(context).extension<TokyoPalette>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              '外观',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: palette.comment,
              ),
            ),
          ),
          RadioGroup<ThemeVariant>(
            groupValue: themeProvider.currentVariant,
            onChanged: (variant) {
              if (variant != null) {
                context.read<ThemeProvider>().select(variant);
              }
            },
            child: Column(
              children: [
                for (final variant in ThemeVariant.values)
                  RadioListTile<ThemeVariant>(
                    key: ValueKey('theme_${variant.name}'),
                    value: variant,
                    title: Text(variant.label),
                    subtitle: Text(variant.description),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
