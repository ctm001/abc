import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import 'game_colors.dart';

/// Sound effects and haptic feedback for the game.
class GameAudio {
  final AudioPlayer _popPlayer = AudioPlayer();
  final AudioPlayer _successPlayer = AudioPlayer();
  final AudioPlayer _celebrationPlayer = AudioPlayer();
  final AudioPlayer _wrongPlayer = AudioPlayer();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    await _popPlayer.setReleaseMode(ReleaseMode.stop);
    await _successPlayer.setReleaseMode(ReleaseMode.stop);
    await _celebrationPlayer.setReleaseMode(ReleaseMode.stop);
    await _wrongPlayer.setReleaseMode(ReleaseMode.stop);
  }

  /// Button tap sound with haptic.
  Future<void> playPop() async {
    await _init();
    if (!kIsWeb) HapticFeedback.mediumImpact();
    try {
      await _popPlayer.stop();
      await _popPlayer.play(AssetSource('audio/sfx/pop.wav'), volume: 0.5);
    } catch (error, stackTrace) {
      log('Failed to play pop sound', error: error, stackTrace: stackTrace);
    }
  }

  /// Correct-answer chime with haptic.
  Future<void> playSuccess() async {
    await _init();
    if (!kIsWeb) HapticFeedback.mediumImpact();
    try {
      await _successPlayer.stop();
      await _successPlayer.play(
        AssetSource('audio/sfx/success.wav'),
        volume: 0.7,
      );
    } catch (error, stackTrace) {
      log('Failed to play success sound', error: error, stackTrace: stackTrace);
    }
  }

  /// Level-complete fanfare with triple haptic.
  Future<void> playCelebration() async {
    await _init();
    if (!kIsWeb) {
      HapticFeedback.heavyImpact();
      Future.delayed(
        GameTimings.celebrationHapticRepeatDelay,
        HapticFeedback.heavyImpact,
      );
      Future.delayed(
        GameTimings.celebrationHapticFinalDelay,
        HapticFeedback.heavyImpact,
      );
    }
    try {
      await _celebrationPlayer.stop();
      await _celebrationPlayer.play(
        AssetSource('audio/sfx/celebration.wav'),
        volume: 0.6,
      );
    } catch (error, stackTrace) {
      log(
        'Failed to play celebration sound',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Wrong-answer buzz with vibration.
  Future<void> playWrong() async {
    await _init();
    if (!kIsWeb) HapticFeedback.vibrate();
    try {
      await _wrongPlayer.stop();
      await _wrongPlayer.play(AssetSource('audio/sfx/wrong.wav'), volume: 0.3);
    } catch (error, stackTrace) {
      log('Failed to play wrong sound', error: error, stackTrace: stackTrace);
    }
  }

  /// Release all audio players.
  Future<void> dispose() async {
    await _popPlayer.dispose();
    await _successPlayer.dispose();
    await _celebrationPlayer.dispose();
    await _wrongPlayer.dispose();
  }
}
