import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokyo_reader/services/io_library_directory_adapter.dart';
import 'package:tokyo_reader/services/library_directory_adapter.dart';
import 'package:tokyo_reader/services/memory_library_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDirectory;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDirectory = await Directory.systemTemp.createTemp(
      'tokyo_reader_directory_test',
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('恢复已保存且存在的书库目录', () async {
    SharedPreferences.setMockInitialValues({
      IoLibraryDirectoryAdapter.savedPathKey: tempDirectory.path,
    });

    final selection = await const IoLibraryDirectoryAdapter().restore();

    expect(selection?.label, tempDirectory.path);
    expect(selection?.storage, isNotNull);
  });

  test('已保存目录不存在时忽略该路径', () async {
    SharedPreferences.setMockInitialValues({
      IoLibraryDirectoryAdapter.savedPathKey: '${tempDirectory.path}/missing',
    });

    final selection = await const IoLibraryDirectoryAdapter().restore();

    expect(selection, isNull);
  });

  test('记住成功激活的书库目录', () async {
    const adapter = IoLibraryDirectoryAdapter();
    final selection = LibraryDirectorySelection(
      label: tempDirectory.path,
      storage: MemoryLibraryStorage(),
    );

    await adapter.remember(selection);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getString(IoLibraryDirectoryAdapter.savedPathKey),
      tempDirectory.path,
    );
  });
}
