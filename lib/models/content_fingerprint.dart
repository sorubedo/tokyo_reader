/// 内容指纹：由文件大小、最后修改时间与正文 SHA-256 构成，
/// 用于识别书籍内容是否在应用之外发生变化。
class ContentFingerprint {
  const ContentFingerprint({
    required this.size,
    required this.modifiedAt,
    required this.sha256,
  });

  final int size;
  final DateTime modifiedAt;
  final String sha256;

  factory ContentFingerprint.fromJson(Map<String, dynamic> json) {
    return ContentFingerprint(
      size: json['size'] as int,
      modifiedAt: DateTime.parse(json['modifiedAt'] as String),
      sha256: json['sha256'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'size': size,
      'modifiedAt': modifiedAt.toIso8601String(),
      'sha256': sha256,
    };
  }
}
