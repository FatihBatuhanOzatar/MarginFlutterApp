import 'package:flutter/material.dart';

/// Base URL for TMDB poster/backdrop images; a size segment (e.g. `w500`)
/// and the path from the API are appended to form a full URL.
const String kTmdbImageBaseUrl = 'https://image.tmdb.org/t/p/';

/// The three catalog kinds the prototype exposes. `anime` is not a real TMDB
/// category — it is modeled as TV (Japanese-origin animation), see [tmdbKind].
enum MediaType {
  film,
  tv,
  anime;

  /// Turkish UI label shown on tabs and poster badges (matches the prototype).
  String get label => switch (this) {
        MediaType.film => 'FILM',
        MediaType.tv => 'DİZİ',
        MediaType.anime => 'ANİME',
      };

  /// Which TMDB endpoint family this maps to. Both `tv` and `anime` are served
  /// by the `/tv` endpoints; only `film` uses `/movie`.
  String get tmdbKind => this == MediaType.film ? 'movie' : 'tv';

  static MediaType byName(String name) =>
      MediaType.values.firstWhere((t) => t.name == name);
}

/// A single actor in a title's credits. Trimmed down to what the detail screen
/// renders: a name, the role, and an optional profile photo path.
@immutable
class CastMember {
  const CastMember({required this.name, this.character, this.profilePath});

  final String name;
  final String? character;
  final String? profilePath;

  factory CastMember.fromTmdb(Map<String, dynamic> json) => CastMember(
        name: (json['name'] ?? '') as String,
        character: json['character'] as String?,
        profilePath: json['profile_path'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'character': character,
        'profile_path': profilePath,
      };

  factory CastMember.fromJson(Map<String, dynamic> json) => CastMember(
        name: (json['name'] ?? '') as String,
        character: json['character'] as String?,
        profilePath: json['profile_path'] as String?,
      );
}

/// The app's unified media model. Built from TMDB JSON via [fromTmdbList] (the
/// lightweight list/search shape) or [fromTmdbDetail] (the full detail shape),
/// and round-tripped to/from JSON for the offline Hive cache.
@immutable
class MediaItem {
  const MediaItem({
    required this.id,
    required this.type,
    required this.title,
    required this.rating,
    required this.genres,
    required this.overview,
    this.year,
    this.runtime,
    this.episodes,
    this.country,
    this.cast = const [],
    this.posterPath,
    this.backdropPath,
    this.color,
  });

  final int id;
  final MediaType type;
  final String title;
  final int? year;
  final double rating;
  final int? runtime; // films only (minutes)
  final int? episodes; // tv/anime only
  final String? country;
  final List<String> genres;
  final String overview;
  final List<CastMember> cast;
  final String? posterPath;
  final String? backdropPath;

  /// Dominant color pulled from the poster at runtime (palette_generator).
  /// Not part of the TMDB payload; cached once computed.
  final Color? color;

  /// Full poster URL at the given [size] segment, or null when TMDB has no art.
  String? posterUrl({String size = 'w500'}) =>
      posterPath == null ? null : '$kTmdbImageBaseUrl$size$posterPath';

  /// Full backdrop URL at the given [size] segment, or null when absent.
  String? backdropUrl({String size = 'w780'}) =>
      backdropPath == null ? null : '$kTmdbImageBaseUrl$size$backdropPath';

  /// Short meta string for poster cards: `120DK` for films, `24 BÖL` otherwise.
  String? get metaShort => switch (type) {
        MediaType.film => runtime == null ? null : '${runtime}DK',
        _ => episodes == null ? null : '$episodes BÖL',
      };

  /// Long meta string for the detail screen: `120 DK` / `24 BÖLÜM`.
  String? get metaFull => switch (type) {
        MediaType.film => runtime == null ? null : '$runtime DK',
        _ => episodes == null ? null : '$episodes BÖLÜM',
      };

  MediaItem copyWith({
    String? title,
    int? year,
    double? rating,
    int? runtime,
    int? episodes,
    String? country,
    List<String>? genres,
    String? overview,
    List<CastMember>? cast,
    String? posterPath,
    String? backdropPath,
    Color? color,
  }) =>
      MediaItem(
        id: id,
        type: type,
        title: title ?? this.title,
        year: year ?? this.year,
        rating: rating ?? this.rating,
        runtime: runtime ?? this.runtime,
        episodes: episodes ?? this.episodes,
        country: country ?? this.country,
        genres: genres ?? this.genres,
        overview: overview ?? this.overview,
        cast: cast ?? this.cast,
        posterPath: posterPath ?? this.posterPath,
        backdropPath: backdropPath ?? this.backdropPath,
        color: color ?? this.color,
      );

  /// Builds from the compact shape returned by list/search endpoints, mapping
  /// `genre_ids` to names with [genreNames] (movie vs tv tables differ).
  factory MediaItem.fromTmdbList(
    Map<String, dynamic> json,
    MediaType type,
    List<String> Function(List<int> ids, MediaType type) genreNames,
  ) {
    final ids = ((json['genre_ids'] as List?) ?? const [])
        .map((e) => (e as num).toInt())
        .toList();
    return MediaItem(
      id: (json['id'] as num).toInt(),
      type: type,
      title: _title(json, type),
      year: _year(json, type),
      rating: ((json['vote_average'] as num?) ?? 0).toDouble(),
      country: _country(json),
      genres: genreNames(ids, type),
      overview: (json['overview'] ?? '') as String,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
    );
  }

  /// Builds from the full detail shape (`append_to_response=credits`), which
  /// carries runtime/episodes, named `genres`, country, and the cast list.
  factory MediaItem.fromTmdbDetail(Map<String, dynamic> json, MediaType type) {
    final genres = ((json['genres'] as List?) ?? const [])
        .map((g) => (g as Map)['name'] as String)
        .toList();
    final cast = (((json['credits'] as Map?)?['cast'] as List?) ?? const [])
        .take(12)
        .map((c) => CastMember.fromTmdb(c as Map<String, dynamic>))
        .toList();
    return MediaItem(
      id: (json['id'] as num).toInt(),
      type: type,
      title: _title(json, type),
      year: _year(json, type),
      rating: ((json['vote_average'] as num?) ?? 0).toDouble(),
      runtime: type == MediaType.film ? json['runtime'] as int? : null,
      episodes:
          type == MediaType.film ? null : json['number_of_episodes'] as int?,
      country: _detailCountry(json) ?? _country(json),
      genres: genres,
      overview: (json['overview'] ?? '') as String,
      cast: cast,
      posterPath: json['poster_path'] as String?,
      backdropPath: json['backdrop_path'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'year': year,
        'rating': rating,
        'runtime': runtime,
        'episodes': episodes,
        'country': country,
        'genres': genres,
        'overview': overview,
        'cast': cast.map((c) => c.toJson()).toList(),
        'poster_path': posterPath,
        'backdrop_path': backdropPath,
        'color': color?.toARGB32(),
      };

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        id: (json['id'] as num).toInt(),
        type: MediaType.byName(json['type'] as String),
        title: json['title'] as String,
        year: json['year'] as int?,
        rating: (json['rating'] as num).toDouble(),
        runtime: json['runtime'] as int?,
        episodes: json['episodes'] as int?,
        country: json['country'] as String?,
        genres:
            ((json['genres'] as List?) ?? const []).map((e) => e as String).toList(),
        overview: (json['overview'] ?? '') as String,
        cast: ((json['cast'] as List?) ?? const [])
            .map((c) => CastMember.fromJson(c as Map<String, dynamic>))
            .toList(),
        posterPath: json['poster_path'] as String?,
        backdropPath: json['backdrop_path'] as String?,
        color: json['color'] == null ? null : Color(json['color'] as int),
      );

  // --- TMDB field helpers (movie vs tv use different key names) ---

  static String _title(Map<String, dynamic> json, MediaType type) =>
      ((type == MediaType.film ? json['title'] : json['name']) ??
          json['title'] ??
          json['name'] ??
          '') as String;

  static int? _year(Map<String, dynamic> json, MediaType type) {
    final raw =
        (type == MediaType.film ? json['release_date'] : json['first_air_date'])
            as String?;
    if (raw == null || raw.length < 4) return null;
    return int.tryParse(raw.substring(0, 4));
  }

  static String? _country(Map<String, dynamic> json) {
    final list = json['origin_country'] as List?;
    if (list != null && list.isNotEmpty) return list.first as String;
    return null;
  }

  static String? _detailCountry(Map<String, dynamic> json) {
    final list = json['production_countries'] as List?;
    if (list != null && list.isNotEmpty) {
      return (list.first as Map)['iso_3166_1'] as String?;
    }
    return null;
  }
}
