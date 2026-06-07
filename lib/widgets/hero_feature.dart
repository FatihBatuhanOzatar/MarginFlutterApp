import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media_item.dart';
import '../services/palette_cache.dart';
import '../theme/app_theme.dart';
import '../theme/grain.dart';
import '../theme/palettes.dart';
import '../theme/text_styles.dart';
import 'app_icons.dart';

/// The editorial "ÖNE ÇIKAN" spotlight: the top-rated titles, auto-rotating
/// every ~5s with tappable position dots. Its field is the title's dominant
/// color (falling back to the backdrop image until color extraction runs).
class HeroFeature extends StatefulWidget {
  const HeroFeature({super.key, required this.items, required this.onOpen});

  final List<MediaItem> items;
  final ValueChanged<MediaItem> onOpen;

  @override
  State<HeroFeature> createState() => _HeroFeatureState();
}

class _HeroFeatureState extends State<HeroFeature> {
  static const _interval = Duration(milliseconds: 5200);

  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(HeroFeature old) {
    super.didUpdateWidget(old);
    if (_index >= widget.items.length) _index = 0;
    _restart();
  }

  void _restart() {
    _timer?.cancel();
    if (widget.items.length < 2) return;
    _timer = Timer.periodic(_interval, (_) {
      setState(() => _index = (_index + 1) % widget.items.length);
    });
  }

  void _select(int i) {
    setState(() => _index = i);
    _restart();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final c = context.margin;
    final item = widget.items[_index];
    final color = context.select<PaletteCache, Color?>((p) => p.colorFor(item));
    final ink = color != null ? inkOn(color) : kInkLight;

    return Container(
      height: 306,
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(border: Border.all(color: c.line)),
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 450),
              child: _Slide(
                key: ValueKey(item.id),
                item: item,
                color: color,
                ink: ink,
                onOpen: () => widget.onOpen(item),
              ),
            ),
            if (widget.items.length > 1)
              Positioned(
                right: 18,
                bottom: 18,
                child: Row(
                  children: [
                    for (var i = 0; i < widget.items.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _select(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: i == _index ? 26 : 16,
                          height: 3,
                          color: ink.withValues(alpha: i == _index ? 1 : 0.3),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    super.key,
    required this.item,
    required this.color,
    required this.ink,
    required this.onOpen,
  });

  final MediaItem item;

  /// Extracted dominant color (null until ready → backdrop fallback).
  final Color? color;
  final Color ink;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final field = color ?? context.margin.panel;
    final meta = [
      item.type.label,
      if (item.year != null) '${item.year}',
      if (item.metaShort != null) item.metaShort!,
    ].join(' · ');

    return Stack(
      fit: StackFit.expand,
      children: [
        _background(field),
        GrainOverlay(opacity: 0.05, dark: ink == kInkLight),
        _wash(field, color != null),
        Positioned(
          top: 15,
          right: 15,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: ink.withValues(alpha: 0.45)),
            ),
            child: Text(
              '★ ${item.rating.toStringAsFixed(1)}',
              style: AppFonts.mono(
                size: 10,
                weight: FontWeight.w700,
                letterSpacing: 0.8,
                color: ink,
              ),
            ),
          ),
        ),
        Positioned(
          left: 18,
          right: 18,
          bottom: 18,
          child: _body(context, meta),
        ),
      ],
    );
  }

  Widget _background(Color field) {
    // Color extraction feeds the field; until then fall back to the backdrop.
    if (color != null) return ColoredBox(color: field);
    final url = item.backdropUrl();
    if (url == null) return ColoredBox(color: field);
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => ColoredBox(color: field),
      errorWidget: (_, _, _) => ColoredBox(color: field),
    );
  }

  Widget _wash(Color field, bool hasColor) {
    final bottom = hasColor ? field : Colors.black;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-0.9, -0.4),
              end: Alignment(1, 0.4),
              colors: [Color(0x99000000), Color(0x33000000), Color(0x00000000)],
              stops: [0, 0.55, 1],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [bottom, bottom.withValues(alpha: 0)],
              stops: const [0.02, 0.45],
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, String meta) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width * 0.84,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '◳ ÖNE ÇIKAN',
            style: AppFonts.mono(
              size: 9,
              letterSpacing: 2.34,
              color: ink.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.display(
              size: 38,
              height: 0.88,
              letterSpacing: -1.14,
              color: ink,
            ),
          ),
          if (item.overview.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text(
              item.overview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.body(
                size: 12.5,
                height: 1.45,
                color: ink.withValues(alpha: 0.85),
              ),
            ),
          ],
          const SizedBox(height: 9),
          Text(
            meta,
            style: AppFonts.mono(
              size: 10,
              letterSpacing: 1.2,
              color: ink.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 13),
          GestureDetector(
            onTap: onOpen,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(border: Border.all(color: ink)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'İNCELE',
                    style: AppFonts.mono(
                      size: 11,
                      weight: FontWeight.w700,
                      letterSpacing: 1.76,
                      color: ink,
                    ),
                  ),
                  const SizedBox(width: 9),
                  AppIcon(AppIconKind.arrow, size: 15, color: ink),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
