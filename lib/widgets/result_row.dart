import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../theme/app_theme.dart';
import '../theme/text_styles.dart';
import '../utils/format.dart';
import 'app_icons.dart';
import 'color_field.dart';

/// One search result / suggestion row: index, color-field thumb, title + meta,
/// rating, and a saved marker.
class ResultRow extends StatelessWidget {
  const ResultRow({
    super.key,
    required this.item,
    required this.index,
    required this.saved,
    this.onTap,
  });

  final MediaItem item;
  final int index;
  final bool saved;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final meta = [
      item.type.label,
      if (item.year != null) '${item.year}',
      if (item.metaShort != null) item.metaShort!,
    ].join(' · ');

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                pad2(index),
                style: AppFonts.mono(size: 10, letterSpacing: 0.6, color: c.mut),
              ),
            ),
            const SizedBox(width: 13),
            ColorFieldThumb(
              color: item.color ?? c.panel2,
              letter: item.title.isEmpty ? '?' : item.title[0],
              width: 42,
              height: 58,
              fontSize: 22,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.display(
                      size: 15,
                      weight: FontWeight.w700,
                      letterSpacing: -0.15,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    meta.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.mono(size: 10, letterSpacing: 0.7, color: c.mut),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 13),
            Text(
              '★${item.rating.toStringAsFixed(1)}',
              style: AppFonts.mono(
                size: 11,
                weight: FontWeight.w700,
                color: c.accent,
              ),
            ),
            if (saved) ...[
              const SizedBox(width: 13),
              AppIcon(AppIconKind.bookmark, filled: true, size: 14, color: c.accent),
            ],
          ],
        ),
      ),
    );
  }
}
