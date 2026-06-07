import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/media_item.dart';
import '../providers/catalog_provider.dart';
import '../providers/saved_provider.dart';
import '../providers/search_provider.dart';
import '../theme/app_theme.dart';
import '../theme/text_styles.dart';
import '../utils/format.dart';
import '../widgets/app_icons.dart';
import '../widgets/chip.dart';
import '../widgets/empty_block.dart';
import '../widgets/error_block.dart';
import '../widgets/result_row.dart';
import '../widgets/section_line.dart';
import '../widgets/skeleton.dart';

/// ARA — full-catalog search. A debounced TMDB multi-search with recent-search
/// chips and top-rated suggestions while the field is empty.
///
/// [active] tells the screen when it becomes the visible tab so it can grab /
/// release focus (the [IndexedStack] keeps it alive in the background).
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.active, required this.onOpen});

  final bool active;
  final ValueChanged<MediaItem> onOpen;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {})); // recolor the input border
  }

  @override
  void didUpdateWidget(SearchScreen old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && widget.active) _focusNode.requestFocus();
      });
    } else if (!widget.active && old.active) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  SearchProvider get _search => context.read<SearchProvider>();

  void _selectRecent(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    _search.selectRecent(value);
    _focusNode.requestFocus();
  }

  void _clear() {
    _controller.clear();
    _search.clear();
    _focusNode.requestFocus();
  }

  void _openResult(MediaItem item) {
    _search.commit();
    widget.onOpen(item);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final search = context.watch<SearchProvider>();
    final saved = context.watch<SavedProvider>();
    final hasQuery = search.query.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topBar(c),
          _input(c, hasQuery),
          if (!hasQuery)
            ..._idle(c, search, saved)
          else if (search.busy)
            _skeletonList()
          else if (search.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ErrorBlock(
                message: search.error,
                onRetry: () => search.setQuery(search.query),
              ),
            )
          else if (search.results.isEmpty)
            EmptyBlock(
              glyph: '∅',
              title: '"${search.query}" için sonuç yok',
              sub: 'Başka bir başlık ya da oyuncu dene.',
            )
          else
            ..._results(c, search, saved),
        ],
      ),
    );
  }

  Widget _topBar(MarginColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ARA',
            style: AppFonts.display(
              size: 30,
              letterSpacing: -0.9,
              height: 0.85,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'TÜM KATALOG',
            style: AppFonts.mono(size: 9.5, letterSpacing: 2.47, color: c.mut),
          ),
        ],
      ),
    );
  }

  Widget _input(MarginColors c, bool hasQuery) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: _focusNode.hasFocus ? c.accent : c.line2),
      ),
      child: Row(
        children: [
          AppIcon(AppIconKind.search, size: 18, color: c.mut),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              cursorColor: c.accent,
              onChanged: _search.setQuery,
              onSubmitted: (v) => _search.commit(v),
              style: AppFonts.body(size: 15, letterSpacing: 0.15, color: c.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'BAŞLIK · OYUNCU · TÜR',
                hintStyle:
                    AppFonts.mono(size: 12, letterSpacing: 1.2, color: c.mut),
              ),
            ),
          ),
          if (hasQuery) ...[
            const SizedBox(width: 11),
            GestureDetector(
              onTap: _clear,
              behavior: HitTestBehavior.opaque,
              child: AppIcon(AppIconKind.close, size: 16, color: c.mut),
            ),
          ],
        ],
      ),
    );
  }

  /// Empty-field view: recent searches (if any) + top-rated suggestions.
  List<Widget> _idle(MarginColors c, SearchProvider search, SavedProvider saved) {
    final recents = search.recents;
    final suggestions = context.watch<CatalogProvider>().rail.take(6).toList();
    return [
      if (recents.isNotEmpty) ...[
        const SectionLine(label: 'SON ARAMALAR'),
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            for (final r in recents)
              MarginChip(label: r, active: false, onTap: () => _selectRecent(r)),
          ],
        ),
      ],
      if (suggestions.isNotEmpty) ...[
        const SectionLine(label: 'ÖNERİLER'),
        for (var i = 0; i < suggestions.length; i++)
          ResultRow(
            item: suggestions[i],
            index: i + 1,
            saved: saved.isSaved(suggestions[i].id),
            onTap: () => _openResult(suggestions[i]),
          ),
      ],
    ];
  }

  List<Widget> _results(
      MarginColors c, SearchProvider search, SavedProvider saved) {
    final results = search.results;
    return [
      SectionLine(label: 'SONUÇ', count: pad2(results.length)),
      for (var i = 0; i < results.length; i++)
        ResultRow(
          item: results[i],
          index: i + 1,
          saved: saved.isSaved(results[i].id),
          onTap: () => _openResult(results[i]),
        ),
    ];
  }

  Widget _skeletonList() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: List.generate(5, (_) => const _RowSkeleton()),
      ),
    );
  }
}

/// Result-row placeholder: a thumb block plus two text lines.
class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(width: 33), // index column + gap
          const Skeleton(width: 42, height: 58),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                FractionallySizedBox(
                  widthFactor: 0.6,
                  alignment: Alignment.centerLeft,
                  child: Skeleton(height: 9),
                ),
                SizedBox(height: 8),
                FractionallySizedBox(
                  widthFactor: 0.35,
                  alignment: Alignment.centerLeft,
                  child: Skeleton(height: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
