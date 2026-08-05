import 'dart:typed_data';

import 'package:fs_shim/fs_browser.dart';
import 'package:fs_shim/fs_opfs_web.dart';

import 'global_font_storage.dart';

GlobalFontStorage createPlatformGlobalFontStorage() => _WebGlobalFontStorage();

class _WebGlobalFontStorage implements GlobalFontStorage {
  Future<File> _file() async {
    final fileSystem = await _fileSystem();
    final directory = fileSystem.directory('fonts');
    await directory.create(recursive: true);
    return fileSystem.file('fonts/global_font.bin');
  }

  Future<FileSystem> _fileSystem() async {
    try {
      await fileSystemOpfsWeb.directory('/').exists();
      return fileSystemOpfsWeb;
    } catch (_) {
      return newFileSystemWeb(name: 'tokyo_reader_fonts');
    }
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
    await file.writeAsBytes(bytes);
  }

  @override
  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
