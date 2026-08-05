import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tokyo_reader/models/book_content.dart';
import 'package:tokyo_reader/models/book_metadata.dart';
import 'package:tokyo_reader/services/io_library_storage.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('tokyo_reader_io_test');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('写入书籍后可在同一目录重建存储并完整恢复', () async {
    final storage = IoLibraryStorage(rootPath: tempDir.path);
    await storage.writeBook(
      BookMetadata(
        id: 'book-1',
        title: '示例小说',
        importedAt: DateTime(2026, 8, 5),
      ),
      BookContent(text: '很久很久以前……'),
    );

    final restored = IoLibraryStorage(rootPath: tempDir.path);
    final books = await restored.readMetadataIndex();
    expect(books, hasLength(1));
    expect(books.single.title, '示例小说');
    expect((await restored.readBookContent('book-1'))?.text, '很久很久以前……');
  });

  test('扫描发现目录中未登记的书籍文件', () async {
    final file = File('${tempDir.path}/outside.txt');
    await file.writeAsString('外部放入的正文');

    final storage = IoLibraryStorage(rootPath: tempDir.path);
    final books = await storage.scan();

    expect(books.map((book) => book.id), contains('outside'));
    expect((await storage.readBookContent('outside'))?.text, '外部放入的正文');
  });

  test('删除书籍后文件与索引同步移除', () async {
    final storage = IoLibraryStorage(rootPath: tempDir.path);
    await storage.writeBook(
      BookMetadata(
        id: 'book-1',
        title: '示例小说',
        importedAt: DateTime(2026, 8, 5),
      ),
      BookContent(text: '正文'),
    );

    await storage.deleteBook('book-1');

    expect(await storage.readMetadataIndex(), isEmpty);
    expect(await storage.readBookContent('book-1'), isNull);
    expect(await File('${tempDir.path}/book-1.txt').exists(), isFalse);
  });
}
