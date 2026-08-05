import 'package:dir_picker/dir_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 桌面端书库目录的选取与位置持久化。
class LibraryDirectoryService {
  const LibraryDirectoryService();

  static const String savedPathKey = 'library_directory_path';

  /// 弹出系统目录选择器，返回选中的本地目录路径；取消时返回 null。
  Future<String?> pickDirectoryPath() async {
    final location = await DirPicker.pick();
    if (location is IOPickedLocation) {
      return location.uri.toFilePath();
    }
    return null;
  }

  Future<String?> readSavedPath() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(savedPathKey);
  }

  Future<void> savePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(savedPathKey, path);
  }
}
