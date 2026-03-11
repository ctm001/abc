import 'package:flutter_test/flutter_test.dart';

import 'package:abc2/app.dart';
import 'package:abc2/core/audio/audio_service.dart';
import 'package:abc2/core/routing/app_router.dart';
import 'package:abc2/data/repositories/letter_repository.dart';

void main() {
  testWidgets('App renders home screen', (tester) async {
    final router = AppRouter(
      letterRepository: LetterRepository(),
      audioService: AudioService(),
    );

    await tester.pumpWidget(App(router: router));
    await tester.pump();

    expect(find.text('ABC'), findsOneWidget);
    expect(find.text('Bokstavkobling'), findsOneWidget);
    expect(find.text('Spor bokstavene'), findsOneWidget);
    expect(find.text('Bokstavlyder'), findsOneWidget);
  });
}
