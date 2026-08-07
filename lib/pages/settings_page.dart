import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/tokyo_palette.dart';
import '../core/tokyo_theme.dart';
import '../providers/global_font_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/adwaita_components.dart';
import 'global_font_selection_page.dart';

/// 设置页：管理主题与全局字体。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final fontProvider = context.watch<GlobalFontProvider>();
    return Scaffold(
      appBar: const AppHeaderBar(title: '设置', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          PreferencesGroup(
            key: const ValueKey('appearance_preferences_group'),
            title: '外观',
            children: [
              ComboRow<ThemeVariant>(
                key: const ValueKey('theme_combo_row'),
                title: '主题变体',
                subtitle: '当前主题变体：${themeProvider.currentVariant.label}',
                value: themeProvider.currentVariant,
                options: [
                  for (final variant in ThemeVariant.values)
                    ComboOption<ThemeVariant>(
                      value: variant,
                      label: variant.label,
                      description: variant.description,
                      swatch: _themeSwatch(variant),
                    ),
                ],
                onChanged: (variant) {
                  context.read<ThemeProvider>().select(variant);
                },
              ),
            ],
          ),
          PreferencesGroup(
            key: const ValueKey('font_preferences_group'),
            title: '字体',
            children: [
              ActionRow(
                key: const ValueKey('global_font_setting'),
                leading: const Icon(Icons.font_download_outlined),
                title: '全局字体',
                subtitle: _fontDescription(fontProvider),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _chooseFont(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fontDescription(GlobalFontProvider provider) {
    final label = provider.selection.displayLabel;
    return provider.isUsingFallback ? '$label（暂时使用系统默认）' : label;
  }

  List<Color> _themeSwatch(ThemeVariant variant) {
    final palette = variant.buildTheme().extension<TokyoPalette>()!;
    return [palette.window, palette.accent, palette.warning];
  }

  Future<void> _chooseFont() async {
    await Navigator.of(
      context,
    ).push(appPageRoute(const GlobalFontSelectionPage()));
  }
}
