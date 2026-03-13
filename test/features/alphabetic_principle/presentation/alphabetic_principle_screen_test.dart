import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:abc2/core/audio/audio_service.dart';
import 'package:abc2/data/repositories/letter_repository.dart';
import 'package:abc2/features/alphabetic_principle/alphabetic_principle_audio.dart';
import 'package:abc2/features/alphabetic_principle/alphabetic_principle_state.dart';
import 'package:abc2/features/alphabetic_principle/alphabetic_word.dart';
import 'package:abc2/features/alphabetic_principle/presentation/alphabetic_principle_screen.dart';
import 'package:abc2/features/letter_matching/presentation/widgets/letter_button.dart';
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
          emoji: 'CAT',
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

    await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
    await tester.pump();
    await tester.pump();
    expect(gameState.level, 1);
    expect(audioService.playedAssets, hasLength(2));

    await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
    await tester.pump();
    await tester.pump();
    expect(gameState.level, 2);
    expect(audioService.playedAssets, hasLength(3));
  });

  testWidgets('level selector cycles through all three levels', (tester) async {
    final gameState = AlphabeticPrincipleState(
      letterRepository: LetterRepository(),
      words: const [
        AlphabeticWord(
          word: 'sol',
          emoji: 'SUN',
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

    expect(gameState.level, 0);

    await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
    await tester.pump();
    await tester.pump();
    expect(gameState.level, 1);

    await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
    await tester.pump();
    await tester.pump();
    expect(gameState.level, 2);

    await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
    await tester.pump();
    await tester.pump();
    expect(gameState.level, 0);
  });

  testWidgets('level selector stays pinned to the top right', (tester) async {
    final gameState = AlphabeticPrincipleState(
      letterRepository: LetterRepository(),
      words: const [
        AlphabeticWord(
          word: 'sol',
          emoji: 'SUN',
          audioAssetPath: 'assets/audio/words/sol.mp3',
        ),
      ],
      random: Random(0),
    );
    addTearDown(gameState.dispose);
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAlphabeticPrincipleScreen(
      tester,
      audioService: RecordingAudioService(),
      gameState: gameState,
    );

    expect(
      tester.getTopLeft(find.byIcon(Icons.arrow_back_rounded)).dx,
      lessThan(40),
    );
    expect(
      tester.getTopRight(find.byKey(const ValueKey('game-level-switcher'))).dx,
      greaterThan(850),
    );
  });

  testWidgets(
    'word card keeps the same position across levels',
    (tester) async {
      final gameState = AlphabeticPrincipleState(
        letterRepository: LetterRepository(),
        words: const [
          AlphabeticWord(
            word: 'katt',
            emoji: 'CAT',
            audioAssetPath: 'assets/audio/words/katt.mp3',
          ),
        ],
        random: Random(0),
      );
      addTearDown(gameState.dispose);
      await tester.binding.setSurfaceSize(const Size(320, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await pumpAlphabeticPrincipleScreen(
        tester,
        audioService: RecordingAudioService(),
        gameState: gameState,
      );

      final cardFinder = find.byKey(
        const ValueKey('alphabetic-principle-card'),
      );
      final levelOneCardCenterY = tester.getCenter(cardFinder).dy;

      await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
      await tester.pump();
      await tester.pump();

      final levelThreeCardCenterY = tester.getCenter(cardFinder).dy;
      expect(levelThreeCardCenterY, closeTo(levelOneCardCenterY, 0.01));
    },
  );

  testWidgets('choice bank reuses the matching-game letter button', (
    tester,
  ) async {
    final gameState = AlphabeticPrincipleState(
      letterRepository: LetterRepository(),
      words: const [
        AlphabeticWord(
          word: 'sol',
          emoji: 'SUN',
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

    expect(find.byType(LetterButton), findsNWidgets(4));
  });

  testWidgets('level 3 keeps the same choice-button size as earlier levels', (
    tester,
  ) async {
    final gameState = AlphabeticPrincipleState(
      letterRepository: LetterRepository(),
      words: const [
        AlphabeticWord(
          word: 'katt',
          emoji: 'CAT',
          audioAssetPath: 'assets/audio/words/katt.mp3',
        ),
      ],
      random: Random(0),
    );
    addTearDown(gameState.dispose);
    await tester.binding.setSurfaceSize(const Size(500, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAlphabeticPrincipleScreen(
      tester,
      audioService: RecordingAudioService(),
      gameState: gameState,
    );

    final levelOneButtonSize = tester.getSize(find.byType(LetterButton).first);

    await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
    await tester.pump();
    await tester.pump();

    final levelThreeButtonSize = tester.getSize(
      find.byType(LetterButton).first,
    );

    expect(levelThreeButtonSize.width, closeTo(levelOneButtonSize.width, 0.01));
    expect(
      levelThreeButtonSize.height,
      closeTo(levelOneButtonSize.height, 0.01),
    );
  });

  testWidgets('level 3 shows question marks in empty slots', (tester) async {
    final gameState = AlphabeticPrincipleState(
      letterRepository: LetterRepository(),
      words: const [
        AlphabeticWord(
          word: 'sol',
          emoji: 'SUN',
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

    await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
    await tester.pump();
    await tester.pump();

    expect(find.text('?'), findsNWidgets(3));
  });

  testWidgets('level 3 completion keeps the card in place', (tester) async {
    final gameState = AlphabeticPrincipleState(
      letterRepository: LetterRepository(),
      words: const [
        AlphabeticWord(
          word: 'ape',
          emoji: 'APE',
          audioAssetPath: 'assets/audio/words/ape.mp3',
        ),
      ],
      random: Random(0),
    );
    await tester.binding.setSurfaceSize(const Size(500, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpAlphabeticPrincipleScreen(
      tester,
      audioService: RecordingAudioService(),
      gameState: gameState,
    );

    await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
    await tester.pump();
    await tester.pump();

    final cardFinder = find.byKey(const ValueKey('alphabetic-principle-card'));
    final initialCardTopLeft = tester.getTopLeft(cardFinder);

    for (final letter in gameState.currentWord.letters) {
      final choice = gameState.choices.firstWhere(
        (candidate) => candidate.letter == letter,
      );
      gameState.selectChoice(choice);
      await tester.pump();
    }

    final completedCardTopLeft = tester.getTopLeft(cardFinder);

    expect(completedCardTopLeft.dx, closeTo(initialCardTopLeft.dx, 0.01));
    expect(completedCardTopLeft.dy, closeTo(initialCardTopLeft.dy, 0.01));

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    gameState.dispose();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('level 3 celebration spells the word and pulses slots in order', (
    tester,
  ) async {
    final repository = LetterRepository();
    final audioService = ControlledRecordingAudioService();
    final gameAudio = RecordingAlphabeticPrincipleAudio();
    final gameState = AlphabeticPrincipleState(
      letterRepository: repository,
      words: const [
        AlphabeticWord(
          word: 'katt',
          emoji: 'CAT',
          audioAssetPath: 'assets/audio/words/katt.mp3',
        ),
      ],
      random: Random(0),
    );
    addTearDown(() {
      gameAudio.completeAllCelebrations();
      audioService.completeAllAwaitedPlayback();
      gameState.dispose();
    });

    await pumpAlphabeticPrincipleScreen(
      tester,
      audioService: audioService,
      gameState: gameState,
      gameAudio: gameAudio,
      letterRepository: repository,
    );
    await _switchToBuildWordLevel(tester, gameState, audioService);

    _completeCurrentBuildWord(gameState);
    await tester.pump();

    expect(audioService.playedAssets, isEmpty);
    expect(
      find.byKey(const ValueKey('alphabetic-slot-pulsing-0')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('alphabetic-principle-confetti')),
      findsOneWidget,
    );
    expect(gameAudio.celebrationCalls, 1);
    expect(gameAudio.pendingCelebrationCount, 1);
    expect(find.text('Bra jobba!'), findsNothing);

    gameAudio.completeNextCelebration();
    await tester.pump();

    expect(audioService.playedAssets, [
      repository.getByCharacter('K').soundAssetPath,
    ]);
    expect(
      find.byKey(const ValueKey('alphabetic-slot-pulsing-0')),
      findsOneWidget,
    );

    audioService.completeNextAwaitedPlayback();
    await tester.pump(_celebrationGap);
    expect(audioService.playedAssets, [
      repository.getByCharacter('K').soundAssetPath,
      repository.getByCharacter('A').soundAssetPath,
    ]);
    expect(
      find.byKey(const ValueKey('alphabetic-slot-pulsing-1')),
      findsOneWidget,
    );

    audioService.completeNextAwaitedPlayback();
    await tester.pump(_celebrationGap);
    expect(audioService.playedAssets, [
      repository.getByCharacter('K').soundAssetPath,
      repository.getByCharacter('A').soundAssetPath,
      repository.getByCharacter('T').soundAssetPath,
    ]);
    expect(
      find.byKey(const ValueKey('alphabetic-slot-pulsing-2')),
      findsOneWidget,
    );

    audioService.completeNextAwaitedPlayback();
    await tester.pump(_celebrationGap);
    expect(audioService.playedAssets, [
      repository.getByCharacter('K').soundAssetPath,
      repository.getByCharacter('A').soundAssetPath,
      repository.getByCharacter('T').soundAssetPath,
      repository.getByCharacter('T').soundAssetPath,
    ]);
    expect(
      find.byKey(const ValueKey('alphabetic-slot-pulsing-3')),
      findsOneWidget,
    );

    audioService.completeNextAwaitedPlayback();
    await tester.pump();
    expect(audioService.playedAssets.take(5).toList(), [
      repository.getByCharacter('K').soundAssetPath,
      repository.getByCharacter('A').soundAssetPath,
      repository.getByCharacter('T').soundAssetPath,
      repository.getByCharacter('T').soundAssetPath,
      gameState.currentWord.audioAssetPath,
    ]);
    expect(gameState.showSuccess, isTrue);

    audioService.completeNextAwaitedPlayback();
    await tester.pump();
    await tester.pump(_postWordPause);
    await tester.pump();

    expect(gameState.showSuccess, isFalse);
  });

  testWidgets(
    'level 3 does not advance until the final word replay completes',
    (tester) async {
      final repository = LetterRepository();
      final audioService = ControlledRecordingAudioService();
      final gameAudio = RecordingAlphabeticPrincipleAudio();
      final gameState = AlphabeticPrincipleState(
        letterRepository: repository,
        words: const [
          AlphabeticWord(
            word: 'katt',
            emoji: 'CAT',
            audioAssetPath: 'assets/audio/words/katt.mp3',
          ),
          AlphabeticWord(
            word: 'sol',
            emoji: 'SUN',
            audioAssetPath: 'assets/audio/words/sol.mp3',
          ),
        ],
        random: Random(0),
      );
      addTearDown(() {
        gameAudio.completeAllCelebrations();
        audioService.completeAllAwaitedPlayback();
        gameState.dispose();
      });

      await pumpAlphabeticPrincipleScreen(
        tester,
        audioService: audioService,
        gameState: gameState,
        gameAudio: gameAudio,
        letterRepository: repository,
      );
      await _switchToBuildWordLevel(tester, gameState, audioService);
      final initialWord = gameState.currentWord.word;
      final initialLetterCount = gameState.currentWord.letters.length;
      final nextWord = [
        'katt',
        'sol',
      ].firstWhere((word) => word != initialWord);

      _completeCurrentBuildWord(gameState);
      await tester.pump();

      expect(audioService.pendingAwaitCount, 0);
      gameAudio.completeNextCelebration();
      await tester.pump();

      for (var index = 0; index < initialLetterCount; index++) {
        audioService.completeNextAwaitedPlayback();
        if (index == initialLetterCount - 1) {
          await tester.pump();
        } else {
          await tester.pump(_celebrationGap);
        }
      }

      expect(gameState.currentWord.word, initialWord);
      expect(gameState.showSuccess, isTrue);
      expect(audioService.pendingAwaitCount, 1);

      audioService.completeNextAwaitedPlayback();
      await tester.pump();
      await tester.pump(_postWordPause - const Duration(milliseconds: 1));

      expect(gameState.currentWord.word, initialWord);
      expect(gameState.showSuccess, isTrue);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();

      expect(gameState.currentWord.word, nextWord);
      expect(gameState.showSuccess, isFalse);
      expect(gameAudio.celebrationCalls, 1);
    },
  );

  testWidgets('level 1 uses the full celebration sequence before advancing', (
    tester,
  ) async {
    final repository = LetterRepository();
    final audioService = ControlledRecordingAudioService();
    final gameAudio = RecordingAlphabeticPrincipleAudio();
    final gameState = AlphabeticPrincipleState(
      letterRepository: repository,
      words: const [
        AlphabeticWord(
          word: 'sol',
          emoji: 'SUN',
          audioAssetPath: 'assets/audio/words/sol.mp3',
        ),
        AlphabeticWord(
          word: 'ape',
          emoji: 'APE',
          audioAssetPath: 'assets/audio/words/ape.mp3',
        ),
      ],
      random: Random(0),
    );
    addTearDown(() {
      gameAudio.completeAllCelebrations();
      audioService.completeAllAwaitedPlayback();
      gameState.dispose();
    });

    await pumpAlphabeticPrincipleScreen(
      tester,
      audioService: audioService,
      gameState: gameState,
      gameAudio: gameAudio,
      letterRepository: repository,
    );
    final initialWord = gameState.currentWord.word;
    final initialLetters = gameState.currentWord.letters;
    final nextWord = ['sol', 'ape'].firstWhere((word) => word != initialWord);

    audioService.playedAssets.clear();
    final correctChoice = gameState.choices.firstWhere(
      (choice) =>
          choice.letter ==
          gameState.currentWord.letters[gameState.missingIndex],
    );
    gameState.selectChoice(correctChoice);
    await tester.pump();

    expect(gameState.showSuccess, isTrue);
    expect(audioService.playedAssets, isEmpty);
    expect(
      find.byKey(const ValueKey('alphabetic-principle-confetti')),
      findsOneWidget,
    );
    expect(find.text('Bra jobba!'), findsNothing);
    expect(gameAudio.celebrationCalls, 1);
    expect(gameAudio.pendingCelebrationCount, 1);

    gameAudio.completeNextCelebration();
    await tester.pump();

    for (var index = 0; index < initialLetters.length; index++) {
      expect(
        audioService.playedAssets[index],
        repository.getByCharacter(initialLetters[index]).soundAssetPath,
      );
      expect(
        find.byKey(ValueKey('alphabetic-slot-pulsing-$index')),
        findsOneWidget,
      );

      audioService.completeNextAwaitedPlayback();
      if (index == initialLetters.length - 1) {
        await tester.pump();
      } else {
        await tester.pump(_celebrationGap);
      }
    }

    expect(audioService.pendingAwaitCount, 1);
    expect(
      audioService.playedAssets.last,
      gameState.currentWord.audioAssetPath,
    );

    audioService.completeNextAwaitedPlayback();
    await tester.pump();
    await tester.pump(_postWordPause - const Duration(milliseconds: 1));
    expect(gameState.currentWord.word, initialWord);
    expect(gameState.showSuccess, isTrue);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(gameState.currentWord.word, nextWord);
    expect(gameState.showSuccess, isFalse);
    expect(audioService.playedAssets.last, 'assets/audio/words/$nextWord.mp3');
  });

  testWidgets(
    'tapping during celebration skips straight to the next question',
    (tester) async {
      final repository = LetterRepository();
      final audioService = ControlledRecordingAudioService();
      final gameAudio = RecordingAlphabeticPrincipleAudio();
      final gameState = AlphabeticPrincipleState(
        letterRepository: repository,
        words: const [
          AlphabeticWord(
            word: 'sol',
            emoji: 'SUN',
            audioAssetPath: 'assets/audio/words/sol.mp3',
          ),
          AlphabeticWord(
            word: 'ape',
            emoji: 'APE',
            audioAssetPath: 'assets/audio/words/ape.mp3',
          ),
        ],
        random: Random(0),
      );
      addTearDown(() {
        gameAudio.completeAllCelebrations();
        audioService.completeAllAwaitedPlayback();
        gameState.dispose();
      });

      await pumpAlphabeticPrincipleScreen(
        tester,
        audioService: audioService,
        gameState: gameState,
        gameAudio: gameAudio,
        letterRepository: repository,
      );
      final initialWord = gameState.currentWord.word;
      final nextWord = ['sol', 'ape'].firstWhere((word) => word != initialWord);

      audioService.playedAssets.clear();
      final correctChoice = gameState.choices.firstWhere(
        (choice) =>
            choice.letter ==
            gameState.currentWord.letters[gameState.missingIndex],
      );
      gameState.selectChoice(correctChoice);
      await tester.pump();

      expect(gameState.showSuccess, isTrue);
      expect(gameAudio.pendingCelebrationCount, 1);

      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump();

      expect(gameAudio.stopCelebrationCalls, 1);
      expect(gameState.currentWord.word, nextWord);
      expect(gameState.showSuccess, isFalse);
      expect(
        audioService.playedAssets.last,
        'assets/audio/words/$nextWord.mp3',
      );
    },
  );
}

Future<void> pumpAlphabeticPrincipleScreen(
  WidgetTester tester, {
  required RecordingAudioService audioService,
  required AlphabeticPrincipleState gameState,
  AlphabeticPrincipleAudio? gameAudio,
  LetterRepository? letterRepository,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: AlphabeticPrincipleScreen(
        letterRepository: letterRepository ?? LetterRepository(),
        audioService: audioService,
        gameState: gameState,
        gameAudio: gameAudio ?? SilentAlphabeticPrincipleAudio(),
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
  Future<void> playLetterSoundAndWait(String assetPath) async {
    playedAssets.add(assetPath);
  }

  @override
  Future<void> dispose() async {}
}

class ControlledRecordingAudioService extends RecordingAudioService {
  final Queue<Completer<void>> _pendingAwaitedPlayback =
      Queue<Completer<void>>();

  int get pendingAwaitCount => _pendingAwaitedPlayback.length;

  @override
  Future<void> playLetterSoundAndWait(String assetPath) {
    playedAssets.add(assetPath);
    final completer = Completer<void>();
    _pendingAwaitedPlayback.add(completer);
    return completer.future;
  }

  void completeNextAwaitedPlayback() {
    if (_pendingAwaitedPlayback.isEmpty) {
      throw StateError('No awaited playback is pending.');
    }
    _pendingAwaitedPlayback.removeFirst().complete();
  }

  void completeAllAwaitedPlayback() {
    while (_pendingAwaitedPlayback.isNotEmpty) {
      _pendingAwaitedPlayback.removeFirst().complete();
    }
  }
}

class SilentAlphabeticPrincipleAudio extends AlphabeticPrincipleAudio {
  @override
  Future<void> playTap() async {}

  @override
  Future<void> playSuccess() async {}

  @override
  Future<void> playCelebration() async {}

  @override
  Future<void> playWrong() async {}

  @override
  Future<void> stopCelebration() async {}

  @override
  Future<void> dispose() async {}
}

const _celebrationGap = Duration(milliseconds: 120);
const _postWordPause = Duration(seconds: 2);

class RecordingAlphabeticPrincipleAudio extends SilentAlphabeticPrincipleAudio {
  int celebrationCalls = 0;
  int stopCelebrationCalls = 0;
  final Queue<Completer<void>> _pendingCelebrations = Queue<Completer<void>>();

  int get pendingCelebrationCount => _pendingCelebrations.length;

  @override
  Future<void> playCelebration() async {
    celebrationCalls++;
    final completer = Completer<void>();
    _pendingCelebrations.add(completer);
    await completer.future;
  }

  @override
  Future<void> stopCelebration() async {
    stopCelebrationCalls++;
    completeAllCelebrations();
  }

  void completeNextCelebration() {
    if (_pendingCelebrations.isEmpty) {
      throw StateError('No celebration playback is pending.');
    }
    _pendingCelebrations.removeFirst().complete();
  }

  void completeAllCelebrations() {
    while (_pendingCelebrations.isNotEmpty) {
      _pendingCelebrations.removeFirst().complete();
    }
  }
}

void _completeCurrentBuildWord(AlphabeticPrincipleState gameState) {
  for (final letter in gameState.currentWord.letters) {
    final choice = gameState.choices.firstWhere(
      (candidate) => candidate.letter == letter,
    );
    gameState.selectChoice(choice);
  }
}

Future<void> _switchToBuildWordLevel(
  WidgetTester tester,
  AlphabeticPrincipleState gameState,
  RecordingAudioService audioService,
) async {
  gameState.playLevel(2);
  await tester.pump();
  await tester.pump();
  audioService.playedAssets.clear();
}
