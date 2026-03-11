import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../data/repositories/letter_repository.dart';
import '../../domain/models/norwegian_letter.dart';

/// Controls the round flow for the finger tracing game.
class FingerTracingState extends ChangeNotifier {
  FingerTracingState({
    required LetterRepository letterRepository,
    List<NorwegianLetter>? letterSequence,
    Random? random,
  }) : _letters = List.unmodifiable(letterSequence ?? letterRepository.letters),
       _usesFixedSequence = letterSequence != null,
       _random = random ?? Random() {
    if (_letters.isEmpty) {
      throw ArgumentError('FingerTracingState requires at least one letter.');
    }
  }

  static const completionThreshold = 0.85;
  static const successRevealDuration = Duration(milliseconds: 3000);
  static const successPauseDelay = Duration(seconds: 3);
  static final replayPromptDelay = nextLetterDelay - successPauseDelay;
  static final nextLetterDelay = successPauseDelay + successRevealDuration;

  final List<NorwegianLetter> _letters;
  final bool _usesFixedSequence;
  final Random _random;
  final Queue<NorwegianLetter> _deck = Queue<NorwegianLetter>();

  bool _disposed = false;
  bool _started = false;
  int _sequenceIndex = 0;
  int _roundToken = 0;
  int _audioCueToken = 0;
  int _celebrationToken = 0;
  int _roundId = 0;
  double _coverage = 0;
  bool _reachedFinalCheckpoint = false;
  bool _showSuccess = false;
  NorwegianLetter? _currentLetter;

  NorwegianLetter get currentLetter => _currentLetter!;
  double get coverage => _coverage;
  int get coveragePercent => (_coverage * 100).round();
  bool get showSuccess => _showSuccess;
  bool get canTrace => _started && !_showSuccess;
  int get audioCueToken => _audioCueToken;
  int get celebrationToken => _celebrationToken;
  int get roundId => _roundId;

  /// Starts the first round and triggers the first prompt audio.
  void start() {
    if (_started || _disposed) {
      return;
    }
    _started = true;
    _startNextRound();
  }

  /// Updates the traced checkpoint coverage in the current round.
  void updateCoverage(double coverage, {bool reachedFinalCheckpoint = false}) {
    if (!_started || _disposed || _showSuccess) {
      return;
    }

    final nextCoverage = coverage.clamp(0.0, 1.0);
    final nextReachedFinalCheckpoint =
        _reachedFinalCheckpoint || reachedFinalCheckpoint;
    if ((nextCoverage - _coverage).abs() < 0.0001 &&
        nextReachedFinalCheckpoint == _reachedFinalCheckpoint) {
      return;
    }

    _coverage = nextCoverage;
    _reachedFinalCheckpoint = nextReachedFinalCheckpoint;
    if (_coverage >= completionThreshold && _reachedFinalCheckpoint) {
      _completeRound();
      return;
    }

    _notifyListeners();
  }

  /// Replays the current letter prompt on demand.
  void replayPrompt() {
    if (!_started || _disposed) {
      return;
    }
    _audioCueToken++;
    _notifyListeners();
  }

  void _completeRound() {
    if (_showSuccess || _disposed) {
      return;
    }

    final roundToken = _roundToken;
    _showSuccess = true;
    _coverage = 1;
    _celebrationToken++;
    _notifyListeners();

    Future<void>.delayed(replayPromptDelay, () {
      if (!_isCurrentRound(roundToken)) {
        return;
      }
      _audioCueToken++;
      _notifyListeners();
    });

    Future<void>.delayed(nextLetterDelay, () {
      if (!_isCurrentRound(roundToken)) {
        return;
      }
      _showSuccess = false;
      _startNextRound();
    });
  }

  void _startNextRound() {
    final previousLetter = _currentLetter;
    _roundToken++;
    _roundId++;
    _coverage = 0;
    _reachedFinalCheckpoint = false;
    _showSuccess = false;
    _currentLetter = _takeNextLetter(previousLetter: previousLetter);
    _audioCueToken++;
    _notifyListeners();
  }

  NorwegianLetter _takeNextLetter({NorwegianLetter? previousLetter}) {
    if (_usesFixedSequence) {
      final letter = _letters[_sequenceIndex % _letters.length];
      _sequenceIndex++;
      return letter;
    }

    if (_deck.isEmpty) {
      _refillDeck(previousLetter: previousLetter);
    }
    return _deck.removeFirst();
  }

  void _refillDeck({NorwegianLetter? previousLetter}) {
    final nextLetters = List.of(_letters)..shuffle(_random);
    if (previousLetter != null &&
        _letters.length > 1 &&
        nextLetters.first == previousLetter) {
      final swapIndex = nextLetters.indexWhere(
        (letter) => letter != previousLetter,
      );
      if (swapIndex > 0) {
        final first = nextLetters.first;
        nextLetters[0] = nextLetters[swapIndex];
        nextLetters[swapIndex] = first;
      }
    }
    _deck.addAll(nextLetters);
  }

  bool _isCurrentRound(int roundToken) =>
      !_disposed && _roundToken == roundToken;

  void _notifyListeners() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _roundToken++;
    super.dispose();
  }
}
