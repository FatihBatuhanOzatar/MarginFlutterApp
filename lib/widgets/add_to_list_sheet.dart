import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media_item.dart';
import '../models/rank_list.dart';
import '../providers/lists_provider.dart';
import '../theme/app_theme.dart';
import '../theme/text_styles.dart';
import '../utils/format.dart';
import 'app_icons.dart';
import 'list_name_dialog.dart';

/// Bottom sheet to toggle [item] across the user's lists, or spin up a new list
/// (which the item is added to immediately). Used from the detail screen.
Future<void> showAddToListSheet(BuildContext context, MediaItem item) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => _AddToListSheet(item: item),
  );
}

class _AddToListSheet extends StatelessWidget {
  const _AddToListSheet({required this.item});

  final MediaItem item;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final lists = context.watch<ListsProvider>().lists;

    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        border: Border(top: BorderSide(color: c.line2)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Text(
                'LİSTEYE EKLE',
                style: AppFonts.mono(
                  size: 11,
                  weight: FontWeight.w700,
                  letterSpacing: 2,
                  color: c.ink,
                ),
              ),
            ),
            const SizedBox(height: 8),
            _newListRow(context, c),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final list in lists) _listRow(context, c, list),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _newListRow(BuildContext context, MarginColors c) {
    return GestureDetector(
      onTap: () async {
        final name = await promptListName(context);
        if (name == null || !context.mounted) return;
        final provider = context.read<ListsProvider>();
        final list = await provider.create(name);
        await provider.addItem(list.id, item);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            AppIcon(AppIconKind.plus, size: 16, color: c.accent),
            const SizedBox(width: 12),
            Text(
              'YENİ LİSTE OLUŞTUR',
              style: AppFonts.mono(
                size: 11,
                weight: FontWeight.w700,
                letterSpacing: 1.4,
                color: c.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listRow(BuildContext context, MarginColors c, RankList list) {
    final inList = list.containsItem(item.id);
    final provider = context.read<ListsProvider>();
    return GestureDetector(
      onTap: () => inList
          ? provider.removeItem(list.id, item.id)
          : provider.addItem(list.id, item),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.display(
                        size: 16, weight: FontWeight.w700, color: c.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${pad2(list.entries.length)} BAŞLIK',
                    style:
                        AppFonts.mono(size: 9.5, letterSpacing: 1, color: c.mut),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: inList ? c.accent : Colors.transparent,
                border: Border.all(color: inList ? c.accent : c.line2),
              ),
              child: inList
                  ? Text(
                      '✓',
                      style: AppFonts.mono(
                        size: 13,
                        weight: FontWeight.w700,
                        color: c.accentInk,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
