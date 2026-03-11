import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/presentation/animated_background.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/module_card.dart';

/// Hub screen with animated sage-green background.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 600;
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 64,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const _Title(),
                        const SizedBox(height: 12),
                        const _Subtitle(),
                        const SizedBox(height: 48),
                        if (wide)
                          Wrap(
                            spacing: 20,
                            runSpacing: 20,
                            alignment: WrapAlignment.center,
                            children: _buildCards(context),
                          )
                        else
                          Column(
                            spacing: 20,
                            children: _buildCards(context),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

List<Widget> _buildCards(BuildContext context) => [
  ModuleCard(
    color: AppColors.letterMatching,
    colorLight: AppColors.letterMatchingLight,
    onTap: () => context.go(RouteNames.letterMatching),
    child: const _LetterCubes(),
  ),
  ModuleCard(
    color: AppColors.fingerTracing,
    colorLight: AppColors.fingerTracingLight,
    onTap: () => context.go(RouteNames.fingerTracing),
    child: const Icon(
      Icons.draw_rounded,
      color: Colors.white,
      size: 48,
    ),
  ),
  ModuleCard(
    color: AppColors.alphabeticPrinciple,
    colorLight: AppColors.alphabeticPrincipleLight,
    onTap: () => context.go(RouteNames.alphabeticPrinciple),
    child: const Icon(
      Icons.volume_up_rounded,
      color: Colors.white,
      size: 48,
    ),
  ),
];

// -- Letter cubes icon ---------------------------------------

class _LetterCubes extends StatelessWidget {
  const _LetterCubes();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 3,
      children: [
        _Cube(letter: 'A'),
        _Cube(letter: 'B'),
        _Cube(letter: 'C'),
      ],
    );
  }
}

class _Cube extends StatelessWidget {
  const _Cube({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
        ),
      ),
      child: Center(
        child: Text(
          letter,
          style: GoogleFonts.aBeeZee(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

// -- Title ---------------------------------------------------

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Text(
      'ABC',
      style: GoogleFonts.aBeeZee(
        fontSize: 67,
        fontWeight: FontWeight.w700,
        color: AppColors.seed,
        letterSpacing: -1,
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  const _Subtitle();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Lær bokstavene!',
      style: GoogleFonts.aBeeZee(
        fontSize: 25,
        color: AppColors.textOlive,
      ),
    );
  }
}
