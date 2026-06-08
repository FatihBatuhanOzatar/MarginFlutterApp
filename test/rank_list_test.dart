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

/// Pure model tests — the ranked list must round-trip through JSON keeping the
/// entry order (the ranking) and custom labels, and must still read the legacy
/// `items` format written before labels existed.
void main() {
  test('round-trips entries, preserving order and labels', () {
    final list = RankList(
      id: 'L1',
      name: 'En İyi',
      createdAt: DateTime.fromMillisecondsSinceEpoch(1000),
      entries: [
        RankEntry(item: _item(3), label: 'Villain'),
        RankEntry(item: _item(1)),
        RankEntry(item: _item(2)),
      ],
    );

    final restored = RankList.fromJson(Map<String, dynamic>.from(list.toJson()));

    expect(restored.id, 'L1');
    expect(restored.name, 'En İyi');
    expect(restored.createdAt, list.createdAt);
    expect(restored.entries.map((e) => e.item.id).toList(), [3, 1, 2]);
    expect(restored.entries.first.label, 'Villain');
    expect(restored.entries.first.headline, 'Villain'); // label wins
    expect(restored.entries[1].headline, 'T1'); // no label -> title
    expect(restored.containsItem(1), isTrue);
    expect(restored.containsItem(9), isFalse);
  });

  test('reads the legacy items[] format as label-less entries', () {
    final legacy = {
      'id': 'L2',
      'name': 'Eski',
      'createdAt': 5,
      'items': [_item(7).toJson(), _item(8).toJson()],
    };

    final list = RankList.fromJson(legacy);

    expect(list.entries.map((e) => e.item.id).toList(), [7, 8]);
    expect(list.entries.every((e) => !e.hasLabel), isTrue);
  });
}
