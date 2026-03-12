import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/presentation/animated_background.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/letter_repository.dart';
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
  late final AlphabeticPrincipleState _game;
  late final AlphabeticPrincipleAudio _audio;
  late final bool _ownsGame;
  int _lastPromptToken = 0;

  @override
  void initState() {
    super.initState();
    _ownsGame = widget.gameState == null;
    _game =
        widget.gameState ??
        AlphabeticPrincipleState(letterRepository: widget.letterRepository);
    _audio = widget.gameAudio ?? AlphabeticPrincipleAudio();
    _game.addListener(_handleGameChanged);
    _game.start();
  }

  void _handleGameChanged() {
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

  @override
  void dispose() {
    _game.removeListener(_handleGameChanged);
    if (_ownsGame) {
      _game.dispose();
    }
    unawaited(_audio.dispose());
    super.dispose();
  }

  void _playPrompt() {
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
      unawaited(_audio.playSuccess());
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
        LayoutBuilder(
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
        if (_game.showSuccess) const Positioned.fill(child: _SuccessOverlay()),
      ],
    );
  }

  Widget _buildContent(BuildContext context, double availableWidth) {
    final cardSize = math.min(availableWidth * 0.55, 290).clamp(210.0, 290.0);
    final slotSize = math.min(availableWidth / 5.4, 82).clamp(56.0, 82.0);
    final choiceSize = _game.isBuildWordLevel
        ? math.min(availableWidth / 5.3, 86).clamp(62.0, 86.0)
        : math.min(availableWidth / 4.7, 92).clamp(70.0, 92.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
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
        const SizedBox(height: 20),
        Text(
          _game.titleText,
          textAlign: TextAlign.center,
          style: GoogleFonts.aBeeZee(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textOlive,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _game.helperText,
          textAlign: TextAlign.center,
          style: GoogleFonts.aBeeZee(
            fontSize: 16,
            color: AppColors.textDark.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 26),
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
          slotSize: slotSize.toDouble(),
        ),
        const SizedBox(height: 28),
        _ChoiceBank(
          choices: _game.choices,
          wrongChoiceId: _game.wrongChoiceId,
          onChoiceTapped: _onChoiceTapped,
          choiceSize: choiceSize.toDouble(),
        ),
      ],
    );
  }
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
    return Row(
      children: [
        _BackButton(onTap: onBack),
        const Spacer(),
        _LevelChip(
          currentLevel: currentLevel,
          highestLevel: highestLevel,
          onLevelChanged: onLevelChanged,
        ),
      ],
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
    required this.slotSize,
  });

  final List<String?> slots;
  final int missingIndex;
  final int activeSlotIndex;
  final bool isBuildWordLevel;
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
        final showQuestionMark =
            !isBuildWordLevel && index == missingIndex && letter == null;

        return AnimatedContainer(
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
              color: isActive
                  ? AppColors.rewardGold
                  : letter == null
                  ? AppColors.textDark.withValues(alpha: 0.18)
                  : AppColors.textDark.withValues(alpha: 0.12),
              width: isActive ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
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
        );
      }),
    );
  }
}

class _ChoiceBank extends StatelessWidget {
  const _ChoiceBank({
    required this.choices,
    required this.wrongChoiceId,
    required this.onChoiceTapped,
    required this.choiceSize,
  });

  final List<AlphabeticChoice> choices;
  final String? wrongChoiceId;
  final ValueChanged<AlphabeticChoice> onChoiceTapped;
  final double choiceSize;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 16,
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

class _ChoiceButton extends StatefulWidget {
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
  State<_ChoiceButton> createState() => _ChoiceButtonState();
}

class _ChoiceButtonState extends State<_ChoiceButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = AppColors
        .confetti[widget.choice.paletteIndex % AppColors.confetti.length];
    final color = widget.showWrong ? AppColors.danger : baseColor;

    return AnimatedScale(
      scale: _pressed ? 0.92 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        key: ValueKey('alphabetic-choice-${widget.choice.id}'),
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.choice.letter,
              style: GoogleFonts.aBeeZee(
                fontSize: widget.size * 0.42,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
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
