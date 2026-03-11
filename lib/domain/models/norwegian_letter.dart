/// Represents a single letter in the Norwegian alphabet.
class NorwegianLetter {
  const NorwegianLetter({
    required this.character,
    required this.name,
    required this.soundAssetPath,
    required this.isVowel,
  });

  /// Uppercase character, e.g. 'A', 'Æ'.
  final String character;

  /// Norwegian name of the letter, e.g. 'a', 'æ'.
  final String name;

  /// Path to the audio asset, e.g. 'assets/audio/letters/a.mp3'.
  final String soundAssetPath;

  /// Whether this letter is a vowel.
  final bool isVowel;

  /// Lowercase version of [character].
  String get lowercase => character.toLowerCase();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NorwegianLetter && character == other.character;

  @override
  int get hashCode => character.hashCode;

  @override
  String toString() => 'NorwegianLetter($character)';
}
