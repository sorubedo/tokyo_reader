import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tokyo_reader/app.dart';
import 'package:tokyo_reader/core/tokyo_palette.dart';
import 'package:tokyo_reader/core/tokyo_theme.dart';
import 'package:tokyo_reader/models/book.dart';
import 'package:tokyo_reader/providers/library_provider.dart';
import 'package:tokyo_reader/providers/theme_provider.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('tokyo_reader_test');
    Hive.init(tempDir.path);
    await Hive.openBox(LibraryProvider.boxName, bytes: Uint8List(0));
    await Hive.openBox(ThemeProvider.boxName, bytes: Uint8List(0));
  });

  setUp(() async {
    await Hive.box<dynamic>(LibraryProvider.boxName).clear();
    await Hive.box<dynamic>(ThemeProvider.boxName).clear();
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const TokyoReaderApp());
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

    final group = tester.widget<RadioGroup<ThemeVariant>>(
      find.byType(RadioGroup<ThemeVariant>),
    );
    expect(group.groupValue, ThemeVariant.tokyoNight);
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

  testWidgets('阅读页不显示设置入口', (tester) async {
    await Hive.box<dynamic>(
      LibraryProvider.boxName,
    ).put(LibraryProvider.booksKey, [
      Book(
        id: 'book-1',
        title: '测试之书',
        content: '很久很久以前……',
        importedAt: DateTime(2026, 8, 5),
      ).toJson(),
    ]);

    await pumpApp(tester);
    await tester.tap(find.text('测试之书'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('设置'), findsNothing);
    expect(find.text('测试之书'), findsOneWidget);
  });
}
