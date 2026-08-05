import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'app.dart';
import 'providers/library_provider_factory.dart';

Future<void> main() async {
  enableFlutterDriverExtension();
  WidgetsFlutterBinding.ensureInitialized();
  final libraryProvider = createDefaultLibraryProvider();
  await libraryProvider.init();
  runApp(TokyoReaderApp(libraryProvider: libraryProvider));
}
