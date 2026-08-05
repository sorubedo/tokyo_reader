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

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LibraryPage()),
    GoRoute(
      path: '/reader/:id',
      builder: (context, state) =>
          ReaderPage(bookId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
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
          return MaterialApp.router(
            title: '东京阅读',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentVariant.buildTheme(
              fontProvider: fontProvider,
            ),
            routerConfig: _router,
            builder: (context, child) {
              final family = fontProvider.effectiveFamily;
              if (family == null || family.isEmpty) {
                return child ?? const SizedBox.shrink();
              }
              return DefaultTextStyle.merge(
                style: TextStyle(fontFamily: family),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
