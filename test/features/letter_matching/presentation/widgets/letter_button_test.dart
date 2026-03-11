import 'package:abc2/features/letter_matching/game_letter.dart';
import 'package:abc2/features/letter_matching/presentation/widgets/letter_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('disposing during shake does not throw', (tester) async {
    const letter = GameLetter(character: 'A', index: 0);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LetterButton(letter: letter, onTap: _noop),
        ),
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: LetterButton(letter: letter, onTap: _noop, showShake: true),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
