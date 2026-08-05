import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'font_source_service.dart';

FontSourceService createPlatformFontSourceService() => _WebFontSourceService();

class _WebFontSourceService implements FontSourceService {
  @override
  bool get supportsGoogleFonts => true;

  @override
  bool get supportsImportedFonts => true;

  @override
  bool get supportsSystemFonts => false;

  @override
  bool containsGoogleFont(String family) =>
      GoogleFonts.asMap().containsKey(family);

  @override
  Future<String?> loadGoogleFont(String family) async {
    try {
      GoogleFonts.getTextTheme(family);
      await GoogleFonts.pendingFonts();
      return family;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> loadImportedFont(Uint8List bytes, String alias) async {
    try {
      final loader = FontLoader(alias)
        ..addFont(Future.value(ByteData.view(bytes.buffer)));
      await loader.load();
      return alias;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> loadSystemFont(String family) async => null;

  @override
  Future<List<String>> listSystemFonts() async => [];
}
