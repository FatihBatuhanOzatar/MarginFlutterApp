import 'media_item.dart';

/// One archived title: the saved [item] plus the user's curator [note] and the
/// time it was added. The full [item] is snapshotted (not just an id) so the
/// archive screen still renders when offline or when the live catalog drops it.
class SavedEntry {
  const SavedEntry({
    required this.item,
    required this.note,
    required this.addedAt,
  });

  final MediaItem item;
  final String note;
  final DateTime addedAt;

  SavedEntry copyWith({MediaItem? item, String? note, DateTime? addedAt}) =>
      SavedEntry(
        item: item ?? this.item,
        note: note ?? this.note,
        addedAt: addedAt ?? this.addedAt,
      );

  Map<String, dynamic> toJson() => {
        'item': item.toJson(),
        'note': note,
        'addedAt': addedAt.millisecondsSinceEpoch,
      };

  factory SavedEntry.fromJson(Map<String, dynamic> json) => SavedEntry(
        item: MediaItem.fromJson(
            Map<String, dynamic>.from(json['item'] as Map)),
        note: (json['note'] ?? '') as String,
        addedAt:
            DateTime.fromMillisecondsSinceEpoch((json['addedAt'] as num).toInt()),
      );
}
