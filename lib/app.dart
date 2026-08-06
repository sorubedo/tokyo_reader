import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'pages/library_page.dart';
import 'pages/reader_page.dart';
import 'pages/settings_page.dart';
import 'providers/library_provider.dart';
import 'providers/global_font_provider.dart';
import 'providers/theme_provider.dart';
import 'services/library_storage.dart';
import 'widgets/adwaita_components.dart';

Page<void> _appPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: appTransitionDuration,
    reverseTransitionDuration: appTransitionDuration,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        appPageTransition(context, animation, child),
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => _appPage(state, const LibraryPage()),
    ),
    GoRoute(
      path: '/reader/:id',
      pageBuilder: (context, state) =>
          _appPage(state, ReaderPage(bookId: state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) => _appPage(state, const SettingsPage()),
    ),
  ],
);

class TokyoReaderApp extends StatelessWidget {
  const TokyoReaderApp({super.key, this.libraryStorage, this.libraryProvider})
    : assert(libraryStorage == null || libraryProvider == null);

  final LibraryStorage? libraryStorage;
  final LibraryProvider? libraryProvider;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) {
            final provider = libraryProvider;
            if (provider != null) return provider;
            return LibraryProvider(storage: libraryStorage)..init();
          },
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
        ChangeNotifierProvider(create: (_) => GlobalFontProvider()..init()),
      ],
      child: Consumer2<ThemeProvider, GlobalFontProvider>(
        builder: (context, themeProvider, fontProvider, _) {
          return _TokyoMaterialApp(
            themeProvider: themeProvider,
            fontProvider: fontProvider,
          );
        },
      ),
    );
  }
}

class _TokyoMaterialApp extends StatefulWidget {
  const _TokyoMaterialApp({
    required this.themeProvider,
    required this.fontProvider,
  });

  final ThemeProvider themeProvider;
  final GlobalFontProvider fontProvider;

  @override
  State<_TokyoMaterialApp> createState() => _TokyoMaterialAppState();
}

class _TokyoMaterialAppState extends State<_TokyoMaterialApp>
    with WidgetsBindingObserver {
  late bool _reduceMotion;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reduceMotion = _platformPrefersReducedMotion();
  }

  @override
  void didChangeAccessibilityFeatures() {
    final reduceMotion = _platformPrefersReducedMotion();
    if (reduceMotion != _reduceMotion) {
      setState(() => _reduceMotion = reduceMotion);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  bool _platformPrefersReducedMotion() {
    final features =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    return features.disableAnimations || features.reduceMotion;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '东京阅读',
      debugShowCheckedModeBanner: false,
      themeAnimationDuration: appTransitionDuration,
      themeAnimationStyle: _reduceMotion
          ? AnimationStyle.noAnimation
          : const AnimationStyle(
              duration: appTransitionDuration,
              curve: Curves.easeOutCubic,
            ),
      theme: widget.themeProvider.currentVariant.buildTheme(
        fontProvider: widget.fontProvider,
      ),
      routerConfig: _router,
      builder: (context, child) {
        final family = widget.fontProvider.effectiveFamily;
        if (family == null || family.isEmpty) {
          return child ?? const SizedBox.shrink();
        }
        return DefaultTextStyle.merge(
          style: TextStyle(fontFamily: family),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
