import 'package:flutter/material.dart';

import 'tokyo_palette.dart';

/// Tokyo Day（浅色）调色板变体。
@immutable
class TokyoDay extends TokyoPalette {
  const TokyoDay()
    : super(
        bg: const Color(0xFFE1E2E7),
        bgDark: const Color(0xFFD0D5E3),
        bgHighlight: const Color(0xFFC4C8DA),
        fg: const Color(0xFF3760BF),
        fgDark: const Color(0xFF6172B0),
        comment: const Color(0xFF848CB5),
        blue: const Color(0xFF2E7DE9),
        cyan: const Color(0xFF007197),
        purple: const Color(0xFF9854F1),
        magenta: const Color(0xFFD20065),
        orange: const Color(0xFFB15C00),
        yellow: const Color(0xFF8C6C3E),
        green: const Color(0xFF587539),
        red: const Color(0xFFF52A65),
        accentValue: const Color(0xFF1D5FBF),
        destructiveValue: const Color(0xFFB91C4C),
        successValue: const Color(0xFF587539),
        warningValue: const Color(0xFF8C6C3E),
        windowValue: const Color(0xFFE1E2E7),
        viewValue: const Color(0xFFE1E2E7),
        headerBarValue: const Color(0xFFD0D5E3),
        borderValue: const Color(0xFF848CB5),
        onAccentValue: const Color(0xFFFFFFFF),
        onDestructiveValue: const Color(0xFFFFFFFF),
        onSuccessValue: const Color(0xFFFFFFFF),
        textMutedValue: const Color(0xFF565F89),
      );

  static const TokyoDay tokyoDay = TokyoDay();
}
