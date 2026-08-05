import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tokyo_reader/services/font_source_service.dart';
import 'package:tokyo_reader/services/font_source_service_io.dart';

void main() {
  group('IoFontSourceService', () {
    test('Linux 使用 fontconfig 枚举、去重并排序字体家族', () async {
      final calls = <(String, List<String>)>[];
      final service = IoFontSourceService.withProcessRunner((
        executable,
        arguments,
      ) async {
        calls.add((executable, arguments));
        return ProcessResult(
          1,
          0,
          'Noto Sans CJK SC\n'
              'DejaVu Sans\n'
              'Noto Sans CJK SC\n'
              '\n',
          '',
        );
      });

      expect(await service.listSystemFonts(), [
        'DejaVu Sans',
        'Noto Sans CJK SC',
      ]);
      expect(calls, hasLength(1));
      expect(calls.single.$1, 'fc-list');
      expect(calls.single.$2, [r'--format=%{family[0]}\n']);
    }, skip: !Platform.isLinux);

    test('Linux 加载字体家族时选择常规字重', () async {
      const family = 'Noto Sans CJK SC';
      final fallbackMatch = await Process.run('fc-match', [
        r'--format=%{file}',
        'sans-serif',
      ]);
      final loadablePath = (fallbackMatch.stdout as String).trim();
      expect(loadablePath, isNotEmpty);

      final calls = <(String, List<String>)>[];
      final service = IoFontSourceService.withProcessRunner((
        executable,
        arguments,
      ) async {
        calls.add((executable, arguments));
        if (executable == 'fc-list') {
          return ProcessResult(1, 0, '$family\n$family\n', '');
        }
        return ProcessResult(2, 0, '$loadablePath\n', '');
      });

      expect(await service.loadSystemFont(family), family);
      expect(calls.map((call) => call.$1), ['fc-list', 'fc-match']);
      expect(calls.last.$2, [r'--format=%{file}\n', family]);
    }, skip: !Platform.isLinux);

    test('Linux 可以枚举已安装的系统字体', () async {
      final service = createFontSourceService();

      expect(service.supportsSystemFonts, isTrue);
      final fonts = await service.listSystemFonts();
      expect(fonts, isNotEmpty);
      expect(await service.loadSystemFont(fonts.first), fonts.first);
      if (fonts.contains('Noto Sans CJK SC')) {
        expect(
          await service.loadSystemFont('Noto Sans CJK SC'),
          'Noto Sans CJK SC',
        );
      }
    }, skip: !Platform.isLinux);
  });
}
