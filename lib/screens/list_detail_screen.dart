import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media_item.dart';
import '../models/rank_list.dart';
import '../providers/lists_provider.dart';
import '../services/tmdb_api.dart';
import '../theme/app_theme.dart';
import '../theme/text_styles.dart';
import '../utils/format.dart';
import '../widgets/app_icons.dart';
import '../widgets/color_field.dart';
import '../widgets/empty_block.dart';
import '../widgets/list_name_dialog.dart';
import '../widgets/result_row.dart';
import 'detail_screen.dart';
import 'duel_screen.dart';

/// Slide-up route to a single list (mirrors the detail screen's transition).
Route<void> listDetailRoute(String listId) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    pageBuilder: (_, _, _) => ListDetailScreen(listId: listId),
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.4, 0, 0.1, 1),
      );
      return SlideTransition(
        position:
            Tween(begin: const Offset(0, 1), end: Offset.zero).animate(curved),
        child: child,
      );
    },
  );
}

/// One custom list: a draggable, ranked list of titles. The item order *is* the
/// ranking — drag to reorder, or hand it to the duel mode. Titles are added via
/// the in-list search sheet or from any detail page.
class ListDetailScreen extends StatelessWidget {
  const ListDetailScreen({super.key, required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final provider = context.watch<ListsProvider>();
    final list = provider.byId(listId);

    // The list was deleted (e.g. from here) — leave the screen.
    if (list == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) Navigator.of(context).maybePop();
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _topBar(context, c, list),
            _actions(context, c, list),
            Expanded(
              child: list.items.isEmpty
                  ? const _Empty()
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      padding: EdgeInsets.zero,
                      itemCount: list.items.length,
                      onReorder: (oldI, newI) =>
                          provider.reorder(list.id, oldI, newI),
                      itemBuilder: (ctx, i) => _entry(ctx, c, provider, list, i),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, MarginColors c, RankList list) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 8),
      child: Row(
        children: [
          _ghost(c, AppIconKind.back, () => Navigator.of(context).maybePop()),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => _rename(context, list),
              behavior: HitTestBehavior.opaque,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    list.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.display(
                      size: 24,
                      weight: FontWeight.w700,
                      letterSpacing: -0.6,
                      height: 1,
                      color: c.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${pad2(list.items.length)} BAŞLIK · ADI DÜZENLEMEK İÇİN DOKUN',
                    style:
                        AppFonts.mono(size: 8.5, letterSpacing: 1, color: c.mut),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          _ghost(c, AppIconKind.close, () => _confirmDelete(context, list)),
        ],
      ),
    );
  }

  /// The primary action bar: add titles, and (with ≥2 titles) launch the duel.
  Widget _actions(BuildContext context, MarginColors c, RankList list) {
    final canDuel = list.items.length >= 2;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: Row(
        children: [
          Expanded(
            child: _button(
              c,
              AppIconKind.plus,
              canDuel ? 'EKLE' : 'BAŞLIK EKLE',
              () => _openAddTitles(context, list.id),
            ),
          ),
          if (canDuel) ...[
            const SizedBox(width: 8),
            Expanded(
              child: _button(
                c,
                null,
                'DÜELLO',
                () =>
                    Navigator.of(context).push(duelRoute(list.id, list.items)),
                primary: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _entry(
    BuildContext context,
    MarginColors c,
    ListsProvider provider,
    RankList list,
    int i,
  ) {
    final item = list.items[i];
    final meta = [
      item.type.label,
      if (item.year != null) '${item.year}',
      if (item.metaShort != null) item.metaShort!,
      '★${item.rating.toStringAsFixed(1)}',
    ].join(' · ');

    return DecoratedBox(
      key: ValueKey(item.id),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                pad2(i + 1),
                style: AppFonts.mono(
                  size: 13,
                  weight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: c.accent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ColorFieldThumb(
              color: c.panel2,
              letter: item.title.isEmpty ? '?' : item.title[0],
              imageUrl: item.posterUrl(size: 'w185'),
              width: 40,
              height: 56,
              fontSize: 20,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(detailRoute(item)),
                behavior: HitTestBehavior.opaque,
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
                    const SizedBox(height: 4),
                    Text(
                      meta.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppFonts.mono(
                          size: 9.5, letterSpacing: 0.8, color: c.mut),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () => provider.removeItem(list.id, item.id),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: AppIcon(AppIconKind.close, size: 15, color: c.mut),
              ),
            ),
            ReorderableDragStartListener(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Text('≡', style: AppFonts.display(size: 18, color: c.mut)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ghost(MarginColors c, AppIconKind kind, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: c.line2)),
        child: AppIcon(kind, size: 18, color: c.ink),
      ),
    );
  }

  Widget _button(
    MarginColors c,
    AppIconKind? kind,
    String label,
    VoidCallback onTap, {
    bool primary = false,
  }) {
    final fg = primary ? c.accentInk : c.ink;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: primary ? c.accent : Colors.transparent,
          border: Border.all(color: primary ? c.accent : c.line2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (kind != null) ...[
              AppIcon(kind, size: 15, color: fg),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: AppFonts.mono(
                size: 11,
                weight: FontWeight.w700,
                letterSpacing: 1.4,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _rename(BuildContext context, RankList list) async {
    final name = await promptListName(
      context,
      initial: list.name,
      title: 'LİSTEYİ ADLANDIR',
    );
    if (name == null || !context.mounted) return;
    await context.read<ListsProvider>().rename(list.id, name);
  }

  Future<void> _confirmDelete(BuildContext context, RankList list) async {
    final c = context.margin;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: c.bg,
        insetPadding: const EdgeInsets.symmetric(horizontal: 32),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: c.line2),
          borderRadius: BorderRadius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'LİSTEYİ SİL?',
                style: AppFonts.mono(
                  size: 11,
                  weight: FontWeight.w700,
                  letterSpacing: 2,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '“${list.name}” kalıcı olarak silinecek.',
                style: AppFonts.body(size: 14, height: 1.5, color: c.mut),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      'VAZGEÇ',
                      style: AppFonts.mono(
                          size: 11, letterSpacing: 1.5, color: c.mut),
                    ),
                  ),
                  const SizedBox(width: 24),
                  GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(true),
                    child: Text(
                      'SİL',
                      style: AppFonts.mono(
                        size: 11,
                        weight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: c.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true || !context.mounted) return;
    final provider = context.read<ListsProvider>();
    Navigator.of(context).maybePop(); // close the list screen first
    await provider.delete(list.id);
  }

  void _openAddTitles(BuildContext context, String listId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTitlesSheet(listId: listId),
    );
  }
}

/// Empty state for a list with no titles yet.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: EmptyBlock(
        glyph: '↓',
        title: 'Liste boş',
        sub: '“Başlık ekle” ile ara, ya da bir başlığın sayfasından ekle.',
      ),
    );
  }
}

/// In-list search sheet: debounced TMDB search whose rows toggle membership of
/// the current list (the bookmark marker reflects whether a title is in it).
class _AddTitlesSheet extends StatefulWidget {
  const _AddTitlesSheet({required this.listId});

  final String listId;

  @override
  State<_AddTitlesSheet> createState() => _AddTitlesSheetState();
}

class _AddTitlesSheetState extends State<_AddTitlesSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  List<MediaItem> _results = const [];
  bool _loading = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(q));
  }

  Future<void> _search(String q) async {
    final query = q.trim();
    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final res = await context.read<TmdbApi>().search(query);
      if (!mounted) return;
      setState(() {
        _results = res;
        _loading = false;
      });
    } on TmdbException {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final list = context.watch<ListsProvider>().byId(widget.listId);
    final provider = context.read<ListsProvider>();
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: c.bg,
          border: Border(top: BorderSide(color: c.line2)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Column(
              children: [
                const SizedBox(height: 14),
                Text(
                  'BAŞLIK ARA VE EKLE',
                  style: AppFonts.mono(
                    size: 11,
                    weight: FontWeight.w700,
                    letterSpacing: 2,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 12),
                _searchField(c),
                const SizedBox(height: 6),
                Expanded(child: _resultsView(c, list, provider)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _searchField(MarginColors c) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: c.line2)),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          AppIcon(AppIconKind.search, size: 16, color: c.mut),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: _onChanged,
              cursorColor: c.accent,
              style: AppFonts.mono(size: 12, letterSpacing: 0.5, color: c.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: InputBorder.none,
                hintText: 'BAŞLIK, OYUNCU, TÜR…',
                hintStyle:
                    AppFonts.mono(size: 11, letterSpacing: 0.8, color: c.mut),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultsView(MarginColors c, RankList? list, ListsProvider provider) {
    if (_loading) {
      return Center(
        child: Text(
          'ARANIYOR…',
          style: AppFonts.mono(size: 10, letterSpacing: 1.5, color: c.mut),
        ),
      );
    }
    if (_results.isEmpty) {
      return Center(
        child: Text(
          _controller.text.trim().isEmpty
              ? 'EKLEMEK İÇİN BAŞLIK ARA'
              : 'SONUÇ YOK',
          style: AppFonts.mono(size: 10, letterSpacing: 1.5, color: c.mut),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _results.length,
      itemBuilder: (ctx, i) {
        final item = _results[i];
        final inList = list?.contains(item.id) ?? false;
        return ResultRow(
          item: item,
          index: i + 1,
          saved: inList,
          onTap: () => inList
              ? provider.removeItem(widget.listId, item.id)
              : provider.addItem(widget.listId, item),
        );
      },
    );
  }
}
