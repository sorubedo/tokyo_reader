import 'package:dir_picker/dir_picker.dart';
import 'package:fs_shim/fs_shim.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'io_library_storage.dart';
import 'library_directory_adapter.dart';

/// 桌面端真实书库目录 adapter。
class IoLibraryDirectoryAdapter implements LibraryDirectoryAdapter {
  const IoLibraryDirectoryAdapter();

  static const String savedPathKey = 'library_directory_path';

  @override
  Future<LibraryDirectorySelection?> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(savedPathKey);
    if (path == null || path.isEmpty) return null;
    if (!await fileSystemIo.directory(path).exists()) return null;
    return _selection(path);
  }

  @override
  Future<LibraryDirectorySelection?> select() async {
    final location = await DirPicker.pick();
    if (location is! IOPickedLocation) return null;

    final path = location.uri.toFilePath();
    if (!await fileSystemIo.directory(path).exists()) {
      throw StateError('选择的书库目录不存在：$path');
    }
    return _selection(path);
  }

  @override
  Future<void> remember(LibraryDirectorySelection selection) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(savedPathKey, selection.label);
  }

  LibraryDirectorySelection _selection(String path) {
    return LibraryDirectorySelection(
      label: path,
      storage: IoLibraryStorage(rootPath: path),
    );
  }
}
