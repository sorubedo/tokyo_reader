import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:tokyo_reader/models/book_content.dart';
import 'package:tokyo_reader/models/book_metadata.dart';
import 'package:tokyo_reader/services/library_storage.dart';
import 'package:tokyo_reader/services/memory_library_storage.dart';

BookMetadata _metadata(String id, {String title = '示例小说'}) {
  return BookMetadata(
    id: id,
    title: title,
    importedAt: DateTime(2026, 8, 5, 12, 30),
  );
}

void main() {
  group('MemoryLibraryStorage', () {
    late MemoryLibraryStorage storage;

    setUp(() {
      storage = MemoryLibraryStorage();
    });

    test('写入书籍后索引列出该书且内容可读取', () async {
      await storage.writeBook(
        _metadata('book-1'),
        BookContent(text: '很久很久以前……'),
      );

      final books = await storage.readMetadataIndex();
      expect(books, hasLength(1));
      expect(books.single.id, 'book-1');
      expect(books.single.title, '示例小说');

      final content = await storage.readBookContent('book-1');
      expect(content?.text, '很久很久以前……');
    });

    test('写入同名书籍会覆盖元数据与内容', () async {
      await storage.writeBook(_metadata('book-1'), BookContent(text: '旧正文'));
      await storage.writeBook(
        _metadata('book-1', title: '新标题'),
        BookContent(text: '新正文'),
      );

      final books = await storage.readMetadataIndex();
      expect(books, hasLength(1));
      expect(books.single.title, '新标题');

      final content = await storage.readBookContent('book-1');
      expect(content?.text, '新正文');
    });

    test('删除书籍后文件与索引条目同步移除', () async {
      await storage.writeBook(_metadata('book-1'), BookContent(text: '正文'));

      await storage.deleteBook('book-1');

      expect(await storage.readMetadataIndex(), isEmpty);
      expect(await storage.readBookContent('book-1'), isNull);
      expect(storage.debugFiles.containsKey('book-1.txt'), isFalse);
    });

    test('未导入的书籍内容读取返回 null', () async {
      expect(await storage.readBookContent('missing'), isNull);
    });

    test('元数据索引可单独写入并完整读回', () async {
      final books = [_metadata('book-1', title: '索引之书')];

      await storage.writeMetadataIndex(books);

      final restored = await storage.readMetadataIndex();
      expect(restored, hasLength(1));
      expect(restored.single.title, '索引之书');
    });

    test('书籍内容与元数据索引分离保存', () async {
      await storage.writeBook(
        _metadata('book-1'),
        BookContent(text: '只属于书籍文件的正文'),
      );

      expect(storage.debugFiles['book-1.txt'], '只属于书籍文件的正文');
      expect(storage.debugFiles['library.json'], isNot(contains('只属于书籍文件的正文')));
    });

    test('元数据索引包含当前 schema 版本', () async {
      await storage.writeMetadataIndex([]);

      final index =
          jsonDecode(storage.debugFiles['library.json']!)
              as Map<String, dynamic>;
      expect(index['schemaVersion'], LibraryStorage.schemaVersion);
      expect(index['books'], isEmpty);
    });
  });
}
