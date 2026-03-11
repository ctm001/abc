import 'dart:ui';

/// App-wide colour constants that sit outside [ColorScheme].
abstract final class AppColors {
  /// Seed colour used by [ColorScheme.fromSeed].
  static const seed = Color(0xFF4CAF50);

  /// Accent for the Letter Matching module card.
  static const letterMatching = Color(0xFFFF7043);

  /// Accent for the Finger Tracing module card.
  static const fingerTracing = Color(0xFF42A5F5);

  /// Accent for the Alphabetic Principle module card.
  static const alphabeticPrinciple = Color(0xFFFFCA28);
}
