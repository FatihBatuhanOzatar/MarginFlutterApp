import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:palette_generator/palette_generator.dart';

import '../models/media_item.dart';

/// Derives each title's dominant poster color — TMDB doesn't ship one — and
/// caches it by id. The first read for an unknown id kicks off a background
/// extraction (reusing the on-disk image cache) and notifies when ready, so
/// color-fields, heroes and washes upgrade from the neutral placeholder in
/// place without blocking the first paint.
class PaletteCache extends ChangeNotifier {
  PaletteCache({this.imageSize = 'w185'});

  /// The small poster size decoded for extraction: representative but cheap.
  final String imageSize;

  final Map<int, Color> _colors = {};
  final Set<int> _pending = {};

  /// The dominant color for [item] — its embedded color if it already carries
  /// one, else the cached extraction, else null while one computes in the
  /// background (callers fall back to a neutral field meanwhile).
  Color? colorFor(MediaItem item) {
    if (item.color != null) return item.color;
    final cached = _colors[item.id];
    if (cached != null) return cached;
    _schedule(item);
    return null;
  }

  void _schedule(MediaItem item) {
    final url = item.posterUrl(size: imageSize);
    if (url == null || _pending.contains(item.id)) return;
    _pending.add(item.id);
    // Defer so colorFor() (often called from build/select) never triggers a
    // synchronous notifyListeners().
    Future.microtask(() => _extract(item.id, url));
  }

  Future<void> _extract(int id, String url) async {
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        CachedNetworkImageProvider(url),
        size: const Size(120, 180),
        maximumColorCount: 8,
      );
      final color = palette.dominantColor?.color ??
          palette.vibrantColor?.color ??
          palette.mutedColor?.color;
      if (color != null) {
        _colors[id] = color;
        notifyListeners();
      }
    } catch (_) {
      // Offline or undecodable poster — leave it unset; the neutral field stays.
    } finally {
      _pending.remove(id);
    }
  }
}
