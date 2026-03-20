import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/audio/audio_service.dart';
import '../../../core/presentation/animated_background.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/letter_repository.dart';
import '../../../domain/models/norwegian_letter.dart';
import '../finger_tracing_audio.dart';
import '../finger_tracing_guides.dart';
import '../finger_tracing_state.dart';

@visibleForTesting
double computeFingerTracingCheckpointPulse({
  required int checkpointIndex,
  required int checkpointCount,
  required int cueStartCheckpointIndex,
  required double guideValue,
}) {
  if (checkpointCount == 0 ||
      checkpointIndex < cueStartCheckpointIndex ||
      checkpointIndex >= checkpointCount ||
      cueStartCheckpointIndex >= checkpointCount) {
    return 0;
  }

  final remainingCheckpointCount = checkpointCount - cueStartCheckpointIndex;
  final relativeCheckpointIndex = checkpointIndex - cueStartCheckpointIndex;
  final sequencePosition = guideValue * (remainingCheckpointCount + 1.4);
  final distanceFromLead = (relativeCheckpointIndex - sequencePosition).abs();
  final pulse = (1 - (distanceFromLead / 1.15)).clamp(0.0, 1.0).toDouble();
  return Curves.easeOut.transform(pulse);
}

/// Screen for the finger tracing game.
class FingerTracingScreen extends StatefulWidget {
  const FingerTracingScreen({
    required this.letterRepository,
    required this.audioService,
    this.gameState,
    this.gameAudio,
    super.key,
  });

  final LetterRepository letterRepository;
  final AudioService audioService;
  final FingerTracingState? gameState;
  final FingerTracingAudio? gameAudio;

  @override
  State<FingerTracingScreen> createState() => _FingerTracingScreenState();
}

class _FingerTracingScreenState extends State<FingerTracingScreen> {
  static const _tracingCardAspectRatio = 1.0;

  late final FingerTracingState _game;
  late final FingerTracingAudio _audio;
  late final bool _ownsGame;
  int _lastAudioCueToken = 0;
  int _lastCelebrationToken = 0;

  @override
  void initState() {
    super.initState();
    _ownsGame = widget.gameState == null;
    _game =
        widget.gameState ??
        FingerTracingState(letterRepository: widget.letterRepository);
    _audio = widget.gameAudio ?? FingerTracingAudio();
    _game.addListener(_handleGameChanged);
    _game.start();
  }

  void _handleGameChanged() {
    if (_lastCelebrationToken != _game.celebrationToken) {
      _lastCelebrationToken = _game.celebrationToken;
      unawaited(_audio.playCelebration());
    }

    if (_lastAudioCueToken == _game.audioCueToken) {
      return;
    }

    _lastAudioCueToken = _game.audioCueToken;
    final promptToken = _game.audioCueToken;
    final soundPath = _game.currentLetter.soundAssetPath;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _game.audioCueToken != promptToken) {
        return;
      }
      unawaited(widget.audioService.playLetterSound(soundPath));
    });
  }

  @override
  void dispose() {
    _game.removeListener(_handleGameChanged);
    if (_ownsGame) {
      _game.dispose();
    }
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: _game,
            builder: (context, _) => _buildBody(context),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      children: [
        _Header(
          onBack: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.replace(RouteNames.home);
          },
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    Expanded(
                      child: Center(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final boardDimension = math.min(
                              constraints.maxWidth,
                              constraints.maxHeight,
                            );
                            return SizedBox(
                              width: boardDimension,
                              height: boardDimension,
                              child: _TracingCard(
                                key: ValueKey(_game.roundId),
                                letter: _game.currentLetter,
                                enabled: _game.canTrace,
                                showSuccess: _game.showSuccess,
                                onReplay: _game.replayPrompt,
                                onCoverageChanged:
                                    (coverage, reachedFinalCheckpoint) =>
                                        _game.updateCoverage(
                                          coverage,
                                          reachedFinalCheckpoint:
                                              reachedFinalCheckpoint,
                                        ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.textDark.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.textDark,
                    size: 24,
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 72),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Spor bokstavene!',
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.aBeeZee(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplayButton extends StatefulWidget {
  const _ReplayButton({required this.letter, required this.onTap});

  final String letter;
  final VoidCallback onTap;

  @override
  State<_ReplayButton> createState() => _ReplayButtonState();
}

class _ReplayButtonState extends State<_ReplayButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 140),
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 188,
          height: 88,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.fingerTracing, AppColors.fingerTracingLight],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.fingerTracing.withValues(alpha: 0.28),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    widget.letter,
                    style: GoogleFonts.aBeeZee(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.fingerTracingDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Text(
                'Hør',
                style: GoogleFonts.aBeeZee(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TracingCard extends StatefulWidget {
  const _TracingCard({
    required this.letter,
    required this.enabled,
    required this.showSuccess,
    required this.onReplay,
    required this.onCoverageChanged,
    super.key,
  });

  final NorwegianLetter letter;
  final bool enabled;
  final bool showSuccess;
  final VoidCallback onReplay;
  final void Function(double coverage, bool reachedFinalCheckpoint)
  onCoverageChanged;

  @override
  State<_TracingCard> createState() => _TracingCardState();
}

class _ResumeTarget {
  const _ResumeTarget({
    required this.anchorPoint,
    required this.connectsToFrontier,
  });

  final Offset anchorPoint;
  final bool connectsToFrontier;
}

class _TracingCardState extends State<_TracingCard>
    with TickerProviderStateMixin {
  static const _dotRewindOnStray = 2;

  late final AnimationController _guideController;
  late final AnimationController _successController;
  late final Animation<double> _successCurve;
  FingerTracingLayout? _layout;
  Size? _lastSize;
  final List<List<Offset>> _completedStrokes = <List<Offset>>[];
  final List<List<Offset>> _detachedStrokes = <List<Offset>>[];
  List<Offset>? _activeStroke;
  List<Offset>? _gestureStroke;
  final List<int> _activeCheckpointPathIndices = <int>[];
  bool _gestureConnectedToActiveStroke = false;
  bool _isTracingGesture = false;
  bool _gestureRewound = false;
  int _nextStrokeIndex = 0;
  int _committedCheckpointCount = 0;
  int _activeCheckpointCount = 0;
  int _rewindCheckpointFloor = 0;

  @override
  void initState() {
    super.initState();
    _guideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _successController = AnimationController(
      vsync: this,
      duration: FingerTracingState.successRevealDuration,
    );
    _successCurve = CurvedAnimation(
      parent: _successController,
      curve: Curves.easeInOutCubic,
    );
    _syncGuideAnimation();
  }

  @override
  void didUpdateWidget(covariant _TracingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showSuccess && !oldWidget.showSuccess) {
      _successController.forward(from: 0);
    } else if (!widget.showSuccess && oldWidget.showSuccess) {
      _successController.reset();
    }
    if (widget.enabled != oldWidget.enabled ||
        widget.showSuccess != oldWidget.showSuccess) {
      _syncGuideAnimation();
    }
  }

  @override
  void dispose() {
    _guideController.dispose();
    _successController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFFFF), Color(0xFFF9FCFF)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.textDark.withValues(alpha: 0.10),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: AppColors.fingerTracing.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.fingerTracing.withValues(alpha: 0.03),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  _ensureLayout(size);
                  final layout = _layout!;

                  return IgnorePointer(
                    ignoring: !widget.enabled,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanStart: (details) =>
                          _startStroke(details.localPosition),
                      onPanUpdate: (details) =>
                          _appendStroke(details.localPosition),
                      onPanEnd: (_) => _finishStroke(),
                      onPanCancel: _finishStroke,
                      child: CustomPaint(
                        key: const ValueKey('finger-tracing-board'),
                        painter: _TracingBoardPainter(
                          character: widget.letter.character,
                          layout: layout,
                          strokes: _paintedStrokes,
                          completedStrokeCount: _nextStrokeIndex,
                          activeCheckpointCount: _activeCheckpointCount,
                          hasCurrentStroke: _activeStroke != null,
                          isTracingGesture: _isTracingGesture,
                          success: widget.showSuccess,
                          guideAnimation: _guideController,
                          successAnimation: _successCurve,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (widget.showSuccess && _layout != null)
              Positioned.fromRect(
                rect: _layout!.guideRect,
                child: IgnorePointer(
                  child: FadeTransition(
                    opacity: _successCurve,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 1.03,
                        end: 1,
                      ).animate(_successCurve),
                      child: _SuccessLetterOutline(
                        key: const ValueKey('finger-tracing-success-letter'),
                        character: widget.letter.character,
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 18,
              right: 18,
              child: _CardAudioButton(onTap: widget.onReplay),
            ),
          ],
        ),
      ),
    );
  }

  void _ensureLayout(Size size) {
    if (_layout != null && _lastSize == size) {
      return;
    }

    final hadTraceData =
        _completedStrokes.isNotEmpty ||
        _detachedStrokes.isNotEmpty ||
        _activeStroke != null ||
        _gestureStroke != null ||
        _nextStrokeIndex > 0 ||
        _committedCheckpointCount > 0 ||
        _activeCheckpointCount > 0;
    _lastSize = size;
    _layout = FingerTracingGuides.layoutFor(widget.letter.character, size);

    if (hadTraceData) {
      _resetTraceProgress();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          widget.onCoverageChanged(0, false);
        }
      });
    }
  }

  void _startStroke(Offset point) {
    final layout = _layout;
    if (layout == null || _nextStrokeIndex >= layout.strokes.length) {
      return;
    }

    final clampedPoint = _clampPoint(point);
    final stroke = layout.strokes[_nextStrokeIndex];
    final resumeTarget = _resumeTargetFor(clampedPoint, stroke, layout);
    if (resumeTarget == null) {
      return;
    }

    setState(() {
      _isTracingGesture = true;
      _gestureRewound = false;
      _activeStroke ??= <Offset>[stroke.startDot];
      _gestureStroke = resumeTarget.connectsToFrontier
          ? null
          : <Offset>[resumeTarget.anchorPoint];
      _gestureConnectedToActiveStroke = resumeTarget.connectsToFrontier;
      _captureStrokePoint(clampedPoint, stroke, layout);
    });
  }

  void _appendStroke(Offset point) {
    final layout = _layout;
    if (layout == null ||
        !_isTracingGesture ||
        _captureStrokeForGesture == null ||
        _nextStrokeIndex >= layout.strokes.length) {
      return;
    }

    final clampedPoint = _clampPoint(point);
    setState(() {
      _captureStrokePoint(
        clampedPoint,
        layout.strokes[_nextStrokeIndex],
        layout,
      );
    });
  }

  void _finishStroke() {
    final layout = _layout;
    if (layout == null || !_isTracingGesture) {
      return;
    }

    setState(() {
      _isTracingGesture = false;
      if (_activeStroke == null || _nextStrokeIndex >= layout.strokes.length) {
        return;
      }
      if (_gestureRewound) {
        _restartGuideCue();
        _updateCoverage(layout);
        return;
      }
      _rewindActiveStroke(layout.strokes[_nextStrokeIndex], layout);
      _restartGuideCue();
    });
  }

  void _captureStrokePoint(
    Offset point,
    FingerTracingStrokeLayout stroke,
    FingerTracingLayout layout,
  ) {
    final gestureStroke = _captureStrokeForGesture;
    if (gestureStroke == null) {
      return;
    }

    if (!_isNearStrokePath(point, stroke, layout.pathTolerance)) {
      _rewindActiveStroke(stroke, layout);
      _isTracingGesture = false;
      _restartGuideCue();
      return;
    }

    final previousPoint = gestureStroke.last;
    if ((point - previousPoint).distance > 0.5) {
      gestureStroke.add(point);
    }

    final checkpointStart = _progressionStartForCapture(
      previousPoint,
      point,
      layout,
    );
    if (checkpointStart != null) {
      _advanceCheckpoints(checkpointStart, point, stroke, layout);
    }

    if (_activeCheckpointCount >= stroke.checkpoints.length) {
      _commitActiveStroke(stroke, layout);
      return;
    }

    _updateCoverage(layout);
  }

  void _advanceCheckpoints(
    Offset start,
    Offset end,
    FingerTracingStrokeLayout stroke,
    FingerTracingLayout layout,
  ) {
    while (_activeCheckpointCount < stroke.checkpoints.length) {
      final checkpointIndex = _activeCheckpointCount;
      final checkpoint = stroke.checkpoints[checkpointIndex];
      if (!_segmentHitsCheckpoint(start, end, checkpoint, layout.hitRadius)) {
        break;
      }
      _activeCheckpointPathIndices.add((_activeStroke?.length ?? 1) - 1);
      _activeCheckpointCount++;
    }
  }

  void _commitActiveStroke(
    FingerTracingStrokeLayout stroke,
    FingerTracingLayout layout,
  ) {
    final activeStroke = _activeStroke;
    if (activeStroke == null) {
      return;
    }

    _completedStrokes.addAll(
      _detachedStrokes.map((stroke) => List<Offset>.from(stroke)),
    );
    _completedStrokes.add(List<Offset>.from(activeStroke));
    _committedCheckpointCount += stroke.checkpoints.length;
    _nextStrokeIndex++;
    _activeStroke = null;
    _clearGestureStroke(clearDetachedStrokes: true);
    _activeCheckpointPathIndices.clear();
    _activeCheckpointCount = 0;
    _rewindCheckpointFloor = 0;
    _restartGuideCue();
    _updateCoverage(layout);
  }

  void _rewindActiveStroke(
    FingerTracingStrokeLayout stroke,
    FingerTracingLayout layout,
  ) {
    final activeStroke = _activeStroke;
    if (activeStroke == null) {
      _clearGestureStroke(clearDetachedStrokes: true);
      return;
    }

    _gestureRewound = true;
    _clearGestureStroke();
    final retainedCheckpointCount = (_activeCheckpointCount - _dotRewindOnStray)
        .clamp(_rewindCheckpointFloor, _activeCheckpointCount)
        .toInt();
    _rewindCheckpointFloor = retainedCheckpointCount;

    if (retainedCheckpointCount == 0) {
      _activeStroke = null;
      _activeCheckpointPathIndices.clear();
      _activeCheckpointCount = 0;
      _detachedStrokes.clear();
      _updateCoverage(layout);
      return;
    }

    final retainPathIndex =
        _activeCheckpointPathIndices[retainedCheckpointCount - 1];
    _activeStroke = List<Offset>.from(activeStroke.take(retainPathIndex + 1));
    _activeCheckpointPathIndices.removeRange(
      retainedCheckpointCount,
      _activeCheckpointPathIndices.length,
    );
    _activeCheckpointCount = retainedCheckpointCount;
    _updateCoverage(layout);
  }

  void _resetTraceProgress() {
    _completedStrokes.clear();
    _detachedStrokes.clear();
    _activeStroke = null;
    _clearGestureStroke(clearDetachedStrokes: true);
    _isTracingGesture = false;
    _gestureRewound = false;
    _nextStrokeIndex = 0;
    _committedCheckpointCount = 0;
    _activeCheckpointPathIndices.clear();
    _activeCheckpointCount = 0;
    _rewindCheckpointFloor = 0;
    _restartGuideCue();
  }

  void _syncGuideAnimation() {
    if (widget.enabled && !widget.showSuccess) {
      _guideController.repeat();
      return;
    }
    _guideController.stop();
  }

  void _restartGuideCue() {
    if (widget.enabled && !widget.showSuccess) {
      _guideController.repeat();
      return;
    }
    _guideController.stop();
  }

  void _updateCoverage(FingerTracingLayout layout) {
    if (layout.checkpoints.isEmpty) {
      widget.onCoverageChanged(0, false);
      return;
    }

    final reachedFinalCheckpoint =
        layout.checkpoints.isNotEmpty &&
        _committedCheckpointCount >= layout.checkpoints.length;
    widget.onCoverageChanged(
      (_committedCheckpointCount + _activeCheckpointCount) /
          layout.checkpoints.length,
      reachedFinalCheckpoint,
    );
  }

  bool _isNearStrokePath(
    Offset point,
    FingerTracingStrokeLayout stroke,
    double tolerance,
  ) {
    for (final sample in stroke.samples) {
      if ((sample - point).distance <= tolerance) {
        return true;
      }
    }
    return false;
  }

  bool _segmentHitsCheckpoint(
    Offset start,
    Offset end,
    Offset checkpoint,
    double radius,
  ) => _distanceToSegment(checkpoint, start, end) <= radius;

  Offset? _progressionStartForCapture(
    Offset previousPoint,
    Offset point,
    FingerTracingLayout layout,
  ) {
    final activeStroke = _activeStroke;
    if (activeStroke == null) {
      return null;
    }

    if (_gestureConnectedToActiveStroke) {
      return previousPoint;
    }

    final frontierPoint = activeStroke.last;
    final reachedFrontier =
        (point - frontierPoint).distance <= layout.startHitRadius ||
        _distanceToSegment(frontierPoint, previousPoint, point) <=
            layout.hitRadius;
    if (!reachedFrontier) {
      return null;
    }

    _archiveGestureStroke(frontierPoint);
    _gestureConnectedToActiveStroke = true;
    if ((point - frontierPoint).distance > 0.5) {
      activeStroke.add(point);
    }
    return frontierPoint;
  }

  _ResumeTarget? _resumeTargetFor(
    Offset point,
    FingerTracingStrokeLayout stroke,
    FingerTracingLayout layout,
  ) {
    final activeStroke = _activeStroke;
    if (activeStroke == null || _activeCheckpointCount == 0) {
      return (stroke.startDot - point).distance <= layout.startHitRadius
          ? _ResumeTarget(
              anchorPoint: stroke.startDot,
              connectsToFrontier: true,
            )
          : null;
    }

    final anchorPoint = _nearestPointOnActiveStroke(
      point,
      layout.startHitRadius,
    );
    if (anchorPoint == null) {
      return null;
    }

    return _ResumeTarget(
      anchorPoint: anchorPoint,
      connectsToFrontier:
          (anchorPoint - activeStroke.last).distance <= layout.startHitRadius,
    );
  }

  Offset? _nearestPointOnActiveStroke(Offset point, double maxDistance) {
    final activeStroke = _activeStroke;
    if (activeStroke == null || activeStroke.isEmpty) {
      return null;
    }

    Offset? bestPoint;
    var bestDistance = double.infinity;

    for (var pointIndex = 0; pointIndex < activeStroke.length; pointIndex++) {
      final candidatePoint = activeStroke[pointIndex];
      final distance = (candidatePoint - point).distance;
      if (distance <= maxDistance && distance < bestDistance) {
        bestDistance = distance;
        bestPoint = candidatePoint;
      }
    }

    for (
      var segmentEndIndex = 1;
      segmentEndIndex < activeStroke.length;
      segmentEndIndex++
    ) {
      final segmentStart = activeStroke[segmentEndIndex - 1];
      final segmentEnd = activeStroke[segmentEndIndex];
      final dx = segmentEnd.dx - segmentStart.dx;
      final dy = segmentEnd.dy - segmentStart.dy;
      final segmentLengthSquared = (dx * dx) + (dy * dy);
      if (segmentLengthSquared == 0) {
        continue;
      }

      final projection =
          ((point.dx - segmentStart.dx) * dx +
              (point.dy - segmentStart.dy) * dy) /
          segmentLengthSquared;
      final t = projection.clamp(0.0, 1.0).toDouble();
      final projected = Offset(
        segmentStart.dx + (dx * t),
        segmentStart.dy + (dy * t),
      );
      final distance = (point - projected).distance;
      if (distance > maxDistance || distance >= bestDistance) {
        continue;
      }

      bestDistance = distance;
      bestPoint = projected;
    }

    return bestPoint;
  }

  void _clearGestureStroke({bool clearDetachedStrokes = false}) {
    _gestureStroke = null;
    _gestureConnectedToActiveStroke = false;
    if (clearDetachedStrokes) {
      _detachedStrokes.clear();
    }
  }

  void _archiveGestureStroke(Offset frontierPoint) {
    final gestureStroke = _gestureStroke;
    if (gestureStroke == null || gestureStroke.isEmpty) {
      return;
    }
    final detachedStroke = List<Offset>.from(gestureStroke);
    detachedStroke[detachedStroke.length - 1] = frontierPoint;
    if (detachedStroke.length > 1 ||
        (detachedStroke.first - frontierPoint).distance > 0.5) {
      _detachedStrokes.add(detachedStroke);
    }
    _gestureStroke = null;
  }

  List<Offset>? get _captureStrokeForGesture =>
      _gestureConnectedToActiveStroke ? _activeStroke : _gestureStroke;

  List<List<Offset>> get _paintedStrokes {
    final strokes = <List<Offset>>[..._completedStrokes, ..._detachedStrokes];
    final activeStroke = _activeStroke;
    if (activeStroke != null) {
      strokes.add(activeStroke);
    }
    final gestureStroke = _gestureStroke;
    if (gestureStroke != null) {
      strokes.add(gestureStroke);
    }
    return strokes;
  }

  double _distanceToSegment(Offset point, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    if (dx == 0 && dy == 0) {
      return (point - start).distance;
    }

    final projection =
        ((point.dx - start.dx) * dx + (point.dy - start.dy) * dy) /
        ((dx * dx) + (dy * dy));
    final t = projection.clamp(0.0, 1.0).toDouble();
    final projected = Offset(start.dx + (dx * t), start.dy + (dy * t));
    return (point - projected).distance;
  }

  Offset _clampPoint(Offset point) => Offset(
    point.dx.clamp(0.0, _lastSize!.width).toDouble(),
    point.dy.clamp(0.0, _lastSize!.height).toDouble(),
  );
}

class _CardAudioButton extends StatefulWidget {
  const _CardAudioButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_CardAudioButton> createState() => _CardAudioButtonState();
}

class _CardAudioButtonState extends State<_CardAudioButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) {
      return;
    }
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.92 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        key: const ValueKey('finger-tracing-audio-button'),
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        child: SizedBox(
          width: 48,
          height: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.20),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.34),
                width: 1.1,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.volume_up_rounded,
                color: AppColors.fingerTracingDark.withValues(alpha: 0.70),
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessLetterOutline extends StatelessWidget {
  const _SuccessLetterOutline({required this.character, super.key});

  final String character;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.contain,
      child: _TracingLetterGlyph(
        character: character,
        detachedRingKey: const ValueKey('finger-tracing-success-letter-ring'),
        style: GoogleFonts.aBeeZee(
          fontSize: 220,
          height: 1,
          fontWeight: FontWeight.w400,
          color: AppColors.fingerTracing.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}

class _TracingLetterGlyph extends StatelessWidget {
  const _TracingLetterGlyph({
    required this.character,
    required this.style,
    this.detachedRingKey,
  });

  final String character;
  final TextStyle style;
  final Key? detachedRingKey;

  @override
  Widget build(BuildContext context) {
    if (character != 'Å' && character != 'å') {
      return Text(character, style: style);
    }

    final fontSize = style.fontSize ?? 16;
    final ringColor =
        style.color ?? DefaultTextStyle.of(context).style.color ?? Colors.black;
    final bodyCharacter = character == 'å' ? 'a' : 'A';
    final width = fontSize * 0.90;
    final height = fontSize * 1.18;
    final bodyTop = fontSize * 0.18;
    final ringSize = fontSize * 0.18;
    final ringStrokeWidth = (fontSize * 0.03).clamp(1.0, 8.0).toDouble();

    return Semantics(
      label: character,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned.fill(
                top: bodyTop,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Text(bodyCharacter, style: style.copyWith(height: 1)),
                ),
              ),
              Positioned(
                top: fontSize * 0.01,
                child: SizedBox(
                  key: detachedRingKey,
                  width: ringSize,
                  height: ringSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: ringColor,
                        width: ringStrokeWidth,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TracingBoardPainter extends CustomPainter {
  _TracingBoardPainter({
    required this.character,
    required this.layout,
    required this.strokes,
    required this.completedStrokeCount,
    required this.activeCheckpointCount,
    required this.hasCurrentStroke,
    required this.isTracingGesture,
    required this.success,
    required this.guideAnimation,
    required this.successAnimation,
  }) : super(repaint: Listenable.merge([guideAnimation, successAnimation]));

  final String character;
  final FingerTracingLayout layout;
  final List<List<Offset>> strokes;
  final int completedStrokeCount;
  final int activeCheckpointCount;
  final bool hasCurrentStroke;
  final bool isTracingGesture;
  final bool success;
  final Animation<double> guideAnimation;
  final Animation<double> successAnimation;

  double get _successProgress => successAnimation.value;

  @override
  void paint(Canvas canvas, Size size) {
    _paintGuide(canvas);
    _paintCheckpoints(canvas);
    _paintPlayerStrokes(canvas);
  }

  void _paintGuide(Canvas canvas) {
    final guideWidth = FingerTracingGuides.guidePaintWidthFor(
      character,
      layout.guideStrokeWidth,
    );
    final fade = 1 - _successProgress;

    for (
      var strokeIndex = 0;
      strokeIndex < layout.strokePaths.length;
      strokeIndex++
    ) {
      final isCurrentStroke =
          _showGuideCue && strokeIndex == completedStrokeCount;
      final glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = guideWidth * (1.3 - (_successProgress * 0.16))
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
        ..color = AppColors.fingerTracing.withValues(
          alpha: (isCurrentStroke ? 0.14 : 0.10) * fade,
        );
      final guidePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = guideWidth * (1 - (_successProgress * 0.10))
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.fingerTracing.withValues(
          alpha: (isCurrentStroke ? 0.26 : 0.18) * fade,
        );
      final path = layout.strokePaths[strokeIndex];
      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, guidePaint);
    }
  }

  void _paintCheckpoints(Canvas canvas) {
    final fade = 1 - _successProgress;
    final remainingPaint = Paint()
      ..color = AppColors.fingerTracing.withValues(alpha: 0.10 * fade);
    final currentStrokePaint = Paint()
      ..color = AppColors.fingerTracing.withValues(alpha: 0.18 * fade);
    final hitPaint = Paint()
      ..color = AppColors.fingerTracing.withValues(alpha: 0.34 * fade);
    final cueGlowPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final cueCorePaint = Paint();
    final cueSparkPaint = Paint();

    for (
      var strokeIndex = 0;
      strokeIndex < layout.strokes.length;
      strokeIndex++
    ) {
      final stroke = layout.strokes[strokeIndex];
      final completedCheckpoints = strokeIndex < completedStrokeCount
          ? stroke.checkpoints.length
          : strokeIndex == completedStrokeCount && hasCurrentStroke
          ? activeCheckpointCount
          : 0;

      for (
        var checkpointIndex = 0;
        checkpointIndex < stroke.checkpoints.length;
        checkpointIndex++
      ) {
        final isHit = checkpointIndex < completedCheckpoints;
        final baseRadius = checkpointIndex == 0
            ? layout.startDotRadius
            : layout.checkpointRadius;
        final pulseStrength = _checkpointPulse(
          checkpointIndex,
          stroke.checkpoints.length,
          strokeIndex,
        );
        canvas.drawCircle(
          stroke.checkpoints[checkpointIndex],
          baseRadius,
          isHit
              ? hitPaint
              : strokeIndex == completedStrokeCount && !success
              ? currentStrokePaint
              : remainingPaint,
        );

        if (pulseStrength <= 0 || fade <= 0) {
          continue;
        }

        cueGlowPaint.color = AppColors.fingerTracingLight.withValues(
          alpha: (0.18 + (pulseStrength * 0.22)) * fade,
        );
        cueCorePaint.color = AppColors.fingerTracing.withValues(
          alpha: (0.28 + (pulseStrength * 0.50)) * fade,
        );
        cueSparkPaint.color = Colors.white.withValues(
          alpha: (0.75 + (pulseStrength * 0.20)) * fade,
        );
        final checkpoint = stroke.checkpoints[checkpointIndex];
        canvas.drawCircle(
          checkpoint,
          baseRadius * (1.5 + (pulseStrength * 0.8)),
          cueGlowPaint,
        );
        canvas.drawCircle(
          checkpoint,
          baseRadius * (0.9 + (pulseStrength * 0.35)),
          cueCorePaint,
        );
        canvas.drawCircle(checkpoint, baseRadius * 0.34, cueSparkPaint);
      }
    }
  }

  void _paintPlayerStrokes(Canvas canvas) {
    final strokePaint = Paint()
      ..color = AppColors.fingerTracingDark.withValues(
        alpha: 1 - _successProgress,
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = layout.playerStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final stroke in strokes) {
      if (stroke.isEmpty) {
        continue;
      }

      if (stroke.length == 1) {
        canvas.drawCircle(
          stroke.first,
          layout.playerStrokeWidth / 2,
          Paint()
            ..color = AppColors.fingerTracingDark.withValues(
              alpha: 1 - _successProgress,
            ),
        );
        continue;
      }

      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final point in stroke.skip(1)) {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, strokePaint);
    }
  }

  bool get _showGuideCue =>
      !success &&
      !isTracingGesture &&
      completedStrokeCount < layout.strokes.length;

  double _checkpointPulse(
    int checkpointIndex,
    int checkpointCount,
    int strokeIndex,
  ) {
    if (!_showGuideCue ||
        strokeIndex != completedStrokeCount ||
        checkpointCount == 0) {
      return 0;
    }

    final cueStartCheckpointIndex =
        hasCurrentStroke && activeCheckpointCount > 0
        ? (activeCheckpointCount - 1).clamp(0, checkpointCount - 1).toInt()
        : 0;
    return computeFingerTracingCheckpointPulse(
      checkpointIndex: checkpointIndex,
      checkpointCount: checkpointCount,
      cueStartCheckpointIndex: cueStartCheckpointIndex,
      guideValue: guideAnimation.value,
    );
  }

  @override
  bool shouldRepaint(covariant _TracingBoardPainter oldDelegate) {
    return layout != oldDelegate.layout ||
        character != oldDelegate.character ||
        strokes != oldDelegate.strokes ||
        completedStrokeCount != oldDelegate.completedStrokeCount ||
        activeCheckpointCount != oldDelegate.activeCheckpointCount ||
        hasCurrentStroke != oldDelegate.hasCurrentStroke ||
        isTracingGesture != oldDelegate.isTracingGesture ||
        success != oldDelegate.success ||
        guideAnimation != oldDelegate.guideAnimation ||
        successAnimation != oldDelegate.successAnimation;
  }
}
