import 'dart:math';

import 'package:flutter/material.dart';

import '../../game_colors.dart';

class ParachutingFigure extends StatefulWidget {
  const ParachutingFigure({required this.startHeight, super.key});

  final int startHeight;

  @override
  State<ParachutingFigure> createState() => _ParachutingFigureState();
}

class _ParachutingFigureState extends State<ParachutingFigure>
    with TickerProviderStateMixin {
  late AnimationController _descent;
  late AnimationController _swing;
  late Animation<double> _descentAnim;

  @override
  void initState() {
    super.initState();
    _descent = AnimationController(
      duration: GameTimings.parachuteDescent,
      vsync: this,
    );
    _swing = AnimationController(
      duration: GameTimings.parachuteSwing,
      vsync: this,
    )..repeat(reverse: true);

    _descentAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _descent, curve: Curves.easeInOut));
    _descent.forward();
  }

  @override
  void dispose() {
    _descent.dispose();
    _swing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final start =
        StackDimensions.figureStartBottom +
        widget.startHeight *
            (StackDimensions.tileSize + StackDimensions.tileGap);
    const end = -200.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_descent, _swing]),
      builder: (context, child) {
        final y = start + (end - start) * _descentAnim.value;
        final swing = sin(_swing.value * pi * 2) * 20;
        return Positioned(
          bottom: y,
          left: 10 + swing,
          child: CustomPaint(
            size: const Size(60, 96),
            painter: _ParachuteFigurePainter(),
          ),
        );
      },
    );
  }
}

class _ParachuteFigurePainter extends CustomPainter {
  static const _limbScale = 0.85;
  static const _headRadius = 7.0;
  static const _handRadius = 1.8;

  @override
  void paint(Canvas canvas, Size size) {
    final canopy = Paint()
      ..color = GameColors.primary
      ..style = PaintingStyle.fill;

    final canopyBorder = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final centerX = size.width / 2;

    final canopyPath = Path()
      ..moveTo(centerX - 28, 35)
      ..quadraticBezierTo(centerX - 20, 5, centerX, 0)
      ..quadraticBezierTo(centerX + 20, 5, centerX + 28, 35)
      ..quadraticBezierTo(centerX, 42, centerX - 28, 35);
    canvas.drawPath(canopyPath, canopy);
    canvas.drawPath(canopyPath, canopyBorder);

    final panel = Paint()
      ..color = GameColors.secondary
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(centerX - 14, 8),
      Offset(centerX - 18, 36),
      panel,
    );
    canvas.drawLine(Offset(centerX, 0), Offset(centerX, 38), panel);
    canvas.drawLine(
      Offset(centerX + 14, 8),
      Offset(centerX + 18, 36),
      panel,
    );

    final string = Paint()
      ..color = Colors.black54
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (final points in [
      [centerX - 25, 34.0, centerX - 15, 50.0, centerX - 5, 64.0],
      [centerX + 25, 34.0, centerX + 15, 50.0, centerX + 5, 64.0],
      [centerX - 10, 36.0, centerX - 5, 48.0, centerX - 2, 64.0],
      [centerX + 10, 36.0, centerX + 5, 48.0, centerX + 2, 64.0],
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(points[0], points[1])
          ..quadraticBezierTo(points[2], points[3], points[4], points[5]),
        string,
      );
    }

    final figure = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final head = Paint()
      ..color = GameColors.secondary
      ..style = PaintingStyle.fill;

    const headY = 72.0;
    canvas.drawCircle(Offset(centerX, headY), _headRadius, head);
    canvas.drawCircle(Offset(centerX, headY), _headRadius, figure);

    final shoulderY = headY + _headRadius;
    final hipY = headY + 20;
    canvas.drawPath(
      Path()
        ..moveTo(centerX, shoulderY)
        ..quadraticBezierTo(
          centerX + 1,
          (shoulderY + hipY) / 2,
          centerX,
          hipY,
        ),
      figure,
    );

    // Arms with hands
    for (final direction in [-1, 1]) {
      final shoulder = Offset(centerX + direction * 2, shoulderY + 2);
      final elbow = Offset(
        centerX + direction * (8 * _limbScale),
        shoulderY - 2,
      );
      final hand = Offset(centerX + direction * (5 * _limbScale), headY - 6);
      canvas.drawPath(
        Path()
          ..moveTo(shoulder.dx, shoulder.dy)
          ..quadraticBezierTo(
            elbow.dx + direction * (2 * _limbScale),
            elbow.dy + 4,
            elbow.dx,
            elbow.dy,
          )
          ..quadraticBezierTo(
            elbow.dx + direction * _limbScale,
            elbow.dy - 4,
            hand.dx,
            hand.dy,
          ),
        figure,
      );
      canvas.drawCircle(hand, _handRadius, head);
      canvas.drawCircle(hand, _handRadius, figure);
    }

    // Legs with feet
    for (final direction in [-1, 1]) {
      final hip = Offset(centerX + direction * 2, hipY);
      final knee = Offset(centerX + direction * (6 * _limbScale), hipY + 8);
      final foot = Offset(centerX + direction * (8 * _limbScale), hipY + 18);
      canvas.drawPath(
        Path()
          ..moveTo(hip.dx, hip.dy)
          ..quadraticBezierTo(
            knee.dx - direction * (2 * _limbScale),
            knee.dy - 2,
            knee.dx,
            knee.dy,
          )
          ..quadraticBezierTo(
            knee.dx + direction * (2 * _limbScale),
            knee.dy + 4,
            foot.dx,
            foot.dy,
          ),
        figure,
      );
      canvas.drawLine(
        Offset(foot.dx, foot.dy),
        Offset(foot.dx + direction * 4, foot.dy),
        figure,
      );
    }

    // Face
    final face = Paint()
      ..color = Colors.black87
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(centerX - 2.5, headY - 1.5), 1.2, face);
    canvas.drawCircle(Offset(centerX + 2.5, headY - 1.5), 1.2, face);
    canvas.drawPath(
      Path()
        ..moveTo(centerX - 3, headY + 2)
        ..quadraticBezierTo(centerX, headY + 5, centerX + 3, headY + 2),
      face,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
