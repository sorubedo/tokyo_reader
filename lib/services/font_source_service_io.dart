import 'dart:io';

import 'package:flutter/services.dart';
import 'package:system_fonts/system_fonts.dart';

import 'font_source_service.dart';

FontSourceService createPlatformFontSourceService() => IoFontSourceService();

typedef ProcessRunner =
    Future<ProcessResult> Function(String executable, List<String> arguments);

class IoFontSourceService implements FontSourceService {
  IoFontSourceService() : this.withProcessRunner(Process.run);

  IoFontSourceService.withProcessRunner(this._processRunner);

  static const _fontListFormat = r'%{family[0]}\n';
  static const _fontMatchFormat = r'%{file}\n';

  final SystemFonts _systemFonts = SystemFonts();
  final ProcessRunner _processRunner;
  // Do not cache fc-list paths: their order can pin a bold face.
  Future<Set<String>>? _linuxFontFamilies;

  @override
  bool get supportsGoogleFonts => false;

  @override
  bool get supportsImportedFonts => false;

  @override
  bool get supportsSystemFonts => true;

  @override
  bool containsGoogleFont(String family) => false;

  @override
  Future<String?> loadGoogleFont(String family) async => null;

  @override
  Future<String?> loadImportedFont(Uint8List bytes, String alias) async => null;

  @override
  Future<String?> loadSystemFont(String family) async {
    final path = Platform.isLinux
        ? await _resolveLinuxFontPath(family)
        : _systemFonts.getFontMap()[family];
    if (path == null) return null;
    try {
      final bytes = await File(path).readAsBytes();
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
      return family;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<String>> listSystemFonts() async {
    final fonts = Platform.isLinux
        ? (await _getLinuxFontFamilies()).toList()
        : _systemFonts.getFontList();
    fonts.sort();
    return fonts;
  }

  Future<Set<String>> _getLinuxFontFamilies() =>
      _linuxFontFamilies ??= _loadLinuxFontFamilies();

  Future<Set<String>> _loadLinuxFontFamilies() async {
    final output = await _runFontConfig('fc-list', [
      '--format=$_fontListFormat',
    ]);
    return output
            ?.split('\n')
            .map((family) => family.trim())
            .where((family) => family.isNotEmpty)
            .toSet() ??
        {};
  }

  Future<String?> _resolveLinuxFontPath(String family) async {
    if (!(await _getLinuxFontFamilies()).contains(family)) return null;
    return _matchLinuxFont(family);
  }

  Future<String?> _matchLinuxFont(String family) async {
    final output = await _runFontConfig('fc-match', [
      '--format=$_fontMatchFormat',
      family,
    ]);
    final path = output?.split('\n').first.trim();
    return path == null || path.isEmpty ? null : path;
  }

  Future<String?> _runFontConfig(
    String executable,
    List<String> arguments,
  ) async {
    try {
      final result = await _processRunner(executable, arguments);
      if (result.exitCode != 0 || result.stdout is! String) return null;
      return result.stdout as String;
    } on ProcessException {
      return null;
    }
  }
}
