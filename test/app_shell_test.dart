import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokyo_reader/app.dart';
import 'package:tokyo_reader/core/tokyo_palette.dart';
import 'package:tokyo_reader/core/tokyo_theme.dart';
import 'package:tokyo_reader/providers/theme_provider.dart';
import 'package:tokyo_reader/services/memory_library_storage.dart';
import 'package:tokyo_reader/widgets/adwaita_components.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('应用壳', () {
    for (final variant in ThemeVariant.values) {
      testWidgets('${variant.label} 在桌面和窄窗口使用完整语义应用壳', (tester) async {
        tester.view.physicalSize = const Size(960, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          ThemeProvider.themeVariantKey: variant.storageId,
        });

        await tester.pumpWidget(
          TokyoReaderApp(libraryStorage: MemoryLibraryStorage()),
        );
        await tester.pumpAndSettle();

        final context = tester.element(find.text('书库'));
        final theme = Theme.of(context);
        final palette = theme.extension<TokyoPalette>()!;

        expect(find.byType(AppHeaderBar), findsOneWidget);
        expect(
          tester.widget(find.byKey(const ValueKey('import_button'))),
          isA<FilledButton>(),
        );
        expect(theme.scaffoldBackgroundColor, palette.window);
        expect(theme.colorScheme.primary, palette.accent);
        expect(theme.colorScheme.error, palette.destructive);
        expect(theme.colorScheme.secondary, palette.success);
        expect(theme.appBarTheme.backgroundColor, palette.headerBar);
        expect(theme.dividerColor, palette.border.withValues(alpha: 0.35));
        expect(theme.focusColor, palette.accent.withValues(alpha: 0.36));
        expect(palette.warning, isNot(palette.window));

        tester.view.physicalSize = const Size(360, 640);
        await tester.pumpAndSettle();

        expect(
          tester.widget(find.byKey(const ValueKey('import_button'))),
          isA<IconButton>(),
        );
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('窄窗口的长标题、返回导航和操作不会重叠', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTokyoNightTheme(),
          home: Scaffold(
            appBar: AppHeaderBar(
              title: '这是一本标题非常非常长的测试书籍，需要在窄窗口省略',
              showBack: true,
              actions: [
                AppHeaderAction(
                  icon: Icons.settings_outlined,
                  label: '设置',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      final title = tester.widget<Text>(find.text('这是一本标题非常非常长的测试书籍，需要在窄窗口省略'));
      expect(title.overflow, TextOverflow.ellipsis);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byTooltip('设置'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final firstFocusedContext = FocusManager.instance.primaryFocus?.context;
      expect(
        firstFocusedContext?.findAncestorWidgetOfExactType<BackButton>(),
        isNotNull,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      final secondFocusedContext = FocusManager.instance.primaryFocus?.context;
      expect(
        secondFocusedContext?.findAncestorWidgetOfExactType<IconButton>(),
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('减少动态效果时应用壳关闭非必要动画', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTokyoNightTheme(),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: StatusPage(
              icon: Icons.library_books_outlined,
              title: '空状态',
              description: '测试说明',
            ),
          ),
        ),
      );

      final statusContext = tester.element(find.byType(StatusPage));
      expect(appMotionDuration(statusContext), Duration.zero);
      expect(appAnimationStyle(statusContext), AnimationStyle.noAnimation);
    });

    testWidgets('系统减少动态效果时主题切换不使用动画', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await tester.pumpWidget(
        TokyoReaderApp(libraryStorage: MemoryLibraryStorage()),
      );
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeAnimationDuration, appTransitionDuration);
      expect(app.themeAnimationStyle, AnimationStyle.noAnimation);
    });

    testWidgets('成功与错误 Toast 使用不同停留时长', (tester) async {
      late BuildContext toastContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTokyoNightTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                toastContext = context;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      showAppToast(toastContext, '成功', kind: AppToastKind.success);
      await tester.pump();
      expect(
        tester
            .widget<SnackBar>(
              find.ancestor(
                of: find.text('成功'),
                matching: find.byType(SnackBar),
              ),
            )
            .duration,
        const Duration(seconds: 2),
      );

      ScaffoldMessenger.of(toastContext).clearSnackBars();
      await tester.pumpAndSettle();
      showAppToast(toastContext, '失败', kind: AppToastKind.error);
      await tester.pump(appTransitionDuration);
      expect(
        tester
            .widget<SnackBar>(
              find.ancestor(
                of: find.text('失败'),
                matching: find.byType(SnackBar),
              ),
            )
            .duration,
        const Duration(seconds: 4),
      );
    });
  });
}
