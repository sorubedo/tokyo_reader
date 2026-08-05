import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tokyo_reader/core/tokyo_theme.dart';
import 'package:tokyo_reader/models/global_font.dart';
import 'package:tokyo_reader/providers/global_font_provider.dart';
import 'package:tokyo_reader/services/font_source_service.dart';
import 'package:tokyo_reader/services/global_font_storage.dart';

const _validTtf = <int>[0x00, 0x01, 0x00, 0x00, 0x00, 0x10];
const _validTtc = <int>[0x74, 0x74, 0x63, 0x66, 0x00, 0x01];

class _FakeFontSourceService implements FontSourceService {
  _FakeFontSourceService({
    this.importedResult = 'tokyo_reader_imported_fake',
    this.googleResult = 'Lato',
  });

  final String? importedResult;
  final String? googleResult;
  static const systemFonts = ['Noto Sans'];

  @override
  bool get supportsGoogleFonts => true;

  @override
  bool get supportsImportedFonts => true;

  @override
  bool get supportsSystemFonts => true;

  @override
  bool containsGoogleFont(String family) => family == 'Lato';

  @override
  Future<String?> loadGoogleFont(String family) async => googleResult;

  @override
  Future<String?> loadImportedFont(Uint8List bytes, String alias) async =>
      importedResult;

  @override
  Future<String?> loadSystemFont(String family) async =>
      systemFonts.contains(family) ? family : null;

  @override
  Future<List<String>> listSystemFonts() async => systemFonts;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GlobalFontProvider', () {
    test('默认使用系统默认字体', () async {
      final provider = GlobalFontProvider(
        storage: MemoryGlobalFontStorage(),
        sourceService: _FakeFontSourceService(),
      );

      await provider.init();

      expect(provider.selection.source, GlobalFontSource.systemDefault);
      expect(provider.effectiveFamily, isNull);
      expect(provider.isUsingFallback, isFalse);
    });

    test('导入有效字体后保存字节和选择', () async {
      final storage = MemoryGlobalFontStorage();
      final provider = GlobalFontProvider(
        storage: storage,
        sourceService: _FakeFontSourceService(),
      );
      await provider.init();

      await provider.selectImported(
        bytes: Uint8List.fromList(_validTtf),
        fileName: '霞鹜文楷.ttf',
      );

      final prefs = await SharedPreferences.getInstance();
      expect(provider.selection.source, GlobalFontSource.imported);
      expect(provider.selection.displayName, '霞鹜文楷.ttf');
      expect(provider.effectiveFamily, 'tokyo_reader_imported_fake');
      expect(prefs.getString(GlobalFontProvider.sourceKey), 'imported');
      expect((await storage.read()), orderedEquals(_validTtf));
    });

    test('导入有效 TTC 字体后保存字节和选择', () async {
      final storage = MemoryGlobalFontStorage();
      final provider = GlobalFontProvider(
        storage: storage,
        sourceService: _FakeFontSourceService(),
      );
      await provider.init();

      await provider.selectImported(
        bytes: Uint8List.fromList(_validTtc),
        fileName: 'NotoSansCJK-Regular.ttc',
      );

      expect(provider.selection.source, GlobalFontSource.imported);
      expect(provider.selection.displayName, 'NotoSansCJK-Regular.ttc');
      expect((await storage.read()), orderedEquals(_validTtc));
    });

    test('非法字体不会改变当前选择', () async {
      final provider = GlobalFontProvider(
        storage: MemoryGlobalFontStorage(),
        sourceService: _FakeFontSourceService(),
      );
      await provider.init();

      await provider.selectGoogle('Lato');
      await expectLater(
        provider.selectImported(
          bytes: Uint8List.fromList([1, 2, 3, 4]),
          fileName: 'bad.ttf',
        ),
        throwsA(isA<FontSelectionException>()),
      );

      expect(provider.selection.source, GlobalFontSource.google);
      expect(provider.selection.family, 'Lato');
      expect(provider.effectiveFamily, 'Lato');
    });

    test('字体注册失败时不会覆盖已保存的导入字体', () async {
      final storage = MemoryGlobalFontStorage();
      await storage.write(Uint8List.fromList(_validTtf));
      final provider = GlobalFontProvider(
        storage: storage,
        sourceService: _FakeFontSourceService(importedResult: null),
      );
      await provider.init();

      await expectLater(
        provider.selectImported(
          bytes: Uint8List.fromList([..._validTtf, 1]),
          fileName: 'new.ttf',
        ),
        throwsA(isA<FontSelectionException>()),
      );

      expect((await storage.read()), orderedEquals(_validTtf));
      expect(provider.selection.source, GlobalFontSource.systemDefault);
    });

    test('重建 Provider 后恢复导入字体', () async {
      final storage = MemoryGlobalFontStorage();
      final first = GlobalFontProvider(
        storage: storage,
        sourceService: _FakeFontSourceService(),
      );
      await first.init();
      await first.selectImported(
        bytes: Uint8List.fromList(_validTtf),
        fileName: 'font.otf',
      );

      final restored = GlobalFontProvider(
        storage: storage,
        sourceService: _FakeFontSourceService(),
      );
      await restored.init();

      expect(restored.selection.source, GlobalFontSource.imported);
      expect(restored.selection.displayName, 'font.otf');
      expect(restored.effectiveFamily, 'tokyo_reader_imported_fake');
    });

    test('Google 字体网络失败时保留选择并临时回退', () async {
      SharedPreferences.setMockInitialValues({
        GlobalFontProvider.sourceKey: 'google',
        GlobalFontProvider.familyKey: 'Lato',
      });
      final provider = GlobalFontProvider(
        storage: MemoryGlobalFontStorage(),
        sourceService: _FakeFontSourceService(googleResult: null),
      );

      await provider.init();

      expect(provider.selection.source, GlobalFontSource.google);
      expect(provider.selection.family, 'Lato');
      expect(provider.effectiveFamily, isNull);
      expect(provider.isUsingFallback, isTrue);
    });

    test('已失效的 Google 字体选择会在启动时清回默认', () async {
      SharedPreferences.setMockInitialValues({
        GlobalFontProvider.sourceKey: 'google',
        GlobalFontProvider.familyKey: 'Missing Font',
      });
      final provider = GlobalFontProvider(
        storage: MemoryGlobalFontStorage(),
        sourceService: _FakeFontSourceService(),
      );

      await provider.init();

      final prefs = await SharedPreferences.getInstance();
      expect(provider.selection.source, GlobalFontSource.systemDefault);
      expect(provider.effectiveFamily, isNull);
      expect(provider.isUsingFallback, isFalse);
      expect(prefs.getString(GlobalFontProvider.sourceKey), isNull);
      expect(prefs.getString(GlobalFontProvider.familyKey), isNull);
    });

    test('原生系统字体选择后持久化并应用', () async {
      final provider = GlobalFontProvider(
        storage: MemoryGlobalFontStorage(),
        sourceService: _FakeFontSourceService(),
      );
      await provider.init();

      await provider.selectSystem('Noto Sans');

      expect(provider.selection.source, GlobalFontSource.system);
      expect(provider.selection.family, 'Noto Sans');
      expect(provider.effectiveFamily, 'Noto Sans');
      expect(
        (await SharedPreferences.getInstance()).getString(
          GlobalFontProvider.sourceKey,
        ),
        'system',
      );

      final theme = buildTokyoNightTheme(fontProvider: provider);
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Noto Sans');
      expect(theme.appBarTheme.titleTextStyle?.fontFamily, 'Noto Sans');
    });
  });
}
