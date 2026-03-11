import 'package:flutter/material.dart';

import '../../game_colors.dart';
import '../../game_letter.dart';

/// Animated letter choice button with tap and shake.
class LetterButton extends StatefulWidget {
  const LetterButton({
    required this.letter,
    required this.onTap,
    this.showShake = false,
    super.key,
  });

  final GameLetter letter;
  final VoidCallback onTap;
  final bool showShake;

  @override
  State<LetterButton> createState() => _LetterButtonState();
}

class _LetterButtonState extends State<LetterButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _shake;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: GameTimings.letterButtonPress,
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _shake = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticIn));
  }

  @override
  void didUpdateWidget(LetterButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showShake && !oldWidget.showShake) {
      _playShake();
    }
  }

  Future<void> _playShake() async {
    for (var i = 0; i < 3; i++) {
      if (!mounted) return;
      await _ctrl.forward();
      if (!mounted) return;
      await _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final dx = widget.showShake
            ? _shake.value * ((_ctrl.value * 10).toInt() % 2 == 0 ? 1 : -1)
            : 0.0;
        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.scale(scale: _scale.value, child: child),
        );
      },
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          width: GameDimensions.letterButtonSize,
          height: GameDimensions.letterButtonSize,
          decoration: BoxDecoration(
            color: widget.letter.color,
            borderRadius: BorderRadius.circular(GameDimensions.borderRadius),
            boxShadow: [
              BoxShadow(
                color: widget.letter.color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.letter.character,
              style: const TextStyle(
                fontSize: GameDimensions.letterFontSize,
                fontWeight: FontWeight.bold,
                color: GameColors.letterText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
