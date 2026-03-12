import 'package:abc2/features/finger_tracing/finger_tracing_guides.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('B and R use two strokes, and I and J use one stroke', () {
    expect(
      FingerTracingGuides.layoutFor('B', const Size(520, 520)).strokes,
      hasLength(2),
    );
    expect(
      FingerTracingGuides.layoutFor('R', const Size(520, 520)).strokes,
      hasLength(2),
    );
    expect(
      FingerTracingGuides.layoutFor('I', const Size(520, 520)).strokes,
      hasLength(1),
    );
    expect(
      FingerTracingGuides.layoutFor('J', const Size(520, 520)).strokes,
      hasLength(1),
    );
  });

  test('I guide width stays comparable to other single-stroke letters', () {
    final iLayout = FingerTracingGuides.layoutFor('I', const Size(520, 520));
    final jLayout = FingerTracingGuides.layoutFor('J', const Size(520, 520));

    expect(iLayout.guideRect.width, greaterThanOrEqualTo(300));
    expect(
      iLayout.guideStrokeWidth,
      greaterThanOrEqualTo(jLayout.guideStrokeWidth),
    );
  });

  test('Å guide keeps a smaller top ring inside the drawing area', () {
    final layout = FingerTracingGuides.layoutFor('Å', const Size(520, 520));
    final ringRect = layout.strokePaths.first.getBounds();
    final topMostCheckpoint = layout.checkpoints
        .map((point) => point.dy)
        .reduce((a, b) => a < b ? a : b);

    expect(topMostCheckpoint, greaterThan(layout.guideStrokeWidth / 2));
    expect(ringRect.width, lessThan(layout.guideRect.width * 0.26));
    expect(ringRect.height, lessThan(layout.guideRect.height * 0.19));
  });

  test('Æ guide uses two diagonals and three horizontal bars', () {
    final layout = FingerTracingGuides.layoutFor('Æ', const Size(520, 520));

    expect(layout.strokes, hasLength(5));

    final leftDiagonalEnd = layout.strokes[0].checkpoints.last;
    final rightDiagonalEnd = layout.strokes[1].checkpoints.last;
    final topBarEnd = layout.strokes[2].checkpoints.last;
    final middleBarEnd = layout.strokes[3].checkpoints.last;
    final bottomBarEnd = layout.strokes[4].checkpoints.last;

    expect(layout.strokes[0].startDot.dx, greaterThan(leftDiagonalEnd.dx));
    expect(layout.strokes[0].startDot.dy, lessThan(leftDiagonalEnd.dy));

    expect(layout.strokes[1].startDot.dx, lessThan(rightDiagonalEnd.dx));
    expect(layout.strokes[1].startDot.dy, lessThan(rightDiagonalEnd.dy));

    expect(
      (layout.strokes[2].startDot.dy - topBarEnd.dy).abs(),
      lessThan(0.001),
    );
    expect(
      (layout.strokes[3].startDot.dy - middleBarEnd.dy).abs(),
      lessThan(0.001),
    );
    expect(
      (layout.strokes[4].startDot.dy - bottomBarEnd.dy).abs(),
      lessThan(0.001),
    );
  });
}
