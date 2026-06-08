import 'package:flutter/foundation.dart';

import '../models/media_item.dart';
import '../models/rank_list.dart';
import '../services/storage_service.dart';

/// The user's custom ranked lists. A thin reactive layer over [StorageService]:
/// every mutation persists the affected list, then notifies. A list's item
/// order *is* its ranking, rewritten by manual reordering and the duel mode.
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

  /// Appends [item] to the end of the list (lowest rank), skipping duplicates.
  Future<void> addItem(String listId, MediaItem item) async {
    final list = _find(listId);
    if (list == null || list.contains(item.id)) return;
    await _storage.saveList(list.copyWith(items: [...list.items, item]));
    notifyListeners();
  }

  Future<void> removeItem(String listId, int itemId) async {
    final list = _find(listId);
    if (list == null) return;
    final items = list.items.where((m) => m.id != itemId).toList();
    await _storage.saveList(list.copyWith(items: items));
    notifyListeners();
  }

  /// Manual drag-reorder, using ReorderableListView's index convention.
  Future<void> reorder(String listId, int oldIndex, int newIndex) async {
    final list = _find(listId);
    if (list == null || oldIndex < 0 || oldIndex >= list.items.length) return;
    final items = [...list.items];
    if (newIndex > oldIndex) newIndex -= 1;
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex.clamp(0, items.length), moved);
    await _storage.saveList(list.copyWith(items: items));
    notifyListeners();
  }

  /// Replaces the order outright — used by the duel ranking to write back the
  /// fully sorted result.
  Future<void> setOrder(String listId, List<MediaItem> ordered) async {
    final list = _find(listId);
    if (list == null) return;
    await _storage.saveList(list.copyWith(items: ordered));
    notifyListeners();
  }
}
