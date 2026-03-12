import 'dart:math';

import 'package:abc2/core/audio/audio_service.dart';
import 'package:abc2/data/repositories/letter_repository.dart';
import 'package:abc2/features/alphabetic_principle/alphabetic_principle_audio.dart';
import 'package:abc2/features/alphabetic_principle/alphabetic_principle_state.dart';
import 'package:abc2/features/alphabetic_principle/alphabetic_word.dart';
import 'package:abc2/features/alphabetic_principle/presentation/alphabetic_principle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('autoplay runs on start and on each level change', (
    tester,
  ) async {
    final audioService = RecordingAudioService();
    final gameState = AlphabeticPrincipleState(
      letterRepository: LetterRepository(),
      words: const [
        AlphabeticWord(
          word: 'katt',
          emoji: '🐱',
          audioAssetPath: 'assets/audio/words/katt.mp3',
        ),
      ],
      random: Random(0),
    );
    addTearDown(gameState.dispose);

    await pumpAlphabeticPrincipleScreen(
      tester,
      audioService: audioService,
      gameState: gameState,
    );

    expect(audioService.playedAssets, equals(['assets/audio/words/katt.mp3']));

    await tester.tap(find.text('Nivå 1'));
    await tester.pump();
    await tester.pump();

    expect(audioService.playedAssets, hasLength(2));

    await tester.tap(find.text('Nivå 2'));
    await tester.pump();
    await tester.pump();

    expect(audioService.playedAssets, hasLength(3));
  });

  testWidgets('level selector cycles through all three levels', (tester) async {
    final gameState = AlphabeticPrincipleState(
      letterRepository: LetterRepository(),
      words: const [
        AlphabeticWord(
          word: 'sol',
          emoji: '☀️',
          audioAssetPath: 'assets/audio/words/sol.mp3',
        ),
      ],
      random: Random(0),
    );
    addTearDown(gameState.dispose);

    await pumpAlphabeticPrincipleScreen(
      tester,
      audioService: RecordingAudioService(),
      gameState: gameState,
    );

    expect(find.text('Nivå 1'), findsOneWidget);

    await tester.tap(find.text('Nivå 1'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Nivå 2'), findsOneWidget);

    await tester.tap(find.text('Nivå 2'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Nivå 3'), findsOneWidget);

    await tester.tap(find.text('Nivå 3'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Nivå 1'), findsOneWidget);
  });
}

Future<void> pumpAlphabeticPrincipleScreen(
  WidgetTester tester, {
  required RecordingAudioService audioService,
  required AlphabeticPrincipleState gameState,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AlphabeticPrincipleScreen(
        letterRepository: LetterRepository(),
        audioService: audioService,
        gameState: gameState,
        gameAudio: SilentAlphabeticPrincipleAudio(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

class RecordingAudioService extends AudioService {
  final List<String> playedAssets = <String>[];

  @override
  Future<void> playLetterSound(String assetPath) async {
    playedAssets.add(assetPath);
  }

  @override
  Future<void> dispose() async {}
}

class SilentAlphabeticPrincipleAudio extends AlphabeticPrincipleAudio {
  @override
  Future<void> playTap() async {}

  @override
  Future<void> playSuccess() async {}

  @override
  Future<void> playWrong() async {}

  @override
  Future<void> dispose() async {}
}
