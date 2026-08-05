import 'library_storage.dart';
import 'web_library_storage_factory.dart';

/// Web 端：自动创建应用私有的虚拟书库目录。
Future<LibraryStorage?> createDefaultLibraryStorage() async {
  return const WebLibraryStorageFactory().create();
}
