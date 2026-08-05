import 'package:flutter_test/flutter_test.dart';
import 'package:tokyo_reader/models/book.dart';

void main() {
  group('Book', () {
    test('JSON 序列化可以完整还原', () {
      final book = Book(
        id: 'book-1',
        title: '测试之书',
        content: '你好，世界。',
        importedAt: DateTime(2026, 8, 5, 12, 30),
      );

      final restored = Book.fromJson(book.toJson());

      expect(restored.id, book.id);
      expect(restored.title, book.title);
      expect(restored.content, book.content);
      expect(restored.importedAt, book.importedAt);
    });

    test('characterCount 返回文本字数', () {
      final book = Book(
        id: 'book-1',
        title: '测试之书',
        content: '你好，世界。',
        importedAt: DateTime(2026, 8, 5),
      );
      expect(book.characterCount, 6);
    });
  });
}
