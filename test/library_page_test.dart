import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tokyo_reader/core/tokyo_theme.dart';
import 'package:tokyo_reader/models/book_content.dart';
import 'package:tokyo_reader/models/book_metadata.dart';
import 'package:tokyo_reader/pages/library_page.dart';
import 'package:tokyo_reader/providers/library_provider.dart';
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
    await provider.init();

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('书库'), findsOneWidget);
    expect(find.text('导入 TXT'), findsOneWidget);
    expect(find.text('书库还是空的'), findsOneWidget);
  });

  testWidgets('书库列出已导入书籍', (tester) async {
    final storage = MemoryLibraryStorage();
    await storage.writeBook(
      BookMetadata(
        id: 'book-1',
        title: '示例小说',
        importedAt: DateTime(2026, 8, 5),
      ),
      BookContent(text: '很久很久以前……'),
    );
    final provider = LibraryProvider(storage: storage);
    await provider.init();

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('示例小说'), findsOneWidget);
    expect(find.textContaining('2026-08-05'), findsOneWidget);
  });
}
