import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/tokyo_palette.dart';
import '../models/book_metadata.dart';
import '../providers/library_provider.dart';
import '../services/file_import_service.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('书库'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () => _importTxt(context),
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('导入 TXT'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: '设置',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.push('/settings'),
            ),
          ),
        ],
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, library, _) {
          if (!library.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (library.books.isEmpty) {
            return const _EmptyLibrary();
          }
          return _BookList(books: library.books);
        },
      ),
    );
  }

  Future<void> _importTxt(BuildContext context) async {
    final library = context.read<LibraryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await const FileImportService().pickTxtFile();
      if (result == null) return;

      final title = result.name.toLowerCase().endsWith('.txt')
          ? result.name.substring(0, result.name.length - 4)
          : result.name;
      await library.addBook(title: title, content: result.content);

      messenger.showSnackBar(SnackBar(content: Text('已导入《$title》')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('导入失败：$error')));
    }
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<TokyoPalette>()!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.library_books_outlined, size: 64, color: palette.comment),
          const SizedBox(height: 16),
          Text('书库还是空的', style: TextStyle(fontSize: 16, color: palette.fg)),
          const SizedBox(height: 8),
          Text(
            '点击右上角「导入 TXT」添加第一本书',
            style: TextStyle(fontSize: 13, color: palette.fgDark),
          ),
        ],
      ),
    );
  }
}

class _BookList extends StatelessWidget {
  const _BookList({required this.books});

  final List<BookMetadata> books;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<TokyoPalette>()!;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: books.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final book = books[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: Icon(Icons.menu_book_rounded, color: palette.blue),
          title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(_formatDate(book.importedAt)),
          trailing: IconButton(
            tooltip: '删除',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, book),
          ),
          onTap: () => context.push('/reader/${book.id}'),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, BookMetadata book) async {
    final palette = Theme.of(context).extension<TokyoPalette>()!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('删除书籍'),
          content: Text('确定删除《${book.title}》吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('删除', style: TextStyle(color: palette.red)),
            ),
          ],
        );
      },
    );
    if (confirmed ?? false) {
      if (!context.mounted) return;
      await context.read<LibraryProvider>().deleteBook(book.id);
    }
  }

  String _formatDate(DateTime time) {
    final local = time.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
