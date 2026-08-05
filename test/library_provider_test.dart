import 'package:flutter_test/flutter_test.dart';
import 'package:tokyo_reader/models/book_metadata.dart';
import 'package:tokyo_reader/providers/library_provider.dart';
import 'package:tokyo_reader/services/memory_library_storage.dart';

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
  });
}
