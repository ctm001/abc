import 'package:flutter/material.dart';

import '../../../core/audio/audio_service.dart';
import '../../../data/repositories/letter_repository.dart';

/// Placeholder screen for the Letter Matching game.
class LetterMatchingScreen extends StatelessWidget {
  const LetterMatchingScreen({
    required this.letterRepository,
    required this.audioService,
    super.key,
  });

  final LetterRepository letterRepository;
  final AudioService audioService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bokstavkobling')),
      body: const Center(
        child: Text(
          'Bokstavkobling — kommer snart!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
