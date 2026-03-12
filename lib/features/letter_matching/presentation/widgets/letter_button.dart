import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../game_colors.dart';
import '../../game_letter.dart';

/// Circle answer button with gradient, multi-layer shadow,
/// and 150ms press animation.
class LetterButton extends StatefulWidget {
  const LetterButton({
    required this.letter,
    required this.onTap,
    this.showShake = false,
    this.size = GameDimensions.letterButtonSize,
    this.colorOverride,
    super.key,
  });

  final GameLetter letter;
  final VoidCallback onTap;
  final bool showShake;
  final double size;
  final Color? colorOverride;

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
      end: 0.94,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
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
    final color = widget.colorOverride ?? widget.letter.color;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          final dx = widget.showShake
              ? _shake.value * ((_ctrl.value * 10).toInt() % 2 == 0 ? 1 : -1)
              : 0.0;

          final blurRadius = 8.0 - _ctrl.value * 3;
          final shadowOffset = 4.0 - _ctrl.value * 2;

          return Transform.translate(
            offset: Offset(dx, 0),
            child: Transform.scale(
              scale: _scale.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, Color.lerp(color, Colors.white, 0.15)!],
                  ),
                  border: Border.all(
                    color: AppColors.textDark.withValues(alpha: 0.15),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: blurRadius,
                      offset: Offset(0, shadowOffset),
                    ),
                  ],
                ),
                child: Center(child: child),
              ),
            ),
          );
        },
        child: Text(
          widget.letter.character,
          style: GoogleFonts.aBeeZee(
            fontSize: widget.size * 0.42,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: [
              const Shadow(
                color: Color(0x40000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
