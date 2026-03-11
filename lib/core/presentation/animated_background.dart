import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Warm sage-green gradient with floating decorative shapes.
///
/// Used as the background for every screen, replacing the
/// default Scaffold background colour.
class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({this.child, super.key});

  final Widget? child;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _GradientFill(),
        const _DecorativeCircles(),
        AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) => _FloatingShapes(progress: _ctrl.value),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

// -- Static gradient -----------------------------------------

class _GradientFill extends StatelessWidget {
  const _GradientFill();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.3, 0.7, 1.0],
          colors: [
            AppColors.bgTop,
            AppColors.bgMid,
            AppColors.bgLow,
            AppColors.bgBottom,
          ],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

// -- Fixed decorative circles --------------------------------

class _DecorativeCircles extends StatelessWidget {
  const _DecorativeCircles();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        Positioned(
          top: -30,
          right: -20,
          child: _Circle(120, AppColors.seed, 0.08),
        ),
        Positioned(
          top: 200,
          left: -40,
          child: _Circle(100, AppColors.letterMatching, 0.10),
        ),
        Positioned(
          bottom: 60,
          right: -30,
          child: _Circle(80, AppColors.seed, 0.06),
        ),
        Positioned(
          bottom: -20,
          left: 30,
          child: _Circle(50, AppColors.letterMatching, 0.08),
        ),
      ],
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle(this.size, this.color, this.opacity);

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }
}

// -- Floating animated shapes --------------------------------

class _FloatingShapes extends StatelessWidget {
  const _FloatingShapes({required this.progress});

  final double progress;

  static final _shapes = List.generate(8, (i) {
    final rng = Random(i * 42);
    return _ShapeData(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: 20 + rng.nextDouble() * 30,
      speed: 0.5 + rng.nextDouble(),
      phase: rng.nextDouble() * 2 * pi,
      isCircle: rng.nextBool(),
      color: [
        AppColors.seed,
        AppColors.letterMatching,
        AppColors.fingerTracing,
        AppColors.alphabeticPrinciple,
      ][i % 4],
      opacity: 0.06 + rng.nextDouble() * 0.09,
    );
  });

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    return Stack(
      children: _shapes.map((s) {
        final angle = progress * 2 * pi * s.speed + s.phase;
        final dx = s.x * sz.width + cos(angle) * 30;
        final dy = s.y * sz.height + sin(angle) * 20;
        return Positioned(
          left: dx,
          top: dy,
          child: Transform.rotate(
            angle: angle * 0.3,
            child: s.isCircle
                ? Container(
                    width: s.size,
                    height: s.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: s.color.withValues(alpha: s.opacity),
                    ),
                  )
                : CustomPaint(
                    size: Size(s.size, s.size),
                    painter: _TrianglePainter(
                      color: s.color.withValues(alpha: s.opacity),
                    ),
                  ),
          ),
        );
      }).toList(),
    );
  }
}

class _ShapeData {
  const _ShapeData({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
    required this.isCircle,
    required this.color,
    required this.opacity,
  });

  final double x, y, size, speed, phase, opacity;
  final bool isCircle;
  final Color color;
}

class _TrianglePainter extends CustomPainter {
  const _TrianglePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_TrianglePainter old) => color != old.color;
}
