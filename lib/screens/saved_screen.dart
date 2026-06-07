import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media_item.dart';
import '../models/saved_entry.dart';
import '../providers/saved_provider.dart';
import '../theme/app_theme.dart';
import '../theme/text_styles.dart';
import '../utils/format.dart';
import '../widgets/app_icons.dart';
import '../widgets/color_field.dart';
import '../widgets/empty_block.dart';

/// ARŞİV — the personal archive: a saved/noted stat header over the list of
/// collected titles, each with its curator note preview and a remove action.
/// Tapping a row reopens the detail page; the empty state invites the first save.
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key, required this.onOpen});

  final ValueChanged<MediaItem> onOpen;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final saved = context.watch<SavedProvider>();
    final entries = saved.entries;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topBar(c),
          _stats(c, entries.length, saved.notedCount),
          if (entries.isEmpty)
            const EmptyBlock(
              glyph: '▢',
              title: 'Arşiv boş',
              sub: 'Bir başlığı koleksiyona ekle, kendi notunu bırak.',
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < entries.length; i++)
                    _ArchRow(
                      entry: entries[i],
                      index: i + 1,
                      isLast: i == entries.length - 1,
                      onOpen: () => onOpen(entries[i].item),
                      onRemove: () => saved.remove(entries[i].item.id),
                    ),
                ],
              ),
            ),
          _footer(c),
        ],
      ),
    );
  }

  Widget _topBar(MarginColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ARŞİV',
            style: AppFonts.display(
              size: 30,
              letterSpacing: -0.9,
              height: 0.85,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'SENİN KOLEKSİYONUN',
            style: AppFonts.mono(size: 9.5, letterSpacing: 2.47, color: c.mut),
          ),
        ],
      ),
    );
  }

  /// Two counters (saved / noted) sharing a [c.line] backdrop so a 1px gap
  /// between the cells and a 1px border draw the hairline rules.
  Widget _stats(MarginColors c, int saved, int noted) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(color: c.line, border: Border.all(color: c.line)),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _statCell(c, pad2(saved), 'KAYITLI')),
            const SizedBox(width: 1),
            Expanded(child: _statCell(c, pad2(noted), 'NOTLU')),
          ],
        ),
      ),
    );
  }

  Widget _statCell(MarginColors c, String value, String label) {
    return ColoredBox(
      color: c.bg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppFonts.display(
                size: 32,
                weight: FontWeight.w800,
                height: 0.85,
                letterSpacing: -0.64,
                color: c.ink,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: AppFonts.mono(size: 9.5, letterSpacing: 1.9, color: c.mut),
            ),
          ],
        ),
      ),
    );
  }

  Widget _footer(MarginColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 18),
      child: Text(
        'TMDB · THE MOVIE DATABASE',
        textAlign: TextAlign.center,
        style: AppFonts.mono(
          size: 9.5,
          letterSpacing: 1.71,
          color: c.mut.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

/// One archive row: index, color-field thumb, title + meta + note preview, and a
/// remove button. A top rule separates every row; the last one closes the list
/// with a bottom rule too.
class _ArchRow extends StatelessWidget {
  const _ArchRow({
    required this.entry,
    required this.index,
    required this.isLast,
    required this.onOpen,
    required this.onRemove,
  });

  final SavedEntry entry;
  final int index;
  final bool isLast;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final item = entry.item;
    final hasNote = entry.note.trim().isNotEmpty;
    final meta = [
      item.type.label,
      if (item.year != null) '${item.year}',
      if (item.metaShort != null) item.metaShort!,
      '★${item.rating.toStringAsFixed(1)}',
    ].join(' · ');

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.line),
          bottom: isLast ? BorderSide(color: c.line) : BorderSide.none,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onOpen,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        pad2(index),
                        style: AppFonts.mono(
                          size: 10,
                          letterSpacing: 0.6,
                          color: c.mut,
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    ColorFieldThumb(
                      color: item.color ?? c.panel2,
                      letter: item.title.isEmpty ? '?' : item.title[0],
                      width: 48,
                      height: 66,
                      fontSize: 24,
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
                              size: 16,
                              weight: FontWeight.w700,
                              letterSpacing: -0.16,
                              color: c.ink,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            meta.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.mono(
                              size: 10,
                              letterSpacing: 0.8,
                              color: c.mut,
                            ),
                          ),
                          const SizedBox(height: 5),
                          if (hasNote)
                            Text(
                              '“${entry.note.trim()}”',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppFonts.body(
                                size: 13.5,
                                height: 1.5,
                                fontStyle: FontStyle.italic,
                                color: c.ink.withValues(alpha: 0.9),
                              ),
                            )
                          else
                            Text(
                              '— not eklenmedi —',
                              style: AppFonts.mono(
                                size: 10,
                                letterSpacing: 0.8,
                                color: c.mut.withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 15),
              child: AppIcon(AppIconKind.close, size: 16, color: c.mut),
            ),
          ),
          ],
        ),
      ),
    );
  }
}
