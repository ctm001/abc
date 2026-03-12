import 'package:flutter/material.dart';
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

    expect(find.text('Leselek'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.byIcon(Icons.draw_rounded), findsOneWidget);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
  });

  testWidgets('Home screen stays scrollable on short viewports', (
    tester,
  ) async {
    final binding = tester.binding;
    binding.platformDispatcher.views.single.physicalSize = const Size(800, 480);
    binding.platformDispatcher.views.single.devicePixelRatio = 1.0;
    addTearDown(() {
      binding.platformDispatcher.views.single.resetPhysicalSize();
      binding.platformDispatcher.views.single.resetDevicePixelRatio();
    });

    final router = AppRouter(
      letterRepository: LetterRepository(),
      audioService: AudioService(),
    );

    await tester.pumpWidget(App(router: router));
    await tester.pump();

    expect(find.text('Leselek'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
