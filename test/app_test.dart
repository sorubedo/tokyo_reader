import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fs_shim/fs_memory.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokyo_reader/app.dart';
import 'package:tokyo_reader/core/tokyo_palette.dart';
import 'package:tokyo_reader/core/tokyo_theme.dart';
import 'package:tokyo_reader/models/book_content.dart';
import 'package:tokyo_reader/models/book_metadata.dart';
import 'package:tokyo_reader/providers/library_provider.dart';
import 'package:tokyo_reader/services/directory_library_storage.dart';
import 'package:tokyo_reader/services/file_import_service.dart';
import 'package:tokyo_reader/services/library_directory_adapter.dart';
import 'package:tokyo_reader/services/library_storage.dart';
import 'package:tokyo_reader/services/memory_library_storage.dart';

class _FakeLibraryDirectoryAdapter implements LibraryDirectoryAdapter {
  _FakeLibraryDirectoryAdapter(this.selection);

  final LibraryDirectorySelection selection;
  int selectCalls = 0;

  @override
  Future<LibraryDirectorySelection?> restore() async => null;

  @override
  Future<LibraryDirectorySelection?> select() async {
    selectCalls++;
    return selection;
  }

  @override
  Future<void> remember(LibraryDirectorySelection selection) async {}
}

class _FakeTxtFilePicker implements TxtFilePicker {
  _FakeTxtFilePicker({this.result, this.error});

  final ImportedTxtFile? result;
  final Object? error;
  int calls = 0;

  @override
  Future<ImportedTxtFile?> pickTxtFile() async {
    calls++;
    final error = this.error;
    if (error != null) throw error;
    return result;
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    LibraryStorage? libraryStorage,
    LibraryProvider? libraryProvider,
  }) async {
    await tester.pumpWidget(
      TokyoReaderApp(
        libraryStorage: libraryStorage,
        libraryProvider: libraryProvider,
      ),
    );
    await tester.pumpAndSettle();
    final navigatorContext = tester.element(find.byType(Navigator).first);
    GoRouter.of(navigatorContext).go('/');
    await tester.pumpAndSettle();
  }

  Future<void> selectTheme(WidgetTester tester, String label) async {
    await tester.tap(find.byKey(const ValueKey('theme_combo_row')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  group('TokyoReaderApp', () {
    testWidgets('未选择目录时可选择书库目录并获得 Toast 反馈', (tester) async {
      final storage = MemoryLibraryStorage();
      final adapter = _FakeLibraryDirectoryAdapter(
        LibraryDirectorySelection(label: '/books', storage: storage),
      );
      final provider = LibraryProvider(directoryAdapter: adapter);
      await provider.init();

      await pumpApp(tester, libraryProvider: provider);

      expect(find.text('还没有选择书库目录'), findsOneWidget);
      final importButton = tester.widget<FilledButton>(
        find.byKey(const ValueKey('import_button')),
      );
      expect(importButton.onPressed, isNull);

      await tester.tap(find.byKey(const ValueKey('choose_directory_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      expect(adapter.selectCalls, 1);
      expect(find.text('书库还是空的'), findsOneWidget);
      expect(find.text('书库目录：/books'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const ValueKey('import_button')))
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('360px 下 Header Bar 导入 TXT 并显示成功 Toast', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final picker = _FakeTxtFilePicker(
        result: const ImportedTxtFile(name: '根组件新书.txt', content: '正文'),
      );
      final provider = LibraryProvider(
        storage: MemoryLibraryStorage(),
        filePicker: picker,
      );
      await tester.runAsync(provider.init);

      await pumpApp(tester, libraryProvider: provider);

      expect(find.text('书库还是空的'), findsOneWidget);
      final importFinder = find.byKey(const ValueKey('import_button'));
      expect(tester.widget(importFinder), isA<IconButton>());
      expect(find.byTooltip('导入 TXT'), findsOneWidget);

      await tester.tap(importFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      expect(picker.calls, 1);
      expect(find.text('根组件新书'), findsOneWidget);
      expect(find.text('已导入《根组件新书》'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Header Bar 导入失败时保持空书库并显示错误 Toast', (tester) async {
      final picker = _FakeTxtFilePicker(error: StateError('文件不可读'));
      final provider = LibraryProvider(
        storage: MemoryLibraryStorage(),
        filePicker: picker,
      );
      await tester.runAsync(provider.init);
      await pumpApp(tester, libraryProvider: provider);

      await tester.tap(find.byKey(const ValueKey('import_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 180));

      expect(picker.calls, 1);
      expect(provider.books, isEmpty);
      expect(find.text('书库还是空的'), findsOneWidget);
      expect(find.textContaining('导入失败'), findsOneWidget);
      expect(find.textContaining('文件不可读'), findsOneWidget);
    });

    testWidgets('根组件的 Boxed List 显示书籍时间与外部修改状态', (tester) async {
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
            title: '测试书籍',
            importedAt: DateTime(2026, 8, 5, 14, 30),
          ),
          BookContent(text: '旧正文'),
        );
        await provider.init();
        await fileSystem
            .file(p.join('/library', 'book-1.txt'))
            .writeAsString('在应用之外改写的新正文');
        await provider.refresh();
      });

      await pumpApp(tester, libraryProvider: provider);

      expect(find.byKey(const ValueKey('book_book-1')), findsOneWidget);
      expect(find.text('测试书籍'), findsOneWidget);
      expect(find.textContaining('2026-08-05 14:30'), findsOneWidget);
      expect(find.textContaining('外部修改'), findsOneWidget);
      expect(find.byKey(const ValueKey('delete_book-1')), findsOneWidget);
    });

    testWidgets('从书库进入设置页，Combo Row 展示三种主题且默认选中 Tokyo 夜', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();

      expect(find.text('设置'), findsOneWidget);
      expect(find.text('外观'), findsOneWidget);
      expect(find.text('Tokyo 夜'), findsOneWidget);
      expect(find.text('Tokyo 日'), findsNothing);
      expect(find.text('Tokyo 风暴'), findsNothing);
      expect(find.text('字体'), findsOneWidget);
      expect(find.text('全局字体'), findsOneWidget);
      expect(find.text('系统默认'), findsOneWidget);

      final combo = tester.widget<PopupMenuButton<ThemeVariant>>(
        find.byType(PopupMenuButton<ThemeVariant>),
      );
      expect(combo.initialValue, ThemeVariant.tokyoNight);

      await tester.tap(find.byKey(const ValueKey('theme_combo_row')));
      await tester.pumpAndSettle();

      expect(find.text('Tokyo 日'), findsOneWidget);
      expect(find.text('Tokyo 风暴'), findsOneWidget);
      expect(find.text('默认深色主题'), findsOneWidget);
    });

    for (final viewportSize in [const Size(800, 600), const Size(360, 640)]) {
      testWidgets('${viewportSize.width.toInt()}px 下主题菜单锚定到右侧选择控件下方', (
        tester,
      ) async {
        tester.view.physicalSize = viewportSize;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await pumpApp(tester);

        await tester.tap(find.byTooltip('设置'));
        await tester.pumpAndSettle();

        final comboFinder = find.byType(PopupMenuButton<ThemeVariant>);
        final rowFinder = find.byKey(const ValueKey('theme_combo_row'));
        final comboRect = tester.getRect(comboFinder);
        final rowRect = tester.getRect(rowFinder);

        await tester.tap(rowFinder);
        await tester.pumpAndSettle();

        final firstItemRect = tester.getRect(
          find.byType(PopupMenuItem<ThemeVariant>).first,
        );
        expect(comboRect.width, lessThan(rowRect.width / 2));
        expect(firstItemRect.right, closeTo(comboRect.right, 1));
        expect(firstItemRect.top, greaterThanOrEqualTo(comboRect.bottom));
      });
    }

    testWidgets('Linux 字体入口只展示系统默认和系统字体', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('全局字体'));
      await tester.pumpAndSettle();

      expect(find.text('系统默认'), findsNWidgets(2));
      expect(find.text('系统字体'), findsOneWidget);
      expect(find.text('从本地导入'), findsNothing);
      expect(find.text('Google Fonts'), findsNothing);
    });

    testWidgets('窄窗口仍可进入设置并选择主题变体', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await pumpApp(tester);

      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();
      await selectTheme(tester, 'Tokyo 日');

      expect(find.text('设置'), findsOneWidget);
      expect(find.text('Tokyo 日'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('选择 Tokyo 日立即切换为浅色主题', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();
      await selectTheme(tester, 'Tokyo 日');

      final combo = tester.widget<PopupMenuButton<ThemeVariant>>(
        find.byType(PopupMenuButton<ThemeVariant>),
      );
      expect(combo.initialValue, ThemeVariant.tokyoDay);

      final settingsContext = tester.element(find.text('Tokyo 日'));
      expect(
        Theme.of(settingsContext).extension<TokyoPalette>()!.bg,
        const Color(0xFFE1E2E7),
      );
      expect(
        Theme.of(settingsContext).scaffoldBackgroundColor,
        const Color(0xFFE1E2E7),
      );

      await tester.pageBack();
      await tester.pumpAndSettle();

      final libraryContext = tester.element(find.text('书库'));
      expect(
        Theme.of(libraryContext).extension<TokyoPalette>()!.bg,
        const Color(0xFFE1E2E7),
      );
    });

    testWidgets('选择 Tokyo 风暴应用深蓝灰调，选择 Tokyo 夜恢复默认', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();
      await selectTheme(tester, 'Tokyo 风暴');

      final combo = tester.widget<PopupMenuButton<ThemeVariant>>(
        find.byType(PopupMenuButton<ThemeVariant>),
      );
      expect(combo.initialValue, ThemeVariant.tokyoStorm);
      expect(
        Theme.of(
          tester.element(find.text('Tokyo 风暴')),
        ).extension<TokyoPalette>()!.bg,
        const Color(0xFF24283B),
      );

      await selectTheme(tester, 'Tokyo 夜');

      final restoredCombo = tester.widget<PopupMenuButton<ThemeVariant>>(
        find.byType(PopupMenuButton<ThemeVariant>),
      );
      expect(restoredCombo.initialValue, ThemeVariant.tokyoNight);
      expect(
        Theme.of(
          tester.element(find.text('Tokyo 夜')),
        ).extension<TokyoPalette>()!.bg,
        const Color(0xFF1A1B26),
      );
    });

    testWidgets('重建应用后保持上次选择的主题', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();
      await selectTheme(tester, 'Tokyo 日');

      await tester.pumpWidget(const SizedBox());
      await pumpApp(tester);

      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();

      final combo = tester.widget<PopupMenuButton<ThemeVariant>>(
        find.byType(PopupMenuButton<ThemeVariant>),
      );
      expect(combo.initialValue, ThemeVariant.tokyoDay);
      expect(
        Theme.of(
          tester.element(find.text('Tokyo 日')),
        ).extension<TokyoPalette>()!.bg,
        const Color(0xFFE1E2E7),
      );
    });

    testWidgets('重建应用后保持 Tokyo 风暴选择', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();
      await selectTheme(tester, 'Tokyo 风暴');

      await tester.pumpWidget(const SizedBox());
      await pumpApp(tester);

      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();

      final combo = tester.widget<PopupMenuButton<ThemeVariant>>(
        find.byType(PopupMenuButton<ThemeVariant>),
      );
      expect(combo.initialValue, ThemeVariant.tokyoStorm);
      expect(
        Theme.of(
          tester.element(find.text('Tokyo 风暴')),
        ).extension<TokyoPalette>()!.bg,
        const Color(0xFF24283B),
      );
    });

    testWidgets('阅读页不显示设置入口', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final storage = MemoryLibraryStorage();
      await tester.runAsync(() async {
        await storage.writeBook(
          BookMetadata(
            id: 'book-1',
            title: '一本标题非常非常长但仍然可以在窄窗口阅读的测试之书',
            importedAt: DateTime(2026, 8, 5),
          ),
          BookContent(text: '很久很久以前……'),
        );
      });

      await pumpApp(tester, libraryStorage: storage);
      await tester.tap(find.text('一本标题非常非常长但仍然可以在窄窗口阅读的测试之书'));
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('设置'), findsNothing);
      expect(find.text('一本标题非常非常长但仍然可以在窄窗口阅读的测试之书'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
