import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/genre_maps.dart';
import '../models/media_item.dart';
import '../providers/catalog_provider.dart';
import '../providers/saved_provider.dart';
import '../theme/app_theme.dart';
import '../theme/text_styles.dart';
import '../utils/format.dart';
import '../widgets/app_icons.dart';
import '../widgets/chip.dart';
import '../widgets/empty_block.dart';
import '../widgets/error_block.dart';
import '../widgets/hero_feature.dart';
import '../widgets/poster.dart';
import '../widgets/rail.dart';
import '../widgets/section_line.dart';
import '../widgets/skeleton.dart';
import 'settings_screen.dart';

/// The contact sheet is a fixed two-column grid.
const int kGridColumns = 2;

/// İNDEKS — the editorial browse screen: brand, search trigger, type tabs, the
/// auto-rotating hero + curator rail (only when no genre filter is active), the
/// genre chips, and the poster grid with its own loading / empty / error states.
class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key, required this.onOpen, required this.onSearch});

  final ValueChanged<MediaItem> onOpen;
  final VoidCallback onSearch;

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  // Anchor on the grid header so "TÜMÜNÜ GÖR" can scroll the list into view.
  final _gridKey = GlobalKey();

  void _scrollToGrid() {
    final ctx = _gridKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final catalog = context.watch<CatalogProvider>();
    final saved = context.watch<SavedProvider>();
    final type = catalog.type;
    final editorial = catalog.editorial;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _topBar(c),
          _searchField(c),
          const SizedBox(height: 16),
          _typeTabs(c, catalog),
          if (catalog.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: ErrorBlock(
                message: catalog.error,
                onRetry: catalog.reload,
              ),
            )
          else ...[
            if (editorial)
              catalog.loading
                  ? const _HeroSkeleton()
                  : HeroFeature(items: catalog.featured, onOpen: widget.onOpen),
            if (editorial && !catalog.loading)
              Rail(
                title: 'YÜKSEK PUANLI',
                items: catalog.rail,
                isSaved: saved.isSaved,
                onOpen: widget.onOpen,
                onMore: _scrollToGrid,
              ),
            _chipRow(catalog),
            SectionLine(
              key: _gridKey,
              label: editorial
                  ? 'TÜM ${type.label}'
                  : '${type.label} · ${catalog.genre.toUpperCase()}',
              count:
                  '${catalog.loading ? '— —' : pad2(catalog.filtered.length)} BAŞLIK',
            ),
            _body(c, catalog, saved),
          ],
          _footer(c),
        ],
      ),
    );
  }

  Widget _topBar(MarginColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MARGIN',
                style: AppFonts.display(
                  size: 30,
                  letterSpacing: -0.9,
                  height: 0.85,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'KİŞİSEL EKRAN İNDEKSİ',
                style: AppFonts.mono(size: 9.5, letterSpacing: 2.47, color: c.mut),
              ),
            ],
          ),
          Row(
            children: [
              _ghostButton(
                c,
                AppIconKind.settings,
                () => Navigator.of(context).push(settingsRoute()),
              ),
              const SizedBox(width: 8),
              _ghostButton(c, AppIconKind.search, widget.onSearch),
            ],
          ),
        ],
      ),
    );
  }

  /// A 42×42 hairline-bordered icon button (top-bar affordances).
  Widget _ghostButton(MarginColors c, AppIconKind kind, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: c.line2)),
        child: AppIcon(kind, size: 20, color: c.ink),
      ),
    );
  }

  Widget _searchField(MarginColors c) {
    return GestureDetector(
      onTap: widget.onSearch,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(border: Border.all(color: c.line2)),
        child: Row(
          children: [
            AppIcon(AppIconKind.search, size: 18, color: c.mut),
            const SizedBox(width: 10),
            Text(
              'BAŞLIK, OYUNCU, TÜR ARA…',
              style: AppFonts.mono(size: 11, letterSpacing: 0.88, color: c.mut),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeTabs(MarginColors c, CatalogProvider catalog) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        children: [
          for (final t in MediaType.values)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => catalog.setType(t),
                child: Container(
                  padding: const EdgeInsets.only(top: 11, bottom: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: t == catalog.type ? c.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(
                    t.label,
                    textAlign: TextAlign.center,
                    style: AppFonts.display(
                      size: 13,
                      weight: FontWeight.w700,
                      letterSpacing: 0.52,
                      color: t == catalog.type ? c.ink : c.mut,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _chipRow(CatalogProvider catalog) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Row(
        children: [
          MarginChip(
            label: 'TÜMÜ',
            active: catalog.editorial,
            onTap: () => catalog.setGenre(kAllGenre),
          ),
          for (final g in kGenreFilters) ...[
            const SizedBox(width: 7),
            MarginChip(
              label: g,
              active: catalog.genre == g,
              onTap: () => catalog.setGenre(g),
            ),
          ],
        ],
      ),
    );
  }

  Widget _body(MarginColors c, CatalogProvider catalog, SavedProvider saved) {
    if (catalog.loading) {
      return _grid(c, 8, (_) => const SkeletonTile());
    }
    final items = catalog.filtered;
    if (items.isEmpty) {
      return const EmptyBlock(
        glyph: '∅',
        title: 'Bu filtrede başlık yok',
        sub: 'Türü ya da kategoriyi değiştir.',
      );
    }
    return _grid(c, items.length, (i) {
      final item = items[i];
      return Poster(
        item: item,
        index: i + 1,
        saved: saved.isSaved(item.id),
        onTap: () => widget.onOpen(item),
      );
    });
  }

  /// The hairline-separated contact sheet: a [c.line] backdrop bleeds through the
  /// 1px grid gaps to draw the rules between cells.
  Widget _grid(MarginColors c, int count, Widget Function(int) builder) {
    return DecoratedBox(
      decoration: BoxDecoration(color: c.line, border: Border.all(color: c.line)),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: kGridColumns,
          childAspectRatio: 2 / 3,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemCount: count,
        itemBuilder: (_, i) => builder(i),
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

/// Loading placeholder that fills the hero's footprint (height + top margin).
class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 306,
      margin: const EdgeInsets.only(top: 14),
      child: const Skeleton(),
    );
  }
}
