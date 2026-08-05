import 'package:fs_shim/fs_shim.dart';

import 'io_library_storage.dart';
import 'library_directory_service.dart';
import 'library_storage.dart';

/// 桌面端：从偏好存储恢复上次选择的书库目录。
Future<LibraryStorage?> createDefaultLibraryStorage() async {
  final path = await const LibraryDirectoryService().readSavedPath();
  if (path == null || path.isEmpty) return null;

  final directory = fileSystemIo.directory(path);
  if (!await directory.exists()) return null;

  return IoLibraryStorage(rootPath: path);
}
