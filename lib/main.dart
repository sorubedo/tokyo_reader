import 'package:flutter/material.dart';

import 'app.dart';
import 'providers/library_provider_factory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final libraryProvider = createDefaultLibraryProvider();
  await libraryProvider.init();
  runApp(TokyoReaderApp(libraryProvider: libraryProvider));
}
