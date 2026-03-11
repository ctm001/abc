import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/letter_repository.dart';
import '../../domain/models/norwegian_letter.dart';
import 'game_letter.dart';
import 'game_colors.dart';

/// Game state for Find the Letter (Bokstavkobling).
class FindLetterState extends ChangeNotifier {
  FindLetterState({required LetterRepository letterRepository})
    : _letters = letterRepository.letters;

  static const int visibleLevel = 0;
  static const int questionMarkLevel = 1;
  static const int maxLevel = questionMarkLevel;

  final List<NorwegianLetter> _letters;
  final Random _random = Random();
  bool _disposed = false;
  int _pendingTransitionToken = 0;

  GameLetter _letterAt(int index) =>
      GameLetter(character: _letters[index].character, index: index);

  // -- Public state -----------------------------------------

  GameLetter _target = const GameLetter(character: 'A', index: 0);
  GameLetter get targetLetter => _target;

  List<GameLetter> _choices = [];
  List<GameLetter> get choices => _choices;

  List<GameLetter> _stack = [];
  List<GameLetter> get letterStack => _stack;

  bool _celebration = false;
  bool get showCelebration => _celebration;

  bool _wrongAnswer = false;
  bool get showWrongAnswer => _wrongAnswer;

  bool _crumbling = false;
  bool get stackCrumbling => _crumbling;

  bool _goldCoin = false;
  bool get showGoldCoin => _goldCoin;

  int _level = 0;
  int _highestLevel = 0;
  int get level => _level;
  int get highestLevel => _highestLevel;
  bool get isQuestionMarkMode => _level == questionMarkLevel;

  int _wrongIdx = -1;
  int get wrongAnswerIndex => _wrongIdx;

  int _score = 0;
  int get score => _score;

  int _round = 0;
  int get roundNumber => _round;

  int _autoplayToken = 0;
  int get autoplayToken => _autoplayToken;

  int get alphabetLength => _letters.length;
  bool get canSelectChoices =>
      !_disposed && !_celebration && !_wrongAnswer && !_crumbling && !_goldCoin;

  /// Asset path for the current target's pronunciation.
  String get targetSoundPath => _letters[_target.index].soundAssetPath;

  // -- Game logic -------------------------------------------

  int _letterIdx = 0;

  void _notifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  int _normalizeLevel(int level) {
    if (level <= visibleLevel) {
      return visibleLevel;
    }
    if (level >= maxLevel) {
      return maxLevel;
    }
    return level;
  }

  int _nextUnlockedLevel(int currentLevel) {
    if (currentLevel >= maxLevel) {
      return maxLevel;
    }
    return currentLevel + 1;
  }

  int _beginTransition() => ++_pendingTransitionToken;

  bool _isCurrentTransition(int token) =>
      !_disposed && _pendingTransitionToken == token;

  /// Start the next round in sequence.
  void startNewRound() {
    if (_disposed) return;
    _beginTransition();
    _celebration = false;
    _wrongAnswer = false;
    _wrongIdx = -1;
    _crumbling = false;
    _round++;
    _autoplayToken++;
    _target = _letterAt(_letterIdx);
    _generateChoices();
    _notifyListeners();
  }

  void _generateChoices() {
    final indices = <int>{_target.index};
    while (indices.length < 4) {
      indices.add(_random.nextInt(_letters.length));
    }
    _choices = indices.map(_letterAt).toList()..shuffle(_random);
  }

  /// Process a player's letter selection.
  ///
  /// Returns `true` when the answer is correct.
  bool selectLetter(GameLetter selected) {
    if (!canSelectChoices) {
      return false;
    }
    if (selected == _target) {
      _onCorrect(selected);
      return true;
    }
    _onWrong(selected);
    return false;
  }

  void _onCorrect(GameLetter selected) {
    _score++;
    _stack.add(selected);
    _letterIdx++;
    if (_letterIdx >= _letters.length) {
      _goldCoin = true;
    }
    _celebration = true;
    _wrongAnswer = false;
    _notifyListeners();
  }

  void _onWrong(GameLetter selected) {
    _wrongAnswer = true;
    _wrongIdx = _choices.indexOf(selected);

    if (_stack.isNotEmpty) {
      final transitionToken = _beginTransition();
      _crumbling = true;
      _notifyListeners();
      Future.delayed(GameTimings.stackCrumbleDuration(_stack.length), () {
        if (!_isCurrentTransition(transitionToken)) return;
        _stack = [];
        _crumbling = false;
        _wrongAnswer = false;
        _wrongIdx = -1;
        _letterIdx = 0;
        startNewRound();
      });
      return;
    }

    final transitionToken = _beginTransition();
    _letterIdx = 0;
    _notifyListeners();
    Future.delayed(GameTimings.wrongAnswerReset, () {
      if (!_isCurrentTransition(transitionToken)) return;
      _wrongAnswer = false;
      _wrongIdx = -1;
      _notifyListeners();
    });
  }

  /// Dismiss celebration and advance.
  void nextRound() {
    startNewRound();
  }

  /// Full reset, keeping level progress.
  void resetGame() {
    _score = 0;
    _round = 0;
    _letterIdx = 0;
    _stack = [];
    _celebration = false;
    _wrongAnswer = false;
    _crumbling = false;
    _goldCoin = false;
    _wrongIdx = -1;
    startNewRound();
  }

  /// Dismiss gold coin and unlock the next level.
  void dismissGoldCoin() {
    _goldCoin = false;
    _stack = [];
    _celebration = false;
    _letterIdx = 0;
    _level = _nextUnlockedLevel(_level);
    _highestLevel = max(_highestLevel, _level);
    _round = 0;
    _saveProgress();
    startNewRound();
  }

  /// Switch to a previously unlocked level.
  void playLevel(int lvl) {
    _level = _normalizeLevel(lvl);
    _letterIdx = 0;
    _stack = [];
    _celebration = false;
    _wrongAnswer = false;
    _goldCoin = false;
    _crumbling = false;
    _wrongIdx = -1;
    _round = 0;
    startNewRound();
  }

  // -- Persistence ------------------------------------------

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highest_level', _highestLevel);
  }

  /// Load saved level progress.
  Future<void> loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return;
    final savedHighestLevel = prefs.getInt('highest_level') ?? visibleLevel;
    _highestLevel = _normalizeLevel(savedHighestLevel);
    _level = _highestLevel;
    if (savedHighestLevel != _highestLevel) {
      await prefs.setInt('highest_level', _highestLevel);
    }
    if (_disposed) return;
    _notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
