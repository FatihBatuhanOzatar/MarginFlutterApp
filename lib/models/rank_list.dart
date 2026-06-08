import 'media_item.dart';

/// A user-curated, ranked list of titles (e.g. "En İyi Animeler"). The [items]
/// are kept in rank order — index 0 is rank #1 — and snapshotted in full so a
/// list renders offline, exactly like the archive. Ranking is simply the order,
/// which manual reordering and the duel mode rewrite.
class RankList {
  const RankList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.items = const [],
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final List<MediaItem> items;

  /// Whether a title with [id] is already in this list.
  bool contains(int id) => items.any((m) => m.id == id);

  RankList copyWith({String? name, List<MediaItem>? items}) => RankList(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        items: items ?? this.items,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'items': items.map((m) => m.toJson()).toList(),
      };

  factory RankList.fromJson(Map<String, dynamic> json) => RankList(
        id: json['id'] as String,
        name: (json['name'] ?? '') as String,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (json['createdAt'] as num).toInt()),
        items: ((json['items'] as List?) ?? const [])
            .map((e) => MediaItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}
