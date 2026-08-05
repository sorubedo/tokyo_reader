import 'package:flutter/material.dart';

import 'app.dart';
import 'services/storage_factory.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final libraryStorage = await createDefaultLibraryStorage();
  runApp(TokyoReaderApp(libraryStorage: libraryStorage));
}
