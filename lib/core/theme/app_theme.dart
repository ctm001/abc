import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Child-friendly Material 3 theme with large fonts,
/// rounded shapes, and soft shadows.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: _textTheme,
      cardTheme: _cardTheme(colorScheme),
      elevatedButtonTheme: _buttonTheme(colorScheme),
      appBarTheme: _appBarTheme(colorScheme),
    );
  }

  // -- Text -------------------------------------------------

  static const _textTheme = TextTheme(
    displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w800),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontSize: 18, height: 1.5),
    bodyMedium: TextStyle(fontSize: 16),
    labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
  );

  // -- Cards ------------------------------------------------

  static CardThemeData _cardTheme(ColorScheme cs) => CardThemeData(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    surfaceTintColor: cs.surfaceTint,
  );

  // -- Buttons ----------------------------------------------

  static ElevatedButtonThemeData _buttonTheme(ColorScheme cs) =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(56, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      );

  // -- AppBar -----------------------------------------------

  static AppBarTheme _appBarTheme(ColorScheme cs) => AppBarTheme(
    centerTitle: true,
    backgroundColor: cs.surface,
    foregroundColor: cs.onSurface,
    elevation: 0,
    titleTextStyle: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    ),
  );
}
