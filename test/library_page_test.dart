import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tokyo_reader/core/tokyo_theme.dart';
import 'package:tokyo_reader/models/book.dart';
import 'package:tokyo_reader/pages/library_page.dart';
import 'package:tokyo_reader/providers/library_provider.dart';

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
    final provider = LibraryProvider()..debugSetBooks([]);

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('书库'), findsOneWidget);
    expect(find.text('导入 TXT'), findsOneWidget);
    expect(find.text('书库还是空的'), findsOneWidget);
  });

  testWidgets('书库列出已导入书籍', (tester) async {
    final provider = LibraryProvider()
      ..debugSetBooks([
        Book(
          id: 'book-1',
          title: '示例小说',
          content: '很久很久以前……',
          importedAt: DateTime(2026, 8, 5),
        ),
      ]);

    await tester.pumpWidget(_wrap(provider));

    expect(find.text('示例小说'), findsOneWidget);
    expect(find.textContaining('字'), findsOneWidget);
  });
}
