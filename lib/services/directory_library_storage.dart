import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:fs_shim/fs_shim.dart';
import 'package:path/path.dart' as p;

import '../models/book_content.dart';
import '../models/book_metadata.dart';
import '../models/content_fingerprint.dart';
import 'content_hasher.dart';
import 'library_storage.dart';

/// 基于文件系统实现的 [LibraryStorage]：按「书籍文件 + 元数据索引」布局工作。
///
/// 同一份逻辑可运行在 IO、Web（OPFS / IndexedDB）与内存文件系统上，
/// 只需注入不同的 [FileSystem] 与根目录。
class DirectoryLibraryStorage implements LibraryStorage {
  DirectoryLibraryStorage({
    required this.fileSystem,
    required this.rootPath,
    ContentHasher? hasher,
  }) : _hasher = hasher ?? const Sha256ContentHasher();

  final FileSystem fileSystem;
  final String rootPath;
  final ContentHasher _hasher;

  Directory get _root => fileSystem.directory(rootPath);

  File _bookFile(String bookId) {
    return fileSystem.file(
      p.join(rootPath, LibraryStorage.bookFileName(bookId)),
    );
  }

  File get _indexFile {
    return fileSystem.file(p.join(rootPath, LibraryStorage.indexFileName));
  }

  @override
  Future<List<BookMetadata>> readMetadataIndex() async {
    final file = _indexFile;
    if (!await file.exists()) return [];

    final index = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
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
    final file = _bookFile(bookId);
    if (!await file.exists()) return null;
    return BookContent(text: await file.readAsString());
  }

  @override
  Future<void> writeBook(BookMetadata metadata, BookContent content) async {
    await _ensureRoot();
    final file = _bookFile(metadata.id);
    await file.writeAsString(content.text);

    final stat = await file.stat();
    final stored = BookMetadata(
      id: metadata.id,
      title: metadata.title,
      importedAt: metadata.importedAt,
      readingProgress: metadata.readingProgress,
      contentFingerprint: ContentFingerprint(
        size: stat.size,
        modifiedAt: stat.modified,
        sha256: await _hasher.hash(content.text),
      ),
      externalModified: false,
    );

    await _updateMetadataIndex((books) {
      final index = books.indexWhere((book) => book.id == stored.id);
      if (index == -1) {
        books.add(stored);
      } else {
        books[index] = stored;
      }
    });
  }

  @override
  Future<void> deleteBook(String bookId) async {
    final file = _bookFile(bookId);
    if (await file.exists()) {
      await file.delete();
    }
    await _updateMetadataIndex((books) {
      books.removeWhere((book) => book.id == bookId);
    });
  }

  @override
  Future<void> writeMetadataIndex(List<BookMetadata> books) async {
    await _ensureRoot();
    await _indexFile.writeAsString(
      jsonEncode({
        'schemaVersion': LibraryStorage.schemaVersion,
        'books': [for (final book in books) book.toJson()],
      }),
    );
  }

  @override
  Future<List<BookMetadata>> scan() async {
    await _ensureRoot();
    final byId = {for (final book in await readMetadataIndex()) book.id: book};

    final bookFiles = <File>[];
    await for (final entity in _root.list()) {
      if (entity is File && p.extension(entity.path) == '.txt') {
        bookFiles.add(entity);
      }
    }

    for (final file in bookFiles) {
      final id = p.basenameWithoutExtension(file.path);
      final stat = await file.stat();
      final existing = byId[id];
      if (existing == null) {
        final content = await file.readAsString();
        byId[id] = BookMetadata(
          id: id,
          title: id,
          importedAt: stat.modified,
          contentFingerprint: ContentFingerprint(
            size: stat.size,
            modifiedAt: stat.modified,
            sha256: await _hasher.hash(content),
          ),
        );
        continue;
      }

      final stored = existing.contentFingerprint;
      final fastChanged =
          stored == null ||
          stored.size != stat.size ||
          stored.modifiedAt != stat.modified;
      var fingerprint = stored;
      var externalModified = existing.externalModified;
      if (fastChanged) {
        final content = await file.readAsString();
        fingerprint = ContentFingerprint(
          size: stat.size,
          modifiedAt: stat.modified,
          sha256: await _hasher.hash(content),
        );
        externalModified =
            stored != null && stored.sha256 != fingerprint.sha256;
      }
      byId[id] = BookMetadata(
        id: existing.id,
        title: existing.title,
        importedAt: existing.importedAt,
        readingProgress: existing.readingProgress,
        contentFingerprint: fingerprint,
        externalModified: externalModified,
      );
    }

    for (final entry in byId.entries.toList()) {
      if (!await _bookFile(entry.key).exists()) {
        byId[entry.key] = BookMetadata(
          id: entry.value.id,
          title: entry.value.title,
          importedAt: entry.value.importedAt,
          readingProgress: entry.value.readingProgress,
          contentFingerprint: entry.value.contentFingerprint,
          externalModified: true,
        );
      }
    }

    final updated = byId.values.toList();
    await writeMetadataIndex(updated);
    return updated;
  }

  Future<void> _ensureRoot() async {
    await _root.create(recursive: true);
  }

  Future<void> _updateMetadataIndex(
    void Function(List<BookMetadata> books) update,
  ) async {
    final books = [...await readMetadataIndex()];
    update(books);
    await writeMetadataIndex(books);
  }

  @visibleForTesting
  Future<Map<String, String>> debugFiles() async {
    final result = <String, String>{};
    await for (final entity in _root.list()) {
      if (entity is File) {
        result[p.basename(entity.path)] = await entity.readAsString();
      }
    }
    return result;
  }
}
