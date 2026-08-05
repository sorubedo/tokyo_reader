import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';

import 'app.dart';
import 'services/storage_factory.dart';

Future<void> main() async {
  enableFlutterDriverExtension();
  WidgetsFlutterBinding.ensureInitialized();
  final libraryStorage = await createDefaultLibraryStorage();
  runApp(TokyoReaderApp(libraryStorage: libraryStorage));
}
