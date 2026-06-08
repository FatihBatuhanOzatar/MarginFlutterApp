import 'media_item.dart';

/// One ranked entry: a TMDB [item] plus an optional custom [label]. With a label
/// the entry ranks a *facet* of the title (a character, a song, a scene); without
/// one it just ranks the title itself. Display uses [headline] (label or title).
class RankEntry {
  const RankEntry({required this.item, this.label = ''});

  final MediaItem item;
  final String label;

  /// The custom label when set, otherwise the title.
  String get headline => label.trim().isEmpty ? item.title : label.trim();

  bool get hasLabel => label.trim().isNotEmpty;

  RankEntry withLabel(String value) => RankEntry(item: item, label: value);

  Map<String, dynamic> toJson() => {'item': item.toJson(), 'label': label};

  factory RankEntry.fromJson(Map<String, dynamic> json) => RankEntry(
        item: MediaItem.fromJson(Map<String, dynamic>.from(json['item'] as Map)),
        label: (json['label'] ?? '') as String,
      );
}

/// A user-curated, ranked list (e.g. "En İyi Animeler" or "En İyi Villainlar").
/// [entries] are kept in rank order — index 0 is rank #1 — and snapshotted in
/// full so a list renders offline. Ranking is the order, which manual reordering
/// and the duel mode rewrite.
class RankList {
  const RankList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.entries = const [],
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final List<RankEntry> entries;

  /// Whether a title with [itemId] is already in this list.
  bool containsItem(int itemId) => entries.any((e) => e.item.id == itemId);

  RankList copyWith({String? name, List<RankEntry>? entries}) => RankList(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        entries: entries ?? this.entries,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'entries': entries.map((e) => e.toJson()).toList(),
      };

  factory RankList.fromJson(Map<String, dynamic> json) => RankList(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (json['createdAt'] as num).toInt()),
        entries: _entries(json),
      );

  /// Reads the new `entries` shape, or upgrades the legacy `items` (a list of
  /// MediaItem json) into label-less entries.
  static List<RankEntry> _entries(Map<String, dynamic> json) {
    final raw = json['entries'] as List?;
    if (raw != null) {
      return raw
          .map((e) => RankEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    final legacy = (json['items'] as List?) ?? const [];
    return legacy
        .map((e) => RankEntry(
            item: MediaItem.fromJson(Map<String, dynamic>.from(e as Map))))
        .toList();
  }
}
