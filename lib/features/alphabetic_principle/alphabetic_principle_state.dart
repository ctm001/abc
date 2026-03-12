import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/repositories/letter_repository.dart';
import 'alphabetic_word.dart';

class AlphabeticChoice {
  const AlphabeticChoice({
    required this.id,
    required this.letter,
    required this.paletteIndex,
  });

  final String id;
  final String letter;
  final int paletteIndex;
}

class AlphabeticPrincipleState extends ChangeNotifier {
  AlphabeticPrincipleState({
    required LetterRepository letterRepository,
    List<AlphabeticWord> words = alphabeticPrincipleWords,
    Random? random,
  }) : _letterRepository = letterRepository,
       _words = List<AlphabeticWord>.unmodifiable(words),
       _random = random ?? Random();

  static const autoAdvanceDelay = Duration(milliseconds: 950);
  static const wrongAnswerReset = Duration(milliseconds: 450);

  final LetterRepository _letterRepository;
  final List<AlphabeticWord> _words;
  final Random _random;

  Timer? _advanceTimer;
  Timer? _wrongAnswerTimer;

  int _level = 0;
  int _audioCueToken = 0;
  int _celebrationToken = 0;
  int _missingIndex = 0;
  bool _showSuccess = false;
  String? _wrongChoiceId;
  List<String?> _slots = const [];
  List<AlphabeticChoice> _choices = const [];
  List<int> _roundOrder = const [];
  int _roundPosition = 0;

  int get level => _level;
  int get highestLevel => 2;
  int get audioCueToken => _audioCueToken;
  int get celebrationToken => _celebrationToken;
  bool get showSuccess => _showSuccess;
  bool get isBuildWordLevel => _level == 2;
  int get missingIndex => _missingIndex;
  String? get wrongChoiceId => _wrongChoiceId;
  AlphabeticWord get currentWord => _words[_currentWordIndex];
  List<String?> get slots => List<String?>.unmodifiable(_slots);
  List<AlphabeticChoice> get choices =>
      List<AlphabeticChoice>.unmodifiable(_choices);

  String get titleText => switch (_level) {
    0 => 'Finn første bokstav!',
    1 => 'Finn bokstaven som mangler!',
    _ => 'Stav ordet!',
  };

  int get activeSlotIndex => _slots.indexOf(null);

  void start() {
    _prepareRound(resetRoundIndex: true);
  }

  void playLevel(int level) {
    final normalizedLevel = level.clamp(0, highestLevel);
    if (_level == normalizedLevel) {
      return;
    }

    _level = normalizedLevel;
    _prepareRound(resetRoundIndex: true);
  }

  void replayPrompt() {
    _audioCueToken++;
    notifyListeners();
  }

  void finishBuildWordCelebration(int token) {
    if (!_showSuccess || !isBuildWordLevel || _celebrationToken != token) {
      return;
    }
    nextRound();
  }

  bool selectChoice(AlphabeticChoice choice) {
    if (_showSuccess) {
      return false;
    }

    if (isBuildWordLevel) {
      return _selectBuildWordChoice(choice);
    }

    final correctLetter = currentWord.letters[_missingIndex];
    if (choice.letter != correctLetter) {
      _markWrongChoice(choice.id);
      return false;
    }

    _slots = List<String?>.from(_slots)..[_missingIndex] = correctLetter;
    _completeRound();
    return true;
  }

  void nextRound() {
    if (_words.isEmpty) {
      return;
    }

    _advanceRound();
    _prepareRound();
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _wrongAnswerTimer?.cancel();
    super.dispose();
  }

  bool _selectBuildWordChoice(AlphabeticChoice choice) {
    final targetIndex = activeSlotIndex;
    if (targetIndex == -1) {
      return false;
    }

    final expectedLetter = currentWord.letters[targetIndex];
    if (choice.letter != expectedLetter) {
      _markWrongChoice(choice.id);
      return false;
    }

    final updatedSlots = List<String?>.from(_slots)
      ..[targetIndex] = choice.letter;
    _slots = updatedSlots;
    _choices = _choices
        .where((item) => item.id != choice.id)
        .toList(growable: false);
    _clearWrongChoice();

    if (!_slots.contains(null)) {
      _completeRound();
      return true;
    }

    notifyListeners();
    return true;
  }

  void _prepareRound({bool resetRoundIndex = false}) {
    _advanceTimer?.cancel();
    _wrongAnswerTimer?.cancel();
    _showSuccess = false;
    _wrongChoiceId = null;

    if (_words.isEmpty) {
      _slots = const [];
      _choices = const [];
      notifyListeners();
      return;
    }

    if (resetRoundIndex || _roundOrder.isEmpty) {
      _resetRoundOrder();
    } else {
      _roundPosition %= _roundOrder.length;
    }

    final letters = currentWord.letters;

    switch (_level) {
      case 0:
        _missingIndex = 0;
        _slots = List<String?>.from(letters)..[_missingIndex] = null;
        _choices = _buildChoiceSet(
          correctLetter: letters[_missingIndex],
          excludedLetters: letters.toSet(),
        );
        break;
      case 1:
        _missingIndex = _random.nextInt(letters.length);
        _slots = List<String?>.from(letters)..[_missingIndex] = null;
        _choices = _buildChoiceSet(
          correctLetter: letters[_missingIndex],
          excludedLetters: {letters[_missingIndex]},
        );
        break;
      case 2:
        _missingIndex = 0;
        _slots = List<String?>.filled(letters.length, null);
        _choices = _buildWordChoices(letters);
        break;
    }

    _audioCueToken++;
    notifyListeners();
  }

  List<AlphabeticChoice> _buildChoiceSet({
    required String correctLetter,
    required Set<String> excludedLetters,
  }) {
    final pool = _letterRepository.letters
        .map((letter) => letter.character)
        .where((character) => !excludedLetters.contains(character))
        .toList(growable: false);
    pool.shuffle(_random);

    final letters = <String>[correctLetter, ...pool.take(3)];
    letters.shuffle(_random);

    return List<AlphabeticChoice>.generate(
      letters.length,
      (index) => AlphabeticChoice(
        id: 'choice-$index-${letters[index]}',
        letter: letters[index],
        paletteIndex: index,
      ),
      growable: false,
    );
  }

  List<AlphabeticChoice> _buildWordChoices(List<String> letters) {
    final shuffledLetters = List<String>.from(letters)..shuffle(_random);
    return List<AlphabeticChoice>.generate(
      shuffledLetters.length,
      (index) => AlphabeticChoice(
        id: 'word-$index-${shuffledLetters[index]}',
        letter: shuffledLetters[index],
        paletteIndex: index,
      ),
      growable: false,
    );
  }

  int get _currentWordIndex {
    if (_roundOrder.isNotEmpty) {
      return _roundOrder[_roundPosition];
    }
    return 0;
  }

  void _resetRoundOrder() {
    _roundOrder = _shuffledRoundOrder();
    _roundPosition = 0;
  }

  void _advanceRound() {
    if (_roundOrder.isEmpty) {
      _resetRoundOrder();
      return;
    }

    final previousWordIndex = _roundOrder[_roundPosition];
    _roundPosition++;
    if (_roundPosition < _roundOrder.length) {
      return;
    }

    _roundOrder = _shuffledRoundOrder(avoidFirstIndex: previousWordIndex);
    _roundPosition = 0;
  }

  List<int> _shuffledRoundOrder({int? avoidFirstIndex}) {
    final order = List<int>.generate(_words.length, (index) => index);
    order.shuffle(_random);

    if (avoidFirstIndex != null &&
        order.length > 1 &&
        order.first == avoidFirstIndex) {
      final swapIndex = 1 + _random.nextInt(order.length - 1);
      final first = order.first;
      order[0] = order[swapIndex];
      order[swapIndex] = first;
    }

    return List<int>.unmodifiable(order);
  }

  void _completeRound() {
    _advanceTimer?.cancel();
    _showSuccess = true;
    _clearWrongChoice();
    if (isBuildWordLevel) {
      _celebrationToken++;
      notifyListeners();
      return;
    }
    notifyListeners();
    _advanceTimer = Timer(autoAdvanceDelay, nextRound);
  }

  void _markWrongChoice(String choiceId) {
    _wrongAnswerTimer?.cancel();
    _wrongChoiceId = choiceId;
    notifyListeners();
    _wrongAnswerTimer = Timer(wrongAnswerReset, _clearWrongChoice);
  }

  void _clearWrongChoice() {
    if (_wrongChoiceId == null) {
      return;
    }
    _wrongChoiceId = null;
    notifyListeners();
  }
}
