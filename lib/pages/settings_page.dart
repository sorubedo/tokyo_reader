import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/tokyo_palette.dart';
import '../core/tokyo_theme.dart';
import '../models/global_font.dart';
import '../providers/global_font_provider.dart';
import '../providers/theme_provider.dart';
import 'font_family_picker_page.dart';

enum _FontAction { systemDefault, imported, google, system }

/// 设置页：管理主题与全局字体。
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _selectingFont = false;

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final fontProvider = context.watch<GlobalFontProvider>();
    final palette = Theme.of(context).extension<TokyoPalette>()!;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _SectionTitle(label: '外观', palette: palette),
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
          const Divider(height: 1),
          _SectionTitle(label: '字体', palette: palette),
          ListTile(
            key: const ValueKey('global_font_setting'),
            leading: const Icon(Icons.font_download_outlined),
            title: const Text('全局字体'),
            subtitle: Text(_fontDescription(fontProvider)),
            trailing: _selectingFont
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _selectingFont ? null : () => _chooseFont(fontProvider),
          ),
        ],
      ),
    );
  }

  String _fontDescription(GlobalFontProvider provider) {
    final selection = provider.selection;
    final label = switch (selection.source) {
      GlobalFontSource.systemDefault => '系统默认',
      GlobalFontSource.system => selection.family ?? '系统默认',
      GlobalFontSource.imported => selection.displayName ?? '导入字体',
      GlobalFontSource.google => selection.family ?? 'Google Fonts',
    };
    return provider.isUsingFallback ? '$label（暂时使用系统默认）' : label;
  }

  Future<void> _chooseFont(GlobalFontProvider provider) async {
    final action = await showModalBottomSheet<_FontAction>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.settings_backup_restore),
                title: const Text('系统默认'),
                onTap: () => Navigator.pop(context, _FontAction.systemDefault),
              ),
              if (provider.supportsImportedFonts)
                ListTile(
                  leading: const Icon(Icons.upload_file),
                  title: const Text('从本地导入'),
                  onTap: () => Navigator.pop(context, _FontAction.imported),
                ),
              if (provider.supportsGoogleFonts)
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('Google Fonts'),
                  onTap: () => Navigator.pop(context, _FontAction.google),
                ),
              if (provider.supportsSystemFonts)
                ListTile(
                  leading: const Icon(Icons.computer),
                  title: const Text('系统字体'),
                  onTap: () => Navigator.pop(context, _FontAction.system),
                ),
            ],
          ),
        );
      },
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _FontAction.systemDefault:
        await _runFontAction(provider.selectSystemDefault);
      case _FontAction.imported:
        await _importFont(provider);
      case _FontAction.google:
        await _selectGoogleFont(provider);
      case _FontAction.system:
        await _selectSystemFont(provider);
    }
  }

  Future<void> _importFont(GlobalFontProvider provider) async {
    const fontTypes = XTypeGroup(
      label: '字体',
      extensions: ['ttf', 'otf'],
      webWildCards: ['.ttf', '.otf'],
    );
    final file = await openFile(acceptedTypeGroups: const [fontTypes]);
    if (file == null || !mounted) return;
    await _runFontAction(
      () async => provider.selectImported(
        bytes: await file.readAsBytes(),
        fileName: file.name,
      ),
    );
  }

  Future<void> _selectGoogleFont(GlobalFontProvider provider) async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => FontFamilyPickerPage(
          title: 'Google Fonts',
          loadFamilies: () async {
            final families = GoogleFonts.asMap().keys.toList()
              ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
            return families;
          },
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await _runFontAction(() => provider.selectGoogle(selected));
  }

  Future<void> _selectSystemFont(GlobalFontProvider provider) async {
    final selected = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => FontFamilyPickerPage(
          title: '系统字体',
          loadFamilies: provider.listSystemFonts,
        ),
      ),
    );
    if (selected == null || !mounted) return;
    await _runFontAction(() => provider.selectSystem(selected));
  }

  Future<void> _runFontAction(Future<void> Function() action) async {
    setState(() => _selectingFont = true);
    try {
      await action();
    } on FontSelectionException catch (error) {
      if (mounted) _showError(error.message);
    } catch (_) {
      if (mounted) _showError('字体设置失败');
    } finally {
      if (mounted) setState(() => _selectingFont = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.palette});

  final String label;
  final TokyoPalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: palette.comment,
        ),
      ),
    );
  }
}
