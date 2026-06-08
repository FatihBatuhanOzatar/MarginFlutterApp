import 'package:flutter/foundation.dart';

import '../models/genre_maps.dart';
import '../models/media_item.dart';
import '../services/storage_service.dart';
import '../services/tmdb_api.dart';

/// Drives the browse screen: the active type (FILM/DİZİ/ANİME) and genre filter,
/// the fetched list per type, plus loading/error/offline state.
///
/// Each type's list is fetched once and cached in memory; results are also
/// written to Hive so a later cold start (or an offline launch) can show the
/// last catalog instead of an empty screen.
class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._api, this._storage) {
    // Seed instantly from the offline cache, then refresh from the network.
    final cached = _storage.cachedCatalog(_type);
    if (cached != null) _cache[_type] = cached;
    Future.microtask(() => _load(_type));
  }

  final TmdbApi _api;
  final StorageService _storage;

  final Map<MediaType, List<MediaItem>> _cache = {};
  // Pagination bookkeeping per type: the last page loaded and TMDB's total.
  final Map<MediaType, int> _page = {};
  final Map<MediaType, int> _totalPages = {};
  MediaType _type = MediaType.film;
  String _genre = kAllGenre;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  bool _offline = false;

  MediaType get type => _type;
  String get genre => _genre;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  String? get error => _error;
  bool get isOffline => _offline;
  bool get editorial => _genre == kAllGenre;

  /// Whether the current type still has pages left to fetch (infinite scroll).
  bool get hasMore => (_page[_type] ?? 0) < (_totalPages[_type] ?? 1);

  List<MediaItem> get _current => _cache[_type] ?? const [];

  /// Current list after the genre chip filter (client-side, by genre name).
  List<MediaItem> get filtered => _genre == kAllGenre
      ? _current
      : _current.where((m) => m.genres.contains(_genre)).toList();

  List<MediaItem> get _ranked =>
      [..._current]..sort((a, b) => b.rating.compareTo(a.rating));

  /// Top 3 by rating — the editorial hero spotlight.
  List<MediaItem> get featured => _ranked.take(3).toList();

  /// Top 10 by rating — the "YÜKSEK PUANLI" rail.
  List<MediaItem> get rail => _ranked.take(10).toList();

  /// Switches type, lazily loading it the first time. The genre filter is kept
  /// across type changes, mirroring the prototype.
  Future<void> setType(MediaType type) async {
    if (type == _type) return;
    _type = type;
    notifyListeners();
    if (!_cache.containsKey(type)) {
      await _load(type);
    }
  }

  void setGenre(String genre) {
    if (genre == _genre) return;
    _genre = genre;
    notifyListeners();
  }

  /// Forces a re-fetch of the current type (the ErrorBlock "retry" button).
  Future<void> reload() => _load(_type);

  /// Pull-to-refresh: re-fetch the current type in the background, keeping the
  /// on-screen content (and the RefreshIndicator's own spinner) instead of
  /// flipping to the full-screen skeleton.
  Future<void> refresh() async {
    try {
      final page = await _api.browsePage(_type, 1);
      _cache[_type] = page.items;
      _page[_type] = 1;
      _totalPages[_type] = page.totalPages;
      _offline = false;
      _error = null;
      await _storage.cacheCatalog(_type, page.items);
    } on TmdbException catch (e) {
      // Keep what's shown; only surface an error if there is nothing to show.
      if (_current.isEmpty) {
        _error = e.message;
      } else {
        _offline = true;
      }
    } finally {
      notifyListeners();
    }
  }

  /// Infinite scroll: fetch and append the next page of the current type,
  /// skipping ids already present. No-ops while busy or when no pages remain.
  Future<void> loadMore() async {
    if (_loadingMore || _loading || !hasMore) return;
    _loadingMore = true;
    notifyListeners();
    final next = (_page[_type] ?? 1) + 1;
    try {
      final page = await _api.browsePage(_type, next);
      final existing = _cache[_type] ?? const [];
      final seen = existing.map((m) => m.id).toSet();
      final merged = [
        ...existing,
        for (final m in page.items)
          if (seen.add(m.id)) m,
      ];
      _cache[_type] = merged;
      _page[_type] = next;
      _totalPages[_type] = page.totalPages;
      await _storage.cacheCatalog(_type, merged);
    } on TmdbException catch (_) {
      // Silent: keep what we have; the user can scroll again to retry.
    } finally {
      _loadingMore = false;
      notifyListeners();
    }
  }

  Future<void> _load(MediaType type) async {
    _loading = true;
    _error = null;
    _offline = false;
    notifyListeners();
    try {
      final page = await _api.browsePage(type, 1);
      _cache[type] = page.items;
      _page[type] = 1;
      _totalPages[type] = page.totalPages;
      await _storage.cacheCatalog(type, page.items);
    } on TmdbException catch (e) {
      // No live data — fall back to the cached catalog if we have one.
      final cached = _storage.cachedCatalog(type);
      if (cached != null && cached.isNotEmpty) {
        _cache[type] = cached;
        _page[type] = 1;
        _totalPages[type] = 1; // cached data isn't paginated
        _offline = true;
      } else {
        _error = e.message;
      }
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
