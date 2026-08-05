import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'pages/library_page.dart';
import 'pages/reader_page.dart';
import 'pages/settings_page.dart';
import 'providers/library_provider.dart';
import 'providers/theme_provider.dart';
import 'services/library_storage.dart';
import 'services/memory_library_storage.dart';

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
  const TokyoReaderApp({super.key, this.libraryStorage});

  final LibraryStorage? libraryStorage;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) =>
              LibraryProvider(storage: libraryStorage ?? MemoryLibraryStorage())
                ..init(),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()..init()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: '东京阅读',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.currentVariant.buildTheme(),
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
