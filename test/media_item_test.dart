import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:margin/models/media_item.dart';

/// Pure model tests — no Hive or network. They lock down the TMDB parsing, the
/// type-dependent meta strings, and the JSON round-trip used by the offline
/// cache (including the extracted color).
void main() {
  group('MediaItem.fromTmdbList', () {
    test('parses core fields and maps genre ids via the callback', () {
      final item = MediaItem.fromTmdbList(
        {
          'id': 5,
          'title': 'Editorial',
          'release_date': '2019-05-01',
          'vote_average': 8.2,
          'genre_ids': [18, 53],
          'overview': 'x',
          'poster_path': '/p.jpg',
        },
        MediaType.film,
        (ids, type) => ['Drama', 'Thriller'],
      );

      expect(item.id, 5);
      expect(item.title, 'Editorial');
      expect(item.year, 2019);
      expect(item.rating, 8.2);
      expect(item.genres, ['Drama', 'Thriller']);
      expect(item.posterPath, '/p.jpg');
    });

    test('reads the tv name/first_air_date keys for non-film types', () {
      final item = MediaItem.fromTmdbList(
        {
          'id': 9,
          'name': 'Series',
          'first_air_date': '2021-09-10',
          'vote_average': 7,
        },
        MediaType.tv,
        (ids, type) => const [],
      );

      expect(item.title, 'Series');
      expect(item.year, 2021);
    });
  });

  test('metaShort / metaFull depend on the media type', () {
    const film = MediaItem(
      id: 1,
      type: MediaType.film,
      title: 'F',
      rating: 7,
      genres: [],
      overview: '',
      runtime: 120,
    );
    const tv = MediaItem(
      id: 2,
      type: MediaType.tv,
      title: 'T',
      rating: 7,
      genres: [],
      overview: '',
      episodes: 24,
    );

    expect(film.metaShort, '120DK');
    expect(film.metaFull, '120 DK');
    expect(tv.metaShort, '24 BÖL');
    expect(tv.metaFull, '24 BÖLÜM');
  });

  test('fromJson rebuilds cast from Hive-style loosely-typed maps', () {
    const original = MediaItem(
      id: 7,
      type: MediaType.film,
      title: 'Cast',
      rating: 7,
      genres: [],
      overview: '',
      cast: [CastMember(name: 'Ada', character: 'Lead')],
    );

    // Hive returns nested maps as Map<dynamic, dynamic>; simulate that so the
    // round-trip would crash without the defensive Map.from() in fromJson.
    final json = original.toJson();
    json['cast'] = (json['cast'] as List)
        .map((e) => Map<dynamic, dynamic>.from(e as Map))
        .toList();

    final restored = MediaItem.fromJson(json);
    expect(restored.cast.single.name, 'Ada');
    expect(restored.cast.single.character, 'Lead');
  });

  test('toJson/fromJson round-trips, preserving the extracted color', () {
    const original = MediaItem(
      id: 42,
      type: MediaType.anime,
      title: 'Round Trip',
      year: 2018,
      rating: 8.9,
      episodes: 12,
      country: 'JP',
      genres: ['Animation'],
      overview: 'o',
      color: Color(0xFF123456),
    );

    final restored = MediaItem.fromJson(original.toJson());

    expect(restored.id, 42);
    expect(restored.type, MediaType.anime);
    expect(restored.title, 'Round Trip');
    expect(restored.year, 2018);
    expect(restored.episodes, 12);
    expect(restored.country, 'JP');
    expect(restored.genres, ['Animation']);
    expect(restored.color?.toARGB32(), 0xFF123456);
  });
}
