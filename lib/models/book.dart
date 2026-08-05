class Book {
  const Book({
    required this.id,
    required this.title,
    required this.content,
    required this.importedAt,
  });

  final String id;
  final String title;
  final String content;
  final DateTime importedAt;

  int get characterCount => content.length;

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      importedAt: DateTime.parse(json['importedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'importedAt': importedAt.toIso8601String(),
    };
  }
}
