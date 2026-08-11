import 'package:flutter/material.dart' as legacy_mui;
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';
import 'package:nes_ui/nes_ui.dart';

import '../../style/palette.dart';

/// Adapts the legacy nes_ui and google_fonts theme to package:material_ui.
ThemeData flutterNesThemeAdapted() {
  // =========================================================================
  // COPY THIS EXPRESSION DIRECTLY TO main.dart ONCE LIBRARIES HAVE MIGRATED
  // =========================================================================
  final legacy_mui.ThemeData legacyTheme = flutterNesTheme().copyWith(
    scaffoldBackgroundColor: Palette.background.color,
    colorScheme: legacy_mui.ColorScheme.fromSeed(
      seedColor: Palette.seed.color,
      surface: Palette.background.color,
    ),
    textTheme: GoogleFonts.pressStart2pTextTheme().apply(
      bodyColor: Palette.text.color,
      displayColor: Palette.text.color,
    ),
  );
  // =========================================================================

  // Convert the generated legacy SDK ThemeData into native package:material_ui ThemeData
  return ThemeData(
    brightness: legacyTheme.brightness,
    scaffoldBackgroundColor: legacyTheme.scaffoldBackgroundColor,
    colorScheme: ColorScheme(
      brightness: legacyTheme.colorScheme.brightness,
      primary: legacyTheme.colorScheme.primary,
      onPrimary: legacyTheme.colorScheme.onPrimary,
      secondary: legacyTheme.colorScheme.secondary,
      onSecondary: legacyTheme.colorScheme.onSecondary,
      error: legacyTheme.colorScheme.error,
      onError: legacyTheme.colorScheme.onError,
      surface: legacyTheme.colorScheme.surface,
      onSurface: legacyTheme.colorScheme.onSurface,
    ),
    textTheme: TextTheme(
      displayLarge: legacyTheme.textTheme.displayLarge,
      displayMedium: legacyTheme.textTheme.displayMedium,
      displaySmall: legacyTheme.textTheme.displaySmall,
      headlineLarge: legacyTheme.textTheme.headlineLarge,
      headlineMedium: legacyTheme.textTheme.headlineMedium,
      headlineSmall: legacyTheme.textTheme.headlineSmall,
      titleLarge: legacyTheme.textTheme.titleLarge,
      titleMedium: legacyTheme.textTheme.titleMedium,
      titleSmall: legacyTheme.textTheme.titleSmall,
      bodyLarge: legacyTheme.textTheme.bodyLarge,
      bodyMedium: legacyTheme.textTheme.bodyMedium,
      bodySmall: legacyTheme.textTheme.bodySmall,
      labelLarge: legacyTheme.textTheme.labelLarge,
      labelMedium: legacyTheme.textTheme.labelMedium,
      labelSmall: legacyTheme.textTheme.labelSmall,
    ),
  );
}
