import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:tokyo_reader/services/file_import_service.dart';
import 'package:tokyo_reader/services/library_storage.dart';
import 'package:tokyo_reader/services/memory_library_storage.dart';

class _FakeTxtFilePicker implements TxtFilePicker {
  _FakeTxtFilePicker(this.result);

  final ImportedTxtFile result;
  int calls = 0;

  @override
  Future<ImportedTxtFile?> pickTxtFile() async {
    calls++;
    return result;
  }
}

class _DeleteFailingStorage extends MemoryLibraryStorage {
  @override
  Future<void> deleteBook(String bookId) async {
    throw StateError('磁盘不可写');
  }
}

Widget _wrap(LibraryProvider provider) {
  return ChangeNotifierProvider.value(
    value: provider,
    child: MaterialApp(
      theme: buildTokyoNightTheme(),
      home: const LibraryPage(),
    ),
  );
}

Future<LibraryProvider> _pumpLibraryWithBook(
  WidgetTester tester, {
  required String title,
  LibraryStorage? storage,
}) async {
  final bookStorage = storage ?? MemoryLibraryStorage();
  final provider = LibraryProvider(storage: bookStorage);
  await tester.runAsync(() async {
    await bookStorage.writeBook(
      BookMetadata(
        id: 'book-1',
        title: title,
        importedAt: DateTime(2026, 8, 5),
      ),
      BookContent(text: '正文'),
    );
    await provider.init();
  });
  await tester.pumpWidget(_wrap(provider));
  return provider;
}

Future<void> _openBookMenu(
  WidgetTester tester, {
  String bookId = 'book-1',
}) async {
  await tester.tap(find.byKey(ValueKey('delete_$bookId')));
  await tester.pumpAndSettle();
}

Future<void> _openDeleteDialog(
  WidgetTester tester, {
  String bookId = 'book-1',
}) async {
  await _openBookMenu(tester, bookId: bookId);
  await tester.tap(find.byKey(ValueKey('delete_menu_$bookId')));
  await tester.pumpAndSettle();
}

void main() {
  group('LibraryPage', () {
    testWidgets('空书库显示提示和两个导入入口', (tester) async {
      final provider = LibraryProvider(storage: MemoryLibraryStorage());
      await tester.runAsync(() => provider.init());

      await tester.pumpWidget(_wrap(provider));

      expect(find.text('书库'), findsOneWidget);
      expect(find.text('导入 TXT'), findsNWidgets(2));
      expect(find.text('书库还是空的'), findsOneWidget);
    });

    testWidgets('空书库主操作导入 TXT 并显示成功 Toast', (tester) async {
      final picker = _FakeTxtFilePicker(
        const ImportedTxtFile(name: '新书.txt', content: '正文'),
      );
      final provider = LibraryProvider(
        storage: MemoryLibraryStorage(),
        filePicker: picker,
      );
      await tester.runAsync(() => provider.init());
      await tester.pumpWidget(_wrap(provider));

      final importButton = find.byKey(const ValueKey('empty_import_button'));
      expect(
        find.descendant(of: importButton, matching: find.text('导入 TXT')),
        findsOneWidget,
      );

      await tester.tap(importButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      expect(picker.calls, 1);
      expect(provider.books.single.title, '新书');
      expect(find.text('已导入《新书》'), findsOneWidget);
    });

    testWidgets('未选择目录时显示选择书库目录', (tester) async {
      final provider = LibraryProvider();
      await tester.runAsync(() => provider.init());

      await tester.pumpWidget(_wrap(provider));

      expect(find.text('选择书库目录'), findsOneWidget);
      final importButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('import_button')),
      );
      expect(importButton.onPressed, isNull);
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

    for (final viewportSize in [const Size(960, 720), const Size(360, 640)]) {
      testWidgets('${viewportSize.width.toInt()}px 下有书列表居中且不溢出', (
        tester,
      ) async {
        tester.view.physicalSize = viewportSize;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final storage = MemoryLibraryStorage();
        final provider = LibraryProvider(storage: storage);
        await tester.runAsync(() async {
          await storage.writeBook(
            BookMetadata(
              id: 'book-1',
              title: '示例小说',
              importedAt: DateTime(2026, 8, 5),
            ),
            BookContent(text: '正文'),
          );
          await provider.init();
        });

        await tester.pumpWidget(_wrap(provider));

        final listRect = tester.getRect(
          find.byKey(const ValueKey('book_book-1')),
        );
        expect(listRect.center.dx, closeTo(viewportSize.width / 2, 0.1));
        expect(listRect.width, lessThanOrEqualTo(760));
        expect(listRect.left, greaterThanOrEqualTo(0));
        expect(listRect.right, lessThanOrEqualTo(viewportSize.width));
        expect(tester.takeException(), isNull);
      });
    }

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

    testWidgets('键盘可以打开、导航和关闭书籍菜单', (tester) async {
      final provider = await _pumpLibraryWithBook(tester, title: '键盘操作之书');

      expect(find.byTooltip('《键盘操作之书》的更多操作'), findsOneWidget);

      for (var index = 0; index < 4; index++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('删除'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('删除'), findsNothing);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('删除书籍'), findsOneWidget);
      expect(provider.bookById('book-1'), isNotNull);
    });

    testWidgets('删除项以文字、图标和目标书名表达破坏性语义', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpLibraryWithBook(tester, title: '危险操作之书');

      await _openBookMenu(tester);

      expect(find.text('删除'), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.bySemanticsLabel('删除书籍《危险操作之书》'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('点击取消关闭对话框并保留书籍', (tester) async {
      final provider = await _pumpLibraryWithBook(tester, title: '取消删除之书');

      await _openDeleteDialog(tester);

      expect(find.textContaining('《取消删除之书》'), findsOneWidget);
      final cancelButton = tester.widget<TextButton>(
        find.widgetWithText(TextButton, '取消'),
      );
      expect(cancelButton.autofocus, isTrue);

      await tester.tap(find.widgetWithText(TextButton, '取消'));
      await tester.pumpAndSettle();

      expect(find.text('删除书籍'), findsNothing);
      expect(find.text('取消删除之书'), findsOneWidget);
      expect(provider.bookById('book-1'), isNotNull);
    });

    testWidgets('明确确认后删除书籍', (tester) async {
      final provider = await _pumpLibraryWithBook(tester, title: '确认删除之书');

      await _openDeleteDialog(tester);
      await tester.tap(find.widgetWithText(TextButton, '删除'));
      await tester.pumpAndSettle();

      expect(find.text('确认删除之书'), findsNothing);
      expect(find.text('书库还是空的'), findsOneWidget);
      expect(provider.bookById('book-1'), isNull);
    });

    for (final viewportSize in [const Size(960, 720), const Size(360, 640)]) {
      testWidgets('${viewportSize.width.toInt()}px 下菜单和删除对话框完整可用', (
        tester,
      ) async {
        tester.view.physicalSize = viewportSize;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await _pumpLibraryWithBook(tester, title: '一本需要谨慎删除的长书名');

        await _openBookMenu(tester);

        final menuItem = find.text('删除');
        _expectInsideViewport(tester, menuItem, viewportSize);

        await tester.tap(menuItem);
        await tester.pumpAndSettle();

        _expectInsideViewport(tester, find.text('删除书籍'), viewportSize);
        _expectInsideViewport(
          tester,
          find.textContaining('《一本需要谨慎删除的长书名》'),
          viewportSize,
        );
        _expectInsideViewport(
          tester,
          find.widgetWithText(TextButton, '取消'),
          viewportSize,
        );
        _expectInsideViewport(
          tester,
          find.widgetWithText(TextButton, '删除'),
          viewportSize,
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('书籍菜单删除先确认，Enter 和 Esc 都不会误删书籍', (tester) async {
      final provider = await _pumpLibraryWithBook(tester, title: '待删除之书');

      await tester.tap(find.byKey(const ValueKey('delete_book-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete_menu_book-1')));
      await tester.pumpAndSettle();

      expect(find.text('删除书籍'), findsOneWidget);
      expect(find.textContaining('《待删除之书》'), findsOneWidget);
      expect(
        tester
            .widget<TextButton>(find.widgetWithText(TextButton, '取消'))
            .autofocus,
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(find.text('待删除之书'), findsOneWidget);
      expect(provider.bookById('book-1'), isNotNull);

      await tester.tap(find.byKey(const ValueKey('delete_book-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete_menu_book-1')));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('待删除之书'), findsOneWidget);
      expect(provider.bookById('book-1'), isNotNull);
    });

    testWidgets('删除失败时保留书籍并显示错误 Toast', (tester) async {
      final storage = _DeleteFailingStorage();
      await _pumpLibraryWithBook(tester, title: '待删除之书', storage: storage);

      await _openDeleteDialog(tester);
      await tester.tap(find.widgetWithText(TextButton, '删除').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      expect(find.text('待删除之书'), findsOneWidget);
      expect(find.textContaining('删除失败'), findsOneWidget);
      expect(find.textContaining('磁盘不可写'), findsOneWidget);
    });
  });
}

void _expectInsideViewport(
  WidgetTester tester,
  Finder finder,
  Size viewportSize,
) {
  final rect = tester.getRect(finder);
  expect(rect.left, greaterThanOrEqualTo(0));
  expect(rect.top, greaterThanOrEqualTo(0));
  expect(rect.right, lessThanOrEqualTo(viewportSize.width));
  expect(rect.bottom, lessThanOrEqualTo(viewportSize.height));
}
