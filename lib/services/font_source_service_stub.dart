import 'dart:typed_data';

import 'font_source_service.dart';

FontSourceService createPlatformFontSourceService() =>
    const _UnsupportedFontSourceService();

class _UnsupportedFontSourceService implements FontSourceService {
  const _UnsupportedFontSourceService();

  @override
  bool get supportsGoogleFonts => false;

  @override
  bool get supportsImportedFonts => false;

  @override
  bool get supportsSystemFonts => false;

  @override
  bool containsGoogleFont(String family) => false;

  @override
  Future<String?> loadGoogleFont(String family) async => null;

  @override
  Future<String?> loadImportedFont(Uint8List bytes, String alias) async => null;

  @override
  Future<String?> loadSystemFont(String family) async => null;

  @override
  Future<List<String>> listSystemFonts() async => [];
}
