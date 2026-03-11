import 'package:flutter/material.dart';

import '../../../core/audio/audio_service.dart';
import '../../../data/repositories/letter_repository.dart';

/// Placeholder screen for the Finger Tracing game.
class FingerTracingScreen extends StatelessWidget {
  const FingerTracingScreen({
    required this.letterRepository,
    required this.audioService,
    super.key,
  });

  final LetterRepository letterRepository;
  final AudioService audioService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spor bokstavene')),
      body: const Center(
        child: Text(
          'Spor bokstavene — kommer snart!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
