import 'package:flutter/material.dart';

import '../../game_colors.dart';
import '../../game_letter.dart';
import 'climbing_figure.dart';
import 'falling_figure.dart';
import 'parachuting_figure.dart';
import 'stacked_letter.dart';

/// Animated stack of letters with climbing stick figure.
class LetterStack extends StatelessWidget {
  const LetterStack({
    required this.letters,
    this.isCrumbling = false,
    this.showParachute = false,
    this.isCelebrating = false,
    super.key,
  });

  final List<GameLetter> letters;
  final bool isCrumbling;
  final bool showParachute;
  final bool isCelebrating;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final availableHeight = screenHeight - 140;

    final stackHeight =
        letters.length * (StackDimensions.tileSize + StackDimensions.tileGap) +
        StackDimensions.stackHeadroom;
    final threshold = availableHeight * 0.98;
    final scale = stackHeight > threshold ? threshold / stackHeight : 1.0;

    return SizedBox(
      width: StackDimensions.width,
      height: availableHeight,
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.bottomCenter,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            for (var i = 0; i < letters.length; i++)
              StackedLetter(
                letter: letters[i],
                index: i,
                total: letters.length,
                isCrumbling: isCrumbling,
              ),
            if (letters.isNotEmpty && !isCrumbling && !showParachute)
              ClimbingFigure(
                letterCount: letters.length,
                isCelebrating: isCelebrating,
              ),
            if (letters.isNotEmpty && showParachute)
              ParachutingFigure(startHeight: letters.length),
            if (isCrumbling && letters.isNotEmpty)
              FallingFigure(startHeight: letters.length),
          ],
        ),
      ),
    );
  }
}
