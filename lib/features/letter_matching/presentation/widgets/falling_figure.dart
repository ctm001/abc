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
  static const _deployHeightFraction = 0.5;
  static const _parachuteOpenPhase = 0.35;
  static const _canvasSize = Size(72, 96);
  static const _visibleFigureWidth = 30.0;
  static const _deployProgress =
      GameTimings.fallingFigureFreefallMs /
      (GameTimings.fallingFigureFreefallMs +
          GameTimings.fallingFigureParachuteMs);

  late final AnimationController _fall;
  late final AnimationController _flail;
  late final AnimationController _swing;

  @override
  void initState() {
    super.initState();
    _fall = AnimationController(
      duration: GameTimings.fallingFigureTotal,
      vsync: this,
    );
    _flail = AnimationController(
      duration: GameTimings.fallingFlail,
      vsync: this,
    )..repeat();
    _swing = AnimationController(
      duration: GameTimings.parachuteSwing,
      vsync: this,
    )..repeat(reverse: true);
    _fall.forward();
  }

  @override
  void dispose() {
    _fall.dispose();
    _flail.dispose();
    _swing.dispose();
    super.dispose();
  }

  double _distanceProgress(double progress) {
    if (progress <= _deployProgress) {
      final freefallT = Curves.easeIn.transform(progress / _deployProgress);
      return _deployHeightFraction * freefallT;
    }

    final glideT = Curves.easeOut.transform(
      ((progress - _deployProgress) / (1 - _deployProgress))
          .clamp(0.0, 1.0)
          .toDouble(),
    );
    return _deployHeightFraction + (1 - _deployHeightFraction) * glideT;
  }

  double _rotation(double progress) {
    if (progress <= _deployProgress) {
      final freefallT = Curves.easeIn.transform(progress / _deployProgress);
      return 0.42 * pi * freefallT;
    }

    final glideT = Curves.easeOut.transform(
      ((progress - _deployProgress) / (1 - _deployProgress))
          .clamp(0.0, 1.0)
          .toDouble(),
    );
    final swingAngle = sin(_swing.value * pi * 2) * 0.08;
    return (0.42 * pi) * (1 - glideT) + swingAngle * glideT;
  }

  double _horizontalDrift(double progress) {
    if (progress <= _deployProgress) {
      final freefallT = progress / _deployProgress;
      return sin(freefallT * pi * 3) * 15;
    }

    return sin(_swing.value * pi * 2) * 12;
  }

  double _parachuteProgress(double progress) {
    if (progress <= _deployProgress) {
      return 0;
    }

    final phaseT = ((progress - _deployProgress) / (1 - _deployProgress))
        .clamp(0.0, 1.0)
        .toDouble();
    final openT = (phaseT / _parachuteOpenPhase).clamp(0.0, 1.0).toDouble();
    return Curves.easeOutBack.transform(openT);
  }

  @override
  Widget build(BuildContext context) {
    final start =
        StackDimensions.figureStartBottom +
        widget.startHeight *
            (StackDimensions.tileSize + StackDimensions.tileGap);

    return AnimatedBuilder(
      animation: Listenable.merge([_fall, _flail, _swing]),
      builder: (context, child) {
        final progress = _fall.value;
        final distance = _distanceProgress(progress) * (start + 100);
        final rotation = _rotation(progress);
        final parachuteProgress = _parachuteProgress(progress);
        final left =
            StackDimensions.climbingLeft -
            ((_canvasSize.width - _visibleFigureWidth) / 2) +
            _horizontalDrift(progress);

        return Positioned(
          bottom: start - distance,
          left: left,
          child: Transform.rotate(
            angle: rotation,
            child: SizedBox(
              width: _canvasSize.width,
              height: _canvasSize.height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (parachuteProgress > 0)
                    const Positioned.fill(
                      child: IgnorePointer(
                        child: SizedBox(
                          key: ValueKey('wrong-answer-parachute'),
                        ),
                      ),
                    ),
                  CustomPaint(
                    size: _canvasSize,
                    painter: _FallingStickFigurePainter(
                      flailPhase: _flail.value,
                      parachuteProgress: parachuteProgress,
                      swingPhase: _swing.value,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FallingStickFigurePainter extends CustomPainter {
  _FallingStickFigurePainter({
    required this.flailPhase,
    required this.parachuteProgress,
    required this.swingPhase,
  });

  final double flailPhase;
  final double parachuteProgress;
  final double swingPhase;
  static const _limbScale = 0.85;
  static const _headRadius = 8.0;
  static const _handRadius = 1.8;

  double _mix(double from, double to, double progress) {
    return from + (to - from) * progress;
  }

  void _paintParachute(
    Canvas canvas,
    Size size, {
    required double centerX,
    required double open,
    required double swing,
    required Offset leftHand,
    required Offset rightHand,
  }) {
    final canopyFill = Paint()
      ..color = GameColors.primary.withValues(alpha: 0.85 + open * 0.15)
      ..style = PaintingStyle.fill;

    final canopyBorder = Paint()
      ..color = Colors.white.withValues(alpha: 0.65 + open * 0.35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final panel = Paint()
      ..color = GameColors.secondary.withValues(alpha: 0.85 + open * 0.15)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final string = Paint()
      ..color = Colors.black54.withValues(alpha: open)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;

    final canopyTop = 6 + (1 - open) * 9;
    final canopyHalfWidth = 29 * (0.45 + open * 0.55);
    final canopyDepth = 18 * (0.45 + open * 0.55);
    final baseY = canopyTop + canopyDepth;
    final canopyPath = Path()
      ..moveTo(centerX - canopyHalfWidth, baseY)
      ..quadraticBezierTo(
        centerX - canopyHalfWidth * 0.55,
        canopyTop + 2,
        centerX,
        canopyTop,
      )
      ..quadraticBezierTo(
        centerX + canopyHalfWidth * 0.55,
        canopyTop + 2,
        centerX + canopyHalfWidth,
        baseY,
      )
      ..quadraticBezierTo(
        centerX + swing * 3,
        baseY + 7,
        centerX - canopyHalfWidth,
        baseY,
      );
    canvas.drawPath(canopyPath, canopyFill);
    canvas.drawPath(canopyPath, canopyBorder);

    canvas.drawLine(
      Offset(centerX - canopyHalfWidth * 0.55, canopyTop + 6),
      Offset(centerX - canopyHalfWidth * 0.35, baseY + 1),
      panel,
    );
    canvas.drawLine(
      Offset(centerX, canopyTop),
      Offset(centerX, baseY + 2),
      panel,
    );
    canvas.drawLine(
      Offset(centerX + canopyHalfWidth * 0.55, canopyTop + 6),
      Offset(centerX + canopyHalfWidth * 0.35, baseY + 1),
      panel,
    );

    for (final anchor in [
      [centerX - canopyHalfWidth * 0.82, baseY - 1, leftHand.dx, leftHand.dy],
      [centerX - canopyHalfWidth * 0.28, baseY + 2, leftHand.dx, leftHand.dy],
      [
        centerX + canopyHalfWidth * 0.28,
        baseY + 2,
        rightHand.dx,
        rightHand.dy,
      ],
      [
        centerX + canopyHalfWidth * 0.82,
        baseY - 1,
        rightHand.dx,
        rightHand.dy,
      ],
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(anchor[0], anchor[1])
          ..quadraticBezierTo(
            _mix(anchor[0], anchor[2], 0.55),
            _mix(anchor[1], anchor[3], 0.45) - 4,
            anchor[2],
            anchor[3],
          ),
        string,
      );
    }
  }

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
    final open = parachuteProgress.clamp(0.0, 1.0);
    final phase = flailPhase * 2 * pi;
    final swing = sin(swingPhase * pi * 2);
    final flailStrength = 1 - open;
    final twist = sin(phase * 3) * 3 * flailStrength;
    final headShake = sin(phase * 4) * 2 * flailStrength + swing * open * 1.5;

    const headY = 48.0;
    const holdingHandSpread = 8.0 * _limbScale;
    const holdingHandLift = 8.0;
    const kneeSpread = 5.0 * _limbScale;
    const footSpread = 8.0 * _limbScale;
    const upperArmSpread = 6.0 * _limbScale;
    const handSpread = 10.0 * _limbScale;
    final headX = centerX + headShake;

    final leftHoldingHand = Offset(
      centerX - holdingHandSpread + swing * 2,
      headY - holdingHandLift,
    );
    final rightHoldingHand = Offset(
      centerX + holdingHandSpread + swing * 2,
      headY - holdingHandLift,
    );
    if (open > 0) {
      _paintParachute(
        canvas,
        size,
        centerX: centerX,
        open: open,
        swing: swing,
        leftHand: leftHoldingHand,
        rightHand: rightHoldingHand,
      );
    }

    canvas.drawCircle(Offset(headX, headY), _headRadius, fill);
    canvas.drawCircle(Offset(headX, headY), _headRadius, paint);

    const shoulderY = 60.0;
    const hipY = 74.0;
    canvas.drawPath(
      Path()
        ..moveTo(headX, headY + _headRadius)
        ..quadraticBezierTo(
          centerX + twist,
          (shoulderY + hipY) / 2,
          centerX,
          hipY,
        ),
      paint,
    );

    // Legs with feet
    for (final direction in [-1, 1]) {
      final kneeX =
          centerX +
          direction * kneeSpread +
          sin(phase) * (6 * _limbScale) * direction * flailStrength;
      final kneeY = hipY + 9 + cos(phase * 2) * 2.5 * flailStrength;
      final footX =
          centerX +
          direction * footSpread +
          sin(phase + 1) * (6 * _limbScale) * direction * flailStrength +
          swing * open * 1.5;
      final footY = 92.0 + sin(phase * 1.5) * 3 * flailStrength;
      canvas.drawPath(
        Path()
          ..moveTo(centerX + direction * 2, hipY)
          ..quadraticBezierTo(
            kneeX - direction * (2 * _limbScale),
            kneeY - 2,
            kneeX,
            kneeY,
          )
          ..quadraticBezierTo(
            kneeX + direction * (3 * _limbScale),
            kneeY + 4,
            footX,
            footY,
          ),
        paint,
      );
      canvas.drawLine(
        Offset(footX, footY),
        Offset(footX + direction * 4, footY),
        paint,
      );
    }

    // Arms with hands
    for (final direction in [-1, 1]) {
      final shoulder = Offset(centerX + direction * 3 + twist, shoulderY);
      final flailElbowX =
          centerX +
          direction * upperArmSpread +
          (direction > 0
                  ? cos(phase * 1.5) * (4 * _limbScale)
                  : sin(phase * 1.5) * (4 * _limbScale)) *
              flailStrength;
      final flailElbowY =
          shoulderY - 3 + (direction > 0 ? sin(phase) * 3 : cos(phase) * 3);
      final flailHandX =
          centerX +
          direction * handSpread +
          (direction > 0
                  ? cos(phase) * (5 * _limbScale)
                  : sin(phase) * (5 * _limbScale)) *
              flailStrength;
      final flailHandY =
          headY -
          18 +
          (direction > 0 ? cos(phase * 2) * 4 : sin(phase * 2) * 4) *
              flailStrength;

      final holdingHand = direction < 0 ? leftHoldingHand : rightHoldingHand;
      final elbowX = _mix(
        flailElbowX,
        centerX + direction * upperArmSpread,
        open,
      );
      final elbowY = _mix(flailElbowY, shoulderY - 6, open);
      final handX = _mix(flailHandX, holdingHand.dx, open);
      final handY = _mix(flailHandY, holdingHand.dy, open);

      canvas.drawPath(
        Path()
          ..moveTo(shoulder.dx, shoulder.dy)
          ..quadraticBezierTo(
            elbowX - direction * (2 * _limbScale),
            elbowY + 3,
            elbowX,
            elbowY,
          )
          ..quadraticBezierTo(
            elbowX + direction * (3 * _limbScale),
            elbowY - 4,
            handX,
            handY,
          ),
        paint,
      );
      canvas.drawCircle(Offset(handX, handY), _handRadius, fill);
      canvas.drawCircle(Offset(handX, handY), _handRadius, paint);
    }

    // Face
    final face = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(headX - 2.8, headY - 1), 1.8, face);
    canvas.drawCircle(Offset(headX + 2.8, headY - 1), 2.0, face);
    canvas.drawLine(
      Offset(headX - 4, headY - 4.5),
      Offset(headX - 1, headY - 3.5),
      face,
    );
    canvas.drawLine(
      Offset(headX + 4, headY - 4.5),
      Offset(headX + 1, headY - 3.5),
      face,
    );

    final mouthOpen = 2 + sin(phase * 3) * (0.6 + flailStrength);
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
      oldDelegate.flailPhase != flailPhase ||
      oldDelegate.parachuteProgress != parachuteProgress ||
      oldDelegate.swingPhase != swingPhase;
}
