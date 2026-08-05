import 'dart:typed_data';

import 'font_source_service_factory.dart';

/// 平台字体来源与运行时注册能力。
abstract interface class FontSourceService {
  bool get supportsSystemFonts;

  bool get supportsImportedFonts;

  bool get supportsGoogleFonts;

  bool containsGoogleFont(String family);

  Future<List<String>> listSystemFonts();

  Future<String?> loadSystemFont(String family);

  Future<String?> loadImportedFont(Uint8List bytes, String alias);

  Future<String?> loadGoogleFont(String family);
}

FontSourceService createFontSourceService() =>
    createPlatformFontSourceService();
