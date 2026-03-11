import 'dart:math';

import 'package:flutter/material.dart';

import '../../game_colors.dart';

class ClimbingFigure extends StatefulWidget {
  const ClimbingFigure({required this.letterCount, super.key});

  final int letterCount;

  @override
  State<ClimbingFigure> createState() => _ClimbingFigureState();
}

class _ClimbingFigureState extends State<ClimbingFigure>
    with TickerProviderStateMixin {
  late AnimationController _bounce;
  late AnimationController _idle;
  late Animation<double> _bounceAnim;

  @override
  void initState() {
    super.initState();
    _bounce = AnimationController(
      duration: GameTimings.climbingBounce,
      vsync: this,
    );
    _bounceAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _bounce, curve: Curves.elasticOut));
    _idle = AnimationController(duration: GameTimings.climbingIdle, vsync: this)
      ..repeat();
    _bounce.forward();
  }

  @override
  void didUpdateWidget(ClimbingFigure oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.letterCount != oldWidget.letterCount) {
      _bounce
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom =
        StackDimensions.baseHeight +
        widget.letterCount *
            (StackDimensions.tileSize + StackDimensions.tileGap);

    return AnimatedBuilder(
      animation: Listenable.merge([_bounce, _idle]),
      builder: (context, child) {
        final bounce = sin(_bounceAnim.value * pi) * 3;
        return Positioned(
          bottom: bottom + bounce,
          left: StackDimensions.climbingLeft,
          child: CustomPaint(
            size: const Size(30, 50),
            painter: _StickFigurePainter(animationPhase: _idle.value),
          ),
        );
      },
    );
  }
}

class _StickFigurePainter extends CustomPainter {
  _StickFigurePainter({this.animationPhase = 0});

  final double animationPhase;

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
    final phase = animationPhase;

    final waving = phase >= 0.0 && phase < 0.12;
    final looking = phase >= 0.45 && phase < 0.55;
    final waveProgress = waving ? (phase / 0.12) : 0.0;
    final lookProgress = looking ? ((phase - 0.45) / 0.1) : 0.0;
    final breath = sin(phase * 2 * pi) * 0.3;

    const headY = 7.0;
    final headX = centerX;
    final tilt = looking ? sin(lookProgress * pi) * 0.15 : 0.0;

    canvas.save();
    if (looking) {
      canvas.translate(headX, headY);
      canvas.rotate(tilt);
      canvas.translate(-headX, -headY);
    }
    canvas.drawCircle(Offset(headX, headY), 7, fill);
    canvas.drawCircle(Offset(headX, headY), 7, paint);
    canvas.restore();

    const shoulderY = 18.0;
    final hipY = 32.0 + breath;
    canvas.drawPath(
      Path()
        ..moveTo(centerX, headY + 7)
        ..quadraticBezierTo(centerX, (shoulderY + hipY) / 2, centerX, hipY),
      paint,
    );

    _drawLeg(
      canvas,
      paint,
      centerX,
      hipY,
      centerX - 4,
      hipY + 8,
      centerX - 6,
      48,
    );
    _drawLeg(
      canvas,
      paint,
      centerX,
      hipY,
      centerX + 4,
      hipY + 8,
      centerX + 6,
      48,
    );

    if (waving) {
      _drawWavingArms(canvas, paint, centerX, shoulderY, waveProgress);
    } else {
      _drawRelaxedArms(canvas, paint, centerX, shoulderY);
    }

    final face = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final eyeY = looking ? headY : headY - 1;
    final blink = (phase > 0.88 && phase < 0.92) ? 0.2 : 1.2;
    canvas.drawCircle(Offset(headX - 2.5, eyeY), blink, face);
    canvas.drawCircle(Offset(headX + 2.5, eyeY), blink, face);

    canvas.drawPath(
      Path()
        ..moveTo(headX - 3, headY + 2)
        ..quadraticBezierTo(headX, headY + 5, headX + 3, headY + 2),
      face,
    );
  }

  void _drawLeg(
    Canvas canvas,
    Paint paint,
    double centerX,
    double hipY,
    double kneeX,
    double kneeY,
    double footX,
    double footY,
  ) {
    canvas.drawPath(
      Path()
        ..moveTo(centerX + (kneeX < centerX ? -2 : 2), hipY)
        ..quadraticBezierTo(
          kneeX + (kneeX < centerX ? -1 : 1),
          kneeY,
          kneeX,
          kneeY,
        )
        ..quadraticBezierTo(
          kneeX + (kneeX < centerX ? -1 : 1),
          (kneeY + footY) / 2,
          footX,
          footY,
        ),
      paint,
    );
  }

  void _drawWavingArms(
    Canvas canvas,
    Paint paint,
    double centerX,
    double shoulderY,
    double waveProgress,
  ) {
    final elbowX = centerX - 8;
    final elbowY = shoulderY - 2;
    final handX = centerX - 12 + sin(waveProgress * pi * 4) * 3;
    final handY = shoulderY - 10 + sin(waveProgress * pi * 4) * 4;

    canvas.drawPath(
      Path()
        ..moveTo(centerX - 3, shoulderY)
        ..quadraticBezierTo(elbowX, elbowY + 3, elbowX, elbowY)
        ..quadraticBezierTo(elbowX - 2, elbowY - 3, handX, handY),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(centerX + 3, shoulderY)
        ..quadraticBezierTo(
          centerX + 7,
          shoulderY + 4,
          centerX + 6,
          shoulderY + 6,
        )
        ..quadraticBezierTo(
          centerX + 5,
          shoulderY + 9,
          centerX + 4,
          shoulderY + 12,
        ),
      paint,
    );
  }

  void _drawRelaxedArms(
    Canvas canvas,
    Paint paint,
    double centerX,
    double shoulderY,
  ) {
    for (final direction in [-1, 1]) {
      canvas.drawPath(
        Path()
          ..moveTo(centerX + direction * 3, shoulderY)
          ..quadraticBezierTo(
            centerX + direction * 7,
            shoulderY + 4,
            centerX + direction * 6,
            shoulderY + 6,
          )
          ..quadraticBezierTo(
            centerX + direction * 5,
            shoulderY + 9,
            centerX + direction * 4,
            shoulderY + 12,
          ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StickFigurePainter oldDelegate) =>
      oldDelegate.animationPhase != animationPhase;
}
