import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/media_item.dart';
import '../providers/saved_provider.dart';
import '../services/palette_cache.dart';
import '../services/tmdb_api.dart';
import '../theme/app_theme.dart';
import '../theme/grain.dart';
import '../theme/palettes.dart';
import '../theme/text_styles.dart';
import '../utils/format.dart';
import '../widgets/add_to_list_sheet.dart';
import '../widgets/app_icons.dart';
import '../widgets/note_card.dart';
import '../widgets/rail.dart';
import '../widgets/section_line.dart';
import '../widgets/share_card.dart';
import '../widgets/skeleton.dart';
import 'share_preview_screen.dart';

/// The detail overlay's slide-up route: bottom-to-top with the prototype's
/// `cubic-bezier(.4,0,.1,1)` easing over 340ms.
Route<void> detailRoute(MediaItem item) {
  return PageRouteBuilder<void>(
    transitionDuration: const Duration(milliseconds: 340),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) => DetailScreen(item: item),
    transitionsBuilder: (_, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: const Cubic(0.4, 0, 0.1, 1),
      );
      return SlideTransition(
        position: Tween(begin: const Offset(0, 1), end: Offset.zero)
            .animate(curved),
        child: child,
      );
    },
  );
}

/// DETAY — the full title page: a color/backdrop hero, the meta strip, genres,
/// the collection toggle, overview, cast, and the curator note ("KENAR NOTU").
///
/// Opens from the lightweight list item and upgrades itself to the full TMDB
/// detail (runtime/episodes + cast) once fetched, keeping any extracted color.
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.item});

  final MediaItem item;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late MediaItem _item = widget.item;
  bool _loadingDetail = true;
  List<MediaItem> _similar = const [];
  String? _trailerKey;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
    _fetchSimilar();
    _fetchTrailer();
  }

  Future<void> _fetchDetail() async {
    try {
      final full =
          await context.read<TmdbApi>().detail(widget.item.type, widget.item.id);
      if (!mounted) return;
      setState(() {
        _item = full.copyWith(color: widget.item.color);
        _loadingDetail = false;
      });
    } on TmdbException {
      if (!mounted) return; // keep the list item; show what we already have
      setState(() => _loadingDetail = false);
    }
  }

  Future<void> _fetchSimilar() async {
    try {
      final recs = await context
          .read<TmdbApi>()
          .recommendations(widget.item.type, widget.item.id);
      if (!mounted) return;
      setState(() => _similar = recs);
    } on TmdbException {
      // Non-critical — just omit the rail if recommendations fail.
    }
  }

  Future<void> _fetchTrailer() async {
    try {
      final key = await context
          .read<TmdbApi>()
          .trailerKey(widget.item.type, widget.item.id);
      if (!mounted || key == null) return;
      setState(() => _trailerKey = key);
    } on TmdbException {
      // Non-critical — hide the trailer button when none is available.
    }
  }

  /// Opens the YouTube trailer in the external app / browser.
  Future<void> _openTrailer() async {
    final key = _trailerKey;
    if (key == null) return;
    await launchUrl(
      Uri.parse('https://www.youtube.com/watch?v=$key'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final saved = context.watch<SavedProvider>();
    final entry = saved.entry(_item.id);
    final stamp = entry != null ? formatStamp(entry.addedAt) : null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 42),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _hero(context),
              _metaStrip(c),
              _genres(c),
              _saveButton(c, saved, entry != null),
              _listButton(c),
              if (_trailerKey != null) _trailerButton(c),
              if (_item.overview.isNotEmpty) ...[
                _section('ÖZET'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    _item.overview,
                    style: AppFonts.body(
                      size: 15,
                      height: 1.6,
                      color: c.ink.withValues(alpha: 0.92),
                    ),
                  ),
                ),
              ],
              if (_loadingDetail || _item.cast.isNotEmpty) ...[
                _section('OYUNCULAR'),
                _cast(),
              ],
              if (_similar.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Rail(
                    title: 'BENZER BAŞLIKLAR',
                    items: _similar,
                    isSaved: saved.isSaved,
                    onOpen: (m) => Navigator.of(context).push(detailRoute(m)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SectionLine(
                  label: 'KENAR NOTU',
                  count: stamp,
                  trailing: (entry?.note.trim().isNotEmpty ?? false)
                      ? GestureDetector(
                          onTap: () => showSharePreview(
                            context,
                            card: NoteShareCard(item: _item, note: entry!.note),
                            shareText:
                                '“${_item.title}” üzerine kenar notum — MARGIN',
                          ),
                          behavior: HitTestBehavior.opaque,
                          child: AppIcon(AppIconKind.share, size: 15, color: c.mut),
                        )
                      : null,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: NoteCard(
                  note: entry?.note ?? '',
                  onSave: (v) => saved.saveNote(_item, v),
                ),
              ),
              _footer(c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context) {
    final color = context.select<PaletteCache, Color?>((p) => p.colorFor(_item));
    final hasColor = color != null;
    final ink = color != null ? inkOn(color) : kInkLight;
    final field = color ?? context.margin.panel2;

    return SizedBox(
      height: 296,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _heroBackground(field),
          GrainOverlay(opacity: 0.05, dark: ink == kInkLight),
          _heroWash(field, hasColor),
          Positioned(
            top: 16,
            left: 18,
            right: 18,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).maybePop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.28),
                      border:
                          Border.all(color: Colors.white.withValues(alpha: 0.28)),
                    ),
                    child: AppIcon(AppIconKind.back, size: 20, color: ink),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: ink.withValues(alpha: 0.45)),
                  ),
                  child: Text(
                    _item.type.label,
                    style: AppFonts.mono(size: 9, letterSpacing: 1.62, color: ink),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${pad2(_item.id % 100)}',
                  style: AppFonts.mono(
                    size: 12,
                    weight: FontWeight.w700,
                    letterSpacing: 1.68,
                    color: ink.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.display(
                    size: 44,
                    height: 0.9,
                    letterSpacing: -1.32,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroBackground(Color field) {
    if (_item.color != null) return ColoredBox(color: field);
    final url = _item.backdropUrl() ?? _item.posterUrl(size: 'w780');
    if (url == null) return ColoredBox(color: field);
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => ColoredBox(color: field),
      errorWidget: (_, _, _) => ColoredBox(color: field),
    );
  }

  Widget _heroWash(Color field, bool hasColor) {
    final bottom = hasColor ? field : Colors.black;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0x26000000), const Color(0x00000000), bottom],
          stops: const [0, 0.35, 0.96],
        ),
      ),
    );
  }

  Widget _metaStrip(MarginColors c) {
    final cells = <String>[
      if (_item.year != null) '${_item.year}',
      if (_item.metaFull != null) _item.metaFull!,
      if (_item.country != null) _item.country!,
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '★ ${_item.rating.toStringAsFixed(1)}',
            style: AppFonts.mono(
              size: 18,
              weight: FontWeight.w700,
              letterSpacing: 0.36,
              color: c.accent,
            ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (var i = 0; i < cells.length; i++) ...[
                  if (i > 0) ...[
                    const SizedBox(width: 11),
                    Container(width: 1, height: 11, color: c.line2),
                    const SizedBox(width: 11),
                  ],
                  Flexible(
                    child: Text(
                      cells[i].toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppFonts.mono(size: 11, letterSpacing: 1.1, color: c.mut),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _genres(MarginColors c) {
    if (_item.genres.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 4),
      child: Wrap(
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final g in _item.genres)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(border: Border.all(color: c.line)),
              child: Text(
                g.toUpperCase(),
                style: AppFonts.mono(size: 10, letterSpacing: 1.2, color: c.mut),
              ),
            ),
        ],
      ),
    );
  }

  Widget _saveButton(MarginColors c, SavedProvider saved, bool isSaved) {
    final fg = isSaved ? c.accentInk : c.ink;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
      child: GestureDetector(
        onTap: () => saved.toggle(_item),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isSaved ? c.accent : Colors.transparent,
            border: Border.all(color: isSaved ? c.accent : c.line2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(AppIconKind.bookmark, filled: isSaved, size: 18, color: fg),
              const SizedBox(width: 10),
              Text(
                isSaved ? 'KOLEKSİYONDA' : 'KOLEKSİYONA EKLE',
                style: AppFonts.mono(
                  size: 12,
                  weight: FontWeight.w700,
                  letterSpacing: 1.92,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens the "add to list" sheet for this title.
  Widget _listButton(MarginColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: GestureDetector(
        onTap: () => showAddToListSheet(context, _item),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border.all(color: c.line2)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(AppIconKind.plus, size: 16, color: c.ink),
              const SizedBox(width: 10),
              Text(
                'LİSTEYE EKLE',
                style: AppFonts.mono(
                  size: 12,
                  weight: FontWeight.w700,
                  letterSpacing: 1.92,
                  color: c.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Secondary outline action shown only when a YouTube trailer exists.
  Widget _trailerButton(MarginColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      child: GestureDetector(
        onTap: _openTrailer,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border.all(color: c.line2)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('▶', style: AppFonts.mono(size: 12, color: c.ink)),
              const SizedBox(width: 10),
              Text(
                'FRAGMANI İZLE',
                style: AppFonts.mono(
                  size: 12,
                  weight: FontWeight.w700,
                  letterSpacing: 1.92,
                  color: c.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cast() {
    final children = _loadingDetail
        ? List<Widget>.generate(5, (_) => const _CastSkeleton())
        : [for (final m in _item.cast) _CastCard(member: m)];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(18, 2, 18, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            children[i],
          ],
        ],
      ),
    );
  }

  Widget _section(String label, {String? count}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: SectionLine(label: label, count: count),
    );
  }

  Widget _footer(MarginColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
      child: Text(
        'TMDB ID ${_item.id} · ${_item.type.label}',
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

/// One cast member: an initials avatar plus the name.
class _CastCard extends StatelessWidget {
  const _CastCard({required this.member});

  final CastMember member;

  @override
  Widget build(BuildContext context) {
    final c = context.margin;
    final initials = member.name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();
    return SizedBox(
      width: 66,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 66,
            height: 66,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.panel2,
              border: Border.all(color: c.line2),
            ),
            child: Text(
              initials,
              style: AppFonts.mono(
                size: 17,
                weight: FontWeight.w700,
                color: c.ink,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            member.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AppFonts.mono(size: 9.5, height: 1.35, letterSpacing: 0.19, color: c.mut),
          ),
        ],
      ),
    );
  }
}

class _CastSkeleton extends StatelessWidget {
  const _CastSkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 66,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(width: 66, height: 66),
          SizedBox(height: 7),
          Skeleton(width: 50, height: 9),
        ],
      ),
    );
  }
}
