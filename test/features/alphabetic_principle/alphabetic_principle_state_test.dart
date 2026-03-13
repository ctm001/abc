import 'dart:math';

import 'package:abc2/data/repositories/letter_repository.dart';
import 'package:abc2/features/alphabetic_principle/alphabetic_principle_state.dart';
import 'package:abc2/features/alphabetic_principle/alphabetic_word.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AlphabeticPrincipleState', () {
    test('default word list only contains words of four letters or fewer', () {
      expect(
        alphabeticPrincipleWords.where((word) => word.word.length > 4),
        isEmpty,
      );
    });

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

    test('level 1 shuffles words before repeating them', () {
      final state = AlphabeticPrincipleState(
        letterRepository: LetterRepository(),
        words: const [
          AlphabeticWord(
            word: 'ape',
            emoji: 'APE',
            audioAssetPath: 'assets/audio/words/ape.mp3',
          ),
          AlphabeticWord(
            word: 'bok',
            emoji: 'BOOK',
            audioAssetPath: 'assets/audio/words/bok.mp3',
          ),
          AlphabeticWord(
            word: 'sol',
            emoji: 'SUN',
            audioAssetPath: 'assets/audio/words/sol.mp3',
          ),
          AlphabeticWord(
            word: 'lam',
            emoji: 'LAMB',
            audioAssetPath: 'assets/audio/words/lam.mp3',
          ),
        ],
        random: Random(0),
      );
      addTearDown(state.dispose);

      state.start();

      final seenWords = <String>[];
      for (var round = 0; round < 4; round++) {
        seenWords.add(state.currentWord.word);
        state.nextRound();
      }

      expect(seenWords.toSet(), {'ape', 'bok', 'sol', 'lam'});
      expect(seenWords, isNot(equals(['ape', 'bok', 'sol', 'lam'])));
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

    test('level 3 shuffles words before repeating them', () {
      final state = AlphabeticPrincipleState(
        letterRepository: LetterRepository(),
        words: const [
          AlphabeticWord(
            word: 'ape',
            emoji: 'APE',
            audioAssetPath: 'assets/audio/words/ape.mp3',
          ),
          AlphabeticWord(
            word: 'bok',
            emoji: 'BOOK',
            audioAssetPath: 'assets/audio/words/bok.mp3',
          ),
          AlphabeticWord(
            word: 'sol',
            emoji: 'SUN',
            audioAssetPath: 'assets/audio/words/sol.mp3',
          ),
          AlphabeticWord(
            word: 'lam',
            emoji: 'LAMB',
            audioAssetPath: 'assets/audio/words/lam.mp3',
          ),
        ],
        random: Random(0),
      );
      addTearDown(state.dispose);

      state.start();
      state.playLevel(2);

      final seenWords = <String>[];
      for (var round = 0; round < 4; round++) {
        seenWords.add(state.currentWord.word);
        _completeCurrentBuildWord(state);
        state.finishCelebration(state.celebrationToken);
      }

      expect(seenWords.toSet(), {'ape', 'bok', 'sol', 'lam'});
      expect(seenWords, isNot(equals(['ape', 'bok', 'sol', 'lam'])));
    });

    test(
      'all levels wait for the celebration to finish before advancing',
      () async {
        for (final level in [0, 1, 2]) {
          final state = AlphabeticPrincipleState(
            letterRepository: LetterRepository(),
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
          addTearDown(state.dispose);

          state.start();
          state.playLevel(level);
          final initialWord = state.currentWord.word;
          final nextWord = [
            'katt',
            'sol',
          ].firstWhere((word) => word != initialWord);
          final audioCueTokenBeforeCelebration = state.audioCueToken;

          if (level == 2) {
            _completeCurrentBuildWord(state);
          } else {
            state.selectChoice(
              _choiceFor(state, state.currentWord.letters[state.missingIndex]),
            );
          }

          final celebrationToken = state.celebrationToken;
          expect(state.showSuccess, isTrue);
          expect(celebrationToken, 1);

          await Future<void>.delayed(const Duration(milliseconds: 1100));

          expect(state.currentWord.word, initialWord);
          expect(state.showSuccess, isTrue);
          expect(state.audioCueToken, audioCueTokenBeforeCelebration);

          state.finishCelebration(celebrationToken);

          expect(state.currentWord.word, nextWord);
          expect(state.showSuccess, isFalse);
          expect(state.audioCueToken, audioCueTokenBeforeCelebration + 1);
        }
      },
    );
  });
}

AlphabeticChoice _choiceFor(AlphabeticPrincipleState state, String letter) {
  return state.choices.firstWhere((choice) => choice.letter == letter);
}

void _completeCurrentBuildWord(AlphabeticPrincipleState state) {
  for (final letter in state.currentWord.letters) {
    state.selectChoice(_choiceFor(state, letter));
  }
}
