import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/genre_maps.dart';
import '../models/media_item.dart';

/// Raised for any TMDB request that fails (network, timeout, bad key, non-2xx).
/// Carries a Turkish, user-facing [message] and the HTTP [statusCode] if known.
class TmdbException implements Exception {
  const TmdbException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'TmdbException($statusCode): $message';
}

/// Thin TMDB v3 client. Reads the API key from the compile-time environment
/// (`--dart-define=TMDB_KEY=...`) so it is never committed to the repo.
///
/// Endpoints used:
/// - browse: `/movie/top_rated`, `/tv/top_rated`, and `/discover/tv` for anime
/// - search: `/search/multi`
/// - detail: `/movie/{id}` · `/tv/{id}` with `append_to_response=credits`
class TmdbApi {
  TmdbApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _base = 'https://api.themoviedb.org/3';
  static const String _key = String.fromEnvironment('TMDB_KEY');
  static const Duration _timeout = Duration(seconds: 12);

  /// Whether a key was supplied at build time. The UI uses this to show a clear
  /// "set your key" message instead of a generic network error.
  bool get hasKey => _key.isNotEmpty;

  Uri _uri(String path, [Map<String, String> query = const {}]) =>
      Uri.parse('$_base$path').replace(queryParameters: {
        'api_key': _key,
        'language': 'tr-TR',
        ...query,
      });

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    if (!hasKey) {
      throw const TmdbException(
        'TMDB anahtarı tanımlı değil. Uygulamayı '
        '--dart-define=TMDB_KEY=... ile başlatın.',
      );
    }
    final http.Response res;
    try {
      res = await _client.get(uri).timeout(_timeout);
    } catch (_) {
      throw const TmdbException(
        'Bağlantı kurulamadı. İnternetinizi kontrol edip tekrar deneyin.',
      );
    }
    if (res.statusCode == 401) {
      throw const TmdbException(
        'TMDB anahtarı geçersiz. Anahtarınızı kontrol edin.',
        statusCode: 401,
      );
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw TmdbException(
        'Sunucu hatası (${res.statusCode}). Lütfen tekrar deneyin.',
        statusCode: res.statusCode,
      );
    }
    return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
  }

  /// Fetches a browse list for [type], pulling [pages] pages and concatenating
  /// them. Drops entries without a poster and de-duplicates by id.
  Future<List<MediaItem>> browse(MediaType type, {int pages = 2}) async {
    final seen = <int>{};
    final items = <MediaItem>[];
    for (var page = 1; page <= pages; page++) {
      final json = await _getJson(_browseUri(type, page));
      final results = (json['results'] as List?) ?? const [];
      for (final raw in results) {
        final map = raw as Map<String, dynamic>;
        if (map['poster_path'] == null) continue;
        final id = (map['id'] as num).toInt();
        if (!seen.add(id)) continue;
        items.add(MediaItem.fromTmdbList(map, type, genreNames));
      }
    }
    return items;
  }

  Uri _browseUri(MediaType type, int page) => switch (type) {
        MediaType.film => _uri('/movie/top_rated', {'page': '$page'}),
        MediaType.tv => _uri('/tv/top_rated', {'page': '$page'}),
        // Anime = Japanese-origin animation, ranked by popularity with enough
        // votes to keep the list reputable.
        MediaType.anime => _uri('/discover/tv', {
            'with_genres': '16',
            'with_origin_country': 'JP',
            'sort_by': 'popularity.desc',
            'vote_count.gte': '500',
            'page': '$page',
          }),
      };

  /// Multi-search across movies and TV. People results are skipped; each hit is
  /// mapped to the right [MediaType] (Japanese animation TV is tagged anime).
  Future<List<MediaItem>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final json = await _getJson(_uri('/search/multi', {
      'query': trimmed,
      'include_adult': 'false',
      'page': '1',
    }));
    final results = (json['results'] as List?) ?? const [];
    final items = <MediaItem>[];
    final seen = <int>{};
    for (final raw in results) {
      final map = raw as Map<String, dynamic>;
      final mediaType = map['media_type'] as String?;
      if (mediaType != 'movie' && mediaType != 'tv') continue;
      if (map['poster_path'] == null) continue;
      final id = (map['id'] as num).toInt();
      if (!seen.add(id)) continue;
      items.add(MediaItem.fromTmdbList(map, _searchType(map, mediaType!),
          genreNames));
    }
    return items;
  }

  /// A TV search hit counts as anime when it is Japanese animation.
  MediaType _searchType(Map<String, dynamic> map, String mediaType) {
    if (mediaType == 'movie') return MediaType.film;
    final ids = ((map['genre_ids'] as List?) ?? const [])
        .map((e) => (e as num).toInt());
    final origins = ((map['origin_country'] as List?) ?? const [])
        .map((e) => e as String);
    final isAnime = ids.contains(16) && origins.contains('JP');
    return isAnime ? MediaType.anime : MediaType.tv;
  }

  /// Full detail for one title, including credits (cast) for the detail screen.
  Future<MediaItem> detail(MediaType type, int id) async {
    final json = await _getJson(_uri('/${type.tmdbKind}/$id', {
      'append_to_response': 'credits',
    }));
    return MediaItem.fromTmdbDetail(json, type);
  }

  void dispose() => _client.close();
}
