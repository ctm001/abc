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
    _bounceAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bounce, curve: Curves.elasticOut),
    );
    _idle = AnimationController(
      duration: GameTimings.climbingIdle,
      vsync: this,
    )..repeat();
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
        StackDimensions.baseHeight -
        3 +
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
            size: const Size(30, 56),
            painter: _StickFigurePainter(idlePhase: _idle.value),
          ),
        );
      },
    );
  }
}

class _StickFigurePainter extends CustomPainter {
  _StickFigurePainter({this.idlePhase = 0});

  final double idlePhase;

  static const _headRadius = 8.0;
  static const _headY = 9.0;
  static const _shoulderY = 21.0;
  static const _hipBaseY = 35.0;
  static const _footY = 53.0;
  static const _handRadius = 1.8;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fill = Paint()
      ..color = GameColors.secondary
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final phase = idlePhase;

    final waving = phase >= 0.0 && phase < 0.12;
    final looking = phase >= 0.45 && phase < 0.55;
    final waveProgress = waving ? (phase / 0.12) : 0.0;
    final lookProgress = looking ? ((phase - 0.45) / 0.1) : 0.0;
    final breath = sin(phase * 2 * pi) * 0.4;

    final hipY = _hipBaseY + breath;

    // --- Legs ---
    for (final dir in [-1.0, 1.0]) {
      final kx = centerX + dir * 5;
      final ky = hipY + 9;
      final fx = centerX + dir * 6;

      canvas.drawPath(
        Path()
          ..moveTo(centerX + dir * 2, hipY)
          ..quadraticBezierTo(kx - dir * 1.5, ky - 2, kx, ky)
          ..quadraticBezierTo(kx + dir * 1.5, (ky + _footY) / 2, fx, _footY),
        stroke,
      );
      canvas.drawLine(
        Offset(fx, _footY),
        Offset(fx + dir * 4, _footY),
        stroke,
      );
    }

    // --- Body ---
    final headX = centerX;
    canvas.drawPath(
      Path()
        ..moveTo(headX, _headY + _headRadius)
        ..quadraticBezierTo(
          centerX,
          (_shoulderY + hipY) / 2,
          centerX,
          hipY,
        ),
      stroke,
    );

    // --- Arms ---
    if (waving) {
      _drawWavingArms(canvas, stroke, fill, centerX, waveProgress);
    } else {
      for (final dir in [-1.0, 1.0]) {
        _drawRelaxedArm(canvas, stroke, fill, centerX, dir);
      }
    }

    // --- Head ---
    final tilt = looking ? sin(lookProgress * pi) * 0.15 : 0.0;
    canvas.save();
    if (looking) {
      canvas.translate(headX, _headY);
      canvas.rotate(tilt);
      canvas.translate(-headX, -_headY);
    }
    canvas.drawCircle(Offset(headX, _headY), _headRadius, fill);
    canvas.drawCircle(Offset(headX, _headY), _headRadius, stroke);
    canvas.restore();

    // --- Face ---
    final face = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final eyeY = looking ? _headY : _headY - 1;
    final blink = (phase > 0.88 && phase < 0.92) ? 0.2 : 1.3;
    canvas.drawCircle(Offset(headX - 2.8, eyeY), blink, face);
    canvas.drawCircle(Offset(headX + 2.8, eyeY), blink, face);

    canvas.drawPath(
      Path()
        ..moveTo(headX - 3, _headY + 2.5)
        ..quadraticBezierTo(headX, _headY + 5.5, headX + 3, _headY + 2.5),
      face,
    );
  }

  void _drawRelaxedArm(
    Canvas canvas,
    Paint stroke,
    Paint handFill,
    double centerX,
    double dir,
  ) {
    final elbowX = centerX + dir * 8;
    final elbowY = _shoulderY + 5;
    final handX = centerX + dir * 5;
    final handY = _shoulderY + 14;

    canvas.drawPath(
      Path()
        ..moveTo(centerX + dir * 2, _shoulderY)
        ..quadraticBezierTo(elbowX, elbowY - 1, elbowX - dir, elbowY)
        ..quadraticBezierTo(elbowX - dir * 2, elbowY + 4, handX, handY),
      stroke,
    );
    canvas.drawCircle(Offset(handX, handY), _handRadius, handFill);
    canvas.drawCircle(Offset(handX, handY), _handRadius, stroke);
  }

  void _drawWavingArms(
    Canvas canvas,
    Paint stroke,
    Paint handFill,
    double centerX,
    double waveProgress,
  ) {
    // Left arm waves
    final elbowX = centerX - 9;
    final elbowY = _shoulderY - 2;
    final handX = centerX - 12 + sin(waveProgress * pi * 4) * 3;
    final handY = _shoulderY - 12 + sin(waveProgress * pi * 4) * 4;

    canvas.drawPath(
      Path()
        ..moveTo(centerX - 2, _shoulderY)
        ..quadraticBezierTo(elbowX, elbowY + 3, elbowX, elbowY)
        ..quadraticBezierTo(elbowX - 2, elbowY - 3, handX, handY),
      stroke,
    );
    canvas.drawCircle(Offset(handX, handY), _handRadius, handFill);
    canvas.drawCircle(Offset(handX, handY), _handRadius, stroke);

    // Right arm relaxed
    _drawRelaxedArm(canvas, stroke, handFill, centerX, 1);
  }

  @override
  bool shouldRepaint(covariant _StickFigurePainter oldDelegate) =>
      oldDelegate.idlePhase != idlePhase;
}
