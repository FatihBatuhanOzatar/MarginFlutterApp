import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:margin/models/media_item.dart';
import 'package:margin/providers/lists_provider.dart';
import 'package:margin/services/storage_service.dart';

MediaItem _item(int id) => MediaItem(
      id: id,
      type: MediaType.film,
      title: 'T$id',
      rating: 7,
      genres: const [],
      overview: '',
    );

/// ListsProvider behavior over a real (temp-dir) Hive box: create, add/dedupe,
/// remove, reorder, replace-order (duel), rename and delete.
void main() {
  late Directory dir;
  late StorageService storage;
  late ListsProvider lists;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('margin_lists');
    Hive.init(dir.path);
    storage = await StorageService.open();
    lists = ListsProvider(storage);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('starts empty', () {
    expect(lists.lists, isEmpty);
  });

  test('create then add items (deduped), preserving insertion order', () async {
    final list = await lists.create('En İyi');
    expect(lists.lists.length, 1);

    await lists.addItem(list.id, _item(1));
    await lists.addItem(list.id, _item(2));
    await lists.addItem(list.id, _item(1)); // duplicate ignored

    expect(lists.byId(list.id)!.items.map((m) => m.id).toList(), [1, 2]);
  });

  test('reorder moves an item to a new rank', () async {
    final list = await lists.create('L');
    for (var i = 1; i <= 3; i++) {
      await lists.addItem(list.id, _item(i));
    }
    // Move the last item (id 3) to the front.
    await lists.reorder(list.id, 2, 0);
    expect(lists.byId(list.id)!.items.map((m) => m.id).toList(), [3, 1, 2]);
  });

  test('setOrder replaces the whole ranking (duel result)', () async {
    final list = await lists.create('L');
    for (var i = 1; i <= 3; i++) {
      await lists.addItem(list.id, _item(i));
    }
    await lists.setOrder(list.id, [_item(2), _item(3), _item(1)]);
    expect(lists.byId(list.id)!.items.map((m) => m.id).toList(), [2, 3, 1]);
  });

  test('remove item, rename and delete the list', () async {
    final list = await lists.create('Old');
    await lists.addItem(list.id, _item(1));
    await lists.addItem(list.id, _item(2));

    await lists.removeItem(list.id, 1);
    expect(lists.byId(list.id)!.items.map((m) => m.id).toList(), [2]);

    await lists.rename(list.id, 'New');
    expect(lists.byId(list.id)!.name, 'New');

    await lists.delete(list.id);
    expect(lists.lists, isEmpty);
  });
}
