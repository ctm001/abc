import 'package:flutter/material.dart';

import '../../game_colors.dart';

/// Reward overlay shown after completing all 29 letters.
class GoldCoinOverlay extends StatefulWidget {
  const GoldCoinOverlay({required this.onDismiss, super.key});

  final VoidCallback onDismiss;

  @override
  State<GoldCoinOverlay> createState() => _GoldCoinOverlayState();
}

class _GoldCoinOverlayState extends State<GoldCoinOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: GameTimings.goldCoinScale,
      vsync: this,
    );
    _scale = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
    Future.delayed(GameTimings.goldCoinRevealDelay, () {
      if (mounted) {
        _ctrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: AnimatedBuilder(
            animation: _ctrl,
            builder: (context, child) {
              return Transform.scale(scale: _scale.value, child: child);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFD700),
                        Color(0xFFFFA500),
                        Color(0xFFFFD700),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFFB8860B),
                      width: 8,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      '\u2605',
                      style: TextStyle(fontSize: 80, color: Color(0xFFB8860B)),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'GRATULERER!',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD700),
                    shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '29 bokstaver!',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
