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
    this.accentValue,
    this.destructiveValue,
    this.successValue,
    this.warningValue,
    this.windowValue,
    this.viewValue,
    this.headerBarValue,
    this.borderValue,
    this.onAccentValue,
    this.onDestructiveValue,
    this.onSuccessValue,
    this.textValue,
    this.textMutedValue,
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
  final Color? accentValue;
  final Color? destructiveValue;
  final Color? successValue;
  final Color? warningValue;
  final Color? windowValue;
  final Color? viewValue;
  final Color? headerBarValue;
  final Color? borderValue;
  final Color? onAccentValue;
  final Color? onDestructiveValue;
  final Color? onSuccessValue;
  final Color? textValue;
  final Color? textMutedValue;

  /// Stable semantic roles consumed by the application shell and pages.
  ///
  /// The raw Tokyo colors above remain available for backwards-compatible
  /// theme construction, but UI code should use these roles instead.
  Color get accent => accentValue ?? blue;
  Color get destructive => destructiveValue ?? red;
  Color get success => successValue ?? green;
  Color get warning => warningValue ?? orange;
  Color get window => windowValue ?? bg;
  Color get view => viewValue ?? bgHighlight;
  Color get headerBar => headerBarValue ?? bgDark;
  Color get border => borderValue ?? comment;
  Color get onAccent => onAccentValue ?? bg;
  Color get onDestructive => onDestructiveValue ?? bg;
  Color get onSuccess => onSuccessValue ?? bg;
  Color get text => textValue ?? fg;
  Color get textMuted => textMutedValue ?? fgDark;

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
    Color? accent,
    Color? destructive,
    Color? success,
    Color? warning,
    Color? window,
    Color? view,
    Color? headerBar,
    Color? border,
    Color? onAccent,
    Color? onDestructive,
    Color? onSuccess,
    Color? text,
    Color? textMuted,
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
      accentValue: accent ?? this.accent,
      destructiveValue: destructive ?? this.destructive,
      successValue: success ?? this.success,
      warningValue: warning ?? this.warning,
      windowValue: window ?? this.window,
      viewValue: view ?? this.view,
      headerBarValue: headerBar ?? this.headerBar,
      borderValue: border ?? this.border,
      onAccentValue: onAccent ?? this.onAccent,
      onDestructiveValue: onDestructive ?? this.onDestructive,
      onSuccessValue: onSuccess ?? this.onSuccess,
      textValue: text ?? this.text,
      textMutedValue: textMuted ?? this.textMuted,
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
      accentValue: Color.lerp(accent, other.accent, t)!,
      destructiveValue: Color.lerp(destructive, other.destructive, t)!,
      successValue: Color.lerp(success, other.success, t)!,
      warningValue: Color.lerp(warning, other.warning, t)!,
      windowValue: Color.lerp(window, other.window, t)!,
      viewValue: Color.lerp(view, other.view, t)!,
      headerBarValue: Color.lerp(headerBar, other.headerBar, t)!,
      borderValue: Color.lerp(border, other.border, t)!,
      onAccentValue: Color.lerp(onAccent, other.onAccent, t)!,
      onDestructiveValue: Color.lerp(onDestructive, other.onDestructive, t)!,
      onSuccessValue: Color.lerp(onSuccess, other.onSuccess, t)!,
      textValue: Color.lerp(text, other.text, t)!,
      textMutedValue: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}
