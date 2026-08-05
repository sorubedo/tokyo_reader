import 'package:adwaita_gtk/adwaita_gtk.dart';
import 'package:flutter/material.dart';

/// Tokyo Night（暗色）调色板。
///
/// 取自 https://github.com/folke/tokyonight.nvim 的 dark 变体。
@immutable
class TokyoNight extends ThemeExtension<TokyoNight> {
  const TokyoNight({
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

  static const TokyoNight tokyoNight = TokyoNight(
    bg: Color(0xFF1A1B26),
    bgDark: Color(0xFF16161E),
    bgHighlight: Color(0xFF292E42),
    fg: Color(0xFFC0CAF5),
    fgDark: Color(0xFFA9B1D6),
    comment: Color(0xFF565F89),
    blue: Color(0xFF7AA2F7),
    cyan: Color(0xFF7DCFFF),
    purple: Color(0xFFBB9AF7),
    magenta: Color(0xFFFF007C),
    orange: Color(0xFFFF9E64),
    yellow: Color(0xFFE0AF68),
    green: Color(0xFF9ECE6A),
    red: Color(0xFFF7768E),
  );

  @override
  TokyoNight copyWith({
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
    return TokyoNight(
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
  TokyoNight lerp(ThemeExtension<TokyoNight>? other, double t) {
    if (other is! TokyoNight) return this;
    return TokyoNight(
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

/// 以 Adwaita 主题为基础、叠加 Tokyo Night 配色的深色主题。
ThemeData buildTokyoNightTheme() {
  final tn = TokyoNight.tokyoNight;
  final adwaitaDark = AdwaitaThemeData.dark();
  final colorScheme = ColorScheme.dark(
    primary: tn.blue,
    onPrimary: tn.bg,
    secondary: tn.cyan,
    onSecondary: tn.bg,
    error: tn.red,
    onError: tn.bg,
    surface: tn.bgHighlight,
    onSurface: tn.fg,
    surfaceContainerHighest: tn.bgHighlight,
    outline: tn.comment,
  );

  return adwaitaDark.copyWith(
    scaffoldBackgroundColor: tn.bg,
    canvasColor: tn.bg,
    cardColor: tn.bgHighlight,
    dialogTheme: DialogThemeData(
      backgroundColor: tn.bgHighlight,
      shape: AdwaitaThemeData.getDialogShape(tn.bgHighlight),
    ),
    dividerColor: tn.comment.withValues(alpha: 0.35),
    colorScheme: colorScheme,
    textTheme: adwaitaDark.textTheme.apply(
      bodyColor: tn.fg,
      displayColor: tn.fg,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: tn.bgDark,
      foregroundColor: tn.fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 48,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: tn.fg,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: tn.blue,
        foregroundColor: tn.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      textColor: tn.fg,
      iconColor: tn.blue,
      subtitleTextStyle: TextStyle(color: tn.fgDark),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: tn.bgHighlight,
      contentTextStyle: TextStyle(color: tn.fg),
    ),
    extensions: [tn],
  );
}
