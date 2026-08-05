import 'package:fs_shim/fs_memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:tokyo_reader/models/book_content.dart';
import 'package:tokyo_reader/models/book_metadata.dart';
import 'package:tokyo_reader/services/content_hasher.dart';
import 'package:tokyo_reader/services/directory_library_storage.dart';

class CountingHasher implements ContentHasher {
  CountingHasher(this._inner);

  final ContentHasher _inner;
  int calls = 0;

  @override
  Future<String> hash(String content) async {
    calls++;
    return _inner.hash(content);
  }
}

void main() {
  group('外部修改检测', () {
    late FileSystem fileSystem;
    late CountingHasher hasher;
    late DirectoryLibraryStorage storage;

    setUp(() {
      fileSystem = newFileSystemMemory();
      hasher = CountingHasher(const Sha256ContentHasher());
      storage = DirectoryLibraryStorage(
        fileSystem: fileSystem,
        rootPath: '/library',
        hasher: hasher,
      );
    });

    test('未变化时扫描不重算哈希', () async {
      await storage.writeBook(
        BookMetadata(
          id: 'book-1',
          title: '示例小说',
          importedAt: DateTime(2026, 8, 5),
        ),
        BookContent(text: '正文'),
      );
      expect(hasher.calls, 1);

      await storage.scan();

      expect(hasher.calls, 1);
    });

    test('外部修改后被标记且指纹更新，内容可读最新', () async {
      await storage.writeBook(
        BookMetadata(
          id: 'book-1',
          title: '示例小说',
          importedAt: DateTime(2026, 8, 5),
        ),
        BookContent(text: '旧'),
      );

      final file = fileSystem.file(p.join('/library', 'book-1.txt'));
      await file.writeAsString('外部改写后的更长正文');

      final books = await storage.scan();

      expect(books.single.externalModified, isTrue);
      expect((await storage.readBookContent('book-1'))?.text, '外部改写后的更长正文');
      expect(books.single.contentFingerprint?.sha256, isNotNull);
    });

    test('文件缺失时被标记而不崩溃', () async {
      await storage.writeBook(
        BookMetadata(
          id: 'book-1',
          title: '示例小说',
          importedAt: DateTime(2026, 8, 5),
        ),
        BookContent(text: '正文'),
      );
      await fileSystem.file(p.join('/library', 'book-1.txt')).delete();

      final books = await storage.scan();

      expect(books.single.externalModified, isTrue);
      expect(await storage.readBookContent('book-1'), isNull);
    });
  });
}
