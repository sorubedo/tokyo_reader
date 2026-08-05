import 'library_directory_adapter.dart';
import 'web_library_storage_factory.dart';

/// Web 端应用私有虚拟书库目录 adapter。
class WebLibraryDirectoryAdapter implements LibraryDirectoryAdapter {
  const WebLibraryDirectoryAdapter();

  @override
  Future<LibraryDirectorySelection?> restore() async {
    final storage = await const WebLibraryStorageFactory().create();
    if (storage == null) return null;
    return LibraryDirectorySelection(label: '浏览器私有书库', storage: storage);
  }

  @override
  Future<LibraryDirectorySelection?> select() async => null;

  @override
  Future<void> remember(LibraryDirectorySelection selection) async {}
}
