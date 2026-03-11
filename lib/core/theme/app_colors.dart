import 'dart:ui';

/// App-wide colour palette.
///
/// Follows the MathMarket design language — warm backgrounds,
/// multi-layer shadows, vibrant module accents — with a
/// distinct green identity for ABC2.
abstract final class AppColors {
  // -- Seed & Primary ----------------------------------------

  /// Seed colour used by [ColorScheme.fromSeed].
  static const seed = Color(0xFF4CAF50);
  static const primaryLight = Color(0xFF66BB6A);
  static const primaryDark = Color(0xFF388E3C);

  // -- Module Accents ----------------------------------------

  static const letterMatching = Color(0xFFFF7043);
  static const letterMatchingLight = Color(0xFFFF8A65);
  static const letterMatchingDark = Color(0xFFE64A19);

  static const fingerTracing = Color(0xFF42A5F5);
  static const fingerTracingLight = Color(0xFF64B5F6);
  static const fingerTracingDark = Color(0xFF1E88E5);

  static const alphabeticPrinciple = Color(0xFFFFCA28);
  static const alphabeticPrincipleLight = Color(0xFFFFD54F);
  static const alphabeticPrincipleDark = Color(0xFFF9A825);

  // -- Feedback Colours --------------------------------------

  static const success = Color(0xFF30A860);
  static const danger = Color(0xFFFF2A10);
  static const rewardGold = Color(0xFFFFAA00);

  // -- Warm Background Gradient (top → bottom) ---------------

  static const bgTop = Color(0xFFF1F8E9);
  static const bgMid = Color(0xFFDCEDC8);
  static const bgLow = Color(0xFFC5E1A5);
  static const bgBottom = Color(0xFFAED581);

  // -- Text Colours ------------------------------------------

  static const textDark = Color(0xFF3A3A3A);
  static const textOlive = Color(0xFF33691E);

  // -- Confetti palette --------------------------------------

  static const confetti = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFE66D),
    Color(0xFF95E1D3),
    Color(0xFFF38181),
    Color(0xFFAA96DA),
    Color(0xFF6EC6E8),
    Color(0xFFFF9A9E),
  ];
}
