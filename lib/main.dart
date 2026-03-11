import 'package:flutter/material.dart';

import 'app.dart';
import 'core/audio/audio_service.dart';
import 'core/routing/app_router.dart';
import 'data/repositories/letter_repository.dart';

void main() {
  final letterRepository = LetterRepository();
  final audioService = AudioService();

  final router = AppRouter(
    letterRepository: letterRepository,
    audioService: audioService,
  );

  runApp(App(router: router));
}
