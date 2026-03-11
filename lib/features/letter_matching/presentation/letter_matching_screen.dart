import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/presentation/animated_background.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/letter_repository.dart';
import '../find_letter_state.dart';
import '../game_audio.dart';
import '../game_colors.dart';
import '../game_letter.dart';
import 'widgets/celebration_overlay.dart';
import 'widgets/gold_coin_overlay.dart';
import 'widgets/letter_button.dart';
import 'widgets/letter_stack.dart';

/// Main screen for the "Finn bokstaven" game.
class LetterMatchingScreen extends StatefulWidget {
  const LetterMatchingScreen({
    required this.letterRepository,
    required this.audioService,
    this.gameState,
    this.gameAudio,
    super.key,
  });

  final LetterRepository letterRepository;
  final AudioService audioService;
  final FindLetterState? gameState;
  final GameAudio? gameAudio;

  @override
  State<LetterMatchingScreen> createState() => _LetterMatchingScreenState();
}

class _LetterMatchingScreenState extends State<LetterMatchingScreen> {
  late final FindLetterState _game;
  late final GameAudio _audio;
  late final bool _ownsGame;
  int _lastAutoplayToken = 0;
  bool _initialized = false;
  bool _wasShowingGoldCoin = false;

  @override
  void initState() {
    super.initState();
    _ownsGame = widget.gameState == null;
    _game =
        widget.gameState ??
        FindLetterState(letterRepository: widget.letterRepository);
    _audio = widget.gameAudio ?? GameAudio();
    _game.addListener(_handleGameChanged);
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    await _game.loadProgress();
    if (!mounted) return;
    _initialized = true;
    _game.resetGame();
  }

  void _handleGameChanged() {
    if (!_initialized) return;
    final goldCoinJustShown = _game.showGoldCoin && !_wasShowingGoldCoin;
    _wasShowingGoldCoin = _game.showGoldCoin;

    if (goldCoinJustShown) {
      unawaited(_audio.playCelebration());
    }

    if (_game.showCelebration || _game.stackCrumbling || _game.showGoldCoin) {
      return;
    }
    if (_lastAutoplayToken == _game.autoplayToken) {
      return;
    }

    _lastAutoplayToken = _game.autoplayToken;
    final autoplayToken = _game.autoplayToken;
    final targetSoundPath = _game.targetSoundPath;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_initialized) return;
      if (_game.autoplayToken != autoplayToken ||
          _game.showCelebration ||
          _game.stackCrumbling ||
          _game.showGoldCoin) {
        return;
      }
      unawaited(widget.audioService.playLetterSound(targetSoundPath));
    });
  }

  @override
  void dispose() {
    _game.removeListener(_handleGameChanged);
    if (_ownsGame) {
      _game.dispose();
    }
    unawaited(_audio.dispose());
    super.dispose();
  }

  void _playTargetSound() {
    unawaited(widget.audioService.playLetterSound(_game.targetSoundPath));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _game,
            builder: (context, _) => _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 20),
              child: LetterStack(
                letters: _game.letterStack,
                isCrumbling: _game.stackCrumbling,
                showParachute: _game.showGoldCoin,
              ),
            ),
            Expanded(child: _buildGameColumn()),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          child: _BackButton(
            onTap: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.replace(RouteNames.home);
            },
          ),
        ),
        if (_game.showCelebration && !_game.showGoldCoin)
          CelebrationOverlay(onComplete: _game.nextRound),
        if (_game.showGoldCoin)
          GoldCoinOverlay(onDismiss: _game.dismissGoldCoin),
      ],
    );
  }

  Widget _buildGameColumn() {
    return Column(
      children: [
        _Header(game: _game, onLevelChanged: _game.playLevel),
        const Spacer(),
        _PressableTargetDisplay(
          onTap: _playTargetSound,
          isQuestionMarkMode: _game.isQuestionMarkMode,
          letter: _game.targetLetter,
        ),
        const Spacer(),
        _buildChoices(),
        const Spacer(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildChoices() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Wrap(
        spacing: GameDimensions.spacing,
        runSpacing: GameDimensions.spacing,
        alignment: WrapAlignment.center,
        children: List.generate(_game.choices.length, (i) {
          final letter = _game.choices[i];
          return LetterButton(
            letter: letter,
            showShake: _game.showWrongAnswer && _game.wrongAnswerIndex == i,
            onTap: () => _onLetterTapped(letter),
          );
        }),
      ),
    );
  }

  void _onLetterTapped(GameLetter letter) {
    if (!_game.canSelectChoices) {
      return;
    }
    unawaited(_audio.playPop());
    if (_game.selectLetter(letter)) {
      unawaited(_audio.playSuccess());
    } else {
      unawaited(_audio.playWrong());
    }
  }
}

// -- Header --------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.game, required this.onLevelChanged});

  final FindLetterState game;
  final ValueChanged<int> onLevelChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Row(
        children: [
          if (game.highestLevel > 0)
            _LevelChip(
              currentLevel: game.level,
              highestLevel: game.highestLevel,
              onLevelChanged: onLevelChanged,
            ),
          const Spacer(),
          _ScorePill(game: game),
        ],
      ),
    );
  }
}

// -- Score pill -----------------------------------------------

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.game});

  final FindLetterState game;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.seed, AppColors.primaryLight],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textDark.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.seed.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.layers, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            '${game.letterStack.length}/${game.alphabetLength}',
            style: GoogleFonts.aBeeZee(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// -- Level chip ----------------------------------------------

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.currentLevel,
    required this.highestLevel,
    required this.onLevelChanged,
  });

  final int currentLevel;
  final int highestLevel;
  final ValueChanged<int> onLevelChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final next = (currentLevel + 1) % (highestLevel + 1);
        onLevelChanged(next);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: currentLevel == 0 ? AppColors.seed : AppColors.letterMatching,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textDark.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentLevel == 0 ? Icons.visibility : Icons.hearing,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              'Niv\u00E5 ${currentLevel + 1}',
              style: GoogleFonts.aBeeZee(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -- Back button ---------------------------------------------

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.textDark.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: AppColors.textDark,
          size: 24,
        ),
      ),
    );
  }
}

// -- Target display ------------------------------------------

class _PressableTargetDisplay extends StatefulWidget {
  const _PressableTargetDisplay({
    required this.onTap,
    required this.isQuestionMarkMode,
    required this.letter,
  });

  final VoidCallback onTap;
  final bool isQuestionMarkMode;
  final GameLetter letter;

  @override
  State<_PressableTargetDisplay> createState() =>
      _PressableTargetDisplayState();
}

class _PressableTargetDisplayState extends State<_PressableTargetDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: GameTimings.targetPress, vsync: this);
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qm = widget.isQuestionMarkMode;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: GameDimensions.targetSize,
          height: GameDimensions.targetSize,
          decoration: BoxDecoration(
            gradient: qm
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.letter.color,
                      widget.letter.color.withValues(alpha: 0.8),
                    ],
                  )
                : null,
            color: qm ? null : Colors.white,
            borderRadius: BorderRadius.circular(GameDimensions.borderRadius),
            border: qm
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 3,
                  )
                : Border.all(color: widget.letter.color, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.6),
                blurRadius: 16,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: widget.letter.color.withValues(alpha: 0.5),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: qm
                ? const Icon(Icons.volume_up, size: 64, color: Colors.white)
                : Text(
                    widget.letter.character,
                    style: GoogleFonts.aBeeZee(
                      fontSize: GameDimensions.targetFontSize,
                      fontWeight: FontWeight.w700,
                      color: widget.letter.color,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
