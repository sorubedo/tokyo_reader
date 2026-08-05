import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'providers/theme_provider.dart';
import 'services/storage_factory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(ThemeProvider.boxName);
  final libraryStorage = await createDefaultLibraryStorage();
  runApp(TokyoReaderApp(libraryStorage: libraryStorage));
}
