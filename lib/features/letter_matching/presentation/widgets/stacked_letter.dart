import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../game_colors.dart';
import '../../game_letter.dart';

class StackedLetter extends StatefulWidget {
  const StackedLetter({
    required this.letter,
    required this.index,
    required this.total,
    required this.isCrumbling,
    super.key,
  });

  final GameLetter letter;
  final int index;
  final int total;
  final bool isCrumbling;

  @override
  State<StackedLetter> createState() => _StackedLetterState();
}

class _StackedLetterState extends State<StackedLetter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fall;
  late Animation<double> _rotate;
  late Animation<double> _slide;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(duration: GameTimings.falling, vsync: this);

    final direction = _rng.nextBool() ? 1.0 : -1.0;
    final rotation = (_rng.nextDouble() * 2 - 1) * 1.5;

    _fall = Tween<double>(
      begin: 0,
      end: 500 + _rng.nextDouble() * 200,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.bounceOut));
    _rotate = Tween<double>(
      begin: 0,
      end: rotation * pi,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _slide = Tween<double>(
      begin: 0,
      end: direction * (80 + _rng.nextDouble() * 120),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(StackedLetter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCrumbling && !oldWidget.isCrumbling) {
      final tilesAbove = widget.total - widget.index - 1;
      Future.delayed(GameTimings.stackCrumbleStaggerDelay(tilesAbove), () {
        if (mounted) {
          _ctrl.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom =
        StackDimensions.figureStartBottom +
        widget.index * (StackDimensions.tileSize + StackDimensions.tileGap);

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Positioned(
          bottom: bottom - _fall.value,
          left: StackDimensions.tileLeft + _slide.value,
          child: Transform.rotate(angle: _rotate.value, child: child),
        );
      },
      child: _LetterTile(letter: widget.letter),
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({required this.letter});

  final GameLetter letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: StackDimensions.tileSize,
      height: StackDimensions.tileSize,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [letter.color, Color.lerp(letter.color, Colors.white, 0.15)!],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.textDark.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: letter.color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(1, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          letter.character,
          style: GoogleFonts.aBeeZee(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            shadows: [
              const Shadow(
                color: Color(0x40000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
