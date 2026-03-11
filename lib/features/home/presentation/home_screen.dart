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
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth > 600;
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 48,
                ),
                child: Column(
                  children: [
                    const _Title(),
                    const SizedBox(height: 12),
                    const _Subtitle(),
                    const SizedBox(height: 48),
                    if (wide)
                      _WideLayout(context: context)
                    else
                      _NarrowLayout(context: context),
                  ],
                ),
              );
            },
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
        fontSize: 48,
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
        fontSize: 18,
        color: AppColors.textOlive,
      ),
    );
  }
}

// -- Layouts -------------------------------------------------

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return Column(spacing: 16, children: _buildCards(context));
  }
}

class _WideLayout extends StatelessWidget {
  const _WideLayout({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    final cards = _buildCards(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 16,
      children: cards.map((c) => Expanded(child: c)).toList(),
    );
  }
}

// -- Card list builder ---------------------------------------

List<ModuleCard> _buildCards(BuildContext context) => [
  ModuleCard(
    title: 'Bokstavkobling',
    description: 'Finn riktig bokstav',
    icon: Icons.extension_rounded,
    color: AppColors.letterMatching,
    colorLight: AppColors.letterMatchingLight,
    onTap: () => context.go(RouteNames.letterMatching),
  ),
  ModuleCard(
    title: 'Spor bokstavene',
    description: 'Lær å skrive bokstaver',
    icon: Icons.draw_rounded,
    color: AppColors.fingerTracing,
    colorLight: AppColors.fingerTracingLight,
    onTap: () => context.go(RouteNames.fingerTracing),
  ),
  ModuleCard(
    title: 'Bokstavlyder',
    description: 'Koble bokstaver til lyder',
    icon: Icons.volume_up_rounded,
    color: AppColors.alphabeticPrinciple,
    colorLight: AppColors.alphabeticPrincipleLight,
    onTap: () => context.go(RouteNames.alphabeticPrinciple),
  ),
];
