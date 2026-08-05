import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tokyo_reader/core/tokyo_night.dart';
import 'package:tokyo_reader/models/book.dart';
import 'package:tokyo_reader/pages/reader_page.dart';
import 'package:tokyo_reader/providers/library_provider.dart';

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
    final provider = LibraryProvider()
      ..debugSetBooks([
        Book(
          id: 'book-1',
          title: '测试之书',
          content: '第一段文字\n第二段文字',
          importedAt: DateTime(2026, 8, 5),
        ),
      ]);

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('测试之书'), findsOneWidget);
    expect(find.textContaining('第一段文字'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });
}
