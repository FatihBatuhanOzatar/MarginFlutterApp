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
  MediaType _type = MediaType.film;
  String _genre = kAllGenre;
  bool _loading = false;
  String? _error;
  bool _offline = false;

  MediaType get type => _type;
  String get genre => _genre;
  bool get loading => _loading;
  String? get error => _error;
  bool get isOffline => _offline;
  bool get editorial => _genre == kAllGenre;

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

  Future<void> _load(MediaType type) async {
    _loading = true;
    _error = null;
    _offline = false;
    notifyListeners();
    try {
      final items = await _api.browse(type);
      _cache[type] = items;
      await _storage.cacheCatalog(type, items);
    } on TmdbException catch (e) {
      // No live data — fall back to the cached catalog if we have one.
      final cached = _storage.cachedCatalog(type);
      if (cached != null && cached.isNotEmpty) {
        _cache[type] = cached;
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
