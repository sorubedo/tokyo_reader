import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/tokyo_night.dart';
import 'pages/library_page.dart';
import 'pages/reader_page.dart';
import 'providers/library_provider.dart';

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const LibraryPage()),
    GoRoute(
      path: '/reader/:id',
      builder: (context, state) =>
          ReaderPage(bookId: state.pathParameters['id']!),
    ),
  ],
);

class TokyoReaderApp extends StatelessWidget {
  const TokyoReaderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LibraryProvider()..init(),
      child: MaterialApp.router(
        title: '东京阅读',
        debugShowCheckedModeBanner: false,
        theme: buildTokyoNightTheme(),
        darkTheme: buildTokyoNightTheme(),
        themeMode: ThemeMode.dark,
        routerConfig: _router,
      ),
    );
  }
}
