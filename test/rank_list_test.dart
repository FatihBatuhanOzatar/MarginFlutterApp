import 'package:flutter_test/flutter_test.dart';
import 'package:margin/models/media_item.dart';
import 'package:margin/models/rank_list.dart';

MediaItem _item(int id) => MediaItem(
      id: id,
      type: MediaType.film,
      title: 'T$id',
      rating: 7,
      genres: const [],
      overview: '',
    );

/// Pure model test — the ranked list must round-trip through JSON keeping the
/// item order intact (the order *is* the ranking the duel mode writes).
void main() {
  test('RankList round-trips through JSON, preserving item order', () {
    final list = RankList(
      id: 'L1',
      name: 'En İyi',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      items: [_item(3), _item(1), _item(2)],
    );

    final restored = RankList.fromJson(Map<String, dynamic>.from(list.toJson()));

    expect(restored.id, 'L1');
    expect(restored.name, 'En İyi');
    expect(restored.createdAt, list.createdAt);
    expect(restored.items.map((m) => m.id).toList(), [3, 1, 2]);
    expect(restored.contains(1), isTrue);
    expect(restored.contains(9), isFalse);
  });
}
