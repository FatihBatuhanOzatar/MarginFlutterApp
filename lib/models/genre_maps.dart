import 'media_item.dart';

/// TMDB genre id → name tables. Movie and TV use *different* id sets, so list
/// endpoints (which return only `genre_ids`) need the matching table to label a
/// title. Sourced from TMDB's `/genre/movie/list` and `/genre/tv/list`.
const Map<int, String> kMovieGenreById = {
  28: 'Action',
  12: 'Adventure',
  16: 'Animation',
  35: 'Comedy',
  80: 'Crime',
  99: 'Documentary',
  18: 'Drama',
  10751: 'Family',
  14: 'Fantasy',
  36: 'History',
  27: 'Horror',
  10402: 'Music',
  9648: 'Mystery',
  10749: 'Romance',
  878: 'Science Fiction',
  10770: 'TV Movie',
  53: 'Thriller',
  10752: 'War',
  37: 'Western',
};

const Map<int, String> kTvGenreById = {
  10759: 'Action & Adventure',
  16: 'Animation',
  35: 'Comedy',
  80: 'Crime',
  99: 'Documentary',
  18: 'Drama',
  10751: 'Family',
  10762: 'Kids',
  9648: 'Mystery',
  10763: 'News',
  10764: 'Reality',
  10765: 'Sci-Fi & Fantasy',
  10766: 'Soap',
  10767: 'Talk',
  10768: 'War & Politics',
  37: 'Western',
};

/// Maps a list of TMDB genre ids to names using the table for [type].
List<String> genreNames(List<int> ids, MediaType type) {
  final table = type == MediaType.film ? kMovieGenreById : kTvGenreById;
  return ids.map((id) => table[id]).whereType<String>().toList();
}

/// Sentinel for the "TÜMÜ" (all) chip — no genre filter applied.
const String kAllGenre = 'ALL';

/// Fixed filter chips shown on the browse screen (verbatim from the prototype).
/// Filtering is client-side by genre *name*, matching the prototype's
/// `genres.includes(label)`. Note: TMDB's TV table has no Thriller/Horror, so
/// those chips naturally yield fewer results for tv/anime than for film.
const List<String> kGenreFilters = ['Thriller', 'Mystery', 'Drama', 'Horror'];
