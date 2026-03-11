import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';

/// Service for playing letter pronunciation audio.
class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  /// Plays the sound at [assetPath].
  ///
  /// Example: `playLetterSound('assets/audio/letters/a.mp3')`
  Future<void> playLetterSound(String assetPath) async {
    await _init();
    try {
      await _player.stop();
      final relative = assetPath.startsWith('assets/')
          ? assetPath.substring(7)
          : assetPath;
      await _player.play(AssetSource(relative));
    } catch (error, stackTrace) {
      log('Failed to play letter sound', error: error, stackTrace: stackTrace);
    }
  }

  /// Release audio resources.
  Future<void> dispose() async {
    await _player.dispose();
  }
}
