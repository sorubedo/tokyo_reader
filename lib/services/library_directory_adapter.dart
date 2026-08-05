import 'library_storage.dart';

/// 平台选中或恢复的书库目录，以及对应的持久化 adapter。
class LibraryDirectorySelection {
  const LibraryDirectorySelection({required this.label, required this.storage});

  final String label;
  final LibraryStorage storage;
}

/// 书库目录平台 seam；生命周期编排由 LibraryProvider 负责。
abstract interface class LibraryDirectoryAdapter {
  Future<LibraryDirectorySelection?> restore();

  Future<LibraryDirectorySelection?> select();

  Future<void> remember(LibraryDirectorySelection selection);
}
