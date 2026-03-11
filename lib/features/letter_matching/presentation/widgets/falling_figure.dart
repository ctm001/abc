import 'dart:math';

import 'package:flutter/material.dart';

import '../../game_colors.dart';

class FallingFigure extends StatefulWidget {
  const FallingFigure({required this.startHeight, super.key});

  final int startHeight;

  @override
  State<FallingFigure> createState() => _FallingFigureState();
}

class _FallingFigureState extends State<FallingFigure>
    with TickerProviderStateMixin {
  late AnimationController _fall;
  late AnimationController _flail;
  late Animation<double> _fallAnim;
  late Animation<double> _rotateAnim;

  @override
  void initState() {
    super.initState();
    _fall = AnimationController(duration: GameTimings.falling, vsync: this);
    _flail = AnimationController(
      duration: GameTimings.fallingFlail,
      vsync: this,
    )..repeat();

    _fallAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fall, curve: Curves.easeIn));
    _rotateAnim = Tween<double>(
      begin: 0,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _fall, curve: Curves.easeIn));
    _fall.forward();
  }

  @override
  void dispose() {
    _fall.dispose();
    _flail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start =
        StackDimensions.figureStartBottom +
        widget.startHeight *
            (StackDimensions.tileSize + StackDimensions.tileGap);

    return AnimatedBuilder(
      animation: Listenable.merge([_fall, _flail]),
      builder: (context, child) {
        final distance = _fallAnim.value * (start + 100);
        final rotation = _rotateAnim.value * pi;
        return Positioned(
          bottom: start - distance,
          left:
              StackDimensions.climbingLeft + sin(_fallAnim.value * pi * 3) * 15,
          child: Transform.rotate(
            angle: rotation,
            child: CustomPaint(
              size: const Size(30, 50),
              painter: _FallingStickFigurePainter(flailPhase: _flail.value),
            ),
          ),
        );
      },
    );
  }
}

class _FallingStickFigurePainter extends CustomPainter {
  _FallingStickFigurePainter({required this.flailPhase});

  final double flailPhase;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fill = Paint()
      ..color = GameColors.secondary
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final phase = flailPhase * 2 * pi;
    final twist = sin(phase * 3) * 3;
    final headShake = sin(phase * 4) * 2;

    const headY = 7.0;
    final headX = centerX + headShake;
    canvas.drawCircle(Offset(headX, headY), 7, fill);
    canvas.drawCircle(Offset(headX, headY), 7, paint);

    const shoulderY = 17.0;
    const hipY = 32.0;
    canvas.drawPath(
      Path()
        ..moveTo(headX, headY + 7)
        ..quadraticBezierTo(
          centerX + twist,
          (shoulderY + hipY) / 2,
          centerX,
          hipY,
        ),
      paint,
    );

    for (final direction in [-1, 1]) {
      final kneeX = centerX + direction * 6 + sin(phase) * 8 * direction;
      final kneeY = hipY + 6 + cos(phase * 2) * 3;
      final footX = centerX + direction * 10 + sin(phase + 1) * 10 * direction;
      final footY = 48.0 + sin(phase * 1.5) * 4;
      canvas.drawPath(
        Path()
          ..moveTo(centerX + direction * 2, hipY)
          ..quadraticBezierTo(kneeX - direction * 2, kneeY - 2, kneeX, kneeY)
          ..quadraticBezierTo(kneeX + direction * 3, kneeY + 4, footX, footY),
        paint,
      );
    }

    for (final direction in [-1, 1]) {
      final shoulder = Offset(centerX + direction * 3 + twist, shoulderY);
      final elbowX =
          centerX +
          direction * 8 +
          (direction > 0 ? cos(phase * 1.5) * 6 : sin(phase * 1.5) * 6);
      final elbowY =
          shoulderY - 4 + (direction > 0 ? sin(phase) * 4 : cos(phase) * 4);
      final handX =
          centerX +
          direction * 14 +
          (direction > 0 ? cos(phase) * 8 : sin(phase) * 8);
      final handY =
          6 + (direction > 0 ? cos(phase * 2) * 5 : sin(phase * 2) * 5);

      canvas.drawPath(
        Path()
          ..moveTo(shoulder.dx, shoulder.dy)
          ..quadraticBezierTo(
            elbowX - direction * 2,
            elbowY + 3,
            elbowX,
            elbowY,
          )
          ..quadraticBezierTo(elbowX + direction * 3, elbowY - 4, handX, handY),
        paint,
      );
    }

    final face = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(headX - 2.5, headY - 1), 1.8, face);
    canvas.drawCircle(Offset(headX + 2.5, headY - 1), 2.0, face);
    canvas.drawLine(
      Offset(headX - 4, headY - 4),
      Offset(headX - 1, headY - 3),
      face,
    );
    canvas.drawLine(
      Offset(headX + 4, headY - 4),
      Offset(headX + 1, headY - 3),
      face,
    );

    final mouthOpen = 3 + sin(phase * 3);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headX, headY + 3),
        width: 4,
        height: mouthOpen,
      ),
      face,
    );
  }

  @override
  bool shouldRepaint(covariant _FallingStickFigurePainter oldDelegate) =>
      oldDelegate.flailPhase != flailPhase;
}
