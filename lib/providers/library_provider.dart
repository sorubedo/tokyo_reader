import 'package:flutter/foundation.dart';

import '../models/book_content.dart';
import '../models/book_metadata.dart';
import '../services/library_storage.dart';

/// 书库状态：基于 [LibraryStorage] 读写书籍元数据，正文按需读取。
class LibraryProvider extends ChangeNotifier {
  LibraryProvider({required this.storage});

  final LibraryStorage storage;
  final List<BookMetadata> _books = [];
  bool _loaded = false;

  List<BookMetadata> get books => List.unmodifiable(_books);
  bool get isLoaded => _loaded;

  Future<void> init() async {
    if (_loaded) return;
    await _reload();
    _loaded = true;
    notifyListeners();
  }

  BookMetadata? bookById(String id) {
    for (final metadata in _books) {
      if (metadata.id == id) return metadata;
    }
    return null;
  }

  /// 按需读取书籍正文，Provider 不缓存整库正文。
  Future<BookContent?> readBookContent(String bookId) {
    return storage.readBookContent(bookId);
  }

  Future<void> addBook({required String title, required String content}) async {
    final now = DateTime.now();
    final metadata = BookMetadata(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      importedAt: now,
    );
    await storage.writeBook(metadata, BookContent(text: content));
    await _reload();
    notifyListeners();
  }

  Future<void> deleteBook(String id) async {
    final before = _books.length;
    await storage.deleteBook(id);
    await _reload();
    if (_books.length == before) return;
    notifyListeners();
  }

  Future<void> _reload() async {
    final loaded = await storage.readMetadataIndex();
    loaded.sort((a, b) => b.importedAt.compareTo(a.importedAt));
    _books
      ..clear()
      ..addAll(loaded);
  }
}
