import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/global_font.dart';
import '../providers/global_font_provider.dart';
import '../widgets/adwaita_components.dart';
import 'font_family_picker_page.dart';

/// Global font source selection on its own page, preserving browser history.
class GlobalFontSelectionPage extends StatefulWidget {
  const GlobalFontSelectionPage({super.key});

  @override
  State<GlobalFontSelectionPage> createState() =>
      _GlobalFontSelectionPageState();
}

class _GlobalFontSelectionPageState extends State<GlobalFontSelectionPage> {
  bool _selectingFont = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GlobalFontProvider>();
    return Scaffold(
      appBar: const AppHeaderBar(title: '字体', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(child: Text(provider.selection.displayLabel)),
          ),
          Center(
            child: BoxedList(
              children: [
                ActionRow(
                  key: const ValueKey('font_source_system_default'),
                  leading: const Icon(Icons.settings_backup_restore),
                  title: '系统默认',
                  subtitle:
                      provider.selection.source ==
                          GlobalFontSource.systemDefault
                      ? '当前选择'
                      : null,
                  trailing:
                      provider.selection.source ==
                          GlobalFontSource.systemDefault
                      ? const Icon(Icons.check)
                      : null,
                  onTap: _selectingFont
                      ? null
                      : () => _runFontAction(provider.selectSystemDefault),
                ),
                if (provider.supportsImportedFonts)
                  ActionRow(
                    key: const ValueKey('font_source_imported'),
                    leading: const Icon(Icons.upload_file),
                    title: '从本地导入',
                    onTap: _selectingFont ? null : () => _importFont(provider),
                  ),
                if (provider.supportsGoogleFonts)
                  ActionRow(
                    key: const ValueKey('font_source_google'),
                    leading: const Icon(Icons.cloud_outlined),
                    title: 'Google Fonts',
                    onTap: _selectingFont
                        ? null
                        : () => _selectGoogleFont(provider),
                  ),
                if (provider.supportsSystemFonts)
                  ActionRow(
                    key: const ValueKey('font_source_system'),
                    leading: const Icon(Icons.computer),
                    title: '系统字体',
                    onTap: _selectingFont
                        ? null
                        : () => _selectSystemFont(provider),
                  ),
              ],
            ),
          ),
          if (_selectingFont)
            const Padding(
              padding: EdgeInsets.only(top: 20),
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _importFont(GlobalFontProvider provider) async {
    const fontTypes = XTypeGroup(
      label: '字体',
      extensions: ['ttf', 'otf', 'ttc'],
      webWildCards: ['.ttf', '.otf', '.ttc'],
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
      appPageRoute(
        FontFamilyPickerPage(
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
      appPageRoute(
        FontFamilyPickerPage(
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
      if (mounted) {
        showAppToast(context, error.message, kind: AppToastKind.error);
      }
    } catch (_) {
      if (mounted) {
        showAppToast(context, '全局字体选择失败', kind: AppToastKind.error);
      }
    } finally {
      if (mounted) setState(() => _selectingFont = false);
    }
  }
}
