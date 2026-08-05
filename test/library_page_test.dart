import 'package:flutter/material.dart';
import 'package:fs_shim/fs_memory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:tokyo_reader/core/tokyo_theme.dart';
import 'package:tokyo_reader/models/book_content.dart';
import 'package:tokyo_reader/models/book_metadata.dart';
import 'package:tokyo_reader/pages/library_page.dart';
import 'package:tokyo_reader/providers/library_provider.dart';
import 'package:tokyo_reader/services/directory_library_storage.dart';
import 'package:tokyo_reader/services/memory_library_storage.dart';

Widget _wrap(LibraryProvider provider) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      theme: buildTokyoNightTheme(),
      home: const LibraryPage(),
    ),
  );
}

void main() {
  testWidgets('空书库显示提示和导入按钮', (tester) async {
    final provider = LibraryProvider(storage: MemoryLibraryStorage());
    await tester.runAsync(() => provider.init());

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('书库'), findsOneWidget);
    expect(find.text('导入 TXT'), findsOneWidget);
    expect(find.text('书库还是空的'), findsOneWidget);
  });

  testWidgets('未选择目录时显示选择书库目录', (tester) async {
    final provider = LibraryProvider();
    await tester.runAsync(() => provider.init());

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('选择书库目录'), findsOneWidget);
  });

  testWidgets('书库列出已导入书籍', (tester) async {
    final storage = MemoryLibraryStorage();
    final provider = LibraryProvider(storage: storage);
    await tester.runAsync(() async {
      await storage.writeBook(
        BookMetadata(
          id: 'book-1',
          title: '示例小说',
          importedAt: DateTime(2026, 8, 5),
        ),
        BookContent(text: '很久很久以前……'),
      );
      await provider.init();
    });

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('示例小说'), findsOneWidget);
    expect(find.textContaining('2026-08-05'), findsOneWidget);
  });

  testWidgets('外部修改的书籍在书库页显示标记', (tester) async {
    final fileSystem = newFileSystemMemory();
    final storage = DirectoryLibraryStorage(
      fileSystem: fileSystem,
      rootPath: '/library',
    );
    final provider = LibraryProvider(storage: storage);
    await tester.runAsync(() async {
      await storage.writeBook(
        BookMetadata(
          id: 'book-1',
          title: '示例小说',
          importedAt: DateTime(2026, 8, 5),
        ),
        BookContent(text: '旧正文'),
      );
      await provider.init();
      final file = fileSystem.file(p.join('/library', 'book-1.txt'));
      await file.writeAsString('外部改写的正文');
      await provider.refresh();
    });

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('示例小说'), findsOneWidget);
    expect(find.textContaining('外部修改'), findsOneWidget);
  });
}
