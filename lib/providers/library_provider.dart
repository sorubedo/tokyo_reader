import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/book.dart';

/// 书库状态：负责从 Hive 读取/写入书籍列表。
class LibraryProvider extends ChangeNotifier {
  LibraryProvider([this._box]);

  static const String boxName = 'library';
  static const String booksKey = 'books';

  Box? _box;
  final List<Book> _books = [];
  bool _loaded = false;

  List<Book> get books => List.unmodifiable(_books);
  bool get isLoaded => _loaded;

  Future<void> init() async {
    if (_loaded) return;
    _box ??= Hive.box(boxName);

    final raw = _box!.get(booksKey);
    if (raw is List) {
      final loaded = <Book>[];
      for (final item in raw) {
        if (item is Map) {
          loaded.add(Book.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      loaded.sort((a, b) => b.importedAt.compareTo(a.importedAt));
      _books
        ..clear()
        ..addAll(loaded);
    }

    _loaded = true;
    notifyListeners();
  }

  Book? bookById(String id) {
    for (final book in _books) {
      if (book.id == id) return book;
    }
    return null;
  }

  Future<void> addBook({required String title, required String content}) async {
    final now = DateTime.now();
    final book = Book(
      id: now.microsecondsSinceEpoch.toString(),
      title: title,
      content: content,
      importedAt: now,
    );
    _books.insert(0, book);
    await _persist();
    notifyListeners();
  }

  Future<void> deleteBook(String id) async {
    final before = _books.length;
    _books.removeWhere((book) => book.id == id);
    if (_books.length == before) return;
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    final box = _box;
    if (box == null) return;
    await box.put(booksKey, _books.map((book) => book.toJson()).toList());
  }

  @visibleForTesting
  void debugSetBooks(Iterable<Book> books) {
    _books
      ..clear()
      ..addAll(books);
    _loaded = true;
    notifyListeners();
  }
}
