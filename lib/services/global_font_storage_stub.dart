import 'dart:typed_data';

import 'global_font_storage.dart';

GlobalFontStorage createPlatformGlobalFontStorage() =>
    _UnsupportedGlobalFontStorage();

class _UnsupportedGlobalFontStorage implements GlobalFontStorage {
  @override
  Future<Uint8List?> read() async => null;

  @override
  Future<void> write(Uint8List bytes) async {
    throw UnsupportedError('当前平台不支持导入字体');
  }

  @override
  Future<void> clear() async {}
}
