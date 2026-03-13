import 'package:abc2/data/repositories/letter_repository.dart';
import 'package:abc2/features/letter_matching/find_letter_state.dart';
import 'package:abc2/features/letter_matching/game_colors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  FindLetterState createState() {
    return FindLetterState(letterRepository: LetterRepository());
  }

  test('startNewRound creates 4 unique choices with the target', () {
    final state = createState();

    state.startNewRound();

    expect(state.roundNumber, 1);
    expect(state.choices, hasLength(4));
    expect(state.choices, contains(state.targetLetter));
    expect(state.choices.map((letter) => letter.index).toSet(), hasLength(4));

    state.dispose();
  });

  test('loadProgress clamps saved levels to the supported range', () async {
    SharedPreferences.setMockInitialValues({'highest_level': 3});
    final state = createState();

    await state.loadProgress();
    final prefs = await SharedPreferences.getInstance();
    expect(state.level, FindLetterState.maxLevel);
    expect(state.highestLevel, FindLetterState.maxLevel);
    expect(prefs.getInt('highest_level'), FindLetterState.maxLevel);

    state.dispose();
  });

  test(
    'dismissGoldCoin unlocks one level at a time up to speaker-only',
    () async {
      final state = createState();

      state.playLevel(FindLetterState.visibleLevel);
      state.dismissGoldCoin();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(state.level, FindLetterState.fadeToAudioLevel);
      expect(state.highestLevel, FindLetterState.fadeToAudioLevel);

      state.dismissGoldCoin();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(state.level, FindLetterState.audioOnlyLevel);
      expect(state.highestLevel, FindLetterState.audioOnlyLevel);

      state.dismissGoldCoin();
      await Future<void>.delayed(const Duration(milliseconds: 10));

      final prefs = await SharedPreferences.getInstance();
      expect(state.level, FindLetterState.audioOnlyLevel);
      expect(state.highestLevel, FindLetterState.audioOnlyLevel);
      expect(prefs.getInt('highest_level'), FindLetterState.audioOnlyLevel);

      state.dispose();
    },
  );

  test('crumble reset does not run after dispose', () async {
    final state = createState();

    state.startNewRound();
    state.selectLetter(state.targetLetter);
    final wrongChoice = state.choices.firstWhere(
      (choice) => choice != state.targetLetter,
    );

    state.selectLetter(wrongChoice);
    state.dispose();

    await Future<void>.delayed(
      GameTimings.stackCrumbleDuration(1) + const Duration(milliseconds: 100),
    );

    expect(true, isTrue);
  });

  test('extra taps during stack crumble are ignored', () async {
    final state = createState();

    state.startNewRound();
    state.selectLetter(state.targetLetter);
    state.nextRound();

    final wrongChoice = state.choices.firstWhere(
      (choice) => choice != state.targetLetter,
    );

    state.selectLetter(wrongChoice);
    final scoreBeforeExtraTap = state.score;
    final stackBeforeExtraTap = List.of(state.letterStack);

    expect(state.stackCrumbling, isTrue);
    expect(state.canSelectChoices, isFalse);
    expect(state.selectLetter(state.targetLetter), isFalse);
    expect(state.score, scoreBeforeExtraTap);
    expect(state.letterStack, stackBeforeExtraTap);

    state.dispose();
  });

  test('playLevel cancels a pending stack crumble reset', () async {
    final state = createState();

    state.startNewRound();
    state.selectLetter(state.targetLetter);
    state.nextRound();

    final wrongChoice = state.choices.firstWhere(
      (choice) => choice != state.targetLetter,
    );

    state.selectLetter(wrongChoice);
    state.playLevel(FindLetterState.visibleLevel);
    final roundAfterLevelChange = state.roundNumber;
    final targetAfterLevelChange = state.targetLetter;

    await Future<void>.delayed(
      GameTimings.stackCrumbleDuration(1) + const Duration(milliseconds: 100),
    );

    expect(state.roundNumber, roundAfterLevelChange);
    expect(state.targetLetter, targetAfterLevelChange);
    expect(state.stackCrumbling, isFalse);

    state.dispose();
  });

  test('loadProgress returns cleanly after dispose', () async {
    SharedPreferences.setMockInitialValues({'highest_level': 2});
    final state = createState();

    final future = state.loadProgress();
    state.dispose();
    await future;

    expect(true, isTrue);
  });
}
