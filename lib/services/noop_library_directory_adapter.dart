import 'library_directory_adapter.dart';

class NoopLibraryDirectoryAdapter implements LibraryDirectoryAdapter {
  const NoopLibraryDirectoryAdapter();

  @override
  Future<LibraryDirectorySelection?> restore() async => null;

  @override
  Future<LibraryDirectorySelection?> select() async => null;

  @override
  Future<void> remember(LibraryDirectorySelection selection) async {}
}
