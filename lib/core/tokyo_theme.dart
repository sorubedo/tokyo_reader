import 'package:adwaita_gtk/adwaita_gtk.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/global_font.dart';
import '../providers/global_font_provider.dart';
import 'tokyo_day.dart';
import 'tokyo_night.dart';
import 'tokyo_palette.dart';
import 'tokyo_storm.dart';

/// 可选的主题变体。
enum ThemeVariant {
  tokyoNight(storageId: 'tokyo_night', label: 'Tokyo 夜', description: '默认深色主题'),
  tokyoDay(storageId: 'tokyo_day', label: 'Tokyo 日', description: '明亮浅色主题'),
  tokyoStorm(
    storageId: 'tokyo_storm',
    label: 'Tokyo 风暴',
    description: '深蓝灰调主题',
  );

  const ThemeVariant({
    required this.storageId,
    required this.label,
    required this.description,
  });

  final String storageId;
  final String label;
  final String description;

  static ThemeVariant? fromStorageId(String id) {
    for (final variant in values) {
      if (variant.storageId == id) return variant;
    }
    return null;
  }

  ThemeData buildTheme({GlobalFontProvider? fontProvider}) {
    return switch (this) {
      ThemeVariant.tokyoNight => buildTokyoNightTheme(
        fontProvider: fontProvider,
      ),
      ThemeVariant.tokyoDay => buildTokyoDayTheme(fontProvider: fontProvider),
      ThemeVariant.tokyoStorm => buildTokyoStormTheme(
        fontProvider: fontProvider,
      ),
    };
  }
}

ThemeData _buildTokyoTheme(
  TokyoPalette palette,
  Brightness brightness, {
  GlobalFontProvider? fontProvider,
}) {
  final base = brightness == Brightness.dark
      ? AdwaitaThemeData.dark()
      : AdwaitaThemeData.light();
  final colorScheme = brightness == Brightness.dark
      ? ColorScheme.dark(
          primary: palette.blue,
          onPrimary: palette.bg,
          secondary: palette.cyan,
          onSecondary: palette.bg,
          error: palette.red,
          onError: palette.bg,
          surface: palette.bgHighlight,
          onSurface: palette.fg,
          surfaceContainerHighest: palette.bgHighlight,
          outline: palette.comment,
        )
      : ColorScheme.light(
          primary: palette.blue,
          onPrimary: palette.bg,
          secondary: palette.cyan,
          onSecondary: palette.bg,
          error: palette.red,
          onError: palette.bg,
          surface: palette.bgHighlight,
          onSurface: palette.fg,
          surfaceContainerHighest: palette.bgHighlight,
          outline: palette.comment,
        );

  final theme = base.copyWith(
    scaffoldBackgroundColor: palette.bg,
    canvasColor: palette.bg,
    cardColor: palette.bgHighlight,
    dialogTheme: DialogThemeData(
      backgroundColor: palette.bgHighlight,
      shape: AdwaitaThemeData.getDialogShape(palette.bgHighlight),
    ),
    dividerColor: palette.comment.withValues(alpha: 0.35),
    colorScheme: colorScheme,
    textTheme: base.textTheme.apply(
      bodyColor: palette.fg,
      displayColor: palette.fg,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.bgDark,
      foregroundColor: palette.fg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      toolbarHeight: 48,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: palette.fg,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.blue,
        foregroundColor: palette.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      textColor: palette.fg,
      iconColor: palette.blue,
      subtitleTextStyle: TextStyle(color: palette.fgDark),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.bgHighlight,
      contentTextStyle: TextStyle(color: palette.fg),
    ),
    extensions: [palette],
  );
  return fontProvider == null ? theme : applyGlobalFont(theme, fontProvider);
}

ThemeData buildTokyoNightTheme({GlobalFontProvider? fontProvider}) {
  return _buildTokyoTheme(
    TokyoNight.tokyoNight,
    Brightness.dark,
    fontProvider: fontProvider,
  );
}

ThemeData buildTokyoDayTheme({GlobalFontProvider? fontProvider}) {
  return _buildTokyoTheme(
    TokyoDay.tokyoDay,
    Brightness.light,
    fontProvider: fontProvider,
  );
}

ThemeData buildTokyoStormTheme({GlobalFontProvider? fontProvider}) {
  return _buildTokyoTheme(
    TokyoStorm.tokyoStorm,
    Brightness.dark,
    fontProvider: fontProvider,
  );
}

ThemeData applyGlobalFont(ThemeData base, GlobalFontProvider fontProvider) {
  final family = fontProvider.effectiveFamily;
  if (family == null || family.isEmpty) return base;

  TextTheme applyTextTheme(TextTheme textTheme) {
    final selection = fontProvider.selection;
    if (selection.source == GlobalFontSource.google &&
        selection.family != null) {
      try {
        return GoogleFonts.getTextTheme(selection.family!, textTheme);
      } catch (_) {
        return textTheme.apply(fontFamily: family);
      }
    }
    return textTheme.apply(fontFamily: family);
  }

  TextStyle applyTextStyle(TextStyle style) {
    final selection = fontProvider.selection;
    if (selection.source == GlobalFontSource.google &&
        selection.family != null) {
      try {
        return GoogleFonts.getFont(selection.family!, textStyle: style);
      } catch (_) {
        return style.copyWith(fontFamily: family);
      }
    }
    return style.copyWith(fontFamily: family);
  }

  final appBar = base.appBarTheme;
  final listTile = base.listTileTheme;
  final snackBar = base.snackBarTheme;
  return base.copyWith(
    textTheme: applyTextTheme(base.textTheme),
    primaryTextTheme: applyTextTheme(base.primaryTextTheme),
    appBarTheme: appBar.copyWith(
      titleTextStyle: appBar.titleTextStyle == null
          ? null
          : applyTextStyle(appBar.titleTextStyle!),
      toolbarTextStyle: appBar.toolbarTextStyle == null
          ? null
          : applyTextStyle(appBar.toolbarTextStyle!),
    ),
    listTileTheme: listTile.copyWith(
      titleTextStyle: listTile.titleTextStyle == null
          ? null
          : applyTextStyle(listTile.titleTextStyle!),
      subtitleTextStyle: listTile.subtitleTextStyle == null
          ? null
          : applyTextStyle(listTile.subtitleTextStyle!),
    ),
    snackBarTheme: snackBar.copyWith(
      contentTextStyle: snackBar.contentTextStyle == null
          ? null
          : applyTextStyle(snackBar.contentTextStyle!),
    ),
  );
}
