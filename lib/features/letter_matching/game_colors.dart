import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Colour palette and sizes for the letter matching game.
abstract final class GameColors {
  static const primary = AppColors.seed;
  static const primaryLight = AppColors.primaryLight;
  static const secondary = AppColors.rewardGold;
  static const accent = Color(0xFF4ECDC4);
  static const correct = AppColors.success;
  static const letterText = AppColors.textDark;

  static const letterColors = [
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

/// Touch-target and font sizes for the game.
abstract final class GameDimensions {
  static const letterButtonSize = 115.0;
  static const letterFontSize = 48.0;
  static const targetSize = 203.0;
  static const targetFontSize = 94.0;
  static const borderRadius = 20.0;
  static const spacing = 20.0;
}

/// Shared layout constants for the letter stack widgets.
abstract final class StackDimensions {
  static const width = 100.0;
  static const baseWidth = 70.0;
  static const baseHeight = 8.0;
  static const tileSize = 50.0;
  static const tileGap = 4.0;
  static const stackHeadroom = 80.0;
  static const climbingLeft = 25.0;
  static const figureStartBottom = 10.0;
  static const tileLeft = 15.0;
}

/// Shared animation timings for the letter matching game.
abstract final class GameTimings {
  static const wrongAnswerReset = Duration(milliseconds: 500);
  static const stackCrumbleBase = Duration(milliseconds: 1200);
  static const stackCrumblePerTileMs = 100;
  static const climbingBounce = Duration(milliseconds: 400);
  static const climbingIdle = Duration(milliseconds: 8000);
  static const falling = Duration(milliseconds: 1200);
  static const fallingFlail = Duration(milliseconds: 150);
  static const parachuteDescent = Duration(milliseconds: 3000);
  static const parachuteSwing = Duration(milliseconds: 800);
  static const stackCrumbleStaggerMs = 80;
  static const goldCoinScale = Duration(milliseconds: 1000);
  static const goldCoinRevealDelay = Duration(milliseconds: 800);
  static const celebrationScale = Duration(milliseconds: 300);
  static const celebrationAutoAdvance = Duration(seconds: 1);
  static const celebrationEffect = Duration(seconds: 1);
  static const celebrationHapticRepeatDelay = Duration(milliseconds: 150);
  static const celebrationHapticFinalDelay = Duration(milliseconds: 300);
  static const letterButtonPress = Duration(milliseconds: 150);
  static const targetPress = Duration(milliseconds: 100);

  static Duration stackCrumbleDuration(int tileCount) {
    return stackCrumbleBase +
        Duration(milliseconds: tileCount * stackCrumblePerTileMs);
  }

  static Duration stackCrumbleStaggerDelay(int tilesAbove) {
    return Duration(milliseconds: tilesAbove * stackCrumbleStaggerMs);
  }
}
