import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The prototype's hard-edged icon set, redrawn as [CustomPainter]s so they
/// match the original SVGs exactly: 24×24 grid, butt caps, miter joins, no
/// rounding. Stroke width is given in grid units and scales with [size].
enum AppIconKind { search, grid, bookmark, back, close, arrow, retry, alert, plus }

class AppIcon extends StatelessWidget {
  const AppIcon(
    this.kind, {
    super.key,
    this.size = 22,
    this.color,
    this.filled = false,
    this.strokeWidth = 1.6,
  });

  final AppIconKind kind;
  final double size;
  final Color? color;

  /// Only meaningful for [AppIconKind.bookmark]: solid vs. outline.
  final bool filled;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final resolved =
        color ?? IconTheme.of(context).color ?? const Color(0xFFF2F0EA);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _IconPainter(
          kind: kind,
          color: resolved,
          filled: filled,
          strokeWidth: strokeWidth,
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter({
    required this.kind,
    required this.color,
    required this.filled,
    required this.strokeWidth,
  });

  final AppIconKind kind;
  final Color color;
  final bool filled;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw on the prototype's 24-unit grid; scaling the canvas scales the
    // stroke too, exactly like a non-scaling-stroke-off SVG.
    canvas.scale(size.width / 24, size.height / 24);

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..strokeJoin = StrokeJoin.miter
      ..strokeMiterLimit = 10;
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    switch (kind) {
      case AppIconKind.search:
        canvas.drawCircle(const Offset(10.5, 10.5), 6.5, stroke);
        canvas.drawLine(const Offset(15.5, 15.5), const Offset(21, 21), stroke);
      case AppIconKind.grid:
        for (final o in const [
          Offset(3, 3),
          Offset(14, 3),
          Offset(3, 14),
          Offset(14, 14),
        ]) {
          canvas.drawRect(Rect.fromLTWH(o.dx, o.dy, 7, 7), stroke);
        }
      case AppIconKind.bookmark:
        final path = Path()
          ..moveTo(5, 3)
          ..lineTo(19, 3)
          ..lineTo(19, 22)
          ..lineTo(12, 16.5)
          ..lineTo(5, 22)
          ..close();
        canvas.drawPath(path, filled ? fill : stroke);
      case AppIconKind.back:
        canvas.drawPath(
          Path()
            ..moveTo(15, 4)
            ..lineTo(7, 12)
            ..lineTo(15, 20),
          stroke,
        );
      case AppIconKind.close:
        canvas.drawLine(const Offset(5, 5), const Offset(19, 19), stroke);
        canvas.drawLine(const Offset(19, 5), const Offset(5, 19), stroke);
      case AppIconKind.arrow:
        canvas.drawLine(const Offset(4, 12), const Offset(20, 12), stroke);
        canvas.drawPath(
          Path()
            ..moveTo(14, 6)
            ..lineTo(20, 12)
            ..lineTo(14, 18),
          stroke,
        );
      case AppIconKind.retry:
        // Near-full circle with a gap at the top-right, plus the corner arrow.
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(12, 12), radius: 8),
          _deg(70),
          _deg(300),
          false,
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(20, 3)
            ..lineTo(20, 8)
            ..lineTo(15, 8),
          stroke,
        );
      case AppIconKind.alert:
        canvas.drawPath(
          Path()
            ..moveTo(12, 3)
            ..lineTo(22, 20)
            ..lineTo(2, 20)
            ..close(),
          stroke,
        );
        canvas.drawLine(const Offset(12, 9), const Offset(12, 14), stroke);
        canvas.drawLine(
          const Offset(12, 17),
          const Offset(12, 17.4),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = color
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.butt,
        );
      case AppIconKind.plus:
        canvas.drawLine(const Offset(12, 5), const Offset(12, 19), stroke);
        canvas.drawLine(const Offset(5, 12), const Offset(19, 12), stroke);
    }
  }

  double _deg(double degrees) => degrees * math.pi / 180;

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.kind != kind ||
      old.color != color ||
      old.filled != filled ||
      old.strokeWidth != strokeWidth;
}
