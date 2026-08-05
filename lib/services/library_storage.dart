import '../models/book_content.dart';
import '../models/book_metadata.dart';

/// 书库持久化接缝：统一描述「书库目录」布局的读写能力。
///
/// 书库目录布局固定为：每本书一个以书籍 ID 命名的书籍文件，
/// 根目录一个含 schema 版本的元数据索引。
abstract class LibraryStorage {
  /// 元数据索引的 schema 版本，所有后端共享。
  static const int schemaVersion = 1;

  /// 书库目录根部元数据索引的文件名。
  static const String indexFileName = 'library.json';

  /// 书籍文件按稳定 ID 命名，与用户可见标题无关。
  static String bookFileName(String bookId) => '$bookId.txt';

  /// 读取元数据索引，列出书库中全部书籍元数据。
  Future<List<BookMetadata>> readMetadataIndex();

  /// 读取指定书籍的正文；书籍文件不存在时返回 null。
  Future<BookContent?> readBookContent(String bookId);

  /// 写入书籍文件，并在元数据索引中登记或更新该书。
  Future<void> writeBook(BookMetadata metadata, BookContent content);

  /// 删除书籍文件，并同步移除元数据索引中的条目。
  Future<void> deleteBook(String bookId);

  /// 整体写入元数据索引。
  Future<void> writeMetadataIndex(List<BookMetadata> books);
}
