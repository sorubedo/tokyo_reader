import 'content_fingerprint.dart';

/// 书籍元数据：与书籍内容分离保存的描述性信息。
class BookMetadata {
  const BookMetadata({
    required this.id,
    required this.title,
    required this.importedAt,
    this.readingProgress = 0,
    this.contentFingerprint,
    this.externalModified = false,
  });

  final String id;
  final String title;
  final DateTime importedAt;
  final double readingProgress;
  final ContentFingerprint? contentFingerprint;
  final bool externalModified;

  factory BookMetadata.fromJson(Map<String, dynamic> json) {
    final fingerprint = json['contentFingerprint'];
    return BookMetadata(
      id: json['id'] as String,
      title: json['title'] as String,
      importedAt: DateTime.parse(json['importedAt'] as String),
      readingProgress: (json['readingProgress'] as num?)?.toDouble() ?? 0,
      contentFingerprint: fingerprint == null
          ? null
          : ContentFingerprint.fromJson(
              Map<String, dynamic>.from(fingerprint as Map),
            ),
      externalModified: json['externalModified'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'importedAt': importedAt.toIso8601String(),
      'readingProgress': readingProgress,
      'contentFingerprint': contentFingerprint?.toJson(),
      'externalModified': externalModified,
    };
  }
}
