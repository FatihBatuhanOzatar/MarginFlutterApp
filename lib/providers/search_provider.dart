import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/media_item.dart';
import '../services/storage_service.dart';
import '../services/tmdb_api.dart';

/// Drives the search screen: a debounced query against TMDB multi-search plus
/// the persisted recent-search history.
///
/// [busy] is true while waiting out the debounce *or* the network request, so
/// the screen can show one skeleton state for both.
class SearchProvider extends ChangeNotifier {
  SearchProvider(this._api, this._storage);

  final TmdbApi _api;
  final StorageService _storage;

  static const _debounceDelay = Duration(milliseconds: 420);

  String _query = '';
  List<MediaItem> _results = const [];
  bool _typing = false;
  bool _loading = false;
  String? _error;
  Timer? _debounce;
  int _requestId = 0;

  String get query => _query;
  List<MediaItem> get results => _results;
  bool get busy => _typing || _loading;
  String? get error => _error;
  List<String> get recents => _storage.recents();

  /// Updates the query and schedules a debounced search. Clearing the field
  /// resets results immediately without hitting the network.
  void setQuery(String value) {
    _query = value;
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      _typing = false;
      _loading = false;
      _error = null;
      _results = const [];
      notifyListeners();
      return;
    }
    _typing = true;
    notifyListeners();
    _debounce = Timer(_debounceDelay, () => _run(value));
  }

  Future<void> _run(String query) async {
    final requestId = ++_requestId;
    _typing = false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await _api.search(query);
      if (requestId != _requestId) return; // a newer query superseded this one
      _results = results;
    } on TmdbException catch (e) {
      if (requestId != _requestId) return;
      _results = const [];
      _error = e.message;
    } finally {
      if (requestId == _requestId) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// Persists [value] (or the current query) to recent searches.
  Future<void> commit([String? value]) async {
    final query = (value ?? _query).trim();
    if (query.isEmpty) return;
    await _storage.pushRecent(query);
    notifyListeners();
  }

  /// Re-runs a tapped recent search by feeding it back through [setQuery].
  void selectRecent(String value) => setQuery(value);

  void clear() => setQuery('');

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
