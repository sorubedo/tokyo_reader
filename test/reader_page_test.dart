import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tokyo_reader/core/tokyo_theme.dart';
import 'package:tokyo_reader/models/book_content.dart';
import 'package:tokyo_reader/models/book_metadata.dart';
import 'package:tokyo_reader/pages/reader_page.dart';
import 'package:tokyo_reader/providers/library_provider.dart';
import 'package:tokyo_reader/services/memory_library_storage.dart';

Widget _wrap(LibraryProvider provider) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      theme: buildTokyoNightTheme(),
      home: const ReaderPage(bookId: 'book-1'),
    ),
  );
}

void main() {
  testWidgets('阅读页显示书名、正文和进度', (tester) async {
    final storage = MemoryLibraryStorage();
    final provider = LibraryProvider(storage: storage);
    await tester.runAsync(() async {
      await storage.writeBook(
        BookMetadata(
          id: 'book-1',
          title: '测试之书',
          importedAt: DateTime(2026, 8, 5),
        ),
        BookContent(text: '第一段文字\n第二段文字'),
      );
      await provider.init();
    });

    await tester.pumpWidget(_wrap(provider));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.text('测试之书'), findsOneWidget);
    expect(find.textContaining('第一段文字'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });
}
