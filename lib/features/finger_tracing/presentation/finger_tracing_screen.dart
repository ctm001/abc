import 'dart:async';

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
                            return SizedBox(
                              width: constraints.maxWidth,
                              child: AspectRatio(
                                aspectRatio: 0.92,
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
      child: Row(
        children: [
          GestureDetector(
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
          const SizedBox(width: 16),
          Expanded(
            child: IgnorePointer(
              child: Text(
                'Spor bokstavene',
                style: GoogleFonts.aBeeZee(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),
        ],
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

class _TracingCardState extends State<_TracingCard>
    with TickerProviderStateMixin {
  late final AnimationController _guideController;
  late final AnimationController _successController;
  late final Animation<double> _successCurve;
  FingerTracingLayout? _layout;
  Size? _lastSize;
  final List<List<Offset>> _completedStrokes = <List<Offset>>[];
  List<Offset>? _activeStroke;
  int _nextStrokeIndex = 0;
  int _committedCheckpointCount = 0;
  int _activeCheckpointCount = 0;

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
                          hasActiveStroke: _activeStroke != null,
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
        _activeStroke != null ||
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
    if ((stroke.startDot - clampedPoint).distance > layout.startHitRadius) {
      return;
    }

    setState(() {
      _activeStroke = <Offset>[stroke.startDot];
      _activeCheckpointCount = 0;
      _captureStrokePoint(clampedPoint, stroke, layout);
    });
  }

  void _appendStroke(Offset point) {
    final layout = _layout;
    final activeStroke = _activeStroke;
    if (layout == null ||
        activeStroke == null ||
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
    if (layout == null || _activeStroke == null) {
      return;
    }

    setState(() {
      _cancelActiveStroke(layout);
    });
  }

  void _captureStrokePoint(
    Offset point,
    FingerTracingStrokeLayout stroke,
    FingerTracingLayout layout,
  ) {
    final activeStroke = _activeStroke;
    if (activeStroke == null) {
      return;
    }

    if (!_isNearStrokePath(point, stroke, layout.pathTolerance)) {
      _cancelActiveStroke(layout);
      return;
    }

    final previousPoint = activeStroke.last;
    if ((point - previousPoint).distance > 0.5) {
      activeStroke.add(point);
    }
    _advanceCheckpoints(previousPoint, point, stroke, layout);

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
      final radius = checkpointIndex == stroke.checkpoints.length - 1
          ? layout.finalCheckpointHitRadius
          : layout.hitRadius;
      if (!_segmentHitsCheckpoint(start, end, checkpoint, radius)) {
        break;
      }
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

    _completedStrokes.add(List<Offset>.from(activeStroke));
    _committedCheckpointCount += stroke.checkpoints.length;
    _nextStrokeIndex++;
    _activeStroke = null;
    _activeCheckpointCount = 0;
    _restartGuideCue();
    _updateCoverage(layout);
  }

  void _cancelActiveStroke(FingerTracingLayout layout) {
    _activeStroke = null;
    _activeCheckpointCount = 0;
    _restartGuideCue();
    _updateCoverage(layout);
  }

  void _resetTraceProgress() {
    _completedStrokes.clear();
    _activeStroke = null;
    _nextStrokeIndex = 0;
    _committedCheckpointCount = 0;
    _activeCheckpointCount = 0;
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

  List<List<Offset>> get _paintedStrokes {
    final activeStroke = _activeStroke;
    if (activeStroke == null) {
      return _completedStrokes;
    }
    return [..._completedStrokes, activeStroke];
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
      child: Text(
        character,
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

class _TracingBoardPainter extends CustomPainter {
  _TracingBoardPainter({
    required this.character,
    required this.layout,
    required this.strokes,
    required this.completedStrokeCount,
    required this.activeCheckpointCount,
    required this.hasActiveStroke,
    required this.success,
    required this.guideAnimation,
    required this.successAnimation,
  }) : super(repaint: Listenable.merge([guideAnimation, successAnimation]));

  final String character;
  final FingerTracingLayout layout;
  final List<List<Offset>> strokes;
  final int completedStrokeCount;
  final int activeCheckpointCount;
  final bool hasActiveStroke;
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
    final guideWidth = layout.guideStrokeWidth * 1.3;
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
          : strokeIndex == completedStrokeCount && hasActiveStroke
          ? activeCheckpointCount
          : 0;

      for (
        var checkpointIndex = 0;
        checkpointIndex < stroke.checkpoints.length;
        checkpointIndex++
      ) {
        final isHit = checkpointIndex < completedCheckpoints;
        final pulseStrength = isHit
            ? 0.0
            : _checkpointPulse(
                checkpointIndex,
                stroke.checkpoints.length,
                strokeIndex,
              );
        canvas.drawCircle(
          stroke.checkpoints[checkpointIndex],
          layout.checkpointRadius,
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
          layout.checkpointRadius * (1.5 + (pulseStrength * 0.8)),
          cueGlowPaint,
        );
        canvas.drawCircle(
          checkpoint,
          layout.checkpointRadius * (0.9 + (pulseStrength * 0.35)),
          cueCorePaint,
        );
        canvas.drawCircle(
          checkpoint,
          layout.checkpointRadius * 0.34,
          cueSparkPaint,
        );
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
      !hasActiveStroke &&
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

    final sequencePosition = guideAnimation.value * (checkpointCount + 1.4);
    final distanceFromLead = (checkpointIndex - sequencePosition).abs();
    final pulse = (1 - (distanceFromLead / 1.15)).clamp(0.0, 1.0).toDouble();
    return Curves.easeOut.transform(pulse);
  }

  @override
  bool shouldRepaint(covariant _TracingBoardPainter oldDelegate) {
    return layout != oldDelegate.layout ||
        character != oldDelegate.character ||
        strokes != oldDelegate.strokes ||
        completedStrokeCount != oldDelegate.completedStrokeCount ||
        activeCheckpointCount != oldDelegate.activeCheckpointCount ||
        hasActiveStroke != oldDelegate.hasActiveStroke ||
        success != oldDelegate.success ||
        guideAnimation != oldDelegate.guideAnimation ||
        successAnimation != oldDelegate.successAnimation;
  }
}
