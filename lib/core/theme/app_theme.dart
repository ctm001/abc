import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Child-friendly Material 3 theme using ABeeZee throughout
/// — warm, rounded, shadow-rich.
abstract final class AppTheme {
  static ThemeData light() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    );

    final baseTheme = GoogleFonts.aBeeZeeTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: baseTheme.copyWith(
        displayLarge: GoogleFonts.aBeeZee(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        displayMedium: GoogleFonts.aBeeZee(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        headlineLarge: GoogleFonts.aBeeZee(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        headlineMedium: GoogleFonts.aBeeZee(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.textOlive,
        ),
        titleLarge: GoogleFonts.aBeeZee(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        titleMedium: GoogleFonts.aBeeZee(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
        bodyLarge: GoogleFonts.aBeeZee(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.aBeeZee(fontSize: 16),
        labelLarge: GoogleFonts.aBeeZee(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        labelMedium: GoogleFonts.aBeeZee(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),
      scaffoldBackgroundColor: Colors.transparent,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(56, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: GoogleFonts.aBeeZee(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textDark,
        elevation: 0,
        titleTextStyle: GoogleFonts.aBeeZee(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    );
  }
}
