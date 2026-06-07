import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Subtle film-grain texture, the Flutter stand-in for the prototype's SVG
/// fractal-noise overlay. Scatters many tiny semi-transparent dots with a fixed
/// seed so the pattern is stable and never repaints.
///
/// Drop it into a [Stack] above a colored surface with [Positioned.fill].
class GrainOverlay extends StatelessWidget {
  const GrainOverlay({super.key, this.opacity = 0.05, this.dark = true});

  /// Overall strength of the texture.
  final double opacity;

  /// Whether the grain dots are light (on dark fields) or dark (on light fields).
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _GrainPainter(opacity: opacity, dark: dark),
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter({required this.opacity, required this.dark});

  final double opacity;
  final bool dark;

  // One dot per this many square pixels — sparse enough to stay cheap.
  static const double _areaPerDot = 26;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rng = math.Random(7); // fixed seed → stable texture
    final base = dark ? Colors.white : Colors.black;
    final count = (size.width * size.height / _areaPerDot).clamp(0, 6000).toInt();
    final paint = Paint();

    for (var i = 0; i < count; i++) {
      final dx = rng.nextDouble() * size.width;
      final dy = rng.nextDouble() * size.height;
      // Vary each dot's alpha a little so the grain reads as noise, not a grid.
      paint.color = base.withValues(alpha: opacity * (0.4 + rng.nextDouble()));
      canvas.drawRect(Rect.fromLTWH(dx, dy, 1, 1), paint);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter old) =>
      old.opacity != opacity || old.dark != dark;
}
