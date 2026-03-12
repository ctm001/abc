import 'dart:math';

import 'package:abc2/data/repositories/letter_repository.dart';
import 'package:abc2/features/alphabetic_principle/alphabetic_principle_state.dart';
import 'package:abc2/features/alphabetic_principle/alphabetic_word.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlphabeticPrincipleState', () {
    test('level 1 hides the first letter and offers four choices', () {
      final state = AlphabeticPrincipleState(
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
      addTearDown(state.dispose);

      state.start();

      expect(state.level, 0);
      expect(state.slots, equals([null, 'A', 'T', 'T']));
      expect(state.choices, hasLength(4));
      expect(state.choices.map((choice) => choice.letter), contains('K'));
    });

    test('level 2 hides exactly one random letter', () {
      final state = AlphabeticPrincipleState(
        letterRepository: LetterRepository(),
        words: const [
          AlphabeticWord(
            word: 'ball',
            emoji: '⚽',
            audioAssetPath: 'assets/audio/words/ball.mp3',
          ),
        ],
        random: Random(4),
      );
      addTearDown(state.dispose);

      state.start();
      state.playLevel(1);

      expect(state.level, 1);
      expect(state.slots.where((slot) => slot == null), hasLength(1));
      expect(state.choices, hasLength(4));
    });

    test(
      'level 3 uses one choice per letter and completes the word in order',
      () {
        final state = AlphabeticPrincipleState(
          letterRepository: LetterRepository(),
          words: const [
            AlphabeticWord(
              word: 'ball',
              emoji: '⚽',
              audioAssetPath: 'assets/audio/words/ball.mp3',
            ),
          ],
          random: Random(0),
        );
        addTearDown(state.dispose);

        state.start();
        state.playLevel(2);

        expect(state.level, 2);
        expect(state.slots, equals([null, null, null, null]));
        expect(state.choices, hasLength(4));

        expect(state.selectChoice(_choiceFor(state, 'B')), isTrue);
        expect(state.selectChoice(_choiceFor(state, 'A')), isTrue);
        expect(state.selectChoice(_choiceFor(state, 'L')), isTrue);
        expect(state.selectChoice(_choiceFor(state, 'L')), isTrue);

        expect(state.showSuccess, isTrue);
        expect(state.slots, equals(['B', 'A', 'L', 'L']));
        expect(state.choices, isEmpty);
      },
    );
  });
}

AlphabeticChoice _choiceFor(AlphabeticPrincipleState state, String letter) {
  return state.choices.firstWhere((choice) => choice.letter == letter);
}
