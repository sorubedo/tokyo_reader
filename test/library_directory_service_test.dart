import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokyo_reader/services/library_directory_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('保存的书库目录路径可以读回', () async {
    SharedPreferences.setMockInitialValues({});
    const service = LibraryDirectoryService();

    await service.savePath('/tmp/tokyo_reader_library');

    expect(await service.readSavedPath(), '/tmp/tokyo_reader_library');
  });
}
