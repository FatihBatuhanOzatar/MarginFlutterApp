import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../theme/app_theme.dart';
import '../theme/text_styles.dart';
import 'poster.dart';
import 'section_line.dart';

/// Horizontal "YÜKSEK PUANLI" rail of bare poster cards, each with a small
/// caption (title + meta) beneath it and a "TÜMÜNÜ GÖR" action in the header.
class Rail extends StatelessWidget {
  const Rail({
    super.key,
    required this.title,
    required this.items,
    required this.isSaved,
    required this.onOpen,
    this.onMore,
  });

  final String title;
  final List<MediaItem> items;
  final bool Function(int id) isSaved;
  final ValueChanged<MediaItem> onOpen;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLine(
          label: title,
          trailing: onMore == null
              ? null
              : GestureDetector(
                  onTap: onMore,
                  child: Text(
                    'TÜMÜNÜ GÖR ›',
                    style: AppFonts.mono(
                      size: 9.5,
                      letterSpacing: 1.33,
                      color: c.mut,
                    ),
                  ),
                ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 11),
                _RailCard(
                  item: items[i],
                  saved: isSaved(items[i].id),
                  onOpen: () => onOpen(items[i]),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RailCard extends StatelessWidget {
  const _RailCard({
    required this.item,
    required this.saved,
    required this.onOpen,
  });

  final MediaItem item;
  final bool saved;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final meta = [
      if (item.metaShort != null) item.metaShort!,
      '★${item.rating.toStringAsFixed(1)}',
    ].join(' · ');

    return SizedBox(
      width: 128,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(border: Border.all(color: c.line2)),
            child: Poster(item: item, bare: true, saved: saved, onTap: onOpen),
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.display(
              size: 13,
              weight: FontWeight.w700,
              height: 1.05,
              letterSpacing: -0.13,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            meta.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.mono(size: 9.5, letterSpacing: 0.57, color: c.mut),
          ),
        ],
      ),
    );
  }
}
