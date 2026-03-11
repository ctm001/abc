import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../game_colors.dart';

/// Celebration overlay with randomised animations.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({required this.onComplete, super.key});

  final VoidCallback onComplete;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late int _type;

  @override
  void initState() {
    super.initState();
    _type = Random().nextInt(4);
    _ctrl = AnimationController(
      duration: GameTimings.celebrationScale,
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    _ctrl.forward();
    Future.delayed(GameTimings.celebrationAutoAdvance, () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onComplete,
          child: Container(color: Colors.black.withValues(alpha: 0.3)),
        ),
        _buildAnimation(),
        Center(
          child: ScaleTransition(
            scale: _scale,
            child: GestureDetector(
              onTap: widget.onComplete,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.success, Color(0xFF3DBD6B)],
                  ),
                  borderRadius: BorderRadius.circular(
                    GameDimensions.borderRadius,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.6),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 64,
                      color: AppColors.rewardGold,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Riktig!',
                      style: GoogleFonts.aBeeZee(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        shadows: [
                          const Shadow(
                            color: Color(0x40000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
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

  Widget _buildAnimation() {
    return switch (_type) {
      0 => const _Confetti(),
      1 => const _StarsBurst(),
      2 => const _FloatingHearts(),
      _ => const _Sparkles(),
    };
  }
}

// -- Confetti ------------------------------------------------

class _Confetti extends StatefulWidget {
  const _Confetti();

  @override
  State<_Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<_Confetti> {
  late ConfettiController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = ConfettiController(duration: GameTimings.celebrationEffect)..play();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _ctrl,
        blastDirectionality: BlastDirectionality.explosive,
        shouldLoop: false,
        colors: AppColors.confetti,
        numberOfParticles: 30,
        gravity: 0.3,
      ),
    );
  }
}

// -- Stars burst ---------------------------------------------

class _StarsBurst extends StatefulWidget {
  const _StarsBurst();

  @override
  State<_StarsBurst> createState() => _StarsBurstState();
}

class _StarsBurstState extends State<_StarsBurst>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _stars = <_Particle>[];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: GameTimings.celebrationEffect,
      vsync: this,
    );
    final rng = Random();
    for (var i = 0; i < 12; i++) {
      _stars.add(
        _Particle(
          angle: (i * 30) * pi / 180,
          color: AppColors.confetti[i % AppColors.confetti.length],
          delay: rng.nextDouble() * 0.2,
        ),
      );
    }
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          children: _stars.map((s) {
            final p = (_ctrl.value - s.delay).clamp(0.0, 1.0);
            final d = p * 150;
            return Positioned(
              left: sz.width / 2 + cos(s.angle) * d - 15,
              top: sz.height / 2 + sin(s.angle) * d - 15,
              child: Opacity(
                opacity: (1 - p).clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: 1 + p * 0.5,
                  child: Icon(Icons.star, color: s.color, size: 30),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// -- Floating hearts -----------------------------------------

class _FloatingHearts extends StatefulWidget {
  const _FloatingHearts();

  @override
  State<_FloatingHearts> createState() => _FloatingHeartsState();
}

class _FloatingHeartsState extends State<_FloatingHearts>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _hearts = <_HeartParticle>[];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: GameTimings.celebrationEffect,
      vsync: this,
    );
    final rng = Random();
    for (var i = 0; i < 15; i++) {
      _hearts.add(
        _HeartParticle(
          startX: rng.nextDouble(),
          delay: rng.nextDouble() * 0.3,
          speed: 0.5 + rng.nextDouble() * 0.5,
          wobble: rng.nextDouble() * 20 - 10,
          color: [
            Colors.red,
            Colors.pink,
            Colors.pinkAccent,
            AppColors.confetti[0],
          ][rng.nextInt(4)],
        ),
      );
    }
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          children: _hearts.map((h) {
            final p = ((_ctrl.value - h.delay) * h.speed).clamp(0.0, 1.0);
            final y = sz.height - (p * sz.height * 0.8);
            final x = h.startX * sz.width + sin(p * pi * 2) * h.wobble;
            final o = p < 0.8 ? 1.0 : (1 - (p - 0.8) * 5).clamp(0.0, 1.0);
            return Positioned(
              left: x - 15,
              top: y,
              child: Opacity(
                opacity: o,
                child: Transform.scale(
                  scale: 0.5 + p * 0.5,
                  child: Icon(Icons.favorite, color: h.color, size: 30),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// -- Sparkles ------------------------------------------------

class _Sparkles extends StatefulWidget {
  const _Sparkles();

  @override
  State<_Sparkles> createState() => _SparklesState();
}

class _SparklesState extends State<_Sparkles>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _sparks = <_Particle>[];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: GameTimings.celebrationEffect,
      vsync: this,
    );
    final rng = Random();
    for (var i = 0; i < 20; i++) {
      _sparks.add(
        _Particle(
          angle: rng.nextDouble() * 2 * pi,
          color: AppColors.confetti[rng.nextInt(AppColors.confetti.length)],
          delay: rng.nextDouble() * 0.5,
          x: rng.nextDouble(),
          y: rng.nextDouble(),
        ),
      );
    }
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          children: _sparks.map((s) {
            final p = ((_ctrl.value - s.delay) * 2).clamp(0.0, 1.0);
            final sc = p < 0.5 ? p * 2 : (1 - p) * 2;
            return Positioned(
              left: s.x * sz.width - 20,
              top: s.y * sz.height - 20,
              child: Opacity(
                opacity: sc.clamp(0.0, 1.0),
                child: Transform.rotate(
                  angle: p * pi * 2,
                  child: Transform.scale(
                    scale: sc.clamp(0.3, 1.0),
                    child: Icon(Icons.auto_awesome, color: s.color, size: 40),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// -- Particle data -------------------------------------------

class _Particle {
  const _Particle({
    required this.angle,
    required this.color,
    required this.delay,
    this.x = 0,
    this.y = 0,
  });

  final double angle;
  final Color color;
  final double delay;
  final double x;
  final double y;
}

class _HeartParticle {
  const _HeartParticle({
    required this.startX,
    required this.delay,
    required this.speed,
    required this.wobble,
    required this.color,
  });

  final double startX;
  final double delay;
  final double speed;
  final double wobble;
  final Color color;
}
