import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Icon-only module button with gradient, shadow, and press
/// animation.
class ModuleCard extends StatefulWidget {
  const ModuleCard({
    required this.child,
    required this.color,
    required this.colorLight,
    required this.onTap,
    super.key,
  });

  final Widget child;
  final Color color;
  final Color colorLight;
  final VoidCallback onTap;

  @override
  State<ModuleCard> createState() => _ModuleCardState();
}

class _ModuleCardState extends State<ModuleCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 120),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.97,
    ).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [widget.color, widget.colorLight],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.textDark.withValues(alpha: 0.15),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
