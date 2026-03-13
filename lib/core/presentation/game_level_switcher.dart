import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

class GameLevelSwitcher extends StatelessWidget {
  const GameLevelSwitcher({
    required this.currentLevel,
    required this.highestLevel,
    required this.onTap,
    super.key,
  });

  final int currentLevel;
  final int highestLevel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final level = currentLevel.clamp(0, highestLevel);
    final tone = _toneForLevel(level);

    return Semantics(
      button: true,
      label: 'Bytt nivå. Nå nivå ${level + 1}',
      child: GestureDetector(
        key: const ValueKey('game-level-switcher'),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: tone.fill,
            border: Border.all(color: tone.border),
            boxShadow: [
              BoxShadow(
                color: tone.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            '${level + 1}',
            style: GoogleFonts.aBeeZee(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: tone.text,
            ),
          ),
        ),
      ),
    );
  }

  _SwitcherTone _toneForLevel(int level) {
    return switch (level) {
      0 => _SwitcherTone(
        fill: const Color(0xFFDCE8D4),
        border: AppColors.seed.withValues(alpha: 0.5),
        text: AppColors.primaryDark,
        shadow: AppColors.seed.withValues(alpha: 0.12),
      ),
      1 => _SwitcherTone(
        fill: AppColors.alphabeticPrincipleLight.withValues(alpha: 0.34),
        border: AppColors.alphabeticPrincipleDark.withValues(alpha: 0.75),
        text: AppColors.alphabeticPrincipleDark,
        shadow: AppColors.alphabeticPrincipleDark.withValues(alpha: 0.16),
      ),
      _ => _SwitcherTone(
        fill: const Color(0xFFF0D6D1),
        border: AppColors.letterMatchingDark.withValues(alpha: 0.5),
        text: AppColors.letterMatchingDark,
        shadow: AppColors.letterMatchingDark.withValues(alpha: 0.12),
      ),
    };
  }
}

class _SwitcherTone {
  const _SwitcherTone({
    required this.fill,
    required this.border,
    required this.text,
    required this.shadow,
  });

  final Color fill;
  final Color border;
  final Color text;
  final Color shadow;
}
