import 'dart:async';
import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/presentation/animated_background.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/letter_repository.dart';
import '../../letter_matching/game_letter.dart';
import '../../letter_matching/presentation/widgets/letter_button.dart';
import '../alphabetic_principle_audio.dart';
import '../alphabetic_principle_state.dart';

class AlphabeticPrincipleScreen extends StatefulWidget {
  const AlphabeticPrincipleScreen({
    required this.letterRepository,
    required this.audioService,
    this.gameState,
    this.gameAudio,
    super.key,
  });

  final LetterRepository letterRepository;
  final AudioService audioService;
  final AlphabeticPrincipleState? gameState;
  final AlphabeticPrincipleAudio? gameAudio;

  @override
  State<AlphabeticPrincipleScreen> createState() =>
      _AlphabeticPrincipleScreenState();
}

class _AlphabeticPrincipleScreenState extends State<AlphabeticPrincipleScreen> {
  static const _celebrationLetterGap = Duration(milliseconds: 120);
  static const _postWordPause = Duration(seconds: 2);
  static const _horizontalContentPadding = 32.0;
  static const _maxContentWidth = 760.0;

  late final AlphabeticPrincipleState _game;
  late final AlphabeticPrincipleAudio _audio;
  late final ConfettiController _confettiController;
  late final bool _ownsGame;
  int _lastPromptToken = 0;
  int _lastCelebrationToken = 0;
  int _runningCelebrationToken = 0;
  int? _activeCelebrationSlotIndex;

  @override
  void initState() {
    super.initState();
    _ownsGame = widget.gameState == null;
    _game =
        widget.gameState ??
        AlphabeticPrincipleState(letterRepository: widget.letterRepository);
    _audio = widget.gameAudio ?? AlphabeticPrincipleAudio();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 1),
    );
    _game.addListener(_handleGameChanged);
    _game.start();
  }

  void _handleGameChanged() {
    if (_game.showSuccess && _game.isBuildWordLevel) {
      if (_lastCelebrationToken != _game.celebrationToken) {
        _lastCelebrationToken = _game.celebrationToken;
        _runningCelebrationToken = _game.celebrationToken;
        _confettiController.play();
        unawaited(_audio.playCelebration());
        unawaited(_runBuildWordCelebration(_game.celebrationToken));
      }
    } else {
      _confettiController.stop();
      _setActiveCelebrationSlotIndex(null);
    }

    if (_lastPromptToken == _game.audioCueToken) {
      return;
    }

    _lastPromptToken = _game.audioCueToken;
    final promptToken = _game.audioCueToken;
    final assetPath = _game.currentWord.audioAssetPath;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _game.audioCueToken != promptToken) {
        return;
      }
      unawaited(widget.audioService.playLetterSound(assetPath));
    });
  }

  bool _isCurrentBuildCelebration(int token) =>
      mounted &&
      _runningCelebrationToken == token &&
      _game.showSuccess &&
      _game.isBuildWordLevel &&
      _game.celebrationToken == token;

  Future<void> _runBuildWordCelebration(int token) async {
    final word = _game.currentWord;
    final letters = word.letters;

    try {
      for (var index = 0; index < letters.length; index++) {
        if (!_isCurrentBuildCelebration(token)) {
          return;
        }

        _setActiveCelebrationSlotIndex(index);
        final letter = widget.letterRepository.getByCharacter(letters[index]);
        await widget.audioService.playLetterSoundAndWait(letter.soundAssetPath);

        if (!_isCurrentBuildCelebration(token)) {
          return;
        }

        if (index == letters.length - 1) {
          continue;
        }

        await Future<void>.delayed(_celebrationLetterGap);
      }

      if (!_isCurrentBuildCelebration(token)) {
        return;
      }

      _setActiveCelebrationSlotIndex(null);
      await widget.audioService.playLetterSoundAndWait(word.audioAssetPath);
      if (!_isCurrentBuildCelebration(token)) {
        return;
      }

      await Future<void>.delayed(_postWordPause);
      if (!_isCurrentBuildCelebration(token)) {
        return;
      }

      _game.finishBuildWordCelebration(token);
    } finally {
      if (mounted &&
          _runningCelebrationToken == token &&
          (!_game.showSuccess || !_game.isBuildWordLevel)) {
        _setActiveCelebrationSlotIndex(null);
      }
    }
  }

  void _setActiveCelebrationSlotIndex(int? index) {
    if (!mounted || _activeCelebrationSlotIndex == index) {
      return;
    }
    setState(() {
      _activeCelebrationSlotIndex = index;
    });
  }

  @override
  void dispose() {
    _game.removeListener(_handleGameChanged);
    if (_ownsGame) {
      _game.dispose();
    }
    _confettiController.dispose();
    unawaited(_audio.dispose());
    super.dispose();
  }

  void _playPrompt() {
    if (_game.showSuccess) {
      return;
    }
    unawaited(
      widget.audioService.playLetterSound(_game.currentWord.audioAssetPath),
    );
  }

  void _onChoiceTapped(AlphabeticChoice choice) {
    if (_game.showSuccess) {
      return;
    }

    unawaited(_audio.playTap());
    if (_game.selectChoice(choice)) {
      if (!(_game.showSuccess && _game.isBuildWordLevel)) {
        unawaited(_audio.playSuccess());
      }
    } else {
      unawaited(_audio.playWrong());
    }
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
              currentLevel: _game.level,
              highestLevel: _game.highestLevel,
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: _buildContent(context, constraints.maxWidth),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        if (_game.showSuccess && _game.isBuildWordLevel)
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  key: const ValueKey('alphabetic-principle-confetti'),
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: AppColors.confetti,
                  numberOfParticles: 30,
                  gravity: 0.3,
                ),
              ),
            ),
          ),
        if (_game.showSuccess && !_game.isBuildWordLevel)
          const Positioned.fill(child: _SuccessOverlay()),
      ],
    );
  }

  Widget _buildContent(BuildContext context, double availableWidth) {
    final contentWidth = _contentWidth(availableWidth);
    final cardSize = math.min(contentWidth * 0.55, 290).clamp(210.0, 290.0);
    final slotSize = math.min(contentWidth / 5.4, 82).clamp(56.0, 82.0);
    final choiceLayout = _choiceLayoutMetrics(
      availableWidth: contentWidth,
      totalChoices: _game.isBuildWordLevel
          ? _game.currentWord.letters.length
          : 4,
      isBuildWordLevel: _game.isBuildWordLevel,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _game.titleText,
          textAlign: TextAlign.center,
          style: GoogleFonts.aBeeZee(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textOlive,
          ),
        ),
        const SizedBox(height: 24),
        _WordCard(
          emoji: _game.currentWord.emoji,
          onReplay: _playPrompt,
          size: cardSize.toDouble(),
        ),
        const SizedBox(height: 24),
        _WordSlots(
          slots: _game.slots,
          missingIndex: _game.missingIndex,
          activeSlotIndex: _game.activeSlotIndex,
          isBuildWordLevel: _game.isBuildWordLevel,
          celebrationSlotIndex: _game.showSuccess && _game.isBuildWordLevel
              ? _activeCelebrationSlotIndex
              : null,
          slotSize: slotSize.toDouble(),
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: choiceLayout.height,
          child: Align(
            alignment: Alignment.topCenter,
            child: _ChoiceBank(
              choices: _game.choices,
              wrongChoiceId: _game.wrongChoiceId,
              onChoiceTapped: _onChoiceTapped,
              choiceSize: choiceLayout.size,
              spacing: choiceLayout.spacing,
            ),
          ),
        ),
      ],
    );
  }

  double _contentWidth(double availableWidth) {
    final paddedWidth = math.max(
      0.0,
      availableWidth - _horizontalContentPadding,
    );
    return math.min(paddedWidth, _maxContentWidth);
  }

  _ChoiceLayoutMetrics _choiceLayoutMetrics({
    required double availableWidth,
    required int totalChoices,
    required bool isBuildWordLevel,
  }) {
    final spacing = isBuildWordLevel ? 10.0 : 16.0;
    final maxChoiceSize = 92.0;
    final minChoiceSize = isBuildWordLevel ? 42.0 : 70.0;
    final contentWidth = math.max(0.0, availableWidth);
    final singleRowSize =
        (contentWidth - (spacing * (totalChoices - 1))) / totalChoices;
    final choiceSize =
        (isBuildWordLevel
                ? singleRowSize
                : math.min(contentWidth / 4.7, maxChoiceSize))
            .clamp(minChoiceSize, maxChoiceSize)
            .toDouble();
    final columns = math.max(
      1,
      ((contentWidth + spacing) / (choiceSize + spacing)).floor(),
    );
    final rows = (totalChoices / columns).ceil();
    return _ChoiceLayoutMetrics(
      size: choiceSize,
      spacing: spacing,
      height: (rows * choiceSize) + ((rows - 1) * spacing),
    );
  }
}

class _ChoiceLayoutMetrics {
  const _ChoiceLayoutMetrics({
    required this.size,
    required this.spacing,
    required this.height,
  });

  final double size;
  final double spacing;
  final double height;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.currentLevel,
    required this.highestLevel,
    required this.onLevelChanged,
    required this.onBack,
  });

  final int currentLevel;
  final int highestLevel;
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
            _LevelChip(
              currentLevel: currentLevel,
              highestLevel: highestLevel,
              onLevelChanged: onLevelChanged,
            ),
          ],
        ),
      ),
    );
  }
}

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
      onTap: () => onLevelChanged((currentLevel + 1) % (highestLevel + 1)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.alphabeticPrinciple,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.textDark.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.tune_rounded, size: 18, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'Nivå ${currentLevel + 1}',
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

class _WordCard extends StatelessWidget {
  const _WordCard({
    required this.emoji,
    required this.onReplay,
    required this.size,
  });

  final String emoji;
  final VoidCallback onReplay;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onReplay,
      child: Container(
        key: const ValueKey('alphabetic-principle-card'),
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF7F3E8)],
          ),
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: AppColors.alphabeticPrinciple, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: 16,
              right: 16,
              child: _ReplayButton(onTap: onReplay),
            ),
            Center(
              child: Text(emoji, style: TextStyle(fontSize: size * 0.38)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplayButton extends StatelessWidget {
  const _ReplayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: AppColors.alphabeticPrinciple.withValues(alpha: 0.16),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.volume_up_rounded,
          color: AppColors.alphabeticPrincipleDark,
          size: 24,
        ),
      ),
    );
  }
}

class _WordSlots extends StatelessWidget {
  const _WordSlots({
    required this.slots,
    required this.missingIndex,
    required this.activeSlotIndex,
    required this.isBuildWordLevel,
    required this.celebrationSlotIndex,
    required this.slotSize,
  });

  final List<String?> slots;
  final int missingIndex;
  final int activeSlotIndex;
  final bool isBuildWordLevel;
  final int? celebrationSlotIndex;
  final double slotSize;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: List<Widget>.generate(slots.length, (index) {
        final letter = slots[index];
        final isActive = isBuildWordLevel && index == activeSlotIndex;
        final isCelebrating = celebrationSlotIndex == index;
        final showQuestionMark =
            letter == null && (isBuildWordLevel || index == missingIndex);

        return _PulsingWordSlot(
          index: index,
          isPulsing: isCelebrating,
          child: AnimatedContainer(
            key: ValueKey('alphabetic-slot-$index'),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: slotSize,
            height: slotSize,
            decoration: BoxDecoration(
              color: letter == null
                  ? Colors.white.withValues(alpha: 0.48)
                  : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCelebrating
                    ? AppColors.alphabeticPrincipleDark
                    : isActive
                    ? AppColors.rewardGold
                    : letter == null
                    ? AppColors.textDark.withValues(alpha: 0.18)
                    : AppColors.textDark.withValues(alpha: 0.12),
                width: isCelebrating
                    ? 3
                    : isActive
                    ? 3
                    : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isCelebrating
                      ? AppColors.alphabeticPrinciple.withValues(alpha: 0.28)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: isCelebrating ? 18 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                letter ?? (showQuestionMark ? '?' : ''),
                style: GoogleFonts.aBeeZee(
                  fontSize: slotSize * 0.52,
                  fontWeight: FontWeight.w700,
                  color: letter == null
                      ? AppColors.textDark.withValues(alpha: 0.35)
                      : AppColors.textDark,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _PulsingWordSlot extends StatefulWidget {
  const _PulsingWordSlot({
    required this.index,
    required this.isPulsing,
    required this.child,
  });

  final int index;
  final bool isPulsing;
  final Widget child;

  @override
  State<_PulsingWordSlot> createState() => _PulsingWordSlotState();
}

class _PulsingWordSlotState extends State<_PulsingWordSlot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scale = Tween<double>(
      begin: 1,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PulsingWordSlot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsing == oldWidget.isPulsing) {
      return;
    }

    if (widget.isPulsing) {
      _controller.repeat(reverse: true);
      return;
    }

    _controller
      ..stop()
      ..reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (widget.isPulsing)
            SizedBox.shrink(
              key: ValueKey('alphabetic-slot-pulsing-${widget.index}'),
            ),
          widget.child,
        ],
      ),
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isPulsing ? _scale.value : 1,
          child: child,
        );
      },
    );
  }
}

class _ChoiceBank extends StatelessWidget {
  const _ChoiceBank({
    required this.choices,
    required this.wrongChoiceId,
    required this.onChoiceTapped,
    required this.choiceSize,
    required this.spacing,
  });

  final List<AlphabeticChoice> choices;
  final String? wrongChoiceId;
  final ValueChanged<AlphabeticChoice> onChoiceTapped;
  final double choiceSize;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: spacing,
      runSpacing: spacing,
      children: choices
          .map((choice) {
            return _ChoiceButton(
              choice: choice,
              size: choiceSize,
              showWrong: wrongChoiceId == choice.id,
              onTap: () => onChoiceTapped(choice),
            );
          })
          .toList(growable: false),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.choice,
    required this.size,
    required this.showWrong,
    required this.onTap,
  });

  final AlphabeticChoice choice;
  final double size;
  final bool showWrong;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LetterButton(
      key: ValueKey('alphabetic-choice-${choice.id}'),
      letter: GameLetter(character: choice.letter, index: choice.paletteIndex),
      onTap: onTap,
      size: size,
      colorOverride: showWrong ? AppColors.danger : null,
    );
  }
}

class _SuccessOverlay extends StatelessWidget {
  const _SuccessOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.04),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.alphabeticPrinciple.withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  'Bra jobba!',
                  style: GoogleFonts.aBeeZee(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textOlive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
