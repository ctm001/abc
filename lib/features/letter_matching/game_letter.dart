import 'package:flutter/material.dart';

import 'game_colors.dart';

/// A letter in the matching game with an index-based colour.
class GameLetter {
  const GameLetter({required this.character, required this.index});

  final String character;
  final int index;

  /// Colour derived from the letter's alphabet position.
  Color get color =>
      GameColors.letterColors[index % GameColors.letterColors.length];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameLetter && character == other.character;

  @override
  int get hashCode => character.hashCode;

  @override
  String toString() => 'GameLetter($character)';
}
