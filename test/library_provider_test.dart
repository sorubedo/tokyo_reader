import 'package:flutter_test/flutter_test.dart';
import 'package:tokyo_reader/models/book_content.dart';
import 'package:tokyo_reader/models/book_metadata.dart';
import 'package:tokyo_reader/providers/library_provider.dart';
import 'package:tokyo_reader/services/memory_library_storage.dart';

class _ScanFailingStorage extends MemoryLibraryStorage {
  @override
  Future<List<BookMetadata>> scan() async {
    throw StateError('目录不可读');
  }
}

void main() {
  group('LibraryProvider', () {
    late MemoryLibraryStorage storage;
    late LibraryProvider provider;

    setUp(() {
      storage = MemoryLibraryStorage();
      provider = LibraryProvider(storage: storage);
    });

    test('导入书籍后写入书籍文件并登记元数据索引', () async {
      await provider.addBook(title: '示例小说', content: '很久很久以前……');

      final books = await storage.readMetadataIndex();
      expect(books, hasLength(1));
      expect(books.single.title, '示例小说');

      final content = await storage.readBookContent(books.single.id);
      expect(content?.text, '很久很久以前……');
      expect(provider.books.single.title, '示例小说');
    });

    test('同名书籍可以同时存在', () async {
      await provider.addBook(title: '同名书', content: '一');
      await provider.addBook(title: '同名书', content: '二');

      final books = await storage.readMetadataIndex();
      expect(books, hasLength(2));
      expect(books.map((book) => book.title).toSet(), {'同名书'});
      expect(books.map((book) => book.id).toSet(), hasLength(2));
      expect(provider.books, hasLength(2));
    });

    test('删除书籍后文件与索引同步移除', () async {
      await provider.addBook(title: '示例小说', content: '正文');
      final bookId = provider.books.single.id;

      await provider.deleteBook(bookId);

      expect(await storage.readMetadataIndex(), isEmpty);
      expect(await storage.readBookContent(bookId), isNull);
      expect(provider.books, isEmpty);
    });

    test('阅读内容按需读取，Provider 不持有正文', () async {
      await provider.addBook(title: '示例小说', content: '按需读取的正文');

      final book = provider.books.single;
      expect(book, isA<BookMetadata>());

      final content = await provider.readBookContent(book.id);
      expect(content?.text, '按需读取的正文');
    });

    test('init 从元数据索引恢复并按导入时间倒序', () async {
      final older = BookMetadata(
        id: 'old',
        title: '旧书',
        importedAt: DateTime(2026, 1, 1),
      );
      final newer = BookMetadata(
        id: 'new',
        title: '新书',
        importedAt: DateTime(2026, 2, 1),
      );
      await storage.writeMetadataIndex([older, newer]);

      await provider.init();

      expect(provider.books.map((book) => book.id).toList(), ['new', 'old']);
    });

    test('未配置存储时书库为空且不崩溃', () async {
      final emptyProvider = LibraryProvider();

      await emptyProvider.init();

      expect(emptyProvider.isLoaded, isTrue);
      expect(emptyProvider.books, isEmpty);
      expect(await emptyProvider.readBookContent('missing'), isNull);
    });

    test('setStorage 后从新存储恢复书籍', () async {
      final emptyProvider = LibraryProvider();
      await emptyProvider.init();
      expect(emptyProvider.books, isEmpty);

      final newStorage = MemoryLibraryStorage();
      await newStorage.writeBook(
        BookMetadata(
          id: 'book-1',
          title: '新目录之书',
          importedAt: DateTime(2026, 8, 5),
        ),
        BookContent(text: '正文'),
      );

      await emptyProvider.setStorage(newStorage);

      expect(emptyProvider.books.single.title, '新目录之书');
      expect((await emptyProvider.readBookContent('book-1'))?.text, '正文');
    });

    test('切换目录扫描失败时保留原书库状态', () async {
      await storage.writeBook(
        BookMetadata(
          id: 'old-book',
          title: '原目录之书',
          importedAt: DateTime(2026, 8, 5),
        ),
        BookContent(text: '仍可读取的正文'),
      );
      await provider.init();

      await expectLater(
        provider.setStorage(_ScanFailingStorage()),
        throwsStateError,
      );

      expect(provider.storage, same(storage));
      expect(provider.books.single.title, '原目录之书');
      expect((await provider.readBookContent('old-book'))?.text, '仍可读取的正文');
    });
  });
}
