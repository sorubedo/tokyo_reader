import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/tokyo_palette.dart';
import '../models/book_metadata.dart';
import '../providers/library_provider.dart';
import '../widgets/adwaita_components.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final canImport = context.select<LibraryProvider, bool>(
      (library) => library.hasStorage,
    );
    return Scaffold(
      appBar: AppHeaderBar(
        title: '书库',
        actions: [
          AppHeaderAction(
            key: const ValueKey('import_button'),
            icon: Icons.upload_file,
            label: '导入 TXT',
            isPrimary: true,
            onPressed: canImport ? () => _importTxt(context) : null,
          ),
          AppHeaderAction(
            key: const ValueKey('settings_button'),
            icon: Icons.settings_outlined,
            label: '设置',
            tooltip: '设置',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, library, _) {
          if (!library.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!library.hasStorage) {
            return _ChooseDirectory(onSelect: () => _selectDirectory(context));
          }
          if (library.books.isEmpty) {
            return _EmptyLibrary(onImport: () => _importTxt(context));
          }
          return _BookList(books: library.books);
        },
      ),
    );
  }

  Future<void> _importTxt(BuildContext context) async {
    final library = context.read<LibraryProvider>();
    try {
      final imported = await library.importTxt();
      if (imported == null) return;
      if (!context.mounted) return;

      showAppToast(
        context,
        '已导入《${imported.title}》',
        kind: AppToastKind.success,
      );
    } catch (error) {
      if (!context.mounted) return;
      showAppToast(context, '导入失败：$error', kind: AppToastKind.error);
    }
  }

  Future<void> _selectDirectory(BuildContext context) async {
    final library = context.read<LibraryProvider>();
    try {
      final path = await library.selectDirectory();
      if (path == null) return;
      if (!context.mounted) return;

      showAppToast(context, '书库目录：$path', kind: AppToastKind.success);
    } catch (error) {
      if (!context.mounted) return;
      showAppToast(context, '选择目录失败：$error', kind: AppToastKind.error);
    }
  }
}

class _ChooseDirectory extends StatelessWidget {
  const _ChooseDirectory({required this.onSelect});

  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return StatusPage(
      icon: Icons.folder_open_outlined,
      title: '还没有选择书库目录',
      description: '选择一个目录后，导入的书籍会保存在这里。',
      action: FilledButton.icon(
        key: const ValueKey('choose_directory_button'),
        onPressed: onSelect,
        icon: const Icon(Icons.create_new_folder_outlined, size: 18),
        label: const Text('选择书库目录'),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return StatusPage(
      icon: Icons.library_books_outlined,
      title: '书库还是空的',
      description: '点击右上角「导入 TXT」添加第一本书',
      action: FilledButton.icon(
        key: const ValueKey('empty_import_button'),
        onPressed: onImport,
        icon: const Icon(Icons.upload_file, size: 18),
        label: const Text('导入书籍'),
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
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        BoxedList(
          children: [
            for (var index = 0; index < books.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              _bookRow(context, books[index], palette),
            ],
          ],
        ),
      ],
    );
  }

  Widget _bookRow(
    BuildContext context,
    BookMetadata book,
    TokyoPalette palette,
  ) {
    return ListTile(
      key: ValueKey('book_${book.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Icon(Icons.menu_book_rounded, color: palette.accent),
      title: Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${_formatDate(book.importedAt)}'
        '${book.externalModified ? ' · 外部修改' : ''}',
      ),
      trailing: PopupMenuButton<String>(
        key: ValueKey('delete_${book.id}'),
        tooltip: '更多操作',
        icon: const Icon(Icons.more_vert),
        popUpAnimationStyle: appAnimationStyle(context),
        onSelected: (value) {
          if (value == 'delete') _confirmDelete(context, book);
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: 'delete',
            key: ValueKey('delete_menu_${book.id}'),
            child: Row(
              children: [
                Icon(Icons.delete_outline, color: palette.destructive),
                const SizedBox(width: 8),
                const Text('删除'),
              ],
            ),
          ),
        ],
      ),
      onTap: () => context.push('/reader/${book.id}'),
    );
  }

  Future<void> _confirmDelete(BuildContext context, BookMetadata book) async {
    final confirmed = await showAppMessageDialog(
      context,
      title: '删除书籍',
      message: '确定删除《${book.title}》吗？',
      confirmLabel: '删除',
      destructive: true,
    );
    if (confirmed) {
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
