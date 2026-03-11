import 'package:flutter/widgets.dart';

import '../../core/audio/audio_service.dart';
import '../../data/repositories/letter_repository.dart';
import 'presentation/letter_matching_screen.dart';

/// Public API for the Letter Matching module.
///
/// The router should import only this file—never the
/// screen directly.
abstract final class LetterMatchingModule {
  static Widget buildScreen({
    required LetterRepository letterRepository,
    required AudioService audioService,
  }) => LetterMatchingScreen(
    letterRepository: letterRepository,
    audioService: audioService,
  );
}
