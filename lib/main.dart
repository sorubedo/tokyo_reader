import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app.dart';
import 'providers/library_provider.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox(LibraryProvider.boxName);
  await Hive.openBox(ThemeProvider.boxName);
  runApp(const TokyoReaderApp());
}
