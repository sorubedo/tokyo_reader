import 'package:fs_shim/fs_memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tokyo_reader/models/book_content.dart';
import 'package:tokyo_reader/models/book_metadata.dart';
import 'package:tokyo_reader/services/directory_library_storage.dart';
import 'package:tokyo_reader/services/web_library_storage_factory.dart';

void main() {
  test('OPFS 可用时使用 OPFS 文件系统', () async {
    final opfs = newFileSystemMemory();
    final fallback = newFileSystemMemory();

    final storage = await const WebLibraryStorageFactory().create(
      opfsProbe: () async => true,
      opfsFileSystem: opfs,
      fallbackFileSystem: fallback,
    );

    expect(storage, isA<DirectoryLibraryStorage>());
    expect((storage! as DirectoryLibraryStorage).fileSystem, same(opfs));
  });

  test('OPFS 不可用时回退 IndexedDB 文件系统且书库不丢', () async {
    final opfs = newFileSystemMemory();
    final fallback = newFileSystemMemory();
    const factory = WebLibraryStorageFactory();

    final first = await factory.create(
      opfsProbe: () async => false,
      opfsFileSystem: opfs,
      fallbackFileSystem: fallback,
    );
    await first!.writeBook(
      BookMetadata(
        id: 'book-1',
        title: '回退之书',
        importedAt: DateTime(2026, 8, 5),
      ),
      BookContent(text: '正文'),
    );

    final second = await factory.create(
      opfsProbe: () async => false,
      opfsFileSystem: opfs,
      fallbackFileSystem: fallback,
    );
    final books = await second!.scan();

    expect(books.single.title, '回退之书');
    expect((await second.readBookContent('book-1'))?.text, '正文');
  });

  test('虚拟书库目录重新打开后完整恢复', () async {
    final fileSystem = newFileSystemMemory();
    final first = DirectoryLibraryStorage(
      fileSystem: fileSystem,
      rootPath: 'library',
    );
    await first.writeBook(
      BookMetadata(
        id: 'book-1',
        title: '持久之书',
        importedAt: DateTime(2026, 8, 5),
      ),
      BookContent(text: '很久很久以前……'),
    );

    final second = DirectoryLibraryStorage(
      fileSystem: fileSystem,
      rootPath: 'library',
    );
    final books = await second.scan();

    expect(books.single.title, '持久之书');
    expect((await second.readBookContent('book-1'))?.text, '很久很久以前……');
  });
}
