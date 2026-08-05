import 'package:flutter_test/flutter_test.dart';
import 'package:tokyo_reader/models/book_content.dart';
import 'package:tokyo_reader/models/book_metadata.dart';
import 'package:tokyo_reader/providers/library_provider.dart';
import 'package:tokyo_reader/services/file_import_service.dart';
import 'package:tokyo_reader/services/library_directory_adapter.dart';
import 'package:tokyo_reader/services/memory_library_storage.dart';

class _ScanFailingStorage extends MemoryLibraryStorage {
  @override
  Future<List<BookMetadata>> scan() async {
    throw StateError('目录不可读');
  }
}

class _FakeLibraryDirectoryAdapter implements LibraryDirectoryAdapter {
  _FakeLibraryDirectoryAdapter({
    this.restored,
    this.selected,
    this.rememberError,
  });

  final LibraryDirectorySelection? restored;
  final LibraryDirectorySelection? selected;
  final Object? rememberError;
  int rememberCalls = 0;

  @override
  Future<LibraryDirectorySelection?> restore() async => restored;

  @override
  Future<LibraryDirectorySelection?> select() async => selected;

  @override
  Future<void> remember(LibraryDirectorySelection selection) async {
    rememberCalls++;
    final error = rememberError;
    if (error != null) throw error;
  }
}

class _FakeTxtFilePicker implements TxtFilePicker {
  _FakeTxtFilePicker([this.result]);

  ImportedTxtFile? result;
  int calls = 0;

  @override
  Future<ImportedTxtFile?> pickTxtFile() async {
    calls++;
    return result;
  }
}

void main() {
  group('LibraryProvider', () {
    late MemoryLibraryStorage storage;
    late _FakeTxtFilePicker picker;
    late LibraryProvider provider;

    setUp(() {
      storage = MemoryLibraryStorage();
      picker = _FakeTxtFilePicker();
      provider = LibraryProvider(storage: storage, filePicker: picker);
    });

    test('未选择目录时导入不会调用文件选择器', () async {
      final emptyPicker = _FakeTxtFilePicker(
        const ImportedTxtFile(name: '示例小说.txt', content: '正文'),
      );
      final emptyProvider = LibraryProvider(filePicker: emptyPicker);

      await expectLater(emptyProvider.importTxt(), throwsStateError);

      expect(emptyPicker.calls, 0);
      expect(emptyProvider.books, isEmpty);
    });

    test('取消文件选择时不写入书库', () async {
      final imported = await provider.importTxt();

      expect(imported, isNull);
      expect(picker.calls, 1);
      expect(provider.books, isEmpty);
      expect(await storage.scan(), isEmpty);
    });

    test('导入书籍后写入书籍文件并登记元数据索引', () async {
      picker.result = const ImportedTxtFile(
        name: '示例小说.TXT',
        content: '很久很久以前……',
      );

      final imported = await provider.importTxt();

      final books = await storage.readMetadataIndex();
      expect(books, hasLength(1));
      expect(books.single.title, '示例小说');

      final content = await storage.readBookContent(books.single.id);
      expect(content?.text, '很久很久以前……');
      expect(imported?.id, books.single.id);
      expect(provider.books.single.title, '示例小说');
    });

    test('同名书籍可以同时存在', () async {
      picker.result = const ImportedTxtFile(name: '同名书.txt', content: '一');
      await provider.importTxt();
      picker.result = const ImportedTxtFile(name: '同名书.txt', content: '二');
      await provider.importTxt();

      final books = await storage.readMetadataIndex();
      expect(books, hasLength(2));
      expect(books.map((book) => book.title).toSet(), {'同名书'});
      expect(books.map((book) => book.id).toSet(), hasLength(2));
      expect(provider.books, hasLength(2));
    });

    test('删除书籍后文件与索引同步移除', () async {
      picker.result = const ImportedTxtFile(name: '示例小说.txt', content: '正文');
      await provider.importTxt();
      final bookId = provider.books.single.id;

      await provider.deleteBook(bookId);

      expect(await storage.readMetadataIndex(), isEmpty);
      expect(await storage.readBookContent(bookId), isNull);
      expect(provider.books, isEmpty);
    });

    test('阅读内容按需读取，Provider 不持有正文', () async {
      picker.result = const ImportedTxtFile(
        name: '示例小说.txt',
        content: '按需读取的正文',
      );
      await provider.importTxt();

      final book = provider.books.single;
      expect(book, isA<BookMetadata>());

      final content = await provider.readBookContent(book.id);
      expect(content?.text, '按需读取的正文');
    });

    test('init 从元数据索引恢复并按导入时间倒序', () async {
      final older = BookMetadata(
        id: 'old',
        title: '旧书',
        importedAt: DateTime(2026, 1, 1),
      );
      final newer = BookMetadata(
        id: 'new',
        title: '新书',
        importedAt: DateTime(2026, 2, 1),
      );
      await storage.writeMetadataIndex([older, newer]);

      await provider.init();

      expect(provider.books.map((book) => book.id).toList(), ['new', 'old']);
    });

    test('未配置存储时书库为空且不崩溃', () async {
      final emptyProvider = LibraryProvider();

      await emptyProvider.init();

      expect(emptyProvider.isLoaded, isTrue);
      expect(emptyProvider.books, isEmpty);
      expect(await emptyProvider.readBookContent('missing'), isNull);
    });

    test('init 从平台 adapter 恢复书库目录', () async {
      final restoredStorage = MemoryLibraryStorage();
      await restoredStorage.writeBook(
        BookMetadata(
          id: 'book-1',
          title: '恢复目录之书',
          importedAt: DateTime(2026, 8, 5),
        ),
        BookContent(text: '正文'),
      );
      final adapter = _FakeLibraryDirectoryAdapter(
        restored: LibraryDirectorySelection(
          label: '/books',
          storage: restoredStorage,
        ),
      );
      final restoredProvider = LibraryProvider(directoryAdapter: adapter);

      await restoredProvider.init();

      expect(restoredProvider.books.single.title, '恢复目录之书');
      expect((await restoredProvider.readBookContent('book-1'))?.text, '正文');
    });

    test('取消选择目录时不改变书库状态', () async {
      final adapter = _FakeLibraryDirectoryAdapter();
      final selectingProvider = LibraryProvider(directoryAdapter: adapter);
      await selectingProvider.init();

      final path = await selectingProvider.selectDirectory();

      expect(path, isNull);
      expect(selectingProvider.hasStorage, isFalse);
      expect(adapter.rememberCalls, 0);
    });

    test('选择目录后保存路径并加载书籍', () async {
      final selectedStorage = MemoryLibraryStorage();
      await selectedStorage.writeBook(
        BookMetadata(
          id: 'book-1',
          title: '新目录之书',
          importedAt: DateTime(2026, 8, 5),
        ),
        BookContent(text: '正文'),
      );
      final adapter = _FakeLibraryDirectoryAdapter(
        selected: LibraryDirectorySelection(
          label: '/new-books',
          storage: selectedStorage,
        ),
      );
      final selectingProvider = LibraryProvider(directoryAdapter: adapter);
      await selectingProvider.init();

      final path = await selectingProvider.selectDirectory();

      expect(path, '/new-books');
      expect(adapter.rememberCalls, 1);
      expect(selectingProvider.books.single.title, '新目录之书');
      expect((await selectingProvider.readBookContent('book-1'))?.text, '正文');
    });

    test('切换目录扫描失败时保留原书库状态', () async {
      await storage.writeBook(
        BookMetadata(
          id: 'old-book',
          title: '原目录之书',
          importedAt: DateTime(2026, 8, 5),
        ),
        BookContent(text: '仍可读取的正文'),
      );
      final adapter = _FakeLibraryDirectoryAdapter(
        selected: LibraryDirectorySelection(
          label: '/broken',
          storage: _ScanFailingStorage(),
        ),
      );
      final selectingProvider = LibraryProvider(
        storage: storage,
        directoryAdapter: adapter,
      );
      await selectingProvider.init();

      await expectLater(selectingProvider.selectDirectory(), throwsStateError);

      expect(selectingProvider.storage, same(storage));
      expect(selectingProvider.books.single.title, '原目录之书');
      expect(
        (await selectingProvider.readBookContent('old-book'))?.text,
        '仍可读取的正文',
      );
      expect(adapter.rememberCalls, 0);
    });

    test('保存目录路径失败时保留原书库状态', () async {
      await storage.writeBook(
        BookMetadata(
          id: 'old-book',
          title: '原目录之书',
          importedAt: DateTime(2026, 8, 5),
        ),
        BookContent(text: '旧正文'),
      );
      final newStorage = MemoryLibraryStorage();
      await newStorage.writeBook(
        BookMetadata(
          id: 'new-book',
          title: '新目录之书',
          importedAt: DateTime(2026, 8, 5),
        ),
        BookContent(text: '新正文'),
      );
      final adapter = _FakeLibraryDirectoryAdapter(
        selected: LibraryDirectorySelection(
          label: '/new-books',
          storage: newStorage,
        ),
        rememberError: StateError('无法保存路径'),
      );
      final selectingProvider = LibraryProvider(
        storage: storage,
        directoryAdapter: adapter,
      );
      await selectingProvider.init();

      await expectLater(selectingProvider.selectDirectory(), throwsStateError);

      expect(selectingProvider.storage, same(storage));
      expect(selectingProvider.books.single.title, '原目录之书');
      expect(
        (await selectingProvider.readBookContent('old-book'))?.text,
        '旧正文',
      );
    });
  });
}
