import 'dart:typed_data';

import 'global_font_storage_factory.dart';

/// 应用级导入字体存储，不与书库目录共享。
abstract interface class GlobalFontStorage {
  Future<Uint8List?> read();

  Future<void> write(Uint8List bytes);

  Future<void> clear();
}

GlobalFontStorage createGlobalFontStorage() =>
    createPlatformGlobalFontStorage();

/// 测试和内存场景使用的字体存储。
class MemoryGlobalFontStorage implements GlobalFontStorage {
  Uint8List? _bytes;

  @override
  Future<Uint8List?> read() async {
    final bytes = _bytes;
    return bytes == null ? null : Uint8List.fromList(bytes);
  }

  @override
  Future<void> write(Uint8List bytes) async {
    _bytes = Uint8List.fromList(bytes);
  }

  @override
  Future<void> clear() async {
    _bytes = null;
  }
}
