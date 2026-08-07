import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokyo_reader/app.dart';
import 'package:tokyo_reader/core/tokyo_palette.dart';
import 'package:tokyo_reader/models/book_content.dart';
import 'package:tokyo_reader/models/book_metadata.dart';
import 'package:tokyo_reader/services/memory_library_storage.dart';

Future<void> _settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('书库→阅读→删除→主题切换 端到端流程', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = MemoryLibraryStorage();
    await storage.writeBook(
      BookMetadata(
        id: 'book-1',
        title: '示例小说',
        importedAt: DateTime(2026, 8, 5),
      ),
      BookContent(text: '第一段文字\n第二段文字'),
    );

    await tester.pumpWidget(TokyoReaderApp(libraryStorage: storage));
    await _settle(tester);

    expect(find.text('示例小说'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('book_book-1')));
    await _settle(tester);

    expect(find.text('示例小说'), findsOneWidget);
    expect(find.byKey(const ValueKey('reader_content')), findsOneWidget);
    expect(find.textContaining('第一段文字'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);

    await tester.pageBack();
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('delete_book-1')));
    await _settle(tester);
    await tester.tap(find.text('删除'));
    await _settle(tester);

    expect(find.text('删除书籍'), findsOneWidget);
    expect(find.textContaining('《示例小说》'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '删除'));
    await _settle(tester);

    expect(find.text('书库还是空的'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('settings_button')));
    await _settle(tester);

    await tester.tap(find.byKey(const ValueKey('theme_tokyoDay')));
    await _settle(tester);

    final context = tester.element(find.text('Tokyo 日'));
    expect(
      Theme.of(context).extension<TokyoPalette>()!.bg,
      const Color(0xFFE1E2E7),
    );
  });
}
