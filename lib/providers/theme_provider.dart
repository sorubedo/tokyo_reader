import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../core/tokyo_theme.dart';

/// 主题状态：持有当前主题变体，并持久化到独立于书库的设置存储。
class ThemeProvider extends ChangeNotifier {
  ThemeProvider([this._box]);

  static const String boxName = 'settings';
  static const String themeVariantKey = 'theme_variant';

  Box? _box;
  ThemeVariant _variant = ThemeVariant.tokyoNight;
  bool _loaded = false;

  ThemeVariant get currentVariant => _variant;

  Future<void> init() async {
    if (_loaded) return;
    _box ??= Hive.box(boxName);

    final raw = _box!.get(themeVariantKey);
    final stored = raw is String ? ThemeVariant.fromStorageId(raw) : null;
    _variant = stored ?? ThemeVariant.tokyoNight;
    _loaded = true;
    notifyListeners();
  }

  Future<void> select(ThemeVariant variant) async {
    if (variant == _variant) return;
    _variant = variant;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    final box = _box;
    if (box == null) return;
    await box.put(themeVariantKey, _variant.storageId);
  }
}
