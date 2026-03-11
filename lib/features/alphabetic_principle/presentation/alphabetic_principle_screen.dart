import 'package:flutter/material.dart';

import '../../../core/audio/audio_service.dart';
import '../../../data/repositories/letter_repository.dart';

/// Placeholder screen for the Alphabetic Principle game.
class AlphabeticPrincipleScreen extends StatelessWidget {
  const AlphabeticPrincipleScreen({
    required this.letterRepository,
    required this.audioService,
    super.key,
  });

  final LetterRepository letterRepository;
  final AudioService audioService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bokstavlyder')),
      body: const Center(
        child: Text(
          'Bokstavlyder — kommer snart!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
