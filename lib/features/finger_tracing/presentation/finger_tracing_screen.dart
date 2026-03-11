import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/presentation/animated_background.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/letter_repository.dart';

/// Placeholder screen for the Finger Tracing game.
class FingerTracingScreen extends StatelessWidget {
  const FingerTracingScreen({
    required this.letterRepository,
    required this.audioService,
    super.key,
  });

  final LetterRepository letterRepository;
  final AudioService audioService;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                    return;
                  }
                  context.replace(RouteNames.home);
                },
              ),
              const Expanded(
                child: Center(child: _ComingSoon(title: 'Spor bokstavene')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          GestureDetector(
            onTap: onBack,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.textDark.withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textDark,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Spor bokstavene',
            style: GoogleFonts.aBeeZee(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textDark.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: AppColors.fingerTracing.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.draw_rounded,
            size: 64,
            color: AppColors.fingerTracing.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 16),
          Text(
            'Kommer snart!',
            style: GoogleFonts.aBeeZee(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textOlive,
            ),
          ),
        ],
      ),
    );
  }
}
