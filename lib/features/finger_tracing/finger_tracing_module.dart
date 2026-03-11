import 'package:flutter/widgets.dart';

import '../../core/audio/audio_service.dart';
import '../../data/repositories/letter_repository.dart';
import 'presentation/finger_tracing_screen.dart';

/// Public API for the Finger Tracing module.
///
/// The router should import only this file—never the
/// screen directly.
abstract final class FingerTracingModule {
  static Widget buildScreen({
    required LetterRepository letterRepository,
    required AudioService audioService,
  }) => FingerTracingScreen(
    letterRepository: letterRepository,
    audioService: audioService,
  );
}
