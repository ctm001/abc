import 'package:go_router/go_router.dart';

import '../../core/audio/audio_service.dart';
import '../../data/repositories/letter_repository.dart';
import '../../features/alphabetic_principle/alphabetic_principle_module.dart';
import '../../features/finger_tracing/finger_tracing_module.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/letter_matching/letter_matching_module.dart';
import 'route_names.dart';

/// Central router with dependency injection for all module
/// screens.
class AppRouter {
  AppRouter({
    required LetterRepository letterRepository,
    required AudioService audioService,
  }) : _letterRepository = letterRepository,
       _audioService = audioService;

  final LetterRepository _letterRepository;
  final AudioService _audioService;

  late final GoRouter router = GoRouter(
    initialLocation: RouteNames.home,
    routes: [
      GoRoute(path: RouteNames.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: RouteNames.letterMatching,
        builder: (_, _) => LetterMatchingModule.buildScreen(
          letterRepository: _letterRepository,
          audioService: _audioService,
        ),
      ),
      GoRoute(
        path: RouteNames.fingerTracing,
        builder: (_, _) => FingerTracingModule.buildScreen(
          letterRepository: _letterRepository,
          audioService: _audioService,
        ),
      ),
      GoRoute(
        path: RouteNames.alphabeticPrinciple,
        builder: (_, _) => AlphabeticPrincipleModule.buildScreen(
          letterRepository: _letterRepository,
          audioService: _audioService,
        ),
      ),
    ],
  );
}
