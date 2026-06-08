import 'package:flutter/foundation.dart';

import '../models/media_item.dart';
import '../models/rank_list.dart';
import '../services/storage_service.dart';

/// The user's custom ranked lists. A thin reactive layer over [StorageService]:
/// every mutation persists the affected list, then notifies. A list's entry
/// order *is* its ranking, rewritten by manual reordering and the duel mode.
/// Each entry is a title plus an optional custom label (see [RankEntry]).
class ListsProvider extends ChangeNotifier {
  ListsProvider(this._storage);

  final StorageService _storage;

  /// All lists, newest first.
  List<RankList> get lists => _storage.lists();

  RankList? byId(String id) => _find(id);

  RankList? _find(String id) {
    for (final l in _storage.lists()) {
      if (l.id == id) return l;
    }
    return null;
  }

  /// Creates an empty list and returns it (the caller usually navigates to it).
  Future<RankList> create(String name) async {
    final trimmed = name.trim();
    final list = RankList(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed.isEmpty ? 'Adsız liste' : trimmed,
      createdAt: DateTime.now(),
    );
    await _storage.saveList(list);
    notifyListeners();
    return list;
  }

  Future<void> rename(String id, String name) async {
    final list = _find(id);
    final trimmed = name.trim();
    if (list == null || trimmed.isEmpty) return;
    await _storage.saveList(list.copyWith(name: trimmed));
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _storage.deleteList(id);
    notifyListeners();
  }

  /// Appends [item] as a label-less entry, skipping titles already in the list.
  Future<void> addItem(String listId, MediaItem item) async {
    final list = _find(listId);
    if (list == null || list.containsItem(item.id)) return;
    await _storage.saveList(
        list.copyWith(entries: [...list.entries, RankEntry(item: item)]));
    notifyListeners();
  }

  Future<void> removeItem(String listId, int itemId) async {
    final list = _find(listId);
    if (list == null) return;
    final entries = list.entries.where((e) => e.item.id != itemId).toList();
    await _storage.saveList(list.copyWith(entries: entries));
    notifyListeners();
  }

  /// Sets (or clears, when empty) the custom label on the entry for [itemId].
  Future<void> setLabel(String listId, int itemId, String label) async {
    final list = _find(listId);
    if (list == null) return;
    final entries = [
      for (final e in list.entries)
        e.item.id == itemId ? e.withLabel(label.trim()) : e,
    ];
    await _storage.saveList(list.copyWith(entries: entries));
    notifyListeners();
  }

  /// Manual drag-reorder, using ReorderableListView's index convention.
  Future<void> reorder(String listId, int oldIndex, int newIndex) async {
    final list = _find(listId);
    if (list == null || oldIndex < 0 || oldIndex >= list.entries.length) return;
    final entries = [...list.entries];
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = entries.removeAt(oldIndex);
    entries.insert(newIndex.clamp(0, entries.length), moved);
    await _storage.saveList(list.copyWith(entries: entries));
    notifyListeners();
  }

  /// Replaces the order outright — used by the duel ranking to write back the
  /// fully sorted result.
  Future<void> setOrder(String listId, List<RankEntry> ordered) async {
    final list = _find(listId);
    if (list == null) return;
    await _storage.saveList(list.copyWith(entries: ordered));
    notifyListeners();
  }
}
