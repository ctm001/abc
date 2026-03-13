import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Sound effects for the finger tracing game.
class FingerTracingAudio {
  final AudioPlayer _celebrationPlayer = AudioPlayer();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    await _celebrationPlayer.setReleaseMode(ReleaseMode.stop);
  }

  /// Plays the celebration sound with a short haptic burst.
  Future<void> playCelebration() async {
    await _init();
    if (!kIsWeb) {
      HapticFeedback.heavyImpact();
      Future<void>.delayed(
        const Duration(milliseconds: 140),
        HapticFeedback.heavyImpact,
      );
      Future<void>.delayed(
        const Duration(milliseconds: 280),
        HapticFeedback.heavyImpact,
      );
    }

    try {
      await _celebrationPlayer.stop();
      await _celebrationPlayer.play(
        AssetSource('audio/sfx/celebration.wav'),
        volume: 0.23,
      );
    } catch (error, stackTrace) {
      log(
        'Failed to play finger tracing celebration sound',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  /// Releases native audio resources.
  Future<void> dispose() async {
    await _celebrationPlayer.dispose();
  }
}
