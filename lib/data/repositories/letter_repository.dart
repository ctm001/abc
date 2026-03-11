import '../../domain/models/norwegian_letter.dart';

/// Single source of truth for the 29 Norwegian alphabet
/// letters.
class LetterRepository {
  /// All letters in alphabetical order (A – Å).
  List<NorwegianLetter> get letters => List.unmodifiable(_letters);

  /// Returns the letter matching [character] (case-insensitive).
  NorwegianLetter getByCharacter(String character) =>
      _letters.firstWhere((l) => l.character == character.toUpperCase());

  /// All vowels: A, E, I, O, U, Y, Æ, Ø, Å.
  List<NorwegianLetter> get vowels => letters.where((l) => l.isVowel).toList();

  /// All consonants.
  List<NorwegianLetter> get consonants =>
      letters.where((l) => !l.isVowel).toList();

  /// Returns a new list with the letters in random order.
  List<NorwegianLetter> getShuffled() => List.of(_letters)..shuffle();

  // ----------------------------------------------------------
  // Letter data
  // ----------------------------------------------------------

  static const _vowels = {'A', 'E', 'I', 'O', 'U', 'Y', 'Æ', 'Ø', 'Å'};

  static NorwegianLetter _letter(String char, String name, String fileName) =>
      NorwegianLetter(
        character: char,
        name: name,
        soundAssetPath: 'assets/audio/letters/$fileName.mp3',
        isVowel: _vowels.contains(char),
      );

  static final List<NorwegianLetter> _letters = [
    _letter('A', 'a', 'a'),
    _letter('B', 'be', 'b'),
    _letter('C', 'se', 'c'),
    _letter('D', 'de', 'd'),
    _letter('E', 'e', 'e'),
    _letter('F', 'eff', 'f'),
    _letter('G', 'ge', 'g'),
    _letter('H', 'hå', 'h'),
    _letter('I', 'i', 'i'),
    _letter('J', 'jod', 'j'),
    _letter('K', 'kå', 'k'),
    _letter('L', 'ell', 'l'),
    _letter('M', 'em', 'm'),
    _letter('N', 'en', 'n'),
    _letter('O', 'o', 'o'),
    _letter('P', 'pe', 'p'),
    _letter('Q', 'ku', 'q'),
    _letter('R', 'err', 'r'),
    _letter('S', 'ess', 's'),
    _letter('T', 'te', 't'),
    _letter('U', 'u', 'u'),
    _letter('V', 've', 'v'),
    _letter('W', 'dobbelt-ve', 'w'),
    _letter('X', 'eks', 'x'),
    _letter('Y', 'y', 'y'),
    _letter('Z', 'sett', 'z'),
    _letter('Æ', 'æ', 'ae'),
    _letter('Ø', 'ø', 'oe'),
    _letter('Å', 'å', 'aa'),
  ];
}
