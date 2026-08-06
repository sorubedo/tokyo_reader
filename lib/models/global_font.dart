/// 全局字体的来源。
enum GlobalFontSource {
  systemDefault('system_default'),
  system('system'),
  imported('imported'),
  google('google');

  const GlobalFontSource(this.storageId);

  final String storageId;

  static GlobalFontSource? fromStorageId(String id) {
    for (final source in values) {
      if (source.storageId == id) return source;
    }
    return null;
  }
}

/// 用户确认可用并持久化的全局字体选择。
class GlobalFontSelection {
  const GlobalFontSelection({
    required this.source,
    this.family,
    this.displayName,
  });

  const GlobalFontSelection.systemDefault()
    : source = GlobalFontSource.systemDefault,
      family = null,
      displayName = null;

  final GlobalFontSource source;
  final String? family;
  final String? displayName;

  bool get isSystemDefault => source == GlobalFontSource.systemDefault;

  String get displayLabel => switch (source) {
    GlobalFontSource.systemDefault => '系统默认',
    GlobalFontSource.system => family ?? '系统默认',
    GlobalFontSource.imported => displayName ?? '导入字体',
    GlobalFontSource.google => family ?? 'Google Fonts',
  };

  GlobalFontSelection copyWith({
    GlobalFontSource? source,
    String? family,
    String? displayName,
  }) {
    return GlobalFontSelection(
      source: source ?? this.source,
      family: family ?? this.family,
      displayName: displayName ?? this.displayName,
    );
  }
}
