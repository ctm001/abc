import 'package:flutter/widgets.dart';

import '../../core/audio/audio_service.dart';
import '../../data/repositories/letter_repository.dart';
import 'presentation/alphabetic_principle_screen.dart';

/// Public API for the Alphabetic Principle module.
///
/// The router should import only this file—never the
/// screen directly.
abstract final class AlphabeticPrincipleModule {
  static Widget buildScreen({
    required LetterRepository letterRepository,
    required AudioService audioService,
  }) => AlphabeticPrincipleScreen(
    letterRepository: letterRepository,
    audioService: audioService,
  );
}
