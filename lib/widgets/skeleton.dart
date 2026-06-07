import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A panel-colored placeholder with a sweeping highlight, used while content
/// loads. Size it with [width]/[height] or an [aspectRatio].
class Skeleton extends StatefulWidget {
  const Skeleton({super.key, this.width, this.height, this.aspectRatio});

  final double? width;
  final double? height;
  final double? aspectRatio;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    Widget content = ClipRect(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          return Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: c.panel)),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Transform.translate(
                    offset: Offset((_controller.value * 2 - 1) * w, 0),
                    child: Container(
                      width: w,
                      height: constraints.maxHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            c.panel2,
                            Colors.transparent,
                          ],
                          stops: const [0.3, 0.5, 0.7],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );

    if (widget.aspectRatio != null) {
      content = AspectRatio(aspectRatio: widget.aspectRatio!, child: content);
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: content,
    );
  }
}

/// Poster-shaped skeleton (2:3) for the browse grid.
class SkeletonTile extends StatelessWidget {
  const SkeletonTile({super.key});

  @override
  Widget build(BuildContext context) => const Skeleton(aspectRatio: 2 / 3);
}
