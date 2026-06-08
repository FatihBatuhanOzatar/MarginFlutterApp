import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/rank_list.dart';
import '../providers/lists_provider.dart';
import '../theme/app_theme.dart';
import '../theme/text_styles.dart';
import '../utils/format.dart';
import '../widgets/app_icons.dart';
import '../widgets/color_field.dart';
import '../widgets/empty_block.dart';
import '../widgets/list_name_dialog.dart';
import 'list_detail_screen.dart';

/// LİSTELER — the user's custom ranked lists. Each card previews its top titles;
/// tapping opens the list, and the header's + button creates a new one.
class ListsScreen extends StatelessWidget {
  const ListsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final lists = context.watch<ListsProvider>().lists;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topBar(context, c),
          if (lists.isEmpty)
            const EmptyBlock(
              glyph: '≣',
              title: 'Henüz liste yok',
              sub: 'Yeni bir liste aç, başlıkları kendi sıralamana göre diz.',
            )
          else
            for (final list in lists) _ListCard(list: list),
          _footer(c),
        ],
      ),
    );
  }

  Widget _topBar(BuildContext context, MarginColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LİSTELER',
                style: AppFonts.display(
                  size: 30,
                  letterSpacing: -0.9,
                  height: 0.85,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'KENDİ SIRALAMALARIN',
                style:
                    AppFonts.mono(size: 9.5, letterSpacing: 2.47, color: c.mut),
              ),
            ],
          ),
          GestureDetector(
            onTap: () => _createList(context),
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: c.line2)),
              child: AppIcon(AppIconKind.plus, size: 20, color: c.ink),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createList(BuildContext context) async {
    final name = await promptListName(context);
    if (name == null || !context.mounted) return;
    final list = await context.read<ListsProvider>().create(name);
    if (!context.mounted) return;
    await Navigator.of(context).push(listDetailRoute(list.id));
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

/// One list as a bordered card: name, title count, and a strip of up to five
/// poster thumbnails previewing the current ranking.
class _ListCard extends StatelessWidget {
  const _ListCard({required this.list});

  final RankList list;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(listDetailRoute(list.id)),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(border: Border.all(color: c.line2)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.display(
                      size: 19,
                      weight: FontWeight.w700,
                      letterSpacing: -0.2,
                      color: c.ink,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${pad2(list.items.length)} BAŞLIK',
                  style:
                      AppFonts.mono(size: 9.5, letterSpacing: 1.2, color: c.mut),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (list.items.isEmpty)
              Text(
                '— boş —',
                style: AppFonts.mono(
                  size: 10,
                  letterSpacing: 0.8,
                  color: c.mut.withValues(alpha: 0.6),
                ),
              )
            else
              Row(
                children: [
                  for (final item in list.items.take(5)) ...[
                    ColorFieldThumb(
                      color: c.panel2,
                      letter: item.title.isEmpty ? '?' : item.title[0],
                      imageUrl: item.posterUrl(size: 'w185'),
                      width: 38,
                      height: 54,
                      fontSize: 18,
                    ),
                    const SizedBox(width: 7),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }
}
