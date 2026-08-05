import '../models/book_content.dart';
import '../models/book_metadata.dart';

/// 书库持久化 seam：以领域动作隐藏具体目录布局与索引格式。
abstract class LibraryStorage {
  /// 读取指定书籍的正文；书籍文件不存在时返回 null。
  Future<BookContent?> readBookContent(String bookId);

  /// 写入书籍文件，并在元数据索引中登记或更新该书。
  Future<void> writeBook(BookMetadata metadata, BookContent content);

  /// 删除书籍文件，并同步移除元数据索引中的条目。
  Future<void> deleteBook(String bookId);

  /// 扫描书库目录：发现未登记书籍文件、检测外部修改与缺失，
  /// 更新元数据索引并返回最新元数据列表。
  Future<List<BookMetadata>> scan();
}
