import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import 'widgets/module_card.dart';

/// Hub screen that gives direct access to the three
/// learning modules.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 600;
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  _Title(theme: theme),
                  const SizedBox(height: 40),
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
    );
  }
}

// -- Title ---------------------------------------------------

class _Title extends StatelessWidget {
  const _Title({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      'ABC',
      style: theme.textTheme.displayLarge?.copyWith(
        color: theme.colorScheme.primary,
        letterSpacing: 8,
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
    final cards = _buildCards(context);
    return Column(spacing: 16, children: cards);
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
      spacing: 12,
      children: cards.map((card) => Expanded(child: card)).toList(),
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
    onTap: () => context.go(RouteNames.letterMatching),
  ),
  ModuleCard(
    title: 'Spor bokstavene',
    description: 'Lær å skrive bokstaver',
    icon: Icons.draw_rounded,
    color: AppColors.fingerTracing,
    onTap: () => context.go(RouteNames.fingerTracing),
  ),
  ModuleCard(
    title: 'Bokstavlyder',
    description: 'Koble bokstaver til lyder',
    icon: Icons.volume_up_rounded,
    color: AppColors.alphabeticPrinciple,
    onTap: () => context.go(RouteNames.alphabeticPrinciple),
  ),
];
