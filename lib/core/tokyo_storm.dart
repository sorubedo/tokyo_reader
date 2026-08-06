import 'package:flutter/material.dart';

import 'tokyo_palette.dart';

/// Tokyo Storm（深蓝灰调）调色板变体。
@immutable
class TokyoStorm extends TokyoPalette {
  const TokyoStorm()
    : super(
        bg: const Color(0xFF24283B),
        bgDark: const Color(0xFF1F2335),
        bgHighlight: const Color(0xFF292E42),
        fg: const Color(0xFFC0CAF5),
        fgDark: const Color(0xFFA9B1D6),
        comment: const Color(0xFF565F89),
        blue: const Color(0xFF7AA2F7),
        cyan: const Color(0xFF7DCFFF),
        purple: const Color(0xFFBB9AF7),
        magenta: const Color(0xFFFF007C),
        orange: const Color(0xFFFF9E64),
        yellow: const Color(0xFFE0AF68),
        green: const Color(0xFF9ECE6A),
        red: const Color(0xFFF7768E),
        accentValue: const Color(0xFF7AA2F7),
        destructiveValue: const Color(0xFFF7768E),
        successValue: const Color(0xFF9ECE6A),
        warningValue: const Color(0xFFE0AF68),
        windowValue: const Color(0xFF24283B),
        viewValue: const Color(0xFF24283B),
        headerBarValue: const Color(0xFF1F2335),
        borderValue: const Color(0xFF565F89),
      );

  static const TokyoStorm tokyoStorm = TokyoStorm();
}
