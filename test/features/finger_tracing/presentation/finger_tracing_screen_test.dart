import 'package:abc2/core/audio/audio_service.dart';
import 'package:abc2/data/repositories/letter_repository.dart';
import 'package:abc2/features/finger_tracing/finger_tracing_audio.dart';
import 'package:abc2/features/finger_tracing/finger_tracing_guides.dart';
import 'package:abc2/features/finger_tracing/finger_tracing_state.dart';
import 'package:abc2/features/finger_tracing/presentation/finger_tracing_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  testWidgets('headline is shown and centered in the header', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = LetterRepository();
    final a = repository.getByCharacter('A');
    final audioService = RecordingAudioService();
    final gameState = FingerTracingState(
      letterRepository: repository,
      letterSequence: [a],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FingerTracingScreen(
          letterRepository: repository,
          audioService: audioService,
          gameState: gameState,
          gameAudio: RecordingFingerTracingAudio(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final headline = find.text('Spor bokstavene!');
    expect(headline, findsOneWidget);

    final screenCenterX = tester.getRect(find.byType(Scaffold)).center.dx;
    final headlineCenterX = tester.getCenter(headline).dx;
    expect(headlineCenterX, closeTo(screenCenterX, 0.001));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    gameState.dispose();
  });

  testWidgets('tracing board stays square on non-square layouts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1280));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = LetterRepository();
    final a = repository.getByCharacter('A');
    final audioService = RecordingAudioService();
    final gameState = FingerTracingState(
      letterRepository: repository,
      letterSequence: [a],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FingerTracingScreen(
          letterRepository: repository,
          audioService: audioService,
          gameState: gameState,
          gameAudio: RecordingFingerTracingAudio(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final boardSize = tester.getSize(
      find.byKey(const ValueKey('finger-tracing-board')),
    );
    expect(boardSize.width, closeTo(boardSize.height, 0.001));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    gameState.dispose();
  });

  testWidgets('scribbling off path does not complete the letter', (
    tester,
  ) async {
    final repository = LetterRepository();
    final a = repository.getByCharacter('A');
    final audioService = RecordingAudioService();
    final gameState = FingerTracingState(
      letterRepository: repository,
      letterSequence: [a],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FingerTracingScreen(
          letterRepository: repository,
          audioService: audioService,
          gameState: gameState,
          gameAudio: RecordingFingerTracingAudio(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final board = find.byKey(const ValueKey('finger-tracing-board'));
    final topLeft = tester.getTopLeft(board);
    final size = tester.getSize(board);
    final layout = FingerTracingGuides.layoutFor('A', size);

    final gesture = await tester.startGesture(
      topLeft + layout.strokes.first.startDot,
    );
    await tester.pump();
    await gesture.moveTo(
      topLeft + Offset(size.width * 0.88, size.height * 0.18),
    );
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveTo(
      topLeft + Offset(size.width * 0.80, size.height * 0.76),
    );
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveTo(
      topLeft + Offset(size.width * 0.18, size.height * 0.74),
    );
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await tester.pump();

    expect(gameState.coverage, 0);
    expect(gameState.showSuccess, isFalse);
    expect(
      find.byKey(const ValueKey('finger-tracing-success-letter')),
      findsNothing,
    );
    final painter = tester.widget<CustomPaint>(board).painter as dynamic;
    expect(painter.hasCurrentStroke, isFalse);
    expect(painter.strokes, isEmpty);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    gameState.dispose();
  });

  testWidgets('following the guide paths completes the current letter', (
    tester,
  ) async {
    final repository = LetterRepository();
    final a = repository.getByCharacter('A');
    final audioService = RecordingAudioService();
    final gameState = FingerTracingState(
      letterRepository: repository,
      letterSequence: [a],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FingerTracingScreen(
          letterRepository: repository,
          audioService: audioService,
          gameState: gameState,
          gameAudio: RecordingFingerTracingAudio(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final board = find.byKey(const ValueKey('finger-tracing-board'));
    final topLeft = tester.getTopLeft(board);
    final size = tester.getSize(board);
    final layout = FingerTracingGuides.layoutFor('A', size);

    for (final stroke in layout.strokes) {
      final gesture = await tester.startGesture(topLeft + stroke.startDot);
      await tester.pump();
      for (final sample in stroke.samples.skip(1)) {
        await gesture.moveTo(topLeft + sample);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump();
    }

    expect(gameState.showSuccess, isTrue);
    expect(gameState.coverage, greaterThanOrEqualTo(0.85));
    expect(
      find.byKey(const ValueKey('finger-tracing-success-letter')),
      findsOneWidget,
    );
    final successLetter = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('finger-tracing-success-letter')),
        matching: find.byType(Text),
      ),
    );
    expect(successLetter.style?.fontFamily, GoogleFonts.aBeeZee().fontFamily);

    await tester.pump(FingerTracingState.nextLetterDelay);
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    gameState.dispose();
  });

  testWidgets('success overlay renders Å with a detached ring', (tester) async {
    final repository = LetterRepository();
    final aa = repository.getByCharacter('Å');
    final audioService = RecordingAudioService();
    final gameState = FingerTracingState(
      letterRepository: repository,
      letterSequence: [aa],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FingerTracingScreen(
          letterRepository: repository,
          audioService: audioService,
          gameState: gameState,
          gameAudio: RecordingFingerTracingAudio(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    gameState.updateCoverage(0.9, reachedFinalCheckpoint: true);
    await tester.pump();

    expect(
      find.byKey(const ValueKey('finger-tracing-success-letter')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('finger-tracing-success-letter-ring')),
      findsOneWidget,
    );

    final successBody = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('finger-tracing-success-letter')),
        matching: find.text('A'),
      ),
    );
    expect(successBody.style?.fontFamily, GoogleFonts.aBeeZee().fontFamily);

    await tester.pump(FingerTracingState.nextLetterDelay);
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    gameState.dispose();
  });

  testWidgets(
    'stopping just outside the final dot rewinds by five guide dots',
    (tester) async {
      final repository = LetterRepository();
      final c = repository.getByCharacter('C');
      final audioService = RecordingAudioService();
      final gameState = FingerTracingState(
        letterRepository: repository,
        letterSequence: [c],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FingerTracingScreen(
            letterRepository: repository,
            audioService: audioService,
            gameState: gameState,
            gameAudio: RecordingFingerTracingAudio(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final board = find.byKey(const ValueKey('finger-tracing-board'));
      final topLeft = tester.getTopLeft(board);
      final size = tester.getSize(board);
      final layout = FingerTracingGuides.layoutFor('C', size);
      final stroke = layout.strokes.single;
      expect(stroke.checkpoints.length, greaterThan(6));
      final previousCheckpoint =
          stroke.checkpoints[stroke.checkpoints.length - 2];
      final lastCheckpoint = stroke.checkpoints.last;
      final direction = lastCheckpoint - previousCheckpoint;
      final directionLength = direction.distance;
      final unitDirection = Offset(
        direction.dx / directionLength,
        direction.dy / directionLength,
      );
      final almostFinalPoint =
          lastCheckpoint - (unitDirection * (layout.hitRadius + 1));

      final gesture = await tester.startGesture(topLeft + stroke.startDot);
      await tester.pump();
      for (final checkpoint
          in stroke.checkpoints.skip(1).take(stroke.checkpoints.length - 2)) {
        await gesture.moveTo(topLeft + checkpoint);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.moveTo(topLeft + almostFinalPoint);
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.up();
      await tester.pump();

      expect(
        gameState.coverage,
        closeTo(
          (stroke.checkpoints.length - 6) / layout.checkpoints.length,
          0.001,
        ),
      );
      expect(gameState.showSuccess, isFalse);
      expect(
        find.byKey(const ValueKey('finger-tracing-success-letter')),
        findsNothing,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      gameState.dispose();
    },
  );

  testWidgets('straying off path late in a stroke rewinds by five guide dots', (
    tester,
  ) async {
    final repository = LetterRepository();
    final c = repository.getByCharacter('C');
    final audioService = RecordingAudioService();
    final gameState = FingerTracingState(
      letterRepository: repository,
      letterSequence: [c],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FingerTracingScreen(
          letterRepository: repository,
          audioService: audioService,
          gameState: gameState,
          gameAudio: RecordingFingerTracingAudio(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final board = find.byKey(const ValueKey('finger-tracing-board'));
    final topLeft = tester.getTopLeft(board);
    final size = tester.getSize(board);
    final layout = FingerTracingGuides.layoutFor('C', size);
    final stroke = layout.strokes.single;

    expect(stroke.checkpoints.length, greaterThan(10));

    final gesture = await tester.startGesture(topLeft + stroke.startDot);
    await tester.pump();
    const traversedDotCount = 10;
    for (final checkpoint in stroke.checkpoints.skip(1).take(9)) {
      await gesture.moveTo(topLeft + checkpoint);
      await tester.pump(const Duration(milliseconds: 16));
    }

    final coverageBeforeStray = gameState.coverage;
    expect(
      coverageBeforeStray,
      closeTo(traversedDotCount / layout.checkpoints.length, 0.001),
    );

    await gesture.moveTo(
      topLeft + Offset(size.width * 0.10, size.height * 0.12),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      gameState.coverage,
      closeTo((traversedDotCount - 5) / layout.checkpoints.length, 0.001),
    );
    expect(gameState.showSuccess, isFalse);

    await gesture.moveTo(
      topLeft + Offset(size.width * 0.90, size.height * 0.90),
    );
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      gameState.coverage,
      closeTo((traversedDotCount - 5) / layout.checkpoints.length, 0.001),
    );

    await gesture.up();
    await tester.pump();

    expect(
      gameState.coverage,
      closeTo((traversedDotCount - 5) / layout.checkpoints.length, 0.001),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    gameState.dispose();
  });

  testWidgets(
    'lifting finger mid stroke rewinds five guide dots and allows resume',
    (tester) async {
      final repository = LetterRepository();
      final c = repository.getByCharacter('C');
      final audioService = RecordingAudioService();
      final gameState = FingerTracingState(
        letterRepository: repository,
        letterSequence: [c],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FingerTracingScreen(
            letterRepository: repository,
            audioService: audioService,
            gameState: gameState,
            gameAudio: RecordingFingerTracingAudio(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final board = find.byKey(const ValueKey('finger-tracing-board'));
      final topLeft = tester.getTopLeft(board);
      final size = tester.getSize(board);
      final layout = FingerTracingGuides.layoutFor('C', size);
      final stroke = layout.strokes.single;

      expect(stroke.checkpoints.length, greaterThan(10));

      final gesture = await tester.startGesture(topLeft + stroke.startDot);
      await tester.pump();
      const traversedDotCount = 10;
      for (final checkpoint in stroke.checkpoints.skip(1).take(9)) {
        await gesture.moveTo(topLeft + checkpoint);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump();

      expect(
        gameState.coverage,
        closeTo((traversedDotCount - 5) / layout.checkpoints.length, 0.001),
      );
      expect(gameState.showSuccess, isFalse);

      final resumeGesture = await tester.startGesture(
        topLeft + stroke.checkpoints[4],
      );
      await tester.pump();
      for (final checkpoint in stroke.checkpoints.skip(5)) {
        await resumeGesture.moveTo(topLeft + checkpoint);
        await tester.pump(const Duration(milliseconds: 16));
      }
      await resumeGesture.up();
      await tester.pump();

      expect(gameState.showSuccess, isTrue);
      expect(gameState.coverage, greaterThanOrEqualTo(0.85));

      await tester.pump(FingerTracingState.nextLetterDelay);
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      gameState.dispose();
    },
  );

  testWidgets(
    'screen does not celebrate until the final checkpoint is reached',
    (tester) async {
      final repository = LetterRepository();
      final a = repository.getByCharacter('A');
      final audioService = RecordingAudioService();
      final gameAudio = RecordingFingerTracingAudio();
      final gameState = FingerTracingState(
        letterRepository: repository,
        letterSequence: [a],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FingerTracingScreen(
            letterRepository: repository,
            audioService: audioService,
            gameState: gameState,
            gameAudio: gameAudio,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      gameState.updateCoverage(0.9);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('finger-tracing-success-letter')),
        findsNothing,
      );
      expect(gameState.showSuccess, isFalse);
      expect(gameAudio.celebrationCalls, 0);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      gameState.dispose();
    },
  );

  testWidgets(
    'screen plays prompt, celebrates success, and advances to the next letter',
    (tester) async {
      final repository = LetterRepository();
      final a = repository.getByCharacter('A');
      final b = repository.getByCharacter('B');
      final audioService = RecordingAudioService();
      final gameAudio = RecordingFingerTracingAudio();
      final gameState = FingerTracingState(
        letterRepository: repository,
        letterSequence: [a, b],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: FingerTracingScreen(
            letterRepository: repository,
            audioService: audioService,
            gameState: gameState,
            gameAudio: gameAudio,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(audioService.playedAssets, [a.soundAssetPath]);

      gameState.updateCoverage(0.9, reachedFinalCheckpoint: true);
      await tester.pump();

      expect(
        find.byKey(const ValueKey('finger-tracing-success-letter')),
        findsOneWidget,
      );
      expect(gameAudio.celebrationCalls, 1);

      await tester.pump(
        FingerTracingState.replayPromptDelay -
            const Duration(milliseconds: 120),
      );
      await tester.pump();
      expect(audioService.playedAssets, [a.soundAssetPath]);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      expect(audioService.playedAssets, [a.soundAssetPath, a.soundAssetPath]);

      await tester.pump(
        FingerTracingState.nextLetterDelay -
            FingerTracingState.replayPromptDelay -
            const Duration(milliseconds: 120),
      );
      expect(
        find.byKey(const ValueKey('finger-tracing-success-letter')),
        findsOneWidget,
      );
      expect(gameState.currentLetter, a);

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('finger-tracing-success-letter')),
        findsNothing,
      );
      expect(audioService.playedAssets.last, b.soundAssetPath);
      expect(gameState.currentLetter, b);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      gameState.dispose();
    },
  );

  testWidgets('audio button replays the current letter prompt', (tester) async {
    final repository = LetterRepository();
    final a = repository.getByCharacter('A');
    final audioService = RecordingAudioService();
    final gameState = FingerTracingState(
      letterRepository: repository,
      letterSequence: [a],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FingerTracingScreen(
          letterRepository: repository,
          audioService: audioService,
          gameState: gameState,
          gameAudio: RecordingFingerTracingAudio(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(audioService.playedAssets, [a.soundAssetPath]);

    await tester.tap(find.byKey(const ValueKey('finger-tracing-audio-button')));
    await tester.pump();
    await tester.pump();

    expect(audioService.playedAssets, [a.soundAssetPath, a.soundAssetPath]);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    gameState.dispose();
  });
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

class RecordingFingerTracingAudio extends FingerTracingAudio {
  int celebrationCalls = 0;

  @override
  Future<void> playCelebration() async {
    celebrationCalls++;
  }

  @override
  Future<void> dispose() async {}
}
