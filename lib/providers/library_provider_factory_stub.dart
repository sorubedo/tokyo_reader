import '../services/noop_library_directory_adapter.dart';
import 'library_provider.dart';

LibraryProvider createDefaultLibraryProvider() {
  return LibraryProvider(directoryAdapter: const NoopLibraryDirectoryAdapter());
}
