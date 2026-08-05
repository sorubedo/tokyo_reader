import 'package:flutter/material.dart';

/// 三种主题变体共享的调色板类型。
///
/// 页面统一通过 `Theme.of(context).extension<TokyoPalette>()` 取色，
/// 不依赖具体变体；新增主题变体时无需改动页面。
@immutable
class TokyoPalette extends ThemeExtension<TokyoPalette> {
  const TokyoPalette({
    required this.bg,
    required this.bgDark,
    required this.bgHighlight,
    required this.fg,
    required this.fgDark,
    required this.comment,
    required this.blue,
    required this.cyan,
    required this.purple,
    required this.magenta,
    required this.orange,
    required this.yellow,
    required this.green,
    required this.red,
  });

  final Color bg;
  final Color bgDark;
  final Color bgHighlight;
  final Color fg;
  final Color fgDark;
  final Color comment;
  final Color blue;
  final Color cyan;
  final Color purple;
  final Color magenta;
  final Color orange;
  final Color yellow;
  final Color green;
  final Color red;

  @override
  TokyoPalette copyWith({
    Color? bg,
    Color? bgDark,
    Color? bgHighlight,
    Color? fg,
    Color? fgDark,
    Color? comment,
    Color? blue,
    Color? cyan,
    Color? purple,
    Color? magenta,
    Color? orange,
    Color? yellow,
    Color? green,
    Color? red,
  }) {
    return TokyoPalette(
      bg: bg ?? this.bg,
      bgDark: bgDark ?? this.bgDark,
      bgHighlight: bgHighlight ?? this.bgHighlight,
      fg: fg ?? this.fg,
      fgDark: fgDark ?? this.fgDark,
      comment: comment ?? this.comment,
      blue: blue ?? this.blue,
      cyan: cyan ?? this.cyan,
      purple: purple ?? this.purple,
      magenta: magenta ?? this.magenta,
      orange: orange ?? this.orange,
      yellow: yellow ?? this.yellow,
      green: green ?? this.green,
      red: red ?? this.red,
    );
  }

  @override
  TokyoPalette lerp(ThemeExtension<TokyoPalette>? other, double t) {
    if (other is! TokyoPalette) return this;
    return TokyoPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      bgDark: Color.lerp(bgDark, other.bgDark, t)!,
      bgHighlight: Color.lerp(bgHighlight, other.bgHighlight, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      fgDark: Color.lerp(fgDark, other.fgDark, t)!,
      comment: Color.lerp(comment, other.comment, t)!,
      blue: Color.lerp(blue, other.blue, t)!,
      cyan: Color.lerp(cyan, other.cyan, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      magenta: Color.lerp(magenta, other.magenta, t)!,
      orange: Color.lerp(orange, other.orange, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      green: Color.lerp(green, other.green, t)!,
      red: Color.lerp(red, other.red, t)!,
    );
  }
}
