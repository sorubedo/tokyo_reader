import 'package:flutter_test/flutter_test.dart';
import 'package:tokyo_reader/models/book_metadata.dart';
import 'package:tokyo_reader/models/content_fingerprint.dart';

void main() {
  group('BookMetadata', () {
    test('JSON 序列化可以完整还原', () {
      final metadata = BookMetadata(
        id: 'book-1',
        title: '测试之书',
        importedAt: DateTime(2026, 8, 5, 12, 30),
        readingProgress: 0.42,
        contentFingerprint: ContentFingerprint(
          size: 123,
          modifiedAt: DateTime(2026, 8, 5, 12, 31),
          sha256: 'abc123',
        ),
        externalModified: true,
      );

      final restored = BookMetadata.fromJson(metadata.toJson());

      expect(restored.id, metadata.id);
      expect(restored.title, metadata.title);
      expect(restored.importedAt, metadata.importedAt);
      expect(restored.readingProgress, metadata.readingProgress);
      expect(restored.externalModified, metadata.externalModified);
      expect(
        restored.contentFingerprint?.size,
        metadata.contentFingerprint?.size,
      );
      expect(
        restored.contentFingerprint?.modifiedAt,
        metadata.contentFingerprint?.modifiedAt,
      );
      expect(
        restored.contentFingerprint?.sha256,
        metadata.contentFingerprint?.sha256,
      );
    });

    test('无内容指纹时 JSON 序列化仍可完整还原', () {
      final metadata = BookMetadata(
        id: 'book-1',
        title: '测试之书',
        importedAt: DateTime(2026, 8, 5),
      );

      final restored = BookMetadata.fromJson(metadata.toJson());

      expect(restored.id, metadata.id);
      expect(restored.title, metadata.title);
      expect(restored.importedAt, metadata.importedAt);
      expect(restored.contentFingerprint, isNull);
      expect(restored.readingProgress, 0);
      expect(restored.externalModified, isFalse);
    });
  });
}
