import 'dart:async';
import 'dart:developer';

import 'package:audioplayers/audioplayers.dart';

/// Service for playing letter pronunciation audio.
class AudioService {
  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;
  Completer<void>? _activePlaybackCompleter;

  Future<void> _init() async {
    if (_initialized) return;
    _initialized = true;
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  /// Plays the sound at [assetPath].
  ///
  /// Example: `playLetterSound('assets/audio/letters/a.mp3')`
  Future<void> playLetterSound(String assetPath) async {
    await _playAsset(assetPath);
  }

  /// Plays the sound at [assetPath] and resolves when playback finishes or is
  /// interrupted by a newer request on the same service.
  Future<void> playLetterSoundAndWait(String assetPath) async {
    await _playAsset(assetPath, waitUntilComplete: true);
  }

  Future<void> _playAsset(
    String assetPath, {
    bool waitUntilComplete = false,
  }) async {
    await _init();
    _completeActivePlayback();
    try {
      await _player.stop();
      final relative = _relativeAssetPath(assetPath);
      if (!waitUntilComplete) {
        await _player.play(AssetSource(relative));
        return;
      }

      final playbackCompleter = Completer<void>();
      _activePlaybackCompleter = playbackCompleter;
      late final StreamSubscription<void> completionSubscription;
      completionSubscription = _player.onPlayerComplete.listen((_) {
        if (!playbackCompleter.isCompleted) {
          playbackCompleter.complete();
        }
      });

      try {
        await _player.play(AssetSource(relative));
        await playbackCompleter.future;
      } finally {
        if (_activePlaybackCompleter == playbackCompleter) {
          _activePlaybackCompleter = null;
        }
        await completionSubscription.cancel();
      }
    } catch (error, stackTrace) {
      log('Failed to play letter sound', error: error, stackTrace: stackTrace);
    }
  }

  String _relativeAssetPath(String assetPath) =>
      assetPath.startsWith('assets/') ? assetPath.substring(7) : assetPath;

  void _completeActivePlayback() {
    final playbackCompleter = _activePlaybackCompleter;
    if (playbackCompleter != null && !playbackCompleter.isCompleted) {
      playbackCompleter.complete();
    }
    _activePlaybackCompleter = null;
  }

  /// Release audio resources.
  Future<void> dispose() async {
    _completeActivePlayback();
    await _player.dispose();
  }
}
