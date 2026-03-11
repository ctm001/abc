import 'dart:async';

import 'package:flutter/material.dart';

import 'app.dart';
import 'core/audio/audio_service.dart';
import 'core/routing/app_router.dart';
import 'data/repositories/letter_repository.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _AppRoot());
}

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  late final LetterRepository _letterRepository;
  late final AudioService _audioService;
  late final AppRouter _router;

  @override
  void initState() {
    super.initState();
    _letterRepository = LetterRepository();
    _audioService = AudioService();
    _router = AppRouter(
      letterRepository: _letterRepository,
      audioService: _audioService,
    );
  }

  @override
  void dispose() {
    unawaited(_audioService.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return App(router: _router);
  }
}
