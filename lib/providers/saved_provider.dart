import 'package:flutter/foundation.dart';

import '../models/media_item.dart';
import '../models/saved_entry.dart';
import '../services/storage_service.dart';

/// The user's archive: favorites with optional curator notes. A thin reactive
/// layer over [StorageService] — every mutation persists then notifies.
class SavedProvider extends ChangeNotifier {
  SavedProvider(this._storage);

  final StorageService _storage;

  /// All saved entries, newest first.
  List<SavedEntry> get entries => _storage.savedEntries();
  int get count => entries.length;
  int get notedCount =>
      entries.where((e) => e.note.trim().isNotEmpty).length;

  bool isSaved(int id) => _storage.isSaved(id);
  SavedEntry? entry(int id) => _storage.savedEntry(id);

  /// Adds the item if absent, removes it if present (the detail toggle).
  Future<void> toggle(MediaItem item) async {
    if (_storage.isSaved(item.id)) {
      await _storage.removeSaved(item.id);
    } else {
      await _storage.addSaved(item);
    }
    notifyListeners();
  }

  Future<void> remove(int id) async {
    await _storage.removeSaved(id);
    notifyListeners();
  }

  Future<void> saveNote(MediaItem item, String note) async {
    await _storage.setNote(item, note);
    notifyListeners();
  }
}
