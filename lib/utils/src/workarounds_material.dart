import 'package:flutter/material.dart' as legacy_mui;
import 'package:material_ui/material_ui.dart';

/// Adapts the legacy google_fonts theme to package:material_ui.
TextTheme modernise(Object? legacyThemeOrTheme) {
  // If google_fonts outputs the new material_ui TextTheme directly, use it.
  if (legacyThemeOrTheme is TextTheme) {
    return legacyThemeOrTheme;
  }

  // Fallback check for legacy Flutter material TextTheme
  if (legacyThemeOrTheme is legacy_mui.TextTheme) {
    return TextTheme(
      displayLarge: legacyThemeOrTheme.displayLarge,
      displayMedium: legacyThemeOrTheme.displayMedium,
      displaySmall: legacyThemeOrTheme.displaySmall,
      headlineLarge: legacyThemeOrTheme.headlineLarge,
      headlineMedium: legacyThemeOrTheme.headlineMedium,
      headlineSmall: legacyThemeOrTheme.headlineSmall,
      titleLarge: legacyThemeOrTheme.titleLarge,
      titleMedium: legacyThemeOrTheme.titleMedium,
      titleSmall: legacyThemeOrTheme.titleSmall,
      bodyLarge: legacyThemeOrTheme.bodyLarge,
      bodyMedium: legacyThemeOrTheme.bodyMedium,
      bodySmall: legacyThemeOrTheme.bodySmall,
      labelLarge: legacyThemeOrTheme.labelLarge,
      labelMedium: legacyThemeOrTheme.labelMedium,
      labelSmall: legacyThemeOrTheme.labelSmall,
    );
  }

  throw ArgumentError(
    'Expected TextTheme or legacy_mui.TextTheme, but got ${legacyThemeOrTheme.runtimeType}',
  );
}
