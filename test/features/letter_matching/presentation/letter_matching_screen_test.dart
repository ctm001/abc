import 'package:abc2/core/audio/audio_service.dart';
import 'package:abc2/data/repositories/letter_repository.dart';
import 'package:abc2/features/letter_matching/find_letter_state.dart';
import 'package:abc2/features/letter_matching/game_audio.dart';
import 'package:abc2/features/letter_matching/game_colors.dart';
import 'package:abc2/features/letter_matching/presentation/letter_matching_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('autoplay runs once when switching levels', (tester) async {
    final audioService = RecordingAudioService();

    await pumpLetterMatchingScreen(
      tester,
      audioService: audioService,
      prefs: const {'highest_level': 1},
    );

    expect(audioService.playedAssets, hasLength(1));

    await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
    await tester.pump();
    await tester.pump();

    expect(audioService.playedAssets, hasLength(2));
  });

  testWidgets('level selector only cycles through the three supported levels', (
    tester,
  ) async {
    final audioService = RecordingAudioService();

    await pumpLetterMatchingScreen(
      tester,
      audioService: audioService,
      prefs: const {'highest_level': 7},
    );

    expect(currentLevelLabel(tester), endsWith('3'));

    await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
    await tester.pump();
    await tester.pump();

    expect(currentLevelLabel(tester), endsWith('1'));

    await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
    await tester.pump();
    await tester.pump();

    expect(currentLevelLabel(tester), endsWith('2'));

    await tester.tap(find.byKey(const ValueKey('game-level-switcher')));
    await tester.pump();
    await tester.pump();

    expect(currentLevelLabel(tester), endsWith('3'));
  });

  testWidgets('target display grows on roomy layouts', (tester) async {
    final audioService = RecordingAudioService();
    await tester.binding.setSurfaceSize(const Size(768, 1024));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpLetterMatchingScreen(tester, audioService: audioService);

    expect(
      tester
          .getSize(find.byKey(const ValueKey('letter-matching-target-display')))
          .width,
      greaterThan(GameDimensions.targetSize),
    );
  });

  testWidgets('level selector stays pinned to the top right', (tester) async {
    final audioService = RecordingAudioService();
    await tester.binding.setSurfaceSize(const Size(900, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await pumpLetterMatchingScreen(
      tester,
      audioService: audioService,
      prefs: const {'highest_level': 1},
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
    'completing the alphabet shows the gold coin and unlocks level 2',
    (tester) async {
      final audioService = RecordingAudioService();
      final letterRepository = LetterRepository();
      final gameState = FindLetterState(letterRepository: letterRepository);

      await pumpLetterMatchingScreen(
        tester,
        audioService: audioService,
        letterRepository: letterRepository,
        gameState: gameState,
      );

      for (var i = 0; i < letterRepository.letters.length; i++) {
        gameState.selectLetter(gameState.targetLetter);

        if (i < letterRepository.letters.length - 1) {
          gameState.nextRound();
        }

        await tester.pump();
      }

      // Dance plays for 4 seconds before gold coin appears.
      await tester.pump(const Duration(seconds: 4));

      expect(find.text('GRATULERER!'), findsOneWidget);
      expect(find.textContaining('Niv'), findsNothing);

      await tester.pump(GameTimings.goldCoinRevealDelay);
      await tester.tapAt(tester.getCenter(find.byType(Scaffold)));
      await tester.pump();
      await tester.pump();

      expect(currentLevelLabel(tester), endsWith('2'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('highest_level'), 1);

      gameState.dispose();
    },
  );

  testWidgets(
    'gold coin celebration still plays if shown before initialization completes',
    (tester) async {
      final audioService = RecordingAudioService();
      final gameAudio = RecordingGameAudio();

      await pumpLetterMatchingScreen(
        tester,
        audioService: audioService,
        gameState: InitGoldCoinState(letterRepository: LetterRepository()),
        gameAudio: gameAudio,
      );

      expect(gameAudio.celebrationCalls, 1);
      await tester.pump(GameTimings.goldCoinRevealDelay);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );

  testWidgets('level 2 keeps the letter visible for 1 second before fading', (
    tester,
  ) async {
    final audioService = RecordingAudioService();
    final letterRepository = LetterRepository();
    final gameState = FindLetterState(letterRepository: letterRepository);

    await pumpLetterMatchingScreen(
      tester,
      audioService: audioService,
      letterRepository: letterRepository,
      gameState: gameState,
      prefs: const {'highest_level': 1},
    );

    expect(gameState.level, FindLetterState.fadeToAudioLevel);

    expect(targetLetterOpacity(tester), 1);
    expect(targetAudioOpacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 900));
    expect(targetLetterOpacity(tester), 1);
    expect(targetAudioOpacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 600));
    expect(targetLetterOpacity(tester), lessThan(1));
    expect(targetLetterOpacity(tester), greaterThan(0));
    expect(targetAudioOpacity(tester), greaterThan(0));
    expect(targetAudioOpacity(tester), lessThan(1));

    gameState.dispose();
  });

  testWidgets('level 3 target is speaker-only with no visible letter', (
    tester,
  ) async {
    final audioService = RecordingAudioService();
    final letterRepository = LetterRepository();
    final gameState = FindLetterState(letterRepository: letterRepository);

    await pumpLetterMatchingScreen(
      tester,
      audioService: audioService,
      letterRepository: letterRepository,
      gameState: gameState,
      prefs: const {'highest_level': 2},
    );

    expect(gameState.level, FindLetterState.audioOnlyLevel);
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('letter-matching-target-letter-layer')),
          )
          .opacity,
      0,
    );
    expect(
      tester
          .widget<Opacity>(
            find.byKey(const ValueKey('letter-matching-target-audio-layer')),
          )
          .opacity,
      1,
    );

    gameState.dispose();
  });
}

Future<void> pumpLetterMatchingScreen(
  WidgetTester tester, {
  required RecordingAudioService audioService,
  LetterRepository? letterRepository,
  FindLetterState? gameState,
  GameAudio? gameAudio,
  Map<String, Object> prefs = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefs);

  await tester.pumpWidget(
    MaterialApp(
      home: LetterMatchingScreen(
        letterRepository: letterRepository ?? LetterRepository(),
        audioService: audioService,
        gameState: gameState,
        gameAudio: gameAudio ?? SilentGameAudio(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

String currentLevelLabel(WidgetTester tester) {
  return tester
      .widget<Text>(
        find.descendant(
          of: find.byKey(const ValueKey('game-level-switcher')),
          matching: find.byType(Text),
        ),
      )
      .data!;
}

double targetLetterOpacity(WidgetTester tester) {
  return tester
      .widget<Opacity>(
        find.byKey(const ValueKey('letter-matching-target-letter-layer')),
      )
      .opacity;
}

double targetAudioOpacity(WidgetTester tester) {
  return tester
      .widget<Opacity>(
        find.byKey(const ValueKey('letter-matching-target-audio-layer')),
      )
      .opacity;
}

class RecordingAudioService extends AudioService {
  final playedAssets = <String>[];

  @override
  Future<void> playLetterSound(String assetPath) async {
    playedAssets.add(assetPath);
  }

  @override
  Future<void> dispose() async {}
}

class SilentGameAudio extends GameAudio {
  @override
  Future<void> playPop() async {}

  @override
  Future<void> playSuccess() async {}

  @override
  Future<void> playCelebration() async {}

  @override
  Future<void> playWrong() async {}

  @override
  Future<void> dispose() async {}
}

class RecordingGameAudio extends SilentGameAudio {
  int celebrationCalls = 0;

  @override
  Future<void> playCelebration() async {
    celebrationCalls++;
  }
}

class InitGoldCoinState extends FindLetterState {
  InitGoldCoinState({required super.letterRepository});

  bool _showGoldCoinOverride = false;

  @override
  bool get showGoldCoin => _showGoldCoinOverride;

  @override
  Future<void> loadProgress() async {
    _showGoldCoinOverride = true;
    notifyListeners();
  }

  @override
  void resetGame() {
    notifyListeners();
  }
}
