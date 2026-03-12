import 'package:abc2/features/letter_matching/game_colors.dart';
import 'package:abc2/features/letter_matching/presentation/widgets/falling_figure.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('wrong-answer parachute opens after the freefall midpoint', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 480,
            child: Stack(
              clipBehavior: Clip.none,
              children: [FallingFigure(startHeight: 4)],
            ),
          ),
        ),
      ),
    );

    const parachuteKey = ValueKey('wrong-answer-parachute');
    expect(find.byKey(parachuteKey), findsNothing);

    await tester.pump(
      Duration(
        milliseconds: GameTimings.fallingFigureFreefall.inMilliseconds - 1,
      ),
    );
    expect(find.byKey(parachuteKey), findsNothing);

    await tester.pump(const Duration(milliseconds: 2));
    expect(find.byKey(parachuteKey), findsOneWidget);
  });
}
