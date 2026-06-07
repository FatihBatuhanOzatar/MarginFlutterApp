import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:margin/models/media_item.dart';
import 'package:margin/providers/saved_provider.dart';
import 'package:margin/services/storage_service.dart';

MediaItem _item(int id, {String title = 'Test'}) => MediaItem(
      id: id,
      type: MediaType.film,
      title: title,
      rating: 7.5,
      genres: const ['Drama'],
      overview: 'o',
      year: 2020,
      runtime: 120,
    );

/// Archive behavior over a real (temp-dir) Hive box: add/remove via the detail
/// toggle, note authoring, and the saved/noted counters the archive header reads.
void main() {
  late Directory dir;
  late StorageService storage;
  late SavedProvider saved;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('margin_saved');
    Hive.init(dir.path);
    storage = await StorageService.open();
    saved = SavedProvider(storage);
  });

  tearDown(() async {
    await Hive.close();
    await dir.delete(recursive: true);
  });

  test('starts empty', () {
    expect(saved.count, 0);
    expect(saved.entries, isEmpty);
    expect(saved.isSaved(1), isFalse);
  });

  test('toggle adds then removes a title', () async {
    final item = _item(1);

    await saved.toggle(item);
    expect(saved.isSaved(1), isTrue);
    expect(saved.count, 1);

    await saved.toggle(item);
    expect(saved.isSaved(1), isFalse);
    expect(saved.count, 0);
  });

  test('saveNote creates the entry and counts it as noted', () async {
    final item = _item(2);

    await saved.saveNote(item, 'unforgettable');
    expect(saved.isSaved(2), isTrue);
    expect(saved.count, 1);
    expect(saved.notedCount, 1);
    expect(saved.entry(2)?.note, 'unforgettable');
  });

  test('a saved-but-empty note does not count as noted', () async {
    await saved.toggle(_item(3));
    expect(saved.count, 1);
    expect(saved.notedCount, 0);
  });

  test('remove deletes the entry', () async {
    await saved.saveNote(_item(4), 'note');
    expect(saved.isSaved(4), isTrue);

    await saved.remove(4);
    expect(saved.isSaved(4), isFalse);
    expect(saved.count, 0);
  });
}
