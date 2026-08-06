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
          primary: palette.accent,
          onPrimary: palette.onAccent,
          secondary: palette.success,
          onSecondary: palette.onSuccess,
          error: palette.destructive,
          onError: palette.onDestructive,
          surface: palette.view,
          onSurface: palette.text,
          surfaceContainerHighest: palette.view,
          onSurfaceVariant: palette.textMuted,
          outline: palette.border,
          outlineVariant: palette.border.withValues(alpha: 0.55),
        )
      : ColorScheme.light(
          primary: palette.accent,
          onPrimary: palette.onAccent,
          secondary: palette.success,
          onSecondary: palette.onSuccess,
          error: palette.destructive,
          onError: palette.onDestructive,
          surface: palette.view,
          onSurface: palette.text,
          surfaceContainerHighest: palette.view,
          onSurfaceVariant: palette.textMuted,
          outline: palette.border,
          outlineVariant: palette.border.withValues(alpha: 0.55),
        );

  final theme = base.copyWith(
    scaffoldBackgroundColor: palette.window,
    canvasColor: palette.window,
    cardColor: palette.view,
    dialogTheme: DialogThemeData(
      backgroundColor: palette.view,
      shape: AdwaitaThemeData.getDialogShape(palette.view),
    ),
    dividerColor: palette.border.withValues(alpha: 0.35),
    focusColor: palette.accent.withValues(alpha: 0.36),
    hoverColor: palette.accent.withValues(alpha: 0.10),
    highlightColor: palette.accent.withValues(alpha: 0.16),
    disabledColor: palette.textMuted.withValues(alpha: 0.42),
    colorScheme: colorScheme,
    textTheme: base.textTheme.apply(
      bodyColor: palette.text,
      displayColor: palette.text,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: palette.headerBar,
      foregroundColor: palette.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      toolbarHeight: 48,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: palette.text,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        minimumSize: const Size(0, 36),
      ),
    ),
    listTileTheme: ListTileThemeData(
      textColor: palette.text,
      iconColor: palette.accent,
      subtitleTextStyle: TextStyle(color: palette.textMuted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return palette.textMuted.withValues(alpha: 0.5);
        }
        return palette.accent;
      }),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: palette.text,
        minimumSize: const Size(40, 40),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.headerBar,
      contentTextStyle: TextStyle(color: palette.text),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: palette.accent),
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
