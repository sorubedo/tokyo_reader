import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/tokyo_theme.dart';

/// 主题状态：持有当前主题变体，并通过 shared_preferences 持久化。
class ThemeProvider extends ChangeNotifier {
  ThemeProvider();

  static const String themeVariantKey = 'theme_variant';

  ThemeVariant _variant = ThemeVariant.tokyoNight;
  bool _loaded = false;

  ThemeVariant get currentVariant => _variant;

  Future<void> init() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(themeVariantKey);
    _variant = raw == null
        ? ThemeVariant.tokyoNight
        : ThemeVariant.fromStorageId(raw) ?? ThemeVariant.tokyoNight;
    _loaded = true;
    notifyListeners();
  }

  Future<void> select(ThemeVariant variant) async {
    if (variant == _variant) return;
    _variant = variant;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(themeVariantKey, variant.storageId);
  }
}
