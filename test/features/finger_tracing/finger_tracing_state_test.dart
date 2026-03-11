import 'package:abc2/data/repositories/letter_repository.dart';
import 'package:abc2/features/finger_tracing/finger_tracing_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'starting with the default random deck initializes a current letter',
    () {
      final state = FingerTracingState(letterRepository: LetterRepository());

      state.start();

      expect(state.audioCueToken, 1);
      expect(state.currentLetter.character, isNotEmpty);

      state.dispose();
    },
  );

  test('coverage threshold alone does not complete tracing', () {
    final state = FingerTracingState(letterRepository: LetterRepository());

    state.start();
    state.updateCoverage(0.9);

    expect(state.showSuccess, isFalse);
    expect(state.celebrationToken, 0);

    state.dispose();
  });

  test(
    'completing tracing after the final checkpoint replays the prompt and advances to the next letter',
    () async {
      final repository = LetterRepository();
      final a = repository.getByCharacter('A');
      final b = repository.getByCharacter('B');
      final state = FingerTracingState(
        letterRepository: repository,
        letterSequence: [a, b],
      );

      state.start();

      expect(state.currentLetter, a);
      expect(state.audioCueToken, 1);
      expect(state.showSuccess, isFalse);

      state.updateCoverage(0.84);
      expect(state.showSuccess, isFalse);

      state.updateCoverage(0.85);
      expect(state.showSuccess, isFalse);

      state.updateCoverage(0.85, reachedFinalCheckpoint: true);
      expect(state.showSuccess, isTrue);
      expect(state.celebrationToken, 1);

      await Future<void>.delayed(
        FingerTracingState.replayPromptDelay -
            const Duration(milliseconds: 120),
      );
      expect(state.audioCueToken, 1);
      expect(state.currentLetter, a);
      expect(state.showSuccess, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(state.audioCueToken, 2);
      expect(state.currentLetter, a);
      expect(state.showSuccess, isTrue);

      await Future<void>.delayed(
        FingerTracingState.nextLetterDelay -
            FingerTracingState.replayPromptDelay -
            const Duration(milliseconds: 120),
      );
      expect(state.showSuccess, isTrue);
      expect(state.currentLetter, a);
      expect(state.audioCueToken, 2);

      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(state.showSuccess, isFalse);
      expect(state.currentLetter, b);
      expect(state.audioCueToken, 3);

      state.dispose();
    },
  );
}
