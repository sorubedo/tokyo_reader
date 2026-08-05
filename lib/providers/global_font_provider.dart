import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/global_font.dart';
import '../services/font_source_service.dart';
import '../services/global_font_storage.dart';

/// 全局字体状态、持久化与平台字体来源编排。
class GlobalFontProvider extends ChangeNotifier {
  GlobalFontProvider({
    GlobalFontStorage? storage,
    FontSourceService? sourceService,
  }) : _storage = storage ?? createGlobalFontStorage(),
       _sourceService = sourceService ?? createFontSourceService();

  static const String sourceKey = 'global_font_source_v1';
  static const String familyKey = 'global_font_family_v1';
  static const String displayNameKey = 'global_font_display_name_v1';

  final GlobalFontStorage _storage;
  final FontSourceService _sourceService;
  SharedPreferences? _preferences;

  GlobalFontSelection _selection = const GlobalFontSelection.systemDefault();
  String? _effectiveFamily;
  bool _loaded = false;
  bool _usingFallback = false;

  GlobalFontSelection get selection => _selection;
  String? get effectiveFamily => _effectiveFamily;
  bool get isLoaded => _loaded;
  bool get isUsingFallback => _usingFallback;
  bool get supportsSystemFonts => _sourceService.supportsSystemFonts;
  bool get supportsImportedFonts => _sourceService.supportsImportedFonts;
  bool get supportsGoogleFonts => _sourceService.supportsGoogleFonts;

  Future<void> init() async {
    if (_loaded) return;
    final prefs = _preferences ??= await SharedPreferences.getInstance();
    final source = GlobalFontSource.fromStorageId(
      prefs.getString(sourceKey) ?? GlobalFontSource.systemDefault.storageId,
    );
    final family = _nonEmpty(prefs.getString(familyKey));
    final displayName = _nonEmpty(prefs.getString(displayNameKey));

    if (source == null || source == GlobalFontSource.systemDefault) {
      _selection = const GlobalFontSelection.systemDefault();
      _effectiveFamily = null;
    } else if (source == GlobalFontSource.system) {
      await _restoreSystemFont(source, family, prefs);
    } else if (source == GlobalFontSource.imported) {
      await _restoreImportedFont(displayName, prefs);
    } else {
      await _restoreGoogleFont(source, family, prefs);
    }

    _loaded = true;
    notifyListeners();
  }

  Future<List<String>> listSystemFonts() async {
    if (!supportsSystemFonts) return [];
    return _sourceService.listSystemFonts();
  }

  Future<void> selectSystemDefault() async {
    await _persistSelection(const GlobalFontSelection.systemDefault());
    await _storage.clear();
    _selection = const GlobalFontSelection.systemDefault();
    _effectiveFamily = null;
    _usingFallback = false;
    notifyListeners();
  }

  Future<void> selectSystem(String family) async {
    final normalized = family.trim();
    if (!supportsSystemFonts || normalized.isEmpty) {
      throw const FontSelectionException('当前平台不支持该系统字体');
    }
    final loadedFamily = await _sourceService.loadSystemFont(normalized);
    if (loadedFamily == null) {
      throw FontSelectionException('无法加载系统字体：$normalized');
    }

    final selection = GlobalFontSelection(
      source: GlobalFontSource.system,
      family: normalized,
    );
    await _persistSelection(selection);
    _selection = selection;
    _effectiveFamily = loadedFamily;
    _usingFallback = false;
    notifyListeners();
  }

  Future<void> selectImported({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (!supportsImportedFonts) {
      throw const FontSelectionException('当前平台不支持导入字体');
    }
    final normalizedName = fileName.trim();
    if (!_isSupportedFontFile(normalizedName) || !_looksLikeFont(bytes)) {
      throw const FontSelectionException('请选择有效的 TTF 或 OTF 字体文件');
    }

    final alias = _importedAlias(bytes);
    final loadedFamily = await _sourceService.loadImportedFont(bytes, alias);
    if (loadedFamily == null) {
      throw const FontSelectionException('字体文件无法加载');
    }

    final previousBytes = await _storage.read();
    final selection = GlobalFontSelection(
      source: GlobalFontSource.imported,
      displayName: normalizedName.isEmpty ? '导入字体' : normalizedName,
    );
    try {
      await _storage.write(bytes);
      await _persistSelection(selection);
    } catch (_) {
      if (previousBytes == null) {
        await _storage.clear();
      } else {
        await _storage.write(previousBytes);
      }
      rethrow;
    }

    _selection = selection;
    _effectiveFamily = loadedFamily;
    _usingFallback = false;
    notifyListeners();
  }

  Future<void> selectGoogle(String family) async {
    final normalized = family.trim();
    if (!supportsGoogleFonts ||
        normalized.isEmpty ||
        !_sourceService.containsGoogleFont(normalized)) {
      throw const FontSelectionException('当前平台不支持 Google 字体');
    }
    final loadedFamily = await _sourceService.loadGoogleFont(normalized);
    if (loadedFamily == null) {
      throw FontSelectionException('无法加载 Google 字体：$normalized');
    }

    final selection = GlobalFontSelection(
      source: GlobalFontSource.google,
      family: normalized,
    );
    await _persistSelection(selection);
    _selection = selection;
    _effectiveFamily = loadedFamily;
    _usingFallback = false;
    notifyListeners();
  }

  Future<void> _restoreSystemFont(
    GlobalFontSource source,
    String? family,
    SharedPreferences prefs,
  ) async {
    if (!supportsSystemFonts || family == null) {
      await _clearPersistedSelection(prefs);
      _selection = const GlobalFontSelection.systemDefault();
      _effectiveFamily = null;
      return;
    }
    final loadedFamily = await _sourceService.loadSystemFont(family);
    if (loadedFamily == null) {
      await _clearPersistedSelection(prefs);
      _selection = const GlobalFontSelection.systemDefault();
      _effectiveFamily = null;
      return;
    }
    _selection = GlobalFontSelection(source: source, family: family);
    _effectiveFamily = loadedFamily;
  }

  Future<void> _restoreImportedFont(
    String? displayName,
    SharedPreferences prefs,
  ) async {
    if (!supportsImportedFonts) {
      await _clearPersistedSelection(prefs);
      _selection = const GlobalFontSelection.systemDefault();
      _effectiveFamily = null;
      return;
    }
    final bytes = await _storage.read();
    if (bytes == null || !_looksLikeFont(bytes)) {
      await _storage.clear();
      await _clearPersistedSelection(prefs);
      _selection = const GlobalFontSelection.systemDefault();
      _effectiveFamily = null;
      return;
    }
    final loadedFamily = await _sourceService.loadImportedFont(
      bytes,
      _importedAlias(bytes),
    );
    if (loadedFamily == null) {
      await _storage.clear();
      await _clearPersistedSelection(prefs);
      _selection = const GlobalFontSelection.systemDefault();
      _effectiveFamily = null;
      return;
    }
    _selection = GlobalFontSelection(
      source: GlobalFontSource.imported,
      displayName: displayName ?? '导入字体',
    );
    _effectiveFamily = loadedFamily;
  }

  Future<void> _restoreGoogleFont(
    GlobalFontSource source,
    String? family,
    SharedPreferences prefs,
  ) async {
    if (!supportsGoogleFonts ||
        family == null ||
        !_sourceService.containsGoogleFont(family)) {
      await _clearPersistedSelection(prefs);
      _selection = const GlobalFontSelection.systemDefault();
      _effectiveFamily = null;
      return;
    }
    _selection = GlobalFontSelection(source: source, family: family);
    final loadedFamily = await _sourceService.loadGoogleFont(family);
    if (loadedFamily == null) {
      // A network failure is transient on Web: preserve the selection and
      // render with the system default for this session.
      _effectiveFamily = null;
      _usingFallback = true;
      return;
    }
    _effectiveFamily = loadedFamily;
  }

  Future<void> _persistSelection(GlobalFontSelection selection) async {
    final prefs = _preferences ??= await SharedPreferences.getInstance();
    await prefs.setString(sourceKey, selection.source.storageId);
    if (selection.family == null) {
      await prefs.remove(familyKey);
    } else {
      await prefs.setString(familyKey, selection.family!);
    }
    if (selection.displayName == null) {
      await prefs.remove(displayNameKey);
    } else {
      await prefs.setString(displayNameKey, selection.displayName!);
    }
  }

  Future<void> _clearPersistedSelection(SharedPreferences prefs) async {
    await prefs.remove(sourceKey);
    await prefs.remove(familyKey);
    await prefs.remove(displayNameKey);
  }

  String? _nonEmpty(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  String _importedAlias(Uint8List bytes) {
    final digest = sha256.convert(bytes).toString().substring(0, 16);
    return 'tokyo_reader_imported_$digest';
  }

  bool _isSupportedFontFile(String fileName) {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.ttf') || lower.endsWith('.otf');
  }

  bool _looksLikeFont(Uint8List bytes) {
    if (bytes.length < 4) return false;
    final tag = String.fromCharCodes(bytes.take(4));
    return tag == 'OTTO' ||
        tag == 'ttcf' ||
        (bytes[0] == 0x00 &&
            bytes[1] == 0x01 &&
            bytes[2] == 0x00 &&
            bytes[3] == 0x00);
  }
}

class FontSelectionException implements Exception {
  const FontSelectionException(this.message);

  final String message;

  @override
  String toString() => message;
}
