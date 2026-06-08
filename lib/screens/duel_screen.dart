import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media_item.dart';
import '../providers/lists_provider.dart';
import '../theme/app_theme.dart';
import '../theme/palettes.dart';
import '../theme/text_styles.dart';
import '../utils/duel_ranker.dart';
import '../utils/format.dart';
import '../widgets/app_icons.dart';
import '../widgets/color_field.dart';

/// Route into the duel for a list's current [items].
Route<void> duelRoute(String listId, List<MediaItem> items) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (_, _, _) => DuelScreen(listId: listId, items: items),
    transitionsBuilder: (_, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// DÜELLO — ranks a list by repeatedly asking "which is better?". The user never
/// types a score; the [DuelRanker] turns their binary choices into a full order
/// and the result is written back to the list on completion.
class DuelScreen extends StatefulWidget {
  const DuelScreen({super.key, required this.listId, required this.items});

  final String listId;
  final List<MediaItem> items;

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> {
  late final DuelRanker<MediaItem> _ranker =
      DuelRanker<MediaItem>(List.of(widget.items));
  bool _saved = false;

  void _choose(MediaItem winner) {
    setState(() => _ranker.choose(winner));
    if (_ranker.isDone && !_saved) {
      _saved = true;
      // Persist the new ranking once the duel completes.
      context.read<ListsProvider>().setOrder(widget.listId, _ranker.ranking);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    return Scaffold(
      body: SafeArea(
        child: _ranker.isDone ? _doneView(c) : _duelView(c),
      ),
    );
  }

  // --- Comparing ---

  Widget _duelView(MarginColors c) {
    final pair = _ranker.pair!;
    final total = _ranker.estimatedTotal;
    final progress =
        total == 0 ? 1.0 : (_ranker.comparisons / total).clamp(0.0, 1.0);

    return Column(
      children: [
        _topBar(c, 'DÜELLO'),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KARŞILAŞTIRMA ${pad2(_ranker.comparisons + 1)}',
                    style: AppFonts.mono(
                        size: 9.5, letterSpacing: 1.5, color: c.mut),
                  ),
                  Text(
                    '~${pad2(total)}',
                    style: AppFonts.mono(
                        size: 9.5, letterSpacing: 1.5, color: c.mut),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                minHeight: 2,
                backgroundColor: c.line,
                color: c.accent,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'HANGİSİ DAHA İYİ?',
          style: AppFonts.display(size: 17, weight: FontWeight.w700, color: c.ink),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _DuelCard(item: pair.$1, onTap: () => _choose(pair.$1))),
                const SizedBox(width: 12),
                Expanded(child: _DuelCard(item: pair.$2, onTap: () => _choose(pair.$2))),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Result ---

  Widget _doneView(MarginColors c) {
    final ranking = _ranker.ranking;
    return Column(
      children: [
        _topBar(c, 'SIRALAMA HAZIR'),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${_ranker.comparisons} KARŞILAŞTIRMA · ${pad2(ranking.length)} BAŞLIK',
              style: AppFonts.mono(size: 9.5, letterSpacing: 1.5, color: c.mut),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            children: [
              for (var i = 0; i < ranking.length; i++)
                _rankRow(c, i, ranking[i]),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
          child: GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration:
                  BoxDecoration(color: c.accent, border: Border.all(color: c.accent)),
              child: Center(
                child: Text(
                  'LİSTEYE DÖN',
                  style: AppFonts.mono(
                    size: 12,
                    weight: FontWeight.w700,
                    letterSpacing: 1.92,
                    color: c.accentInk,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _rankRow(MarginColors c, int i, MediaItem item) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text(
                pad2(i + 1),
                style: AppFonts.display(
                  size: 18,
                  weight: FontWeight.w800,
                  color: i == 0 ? c.accent : c.ink,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ColorFieldThumb(
              color: c.panel2,
              letter: item.title.isEmpty ? '?' : item.title[0],
              imageUrl: item.posterUrl(size: 'w185'),
              width: 34,
              height: 48,
              fontSize: 16,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppFonts.display(
                    size: 16, weight: FontWeight.w700, color: c.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(MarginColors c, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppFonts.display(
                size: 22, weight: FontWeight.w700, letterSpacing: -0.4, color: c.ink),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: c.line2)),
              child: AppIcon(AppIconKind.close, size: 16, color: c.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// A full-bleed duel option: the poster fills the card, a bottom scrim keeps the
/// title legible, and the whole thing is tappable to pick this title.
class _DuelCard extends StatelessWidget {
  const _DuelCard({required this.item, required this.onTap});

  final MediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final url = item.posterUrl(size: 'w500');
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: c.line2)),
        child: ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: c.panel2),
              if (url != null)
                CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => ColoredBox(color: c.panel2),
                  errorWidget: (_, _, _) => ColoredBox(color: c.panel2),
                ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xD9000000)],
                    stops: [0.42, 1],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.display(
                        size: 18,
                        height: 0.95,
                        letterSpacing: -0.4,
                        color: kInkLight,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '★ ${item.rating.toStringAsFixed(1)}',
                      style: AppFonts.mono(
                        size: 10,
                        letterSpacing: 0.6,
                        color: const Color(0xCCFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
