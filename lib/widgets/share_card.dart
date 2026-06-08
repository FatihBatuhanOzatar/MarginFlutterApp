import 'package:flutter/material.dart';

import '../models/media_item.dart';
import '../models/rank_list.dart';
import '../theme/app_theme.dart';
import '../theme/grain.dart';
import '../theme/text_styles.dart';
import '../utils/format.dart';

/// Logical width of a share card; the capture step scales it up via pixelRatio.
const double kShareCardWidth = 360;

/// Brand chrome (wordmark header, kicker, grain, footer) wrapped around the
/// share-card body. Themed by the current palette so it matches the app.
class _CardFrame extends StatelessWidget {
  const _CardFrame({required this.kicker, required this.child});

  final String kicker;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    return Container(
      width: kShareCardWidth,
      color: c.bg,
      child: Stack(
        children: [
          Positioned.fill(child: GrainOverlay(opacity: 0.05, dark: true)),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'MARGIN',
                      style: AppFonts.display(
                          size: 20, letterSpacing: -0.6, color: c.ink),
                    ),
                    Text(
                      kicker,
                      style:
                          AppFonts.mono(size: 8.5, letterSpacing: 2, color: c.mut),
                    ),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  height: 1,
                  color: c.line,
                ),
                child,
                const SizedBox(height: 18),
                Text(
                  'THE MOVIE DATABASE · TMDB',
                  style: AppFonts.mono(
                    size: 8,
                    letterSpacing: 1.6,
                    color: c.mut.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A shareable image of a ranked list: name + the top entries with their ranks.
class ListShareCard extends StatelessWidget {
  const ListShareCard({super.key, required this.list});

  final RankList list;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final top = list.items.take(8).toList();
    return _CardFrame(
      kicker: 'KİŞİSEL SIRALAMA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            list.name,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.display(
                size: 30, height: 0.95, letterSpacing: -0.8, color: c.ink),
          ),
          const SizedBox(height: 5),
          Text(
            '${pad2(list.items.length)} BAŞLIK',
            style: AppFonts.mono(size: 9, letterSpacing: 1.5, color: c.mut),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < top.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(
                    width: 30,
                    child: Text(
                      pad2(i + 1),
                      style: AppFonts.display(
                        size: 17,
                        weight: FontWeight.w800,
                        color: i == 0 ? c.accent : c.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      top[i].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.display(
                        size: 17,
                        weight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: c.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '★${top[i].rating.toStringAsFixed(1)}',
                    style: AppFonts.mono(
                        size: 10, weight: FontWeight.w700, color: c.accent),
                  ),
                ],
              ),
            ),
          if (list.items.length > top.length)
            Text(
              '+${list.items.length - top.length} DAHA',
              style: AppFonts.mono(size: 9, letterSpacing: 1.2, color: c.mut),
            ),
        ],
      ),
    );
  }
}

/// A shareable image of a curator note: the title, meta, and the note itself.
class NoteShareCard extends StatelessWidget {
  const NoteShareCard({super.key, required this.item, required this.note});

  final MediaItem item;
  final String note;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final meta = [
      item.type.label,
      if (item.year != null) '${item.year}',
      '★${item.rating.toStringAsFixed(1)}',
    ].join(' · ');
    return _CardFrame(
      kicker: 'KENAR NOTU',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppFonts.display(
                size: 30, height: 0.95, letterSpacing: -0.8, color: c.ink),
          ),
          const SizedBox(height: 6),
          Text(
            meta.toUpperCase(),
            style: AppFonts.mono(size: 9, letterSpacing: 1.3, color: c.mut),
          ),
          const SizedBox(height: 18),
          Text(
            '“${note.trim()}”',
            style: AppFonts.body(
              size: 17,
              height: 1.55,
              fontStyle: FontStyle.italic,
              color: c.ink.withValues(alpha: 0.92),
            ),
          ),
        ],
      ),
    );
  }
}
