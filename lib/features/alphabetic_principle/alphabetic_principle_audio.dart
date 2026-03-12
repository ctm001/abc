import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

class AlphabeticPrincipleAudio {
  final AudioPlayer _tapPlayer = AudioPlayer();
  final AudioPlayer _successPlayer = AudioPlayer();
  final AudioPlayer _celebrationPlayer = AudioPlayer();
  final AudioPlayer _wrongPlayer = AudioPlayer();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) {
      return;
    }

    _initialized = true;
    await _tapPlayer.setReleaseMode(ReleaseMode.stop);
    await _successPlayer.setReleaseMode(ReleaseMode.stop);
    await _celebrationPlayer.setReleaseMode(ReleaseMode.stop);
    await _wrongPlayer.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> playTap() async {
    await _init();
    if (!kIsWeb) {
      HapticFeedback.mediumImpact();
    }
    try {
      await _tapPlayer.stop();
      await _tapPlayer.play(AssetSource('audio/sfx/pop.wav'), volume: 0.5);
    } catch (error, stackTrace) {
      log('Failed to play tap sound', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> playSuccess() async {
    await _init();
    if (!kIsWeb) {
      HapticFeedback.mediumImpact();
    }
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

  Future<void> playCelebration() async {
    await _init();
    if (!kIsWeb) {
      HapticFeedback.heavyImpact();
      Future.delayed(
        const Duration(milliseconds: 150),
        HapticFeedback.heavyImpact,
      );
      Future.delayed(
        const Duration(milliseconds: 300),
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
        'Failed to play alphabetic principle celebration sound',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> playWrong() async {
    await _init();
    if (!kIsWeb) {
      HapticFeedback.vibrate();
    }
    try {
      await _wrongPlayer.stop();
      await _wrongPlayer.play(AssetSource('audio/sfx/wrong.wav'), volume: 0.35);
    } catch (error, stackTrace) {
      log('Failed to play wrong sound', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> dispose() async {
    await _tapPlayer.dispose();
    await _successPlayer.dispose();
    await _celebrationPlayer.dispose();
    await _wrongPlayer.dispose();
  }
}
