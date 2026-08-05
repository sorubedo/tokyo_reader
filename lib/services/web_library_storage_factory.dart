import 'package:fs_shim/fs_browser.dart';
import 'package:fs_shim/fs_opfs_web.dart';
import 'package:fs_shim/fs_shim.dart';

import 'directory_library_storage.dart';
import 'library_storage.dart';

/// Web 虚拟书库：优先使用 OPFS，不可用时回退 IndexedDB。
class WebLibraryStorageFactory {
  const WebLibraryStorageFactory();

  Future<LibraryStorage?> create({
    Future<bool> Function()? opfsProbe,
    FileSystem? opfsFileSystem,
    FileSystem? fallbackFileSystem,
  }) async {
    final useOpfs = await (opfsProbe ?? _probeOpfs)();
    final fileSystem = useOpfs
        ? (opfsFileSystem ?? fileSystemOpfsWeb)
        : (fallbackFileSystem ?? fileSystemWeb);
    return DirectoryLibraryStorage(fileSystem: fileSystem, rootPath: 'library');
  }

  Future<bool> _probeOpfs() async {
    try {
      final probe = fileSystemOpfsWeb.directory('__opfs_probe__');
      await probe.create(recursive: true);
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
