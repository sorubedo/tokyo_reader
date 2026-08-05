import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'global_font_storage.dart';

GlobalFontStorage createPlatformGlobalFontStorage() => _IoGlobalFontStorage();

class _IoGlobalFontStorage implements GlobalFontStorage {
  Future<File> _file() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/fonts');
    await directory.create(recursive: true);
    return File('${directory.path}/global_font.bin');
  }

  @override
  Future<Uint8List?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(Uint8List bytes) async {
    final file = await _file();
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
