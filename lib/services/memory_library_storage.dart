import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/book_content.dart';
import '../models/book_metadata.dart';
import 'library_storage.dart';

/// 内存后端：按「书籍文件 + 元数据索引」布局工作的 [LibraryStorage] 实现。
class MemoryLibraryStorage implements LibraryStorage {
  MemoryLibraryStorage({Map<String, String>? files}) : _files = {...?files};

  final Map<String, String> _files;

  @visibleForTesting
  Map<String, String> get debugFiles => Map.unmodifiable(_files);

  @override
  Future<List<BookMetadata>> readMetadataIndex() async {
    final raw = _files[LibraryStorage.indexFileName];
    if (raw == null) return [];

    final index = jsonDecode(raw) as Map<String, dynamic>;
    final version = index['schemaVersion'] as int?;
    if (version != LibraryStorage.schemaVersion) {
      throw StateError('不支持的元数据索引版本：$version');
    }

    final books = index['books'] as List<dynamic>? ?? [];
    return [
      for (final item in books)
        BookMetadata.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  @override
  Future<BookContent?> readBookContent(String bookId) async {
    final raw = _files[LibraryStorage.bookFileName(bookId)];
    if (raw == null) return null;
    return BookContent(text: raw);
  }

  @override
  Future<void> writeBook(BookMetadata metadata, BookContent content) async {
    _files[LibraryStorage.bookFileName(metadata.id)] = content.text;
    await _updateMetadataIndex((books) {
      final index = books.indexWhere((book) => book.id == metadata.id);
      if (index == -1) {
        books.add(metadata);
      } else {
        books[index] = metadata;
      }
    });
  }

  @override
  Future<void> deleteBook(String bookId) async {
    _files.remove(LibraryStorage.bookFileName(bookId));
    await _updateMetadataIndex((books) {
      books.removeWhere((book) => book.id == bookId);
    });
  }

  @override
  Future<void> writeMetadataIndex(List<BookMetadata> books) async {
    _files[LibraryStorage.indexFileName] = jsonEncode({
      'schemaVersion': LibraryStorage.schemaVersion,
      'books': [for (final book in books) book.toJson()],
    });
  }

  Future<void> _updateMetadataIndex(
    void Function(List<BookMetadata> books) update,
  ) async {
    final books = [...await readMetadataIndex()];
    update(books);
    await writeMetadataIndex(books);
  }
}
