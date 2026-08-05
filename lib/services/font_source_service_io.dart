import 'dart:io';

import 'package:flutter/services.dart';
import 'package:system_fonts/system_fonts.dart';

import 'font_source_service.dart';

FontSourceService createPlatformFontSourceService() => _IoFontSourceService();

class _IoFontSourceService implements FontSourceService {
  final SystemFonts _systemFonts = SystemFonts();

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
    final path = _systemFonts.getFontMap()[family];
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
    final fonts = _systemFonts.getFontList().toList()..sort();
    return fonts;
  }
}
