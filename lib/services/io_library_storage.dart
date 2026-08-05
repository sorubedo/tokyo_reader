import 'package:fs_shim/fs_shim.dart';

import 'directory_library_storage.dart';

/// 桌面端 IO 后端：以真实本地文件夹作为书库目录。
class IoLibraryStorage extends DirectoryLibraryStorage {
  IoLibraryStorage({required super.rootPath}) : super(fileSystem: fileSystemIo);
}
