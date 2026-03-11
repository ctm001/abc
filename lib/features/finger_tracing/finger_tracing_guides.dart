import 'dart:math';

import 'package:flutter/material.dart';

/// Geometry used by the tracing board for a specific letter and size.
class FingerTracingLayout {
  const FingerTracingLayout({
    required this.strokes,
    required this.strokePaths,
    required this.startDots,
    required this.checkpoints,
    required this.guideRect,
    required this.hitRadius,
    required this.startHitRadius,
    required this.pathTolerance,
    required this.guideStrokeWidth,
    required this.playerStrokeWidth,
    required this.startDotRadius,
    required this.checkpointRadius,
  });

  final List<FingerTracingStrokeLayout> strokes;
  final List<Path> strokePaths;
  final List<Offset> startDots;
  final List<Offset> checkpoints;
  final Rect guideRect;
  final double hitRadius;
  final double startHitRadius;
  final double pathTolerance;
  final double guideStrokeWidth;
  final double playerStrokeWidth;
  final double startDotRadius;
  final double checkpointRadius;

  double get finalCheckpointHitRadius =>
      (guideStrokeWidth * 0.52).clamp(10.0, 16.0);
}

/// Geometry for one ordered stroke in a traced letter.
class FingerTracingStrokeLayout {
  const FingerTracingStrokeLayout({
    required this.path,
    required this.startDot,
    required this.checkpoints,
    required this.samples,
  });

  final Path path;
  final Offset startDot;
  final List<Offset> checkpoints;
  final List<Offset> samples;
}

typedef _StrokeBuilder = Path Function(_GuideFrame frame);

/// Registry of tracing guides for the Norwegian alphabet.
abstract final class FingerTracingGuides {
  static FingerTracingLayout layoutFor(String character, Size size) {
    final frame = _GuideFrame.fromCharacter(character, size);
    final builders = _guideBuilders[character] ?? _guideBuilders['A']!;
    final strokePaths = builders
        .map((builder) => builder(frame))
        .toList(growable: false);
    final checkpointSpacing = (frame.rect.shortestSide * 0.12).clamp(
      18.0,
      30.0,
    );
    final sampleSpacing = (checkpointSpacing * 0.45).clamp(8.0, 14.0);

    final guideStrokeWidth = (frame.rect.shortestSide * 0.11).clamp(18.0, 30.0);
    final strokes = strokePaths
        .map((path) {
          final checkpoints = _sampleCheckpoints(path, checkpointSpacing);
          return FingerTracingStrokeLayout(
            path: path,
            startDot: _firstPointForPath(path) ?? frame.rect.center,
            checkpoints: checkpoints,
            samples: _sampleCheckpoints(path, sampleSpacing),
          );
        })
        .toList(growable: false);

    return FingerTracingLayout(
      strokes: strokes,
      strokePaths: strokes.map((stroke) => stroke.path).toList(growable: false),
      startDots: strokes
          .map((stroke) => stroke.startDot)
          .toList(growable: false),
      checkpoints: strokes
          .expand((stroke) => stroke.checkpoints)
          .toList(growable: false),
      guideRect: frame.rect,
      hitRadius: (guideStrokeWidth * 0.9).clamp(18.0, 28.0),
      startHitRadius: (guideStrokeWidth * 1.05).clamp(22.0, 34.0),
      pathTolerance: (guideStrokeWidth * 0.85).clamp(16.0, 26.0),
      guideStrokeWidth: guideStrokeWidth,
      playerStrokeWidth: guideStrokeWidth * 0.58,
      startDotRadius: guideStrokeWidth * 0.34,
      checkpointRadius: guideStrokeWidth * 0.16,
    );
  }

  static Offset? _firstPointForPath(Path path) {
    for (final metric in path.computeMetrics()) {
      final tangent = metric.getTangentForOffset(0);
      if (tangent != null) {
        return tangent.position;
      }
    }
    return null;
  }

  static List<Offset> _sampleCheckpoints(Path path, double spacing) {
    final points = <Offset>[];
    for (final metric in path.computeMetrics()) {
      if (metric.length == 0) {
        continue;
      }
      final segments = max(2, (metric.length / spacing).ceil() + 1);
      for (var index = 0; index < segments; index++) {
        final tangent = metric.getTangentForOffset(
          metric.length * index / (segments - 1),
        );
        if (tangent != null) {
          points.add(tangent.position);
        }
      }
    }
    return points;
  }

  static final Map<String, List<_StrokeBuilder>> _guideBuilders = {
    'A': [
      (frame) => _line(frame, [_n(0.50, 0.14), _n(0.18, 0.88)]),
      (frame) => _line(frame, [_n(0.50, 0.14), _n(0.82, 0.88)]),
      (frame) => _line(frame, [_n(0.32, 0.56), _n(0.68, 0.56)]),
    ],
    'B': [
      (frame) => _line(frame, [_n(0.22, 0.14), _n(0.22, 0.88)]),
      (frame) => _build(frame, (path, frame) {
        final start = frame.point(_n(0.22, 0.14));
        final topControl1 = frame.point(_n(0.84, 0.14));
        final topControl2 = frame.point(_n(0.84, 0.48));
        final middle = frame.point(_n(0.22, 0.50));
        final bottomControl1 = frame.point(_n(0.88, 0.50));
        final bottomControl2 = frame.point(_n(0.88, 0.88));
        final end = frame.point(_n(0.22, 0.88));
        path
          ..moveTo(start.dx, start.dy)
          ..cubicTo(
            topControl1.dx,
            topControl1.dy,
            topControl2.dx,
            topControl2.dy,
            middle.dx,
            middle.dy,
          )
          ..cubicTo(
            bottomControl1.dx,
            bottomControl1.dy,
            bottomControl2.dx,
            bottomControl2.dy,
            end.dx,
            end.dy,
          );
      }),
    ],
    'C': [
      (frame) => _arc(
        frame,
        left: 0.18,
        top: 0.12,
        right: 0.82,
        bottom: 0.88,
        startAngle: -0.20 * pi,
        sweepAngle: -1.60 * pi,
      ),
    ],
    'D': [
      (frame) => _line(frame, [_n(0.24, 0.14), _n(0.24, 0.88)]),
      (frame) => _cubic(
        frame,
        _n(0.24, 0.14),
        _n(0.88, 0.18),
        _n(0.88, 0.84),
        _n(0.24, 0.88),
      ),
    ],
    'E': [
      (frame) => _line(frame, [_n(0.24, 0.14), _n(0.24, 0.88)]),
      (frame) => _line(frame, [_n(0.24, 0.14), _n(0.82, 0.14)]),
      (frame) => _line(frame, [_n(0.24, 0.52), _n(0.70, 0.52)]),
      (frame) => _line(frame, [_n(0.24, 0.88), _n(0.82, 0.88)]),
    ],
    'F': [
      (frame) => _line(frame, [_n(0.24, 0.14), _n(0.24, 0.88)]),
      (frame) => _line(frame, [_n(0.24, 0.14), _n(0.82, 0.14)]),
      (frame) => _line(frame, [_n(0.24, 0.52), _n(0.68, 0.52)]),
    ],
    'G': [
      (frame) => _arc(
        frame,
        left: 0.18,
        top: 0.12,
        right: 0.84,
        bottom: 0.88,
        startAngle: -0.20 * pi,
        sweepAngle: -1.55 * pi,
      ),
      (frame) => _line(frame, [_n(0.54, 0.58), _n(0.82, 0.58), _n(0.82, 0.72)]),
    ],
    'H': [
      (frame) => _line(frame, [_n(0.20, 0.14), _n(0.20, 0.88)]),
      (frame) => _line(frame, [_n(0.80, 0.14), _n(0.80, 0.88)]),
      (frame) => _line(frame, [_n(0.20, 0.52), _n(0.80, 0.52)]),
    ],
    'I': [
      (frame) => _line(frame, [_n(0.50, 0.14), _n(0.50, 0.88)]),
    ],
    'J': [
      (frame) => _build(frame, (path, frame) {
        final start = frame.point(_n(0.76, 0.14));
        final bottom = frame.point(_n(0.76, 0.72));
        final control = frame.point(_n(0.54, 0.98));
        final end = frame.point(_n(0.24, 0.78));
        path
          ..moveTo(start.dx, start.dy)
          ..lineTo(bottom.dx, bottom.dy)
          ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      }),
    ],
    'K': [
      (frame) => _line(frame, [_n(0.24, 0.14), _n(0.24, 0.88)]),
      (frame) => _line(frame, [_n(0.24, 0.52), _n(0.82, 0.14)]),
      (frame) => _line(frame, [_n(0.24, 0.52), _n(0.82, 0.88)]),
    ],
    'L': [
      (frame) => _line(frame, [_n(0.28, 0.14), _n(0.28, 0.88)]),
      (frame) => _line(frame, [_n(0.28, 0.88), _n(0.80, 0.88)]),
    ],
    'M': [
      (frame) => _line(frame, [_n(0.18, 0.14), _n(0.18, 0.88)]),
      (frame) => _line(frame, [_n(0.18, 0.14), _n(0.50, 0.52), _n(0.82, 0.14)]),
      (frame) => _line(frame, [_n(0.82, 0.14), _n(0.82, 0.88)]),
    ],
    'N': [
      (frame) => _line(frame, [_n(0.20, 0.14), _n(0.20, 0.88)]),
      (frame) => _line(frame, [_n(0.20, 0.14), _n(0.80, 0.88)]),
      (frame) => _line(frame, [_n(0.80, 0.14), _n(0.80, 0.88)]),
    ],
    'O': [
      (frame) => _arc(
        frame,
        left: 0.18,
        top: 0.12,
        right: 0.82,
        bottom: 0.88,
        startAngle: -pi / 2,
        sweepAngle: (2 * pi) - 0.01,
      ),
    ],
    'P': [
      (frame) => _line(frame, [_n(0.24, 0.14), _n(0.24, 0.88)]),
      (frame) => _cubic(
        frame,
        _n(0.24, 0.14),
        _n(0.86, 0.14),
        _n(0.86, 0.48),
        _n(0.24, 0.50),
      ),
    ],
    'Q': [
      (frame) => _arc(
        frame,
        left: 0.18,
        top: 0.12,
        right: 0.82,
        bottom: 0.88,
        startAngle: -pi / 2,
        sweepAngle: (2 * pi) - 0.01,
      ),
      (frame) => _line(frame, [_n(0.60, 0.68), _n(0.88, 0.94)]),
    ],
    'R': [
      (frame) => _line(frame, [_n(0.24, 0.14), _n(0.24, 0.88)]),
      (frame) => _build(frame, (path, frame) {
        final start = frame.point(_n(0.24, 0.14));
        final topControl1 = frame.point(_n(0.86, 0.14));
        final topControl2 = frame.point(_n(0.86, 0.48));
        final middle = frame.point(_n(0.24, 0.50));
        final legEnd = frame.point(_n(0.84, 0.88));
        path
          ..moveTo(start.dx, start.dy)
          ..cubicTo(
            topControl1.dx,
            topControl1.dy,
            topControl2.dx,
            topControl2.dy,
            middle.dx,
            middle.dy,
          )
          ..lineTo(legEnd.dx, legEnd.dy);
      }),
    ],
    'S': [
      (frame) => _build(frame, (path, frame) {
        final start = frame.point(_n(0.76, 0.18));
        final c1 = frame.point(_n(0.30, 0.00));
        final c2 = frame.point(_n(0.10, 0.42));
        final middle = frame.point(_n(0.52, 0.50));
        final c3 = frame.point(_n(0.92, 0.58));
        final c4 = frame.point(_n(0.76, 0.98));
        final end = frame.point(_n(0.22, 0.82));
        path
          ..moveTo(start.dx, start.dy)
          ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, middle.dx, middle.dy)
          ..cubicTo(c3.dx, c3.dy, c4.dx, c4.dy, end.dx, end.dy);
      }),
    ],
    'T': [
      (frame) => _line(frame, [_n(0.18, 0.14), _n(0.82, 0.14)]),
      (frame) => _line(frame, [_n(0.50, 0.14), _n(0.50, 0.88)]),
    ],
    'U': [
      (frame) => _build(frame, (path, frame) {
        final start = frame.point(_n(0.20, 0.14));
        final leftBottom = frame.point(_n(0.20, 0.66));
        final control = frame.point(_n(0.50, 1.02));
        final rightBottom = frame.point(_n(0.80, 0.66));
        final end = frame.point(_n(0.80, 0.14));
        path
          ..moveTo(start.dx, start.dy)
          ..lineTo(leftBottom.dx, leftBottom.dy)
          ..quadraticBezierTo(
            control.dx,
            control.dy,
            rightBottom.dx,
            rightBottom.dy,
          )
          ..lineTo(end.dx, end.dy);
      }),
    ],
    'V': [
      (frame) => _line(frame, [_n(0.20, 0.14), _n(0.50, 0.88)]),
      (frame) => _line(frame, [_n(0.80, 0.14), _n(0.50, 0.88)]),
    ],
    'W': [
      (frame) => _line(frame, [
        _n(0.12, 0.14),
        _n(0.32, 0.88),
        _n(0.50, 0.46),
        _n(0.68, 0.88),
        _n(0.88, 0.14),
      ]),
    ],
    'X': [
      (frame) => _line(frame, [_n(0.20, 0.14), _n(0.80, 0.88)]),
      (frame) => _line(frame, [_n(0.80, 0.14), _n(0.20, 0.88)]),
    ],
    'Y': [
      (frame) => _line(frame, [_n(0.20, 0.14), _n(0.50, 0.50)]),
      (frame) => _line(frame, [_n(0.80, 0.14), _n(0.50, 0.50)]),
      (frame) => _line(frame, [_n(0.50, 0.50), _n(0.50, 0.88)]),
    ],
    'Z': [
      (frame) => _line(frame, [_n(0.18, 0.14), _n(0.82, 0.14)]),
      (frame) => _line(frame, [_n(0.82, 0.14), _n(0.18, 0.88)]),
      (frame) => _line(frame, [_n(0.18, 0.88), _n(0.82, 0.88)]),
    ],
    'Æ': [
      (frame) => _line(frame, [_n(0.36, 0.14), _n(0.12, 0.90)]),
      (frame) => _line(frame, [_n(0.36, 0.14), _n(0.58, 0.88)]),
      (frame) => _line(frame, [_n(0.38, 0.14), _n(0.86, 0.14)]),
      (frame) => _line(frame, [_n(0.24, 0.52), _n(0.82, 0.52)]),
      (frame) => _line(frame, [_n(0.56, 0.88), _n(0.86, 0.88)]),
    ],
    'Ø': [
      (frame) => _arc(
        frame,
        left: 0.18,
        top: 0.12,
        right: 0.82,
        bottom: 0.88,
        startAngle: -pi / 2,
        sweepAngle: (2 * pi) - 0.01,
      ),
      (frame) => _line(frame, [_n(0.84, 0.12), _n(0.16, 0.88)]),
    ],
    'Å': [
      (frame) => _arc(
        frame,
        left: 0.39,
        top: 0.04,
        right: 0.61,
        bottom: 0.19,
        startAngle: -pi / 2,
        sweepAngle: (2 * pi) - 0.01,
      ),
      (frame) => _line(frame, [_n(0.50, 0.24), _n(0.18, 0.88)]),
      (frame) => _line(frame, [_n(0.50, 0.24), _n(0.82, 0.88)]),
      (frame) => _line(frame, [_n(0.32, 0.58), _n(0.68, 0.58)]),
    ],
  };
}

class _GuideFrame {
  const _GuideFrame({required this.rect});

  final Rect rect;

  factory _GuideFrame.fromCharacter(String character, Size size) {
    const guideScale = 1.2;
    final widthFactor = switch (character) {
      'M' || 'W' => 0.78,
      'Æ' => 0.82,
      'O' || 'Q' || 'Ø' || 'C' || 'G' => 0.70,
      'I' => 0.34,
      'J' => 0.42,
      'L' => 0.46,
      'T' || 'F' || 'E' => 0.58,
      _ => 0.64,
    };
    const topFactor = 0.10;
    final heightFactor = character == 'Å' ? 0.80 : 0.78;
    final width = size.width * widthFactor;
    final height = size.height * heightFactor;
    final baseRect = Rect.fromLTWH(
      (size.width - width) / 2,
      size.height * topFactor,
      width,
      height,
    );
    final scaledWidth = (baseRect.width * guideScale).clamp(
      0.0,
      size.width * 0.98,
    );
    final scaledHeight = (baseRect.height * guideScale).clamp(
      0.0,
      size.height * 0.98,
    );
    final left = (baseRect.center.dx - (scaledWidth / 2)).clamp(
      0.0,
      size.width - scaledWidth,
    );
    final top = (baseRect.center.dy - (scaledHeight / 2)).clamp(
      0.0,
      size.height - scaledHeight,
    );

    return _GuideFrame(
      rect: Rect.fromLTWH(left, top, scaledWidth, scaledHeight),
    );
  }

  Offset point(Offset normalized) => Offset(
    rect.left + normalized.dx * rect.width,
    rect.top + normalized.dy * rect.height,
  );

  Rect box(double left, double top, double right, double bottom) =>
      Rect.fromLTRB(
        rect.left + left * rect.width,
        rect.top + top * rect.height,
        rect.left + right * rect.width,
        rect.top + bottom * rect.height,
      );
}

Offset _n(double x, double y) => Offset(x, y);

Path _line(_GuideFrame frame, List<Offset> points) {
  final path = Path();
  final start = frame.point(points.first);
  path.moveTo(start.dx, start.dy);

  for (final point in points.skip(1)) {
    final actualPoint = frame.point(point);
    path.lineTo(actualPoint.dx, actualPoint.dy);
  }

  return path;
}

Path _cubic(
  _GuideFrame frame,
  Offset start,
  Offset control1,
  Offset control2,
  Offset end,
) {
  final path = Path();
  final startPoint = frame.point(start);
  final controlPoint1 = frame.point(control1);
  final controlPoint2 = frame.point(control2);
  final endPoint = frame.point(end);
  path
    ..moveTo(startPoint.dx, startPoint.dy)
    ..cubicTo(
      controlPoint1.dx,
      controlPoint1.dy,
      controlPoint2.dx,
      controlPoint2.dy,
      endPoint.dx,
      endPoint.dy,
    );
  return path;
}

Path _arc(
  _GuideFrame frame, {
  required double left,
  required double top,
  required double right,
  required double bottom,
  required double startAngle,
  required double sweepAngle,
}) =>
    Path()..addArc(frame.box(left, top, right, bottom), startAngle, sweepAngle);

Path _build(
  _GuideFrame frame,
  void Function(Path path, _GuideFrame frame) builder,
) {
  final path = Path();
  builder(path, frame);
  return path;
}
