import 'package:flutter/foundation.dart';

import '../models/book_content.dart';
import '../models/book_metadata.dart';
import '../services/file_import_service.dart';
import '../services/library_directory_adapter.dart';
import '../services/library_storage.dart';

/// 书库状态：基于 [LibraryStorage] 读写书籍元数据，正文按需读取。
class LibraryProvider extends ChangeNotifier {
  LibraryProvider({
    this.storage,
    this.directoryAdapter,
    this.filePicker = const FileImportService(),
  });

  LibraryStorage? storage;
  final LibraryDirectoryAdapter? directoryAdapter;
  final TxtFilePicker filePicker;
  final List<BookMetadata> _books = [];
  bool _loaded = false;

  bool get hasStorage => storage != null;
  List<BookMetadata> get books => List.unmodifiable(_books);
  bool get isLoaded => _loaded;

  Future<void> init() async {
    if (_loaded) return;
    var initialStorage = storage;
    initialStorage ??= (await directoryAdapter?.restore())?.storage;
    if (initialStorage != null) {
      _commitStorage(initialStorage, await _load(initialStorage));
    }
    _loaded = true;
    notifyListeners();
  }

  /// 选择、验证并记住新的书库目录，取消选择时返回 null。
  Future<String?> selectDirectory() async {
    final directoryAdapter = this.directoryAdapter;
    if (directoryAdapter == null) {
      throw StateError('当前环境不支持选择书库目录');
    }

    final selection = await directoryAdapter.select();
    if (selection == null) return null;

    final loaded = await _load(selection.storage);
    await directoryAdapter.remember(selection);
    _commitStorage(selection.storage, loaded);
    _loaded = true;
    notifyListeners();
    return selection.label;
  }

  Future<void> refresh() async {
    await _reload();
    notifyListeners();
  }

  BookMetadata? bookById(String id) {
    for (final metadata in _books) {
      if (metadata.id == id) return metadata;
    }
    return null;
  }

  /// 按需读取书籍正文，Provider 不缓存整库正文。
  Future<BookContent?> readBookContent(String bookId) async {
    final storage = this.storage;
    if (storage == null) return null;
    return storage.readBookContent(bookId);
  }

  /// 选择 TXT 文件并完成元数据创建、持久化与书库刷新。
  Future<BookMetadata?> importTxt() async {
    final storage = this.storage;
    if (storage == null) throw StateError('尚未选择书库目录');

    final importedFile = await filePicker.pickTxtFile();
    if (importedFile == null) return null;

    final now = DateTime.now();
    final metadata = BookMetadata(
      id: now.microsecondsSinceEpoch.toString(),
      title: _titleFromFileName(importedFile.name),
      importedAt: now,
    );
    await storage.writeBook(metadata, BookContent(text: importedFile.content));
    await _reload();
    notifyListeners();
    return bookById(metadata.id);
  }

  Future<void> deleteBook(String id) async {
    final storage = this.storage;
    if (storage == null) throw StateError('尚未选择书库目录');

    final before = _books.length;
    await storage.deleteBook(id);
    await _reload();
    if (_books.length == before) return;
    notifyListeners();
  }

  Future<void> _reload() async {
    final storage = this.storage;
    if (storage == null) return;
    _replaceBooks(await _load(storage));
  }

  Future<List<BookMetadata>> _load(LibraryStorage storage) async {
    final loaded = await storage.scan();
    loaded.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    return loaded;
  }

  void _commitStorage(LibraryStorage storage, List<BookMetadata> loaded) {
    this.storage = storage;
    _replaceBooks(loaded);
  }

  void _replaceBooks(List<BookMetadata> loaded) {
    _books
      ..clear()
      ..addAll(loaded);
  }

  String _titleFromFileName(String fileName) {
    if (!fileName.toLowerCase().endsWith('.txt')) return fileName;
    return fileName.substring(0, fileName.length - 4);
  }
}
