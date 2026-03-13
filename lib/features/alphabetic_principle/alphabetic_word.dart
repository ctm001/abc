/// Child-friendly word prompt used by the alphabetic principle game.
class AlphabeticWord {
  const AlphabeticWord({
    required this.word,
    required this.emoji,
    required this.audioAssetPath,
  });

  final String word;
  final String emoji;
  final String audioAssetPath;

  List<String> get letters => word.toUpperCase().split('');
}

const alphabeticPrincipleWords = <AlphabeticWord>[
  AlphabeticWord(
    word: 'ape',
    emoji: '🐵',
    audioAssetPath: 'assets/audio/words/ape.mp3',
  ),
  AlphabeticWord(
    word: 'arm',
    emoji: '💪',
    audioAssetPath: 'assets/audio/words/arm.mp3',
  ),
  AlphabeticWord(
    word: 'ball',
    emoji: '⚽',
    audioAssetPath: 'assets/audio/words/ball.mp3',
  ),
  AlphabeticWord(
    word: 'bil',
    emoji: '🚗',
    audioAssetPath: 'assets/audio/words/bil.mp3',
  ),
  AlphabeticWord(
    word: 'bok',
    emoji: '📘',
    audioAssetPath: 'assets/audio/words/bok.mp3',
  ),
  AlphabeticWord(
    word: 'buss',
    emoji: '🚌',
    audioAssetPath: 'assets/audio/words/buss.mp3',
  ),
  AlphabeticWord(
    word: 'drue',
    emoji: '🍇',
    audioAssetPath: 'assets/audio/words/drue.mp3',
  ),
  AlphabeticWord(
    word: 'egg',
    emoji: '🥚',
    audioAssetPath: 'assets/audio/words/egg.mp3',
  ),
  AlphabeticWord(
    word: 'eple',
    emoji: '🍎',
    audioAssetPath: 'assets/audio/words/eple.mp3',
  ),
  AlphabeticWord(
    word: 'fisk',
    emoji: '🐟',
    audioAssetPath: 'assets/audio/words/fisk.mp3',
  ),
  AlphabeticWord(
    word: 'fugl',
    emoji: '🐦',
    audioAssetPath: 'assets/audio/words/fugl.mp3',
  ),
  AlphabeticWord(
    word: 'gris',
    emoji: '🐷',
    audioAssetPath: 'assets/audio/words/gris.mp3',
  ),
  AlphabeticWord(
    word: 'hatt',
    emoji: '🎩',
    audioAssetPath: 'assets/audio/words/hatt.mp3',
  ),
  AlphabeticWord(
    word: 'hund',
    emoji: '🐶',
    audioAssetPath: 'assets/audio/words/hund.mp3',
  ),
  AlphabeticWord(
    word: 'hus',
    emoji: '🏠',
    audioAssetPath: 'assets/audio/words/hus.mp3',
  ),
  AlphabeticWord(
    word: 'katt',
    emoji: '🐱',
    audioAssetPath: 'assets/audio/words/katt.mp3',
  ),
  AlphabeticWord(
    word: 'lam',
    emoji: '🐑',
    audioAssetPath: 'assets/audio/words/lam.mp3',
  ),
  AlphabeticWord(
    word: 'lue',
    emoji: '🧢',
    audioAssetPath: 'assets/audio/words/lue.mp3',
  ),
  AlphabeticWord(
    word: 'mus',
    emoji: '🐭',
    audioAssetPath: 'assets/audio/words/mus.mp3',
  ),
  AlphabeticWord(
    word: 'rev',
    emoji: '🦊',
    audioAssetPath: 'assets/audio/words/rev.mp3',
  ),
  AlphabeticWord(
    word: 'ring',
    emoji: '💍',
    audioAssetPath: 'assets/audio/words/ring.mp3',
  ),
  AlphabeticWord(
    word: 'sau',
    emoji: '🐑',
    audioAssetPath: 'assets/audio/words/sau.mp3',
  ),
  AlphabeticWord(
    word: 'sekk',
    emoji: '🎒',
    audioAssetPath: 'assets/audio/words/sekk.mp3',
  ),
  AlphabeticWord(
    word: 'sko',
    emoji: '👟',
    audioAssetPath: 'assets/audio/words/sko.mp3',
  ),
  AlphabeticWord(
    word: 'smil',
    emoji: '😀',
    audioAssetPath: 'assets/audio/words/smil.mp3',
  ),
  AlphabeticWord(
    word: 'sol',
    emoji: '☀️',
    audioAssetPath: 'assets/audio/words/sol.mp3',
  ),
  AlphabeticWord(
    word: 'stol',
    emoji: '🪑',
    audioAssetPath: 'assets/audio/words/stol.mp3',
  ),
  AlphabeticWord(
    word: 'tog',
    emoji: '🚂',
    audioAssetPath: 'assets/audio/words/tog.mp3',
  ),
  AlphabeticWord(
    word: 'tre',
    emoji: '🌳',
    audioAssetPath: 'assets/audio/words/tre.mp3',
  ),
];
