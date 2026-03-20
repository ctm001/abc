import 'dart:math';

import 'package:flutter/material.dart';

import '../../game_colors.dart';

class ClimbingFigure extends StatefulWidget {
  const ClimbingFigure({
    required this.letterCount,
    this.isCelebrating = false,
    super.key,
  });

  final int letterCount;
  final bool isCelebrating;

  @override
  State<ClimbingFigure> createState() => _ClimbingFigureState();
}

class _ClimbingFigureState extends State<ClimbingFigure>
    with TickerProviderStateMixin {
  late AnimationController _bounce;
  late AnimationController _idle;
  late AnimationController _dance;
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
    _dance = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
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
    if (widget.isCelebrating && !oldWidget.isCelebrating) {
      _dance
        ..reset()
        ..repeat();
    } else if (!widget.isCelebrating && oldWidget.isCelebrating) {
      _dance.stop();
    }
  }

  @override
  void dispose() {
    _bounce.dispose();
    _idle.dispose();
    _dance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stackTop =
        StackDimensions.figureStartBottom +
        StackDimensions.tileSize +
        max(0, widget.letterCount - 1) *
            (StackDimensions.tileSize + StackDimensions.tileGap);
    final bottom = stackTop - 1;

    return AnimatedBuilder(
      animation: Listenable.merge([_bounce, _idle, _dance]),
      builder: (context, child) {
        final bounce = sin(_bounceAnim.value * pi) * 3;
        return Positioned(
          bottom: bottom + bounce,
          left: StackDimensions.climbingLeft,
          child: CustomPaint(
            size: const Size(30, 56),
            painter: _StickFigurePainter(
              idlePhase: _idle.value,
              dancePhase: widget.isCelebrating ? _dance.value : 0,
            ),
          ),
        );
      },
    );
  }
}

class _StickFigurePainter extends CustomPainter {
  _StickFigurePainter({this.idlePhase = 0, this.dancePhase = 0});

  final double idlePhase;
  final double dancePhase;

  static const _headRadius = 8.0;
  static const _headY = 9.0;
  static const _shoulderY = 21.0;
  static const _hipBaseY = 35.0;
  static const _footY = 53.0;
  static const _handRadius = 1.8;

  @override
  void paint(Canvas canvas, Size size) {
    if (dancePhase > 0) {
      _paintDancing(canvas, size);
    } else {
      _paintIdle(canvas, size);
    }
  }

  void _paintIdle(Canvas canvas, Size size) {
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
      canvas.drawLine(Offset(fx, _footY), Offset(fx + dir * 4, _footY), stroke);
    }

    // --- Body ---
    final headX = centerX;
    canvas.drawPath(
      Path()
        ..moveTo(headX, _headY + _headRadius)
        ..quadraticBezierTo(centerX, (_shoulderY + hipY) / 2, centerX, hipY),
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
    _drawFace(canvas, centerX, _headY - 1);
  }

  void _paintDancing(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fill = Paint()
      ..color = GameColors.secondary
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final t = dancePhase * 2 * pi;
    final hop = -sin(t * 2).abs() * 4;
    final sway = sin(t) * 2;

    final hipY = _hipBaseY + hop;
    final headX = centerX + sway;

    // --- Legs ---
    for (final dir in [-1.0, 1.0]) {
      final kick = sin(dir < 0 ? t : t + pi) * 4;
      final kx = centerX + dir * 5 + kick * 0.3;
      final ky = hipY + 9 + kick.abs() * 0.3;
      final fx = centerX + dir * 6 + kick;
      final fy = _footY + hop;

      canvas.drawPath(
        Path()
          ..moveTo(centerX + dir * 2, hipY)
          ..quadraticBezierTo(kx - dir * 1.5, ky - 2, kx, ky)
          ..quadraticBezierTo(kx + dir * 1.5, (ky + fy) / 2, fx, fy),
        stroke,
      );
      canvas.drawLine(Offset(fx, fy), Offset(fx + dir * 4, fy), stroke);
    }

    // --- Body ---
    canvas.drawPath(
      Path()
        ..moveTo(headX, _headY + hop + _headRadius)
        ..quadraticBezierTo(
          centerX + sway * 0.5,
          (_shoulderY + hipY) / 2,
          centerX,
          hipY,
        ),
      stroke,
    );

    // --- Arms raised ---
    for (final dir in [-1.0, 1.0]) {
      final wave = sin(t * 2 + dir * 1.5) * 3;
      final elbowX = centerX + dir * 9;
      final elbowY = _shoulderY - 4 + hop;
      final handX = centerX + dir * 11 + wave;
      final handY = _shoulderY - 14 + hop + wave;

      canvas.drawPath(
        Path()
          ..moveTo(centerX + dir * 2, _shoulderY + hop)
          ..quadraticBezierTo(elbowX, elbowY + 3, elbowX, elbowY)
          ..quadraticBezierTo(elbowX + dir * 2, elbowY - 4, handX, handY),
        stroke,
      );
      canvas.drawCircle(Offset(handX, handY), _handRadius, fill);
      canvas.drawCircle(Offset(handX, handY), _handRadius, stroke);
    }

    // --- Head ---
    final headY = _headY + hop;
    canvas.drawCircle(Offset(headX, headY), _headRadius, fill);
    canvas.drawCircle(Offset(headX, headY), _headRadius, stroke);

    // --- Face ---
    _drawFace(canvas, headX, headY - 1, smiling: true);
  }

  void _drawFace(
    Canvas canvas,
    double headX,
    double eyeY, {
    bool smiling = false,
  }) {
    final face = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final blink = !smiling && (idlePhase > 0.88 && idlePhase < 0.92)
        ? 0.2
        : 1.3;
    canvas.drawCircle(Offset(headX - 2.8, eyeY), blink, face);
    canvas.drawCircle(Offset(headX + 2.8, eyeY), blink, face);

    final mouthY = eyeY + 3.5;
    if (smiling) {
      canvas.drawPath(
        Path()
          ..moveTo(headX - 3.5, mouthY)
          ..quadraticBezierTo(headX, mouthY + 4, headX + 3.5, mouthY),
        face,
      );
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(headX - 3, mouthY)
          ..quadraticBezierTo(headX, mouthY + 3, headX + 3, mouthY),
        face,
      );
    }
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
      oldDelegate.idlePhase != idlePhase ||
      oldDelegate.dancePhase != dancePhase;
}
