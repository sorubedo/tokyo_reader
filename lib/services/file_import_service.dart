import 'package:file_selector/file_selector.dart';

class ImportedTxtFile {
  const ImportedTxtFile({required this.name, required this.content});

  final String name;
  final String content;
}

class FileImportService {
  const FileImportService();

  /// 弹出系统文件选择框，只允许选择 txt 文件。
  Future<ImportedTxtFile?> pickTxtFile() async {
    const typeGroup = XTypeGroup(
      label: 'TXT 文本',
      extensions: ['txt'],
      mimeTypes: ['text/plain'],
    );

    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return null;

    final content = await file.readAsString();
    return ImportedTxtFile(name: file.name, content: content);
  }
}
