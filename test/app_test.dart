import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokyo_reader/app.dart';
import 'package:tokyo_reader/core/tokyo_palette.dart';
import 'package:tokyo_reader/core/tokyo_theme.dart';
import 'package:tokyo_reader/models/book_content.dart';
import 'package:tokyo_reader/models/book_metadata.dart';
import 'package:tokyo_reader/services/library_storage.dart';
import 'package:tokyo_reader/services/memory_library_storage.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpApp(
    WidgetTester tester, {
    LibraryStorage? libraryStorage,
  }) async {
    await tester.pumpWidget(TokyoReaderApp(libraryStorage: libraryStorage));
    await tester.pumpAndSettle();
    final navigatorContext = tester.element(find.byType(Navigator).first);
    GoRouter.of(navigatorContext).go('/');
    await tester.pumpAndSettle();
  }

  testWidgets('从书库进入设置页，展示三种主题且默认选中 Tokyo 夜', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();

    expect(find.text('设置'), findsOneWidget);
    expect(find.text('外观'), findsOneWidget);
    expect(find.text('Tokyo 夜'), findsOneWidget);
    expect(find.text('Tokyo 日'), findsOneWidget);
    expect(find.text('Tokyo 风暴'), findsOneWidget);
    expect(find.text('默认深色主题'), findsOneWidget);
    expect(find.text('字体'), findsOneWidget);
    expect(find.text('全局字体'), findsOneWidget);
    expect(find.text('系统默认'), findsOneWidget);

    final group = tester.widget<RadioGroup<ThemeVariant>>(
      find.byType(RadioGroup<ThemeVariant>),
    );
    expect(group.groupValue, ThemeVariant.tokyoNight);
  });

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

  testWidgets('选择 Tokyo 日立即切换为浅色主题', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tokyo 日'));
    await tester.pumpAndSettle();

    final group = tester.widget<RadioGroup<ThemeVariant>>(
      find.byType(RadioGroup<ThemeVariant>),
    );
    expect(group.groupValue, ThemeVariant.tokyoDay);

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
    await tester.tap(find.text('Tokyo 风暴'));
    await tester.pumpAndSettle();

    final group = tester.widget<RadioGroup<ThemeVariant>>(
      find.byType(RadioGroup<ThemeVariant>),
    );
    expect(group.groupValue, ThemeVariant.tokyoStorm);
    expect(
      Theme.of(
        tester.element(find.text('Tokyo 风暴')),
      ).extension<TokyoPalette>()!.bg,
      const Color(0xFF24283B),
    );

    await tester.tap(find.text('Tokyo 夜'));
    await tester.pumpAndSettle();

    final restoredGroup = tester.widget<RadioGroup<ThemeVariant>>(
      find.byType(RadioGroup<ThemeVariant>),
    );
    expect(restoredGroup.groupValue, ThemeVariant.tokyoNight);
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
    await tester.tap(find.text('Tokyo 日'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester);

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();

    final group = tester.widget<RadioGroup<ThemeVariant>>(
      find.byType(RadioGroup<ThemeVariant>),
    );
    expect(group.groupValue, ThemeVariant.tokyoDay);
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
    await tester.tap(find.text('Tokyo 风暴'));
    await tester.pumpAndSettle();

    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester);

    await tester.tap(find.byTooltip('设置'));
    await tester.pumpAndSettle();

    final group = tester.widget<RadioGroup<ThemeVariant>>(
      find.byType(RadioGroup<ThemeVariant>),
    );
    expect(group.groupValue, ThemeVariant.tokyoStorm);
    expect(
      Theme.of(
        tester.element(find.text('Tokyo 风暴')),
      ).extension<TokyoPalette>()!.bg,
      const Color(0xFF24283B),
    );
  });

  testWidgets('阅读页不显示设置入口', (tester) async {
    final storage = MemoryLibraryStorage();
    await tester.runAsync(() async {
      await storage.writeBook(
        BookMetadata(
          id: 'book-1',
          title: '测试之书',
          importedAt: DateTime(2026, 8, 5),
        ),
        BookContent(text: '很久很久以前……'),
      );
    });

    await pumpApp(tester, libraryStorage: storage);
    await tester.tap(find.text('测试之书'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('设置'), findsNothing);
    expect(find.text('测试之书'), findsOneWidget);
  });
}
