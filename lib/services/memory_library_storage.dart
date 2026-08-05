import 'package:fs_shim/fs_memory.dart';

import 'directory_library_storage.dart';

/// 内存后端：以内存文件系统实现「书籍文件 + 元数据索引」布局。
class MemoryLibraryStorage extends DirectoryLibraryStorage {
  MemoryLibraryStorage()
    : super(fileSystem: newFileSystemMemory(), rootPath: '/library');
}
