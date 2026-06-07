import 'package:hive_flutter/hive_flutter.dart';

import '../models/media_item.dart';
import '../models/saved_entry.dart';

/// Typed wrapper around the app's Hive boxes. All persistence (favorites + notes,
/// recent searches, offline catalog cache, theme settings) goes through here so
/// the providers never touch Hive directly.
///
/// Values are stored as plain JSON-compatible maps/lists via the models'
/// `toJson`/`fromJson`, which avoids generated TypeAdapters and keeps the on-disk
/// format easy to read and evolve.
class StorageService {
  StorageService._(this._saved, this._recents, this._catalog, this._settings);

  final Box _saved; // id (String) -> SavedEntry json
  final Box _recents; // single 'list' key -> List<String>
  final Box _catalog; // MediaType.name -> List<MediaItem json>
  final Box _settings; // theme mode + accent

  static const _savedBox = 'saved';
  static const _recentsBox = 'recents';
  static const _catalogBox = 'catalog_cache';
  static const _settingsBox = 'settings';

  static const _recentsKey = 'list';
  static const _maxRecents = 8;

  /// Initializes Hive (app documents dir) and opens every box. Call once before
  /// `runApp`.
  static Future<StorageService> init() async {
    await Hive.initFlutter();
    return open();
  }

  /// Opens the boxes, assuming Hive is already initialized. Lets tests point
  /// Hive at a temp directory via [Hive.init] before calling this.
  static Future<StorageService> open() async {
    final results = await Future.wait([
      Hive.openBox(_savedBox),
      Hive.openBox(_recentsBox),
      Hive.openBox(_catalogBox),
      Hive.openBox(_settingsBox),
    ]);
    return StorageService._(results[0], results[1], results[2], results[3]);
  }

  // --- Saved / archive ---

  /// All saved entries, newest first.
  List<SavedEntry> savedEntries() {
    final entries = _saved.values
        .map((v) => SavedEntry.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
    entries.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return entries;
  }

  bool isSaved(int id) => _saved.containsKey(id.toString());

  SavedEntry? savedEntry(int id) {
    final v = _saved.get(id.toString());
    if (v == null) return null;
    return SavedEntry.fromJson(Map<String, dynamic>.from(v as Map));
  }

  /// Adds [item] to the archive with an empty note (preserving any existing
  /// note/addedAt if it was already saved).
  Future<void> addSaved(MediaItem item) async {
    final existing = savedEntry(item.id);
    final entry = SavedEntry(
      item: item,
      note: existing?.note ?? '',
      addedAt: existing?.addedAt ?? DateTime.now(),
    );
    await _saved.put(item.id.toString(), entry.toJson());
  }

  Future<void> removeSaved(int id) => _saved.delete(id.toString());

  /// Writes [note] for an already-saved [item], keeping its original addedAt.
  Future<void> setNote(MediaItem item, String note) async {
    final existing = savedEntry(item.id);
    final entry = SavedEntry(
      item: item,
      note: note,
      addedAt: existing?.addedAt ?? DateTime.now(),
    );
    await _saved.put(item.id.toString(), entry.toJson());
  }

  // --- Recent searches ---

  List<String> recents() {
    final raw = _recents.get(_recentsKey) as List?;
    return raw == null ? <String>[] : raw.cast<String>();
  }

  /// Pushes [query] to the front, drops a case-insensitive duplicate, caps the
  /// list at [_maxRecents] (mirrors the prototype's `pushRecent`).
  Future<void> pushRecent(String query) async {
    final value = query.trim();
    if (value.isEmpty) return;
    final next = <String>[
      value,
      ...recents().where((x) => x.toLowerCase() != value.toLowerCase()),
    ].take(_maxRecents).toList();
    await _recents.put(_recentsKey, next);
  }

  Future<void> clearRecents() => _recents.delete(_recentsKey);

  // --- Offline catalog cache ---

  /// Cached browse list for [type], or null if nothing has been cached yet.
  List<MediaItem>? cachedCatalog(MediaType type) {
    final raw = _catalog.get(type.name) as List?;
    if (raw == null) return null;
    return raw
        .map((v) => MediaItem.fromJson(Map<String, dynamic>.from(v as Map)))
        .toList();
  }

  Future<void> cacheCatalog(MediaType type, List<MediaItem> items) =>
      _catalog.put(type.name, items.map((i) => i.toJson()).toList());

  // --- Theme settings ---

  String? themeModeName() => _settings.get('themeMode') as String?;
  Future<void> setThemeModeName(String name) =>
      _settings.put('themeMode', name);

  int? accentValue() => _settings.get('accent') as int?;
  Future<void> setAccentValue(int argb) => _settings.put('accent', argb);
}
