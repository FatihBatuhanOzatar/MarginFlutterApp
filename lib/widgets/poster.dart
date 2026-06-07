import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../theme/app_theme.dart';
import '../theme/grain.dart';
import '../theme/text_styles.dart';
import '../utils/format.dart';
import 'app_icons.dart';

/// Editorial poster card — the hybrid of the prototype and real data: the actual
/// TMDB poster fills the card (with the title's dominant color as the loading /
/// fallback field), and the original wash + typography (index, type, title,
/// meta) is layered on top. Text is always light over a darkening wash so it
/// stays legible regardless of the photo.
class Poster extends StatelessWidget {
  const Poster({
    super.key,
    required this.item,
    this.index,
    this.saved = false,
    this.bare = false,
    this.onTap,
  });

  final MediaItem item;

  /// 1-based editorial index shown top-left; null hides it (rail cards).
  final int? index;
  final bool saved;

  /// Rail variant: drop the bottom title/meta block (a caption sits below).
  final bool bare;
  final VoidCallback? onTap;

  static const Color _ink = Color(0xFFF2F0EA);

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final field = item.color ?? c.panel2;
    return GestureDetector(
      onTap: onTap,
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              _background(field),
              GrainOverlay(opacity: 0.04, dark: true),
              const _PosterWash(),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topRow(),
                    const Spacer(),
                    if (!bare) _bottomBlock(),
                  ],
                ),
              ),
              if (saved)
                Positioned(
                  top: 8,
                  right: 8,
                  child: AppIcon(AppIconKind.bookmark,
                      filled: true, size: 16, color: c.accent),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _background(Color field) {
    final url = item.posterUrl();
    if (url == null) return ColoredBox(color: field);
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => ColoredBox(color: field),
      errorWidget: (_, _, _) => ColoredBox(color: field),
    );
  }

  Widget _topRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          index != null ? pad2(index!) : '',
          style: AppFonts.mono(
            size: 11,
            weight: FontWeight.w700,
            letterSpacing: 1.1,
            color: _ink.withValues(alpha: 0.85),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: _ink.withValues(alpha: 0.4)),
          ),
          child: Text(
            item.type.label,
            style: AppFonts.mono(
              size: 8,
              letterSpacing: 1.12,
              color: _ink,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppFonts.display(
            size: 19,
            height: 0.92,
            letterSpacing: -0.38,
            color: _ink,
          ),
        ),
        const SizedBox(height: 6),
        _metaRow(),
      ],
    );
  }

  Widget _metaRow() {
    final style = AppFonts.mono(
      size: 10,
      letterSpacing: 0.5,
      color: _ink.withValues(alpha: 0.9),
    );
    final parts = <String>[
      if (item.year != null) '${item.year}',
      if (item.metaShort != null) item.metaShort!,
      '★${item.rating.toStringAsFixed(1)}',
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < parts.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(width: 7),
            Container(width: 3, height: 3, color: _ink.withValues(alpha: 0.7)),
            const SizedBox(width: 7),
          ],
          Text(parts[i], style: style),
        ],
      ],
    );
  }
}

/// The darkening overlay that keeps the white typography readable over any
/// poster: a faint diagonal sheen plus a stronger bottom-to-top scrim.
class _PosterWash extends StatelessWidget {
  const _PosterWash();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0x1AFFFFFF), Color(0x6B000000)],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x33000000), Color(0x00000000), Color(0x99000000)],
              stops: [0, 0.42, 1],
            ),
          ),
        ),
      ],
    );
  }
}
