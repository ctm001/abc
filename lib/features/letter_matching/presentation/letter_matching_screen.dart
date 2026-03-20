import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/presentation/animated_background.dart';
import '../../../core/presentation/game_level_switcher.dart';
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
  bool _wasDancing = false;

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
    final dancingJustStarted = _game.isDancing && !_wasDancing;
    _wasDancing = _game.isDancing;
    final goldCoinJustShown = _game.showGoldCoin && !_wasShowingGoldCoin;
    _wasShowingGoldCoin = _game.showGoldCoin;

    if (dancingJustStarted || goldCoinJustShown) {
      unawaited(_audio.playCelebration());
    }

    if (_game.showCelebration ||
        _game.stackCrumbling ||
        _game.isDancing ||
        _game.showGoldCoin) {
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
        Column(
          children: [
            _Header(
              game: _game,
              onLevelChanged: _game.playLevel,
              onBack: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }
                context.replace(RouteNames.home);
              },
            ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8, bottom: 8),
                    child: LetterStack(
                      letters: _game.letterStack,
                      isCrumbling: _game.stackCrumbling,
                      showParachute: _game.showGoldCoin,
                      isCelebrating: _game.isDancing,
                    ),
                  ),
                  Expanded(child: _buildGameColumn()),
                ],
              ),
            ),
          ],
        ),
        if (_game.showCelebration && !_game.showGoldCoin && !_game.isDancing)
          CelebrationOverlay(onComplete: _game.nextRound),
        if (_game.showGoldCoin)
          GoldCoinOverlay(onDismiss: _game.dismissGoldCoin),
      ],
    );
  }

  Widget _buildGameColumn() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final w = constraints.maxWidth;

        const gap = 12.0;
        const padding = 12.0;

        // Keep the 2x2 answer grid stable, but let the target card
        // use extra room on larger layouts.
        final btnFromH = (h - gap * 3) / 3.755;
        final btnFromW = (w - padding * 2 - 8 - gap) / 2;
        final btn = btnFromH
            .clamp(0, btnFromW)
            .clamp(0, GameDimensions.letterButtonSize)
            .toDouble();
        final baseTarget = btn * 1.755;
        final targetFromH = (h - (btn * 2) - (gap * 6)).clamp(
          baseTarget,
          GameDimensions.targetExpandedSize,
        );
        final targetFromW = (w * 0.72).clamp(
          baseTarget,
          GameDimensions.targetExpandedSize,
        );
        final target = math.min(targetFromH, targetFromW).toDouble();

        return Column(
          children: [
            const Spacer(),
            _PressableTargetDisplay(
              onTap: _playTargetSound,
              displayMode: switch (_game.level) {
                FindLetterState.visibleLevel =>
                  _TargetDisplayMode.visibleLetter,
                FindLetterState.fadeToAudioLevel =>
                  _TargetDisplayMode.fadeToAudio,
                _ => _TargetDisplayMode.audioOnly,
              },
              letter: _game.targetLetter,
              size: target,
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(left: padding, right: padding + 8),
              child: Wrap(
                spacing: gap,
                runSpacing: gap,
                alignment: WrapAlignment.center,
                children: List.generate(_game.choices.length, (i) {
                  final letter = _game.choices[i];
                  return LetterButton(
                    letter: letter,
                    size: btn,
                    showShake:
                        _game.showWrongAnswer && _game.wrongAnswerIndex == i,
                    onTap: () => _onLetterTapped(letter),
                  );
                }),
              ),
            ),
            const Spacer(),
          ],
        );
      },
    );
  }

  void _onLetterTapped(GameLetter letter) {
    if (!_game.canSelectChoices) {
      return;
    }
    if (_game.selectLetter(letter)) {
      unawaited(_audio.playSuccess());
    } else {
      unawaited(_audio.playWrong());
    }
  }
}

// -- Header --------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({
    required this.game,
    required this.onLevelChanged,
    required this.onBack,
  });

  final FindLetterState game;
  final ValueChanged<int> onLevelChanged;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            _BackButton(onTap: onBack),
            const Spacer(),
            if (game.highestLevel > 0)
              GameLevelSwitcher(
                currentLevel: game.level,
                highestLevel: game.highestLevel,
                onTap: () {
                  final next = (game.level + 1) % (game.highestLevel + 1);
                  onLevelChanged(next);
                },
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

enum _TargetDisplayMode { visibleLetter, fadeToAudio, audioOnly }

class _PressableTargetDisplay extends StatefulWidget {
  const _PressableTargetDisplay({
    required this.onTap,
    required this.displayMode,
    required this.letter,
    this.size = GameDimensions.targetSize,
  });

  final VoidCallback onTap;
  final _TargetDisplayMode displayMode;
  final GameLetter letter;
  final double size;

  @override
  State<_PressableTargetDisplay> createState() =>
      _PressableTargetDisplayState();
}

class _PressableTargetDisplayState extends State<_PressableTargetDisplay>
    with SingleTickerProviderStateMixin {
  static const _audioCueHoldDuration = Duration(seconds: 1);
  static const _audioCueFadeDuration = Duration(seconds: 2);

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
    final targetProgress = switch (widget.displayMode) {
      _TargetDisplayMode.visibleLetter => 0.0,
      _TargetDisplayMode.fadeToAudio => 1.0,
      _TargetDisplayMode.audioOnly => 1.0,
    };
    final animationDuration =
        widget.displayMode == _TargetDisplayMode.fadeToAudio
        ? _audioCueHoldDuration + _audioCueFadeDuration
        : Duration.zero;
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: TweenAnimationBuilder<double>(
          key: ValueKey(
            'target-display-${widget.letter.character}-${widget.displayMode.name}',
          ),
          tween: Tween<double>(begin: 0, end: targetProgress),
          duration: animationDuration,
          curve: Curves.linear,
          builder: (context, audioCueProgress, _) {
            final progress = _transitionProgress(audioCueProgress);

            return Container(
              key: const ValueKey('letter-matching-target-display'),
              width: widget.size,
              height: widget.size,
              decoration: _buildTransitionDecoration(progress),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    key: const ValueKey('letter-matching-target-letter-layer'),
                    opacity: 1 - progress,
                    child: Text(
                      widget.letter.character,
                      style: GoogleFonts.aBeeZee(
                        fontSize: widget.size * 0.6,
                        fontWeight: FontWeight.w700,
                        color: widget.letter.color,
                      ),
                    ),
                  ),
                  Opacity(
                    key: const ValueKey('letter-matching-target-audio-layer'),
                    opacity: progress,
                    child: Icon(
                      Icons.volume_up,
                      size: widget.size * 0.41,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  double _transitionProgress(double audioCueProgress) {
    if (widget.displayMode != _TargetDisplayMode.fadeToAudio) {
      return audioCueProgress;
    }

    final totalDuration =
        _audioCueHoldDuration.inMilliseconds +
        _audioCueFadeDuration.inMilliseconds;
    final holdFraction = _audioCueHoldDuration.inMilliseconds / totalDuration;
    return ((audioCueProgress - holdFraction) / (1 - holdFraction))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  BoxDecoration _buildTransitionDecoration(double progress) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _saturationColor(widget.letter.color, progress),
          _saturationColor(
            widget.letter.color.withValues(alpha: 0.8),
            progress,
          ),
        ],
      ),
      borderRadius: BorderRadius.circular(GameDimensions.borderRadius),
      border: Border.all(
        color: Color.lerp(
          widget.letter.color,
          Colors.white.withValues(alpha: 0.8),
          progress,
        )!,
        width: lerpDouble(4, 3, progress)!,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.6),
          blurRadius: 16,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: widget.letter.color.withValues(
            alpha: lerpDouble(0.18, 0.5, progress)!,
          ),
          blurRadius: lerpDouble(18, 24, progress)!,
          offset: Offset(0, lerpDouble(6, 10, progress)!),
        ),
      ],
    );
  }

  Color _saturationColor(Color target, double progress) {
    final opaqueTarget = target.withValues(alpha: 1);
    final targetHsl = HSLColor.fromColor(opaqueTarget);
    final saturatedColor = targetHsl
        .withSaturation(targetHsl.saturation * progress)
        .withLightness(lerpDouble(1, targetHsl.lightness, progress)!)
        .toColor();
    return saturatedColor.withValues(alpha: lerpDouble(1, target.a, progress)!);
  }
}
