/// Drives a personal ranking by asking the user one "A or B?" question at a time
/// and running a bottom-up merge sort over the answers.
///
/// Merge sort needs only ~n·log2(n) comparisons and yields a *fully* sorted
/// result — unlike a single-elimination bracket, which only reliably crowns the
/// winner. The class is a pure state machine (no UI, no async): read [pair],
/// call [choose] with the winner, repeat until [isDone], then read [ranking].
class DuelRanker<T> {
  DuelRanker(List<T> items)
      : _runs = [for (final it in items) <T>[it]],
        estimatedTotal = _estimate(items.length) {
    _prepare();
  }

  /// A rough upper bound on the number of comparisons (for a progress bar).
  final int estimatedTotal;

  // Bottom-up merge sort over a list of sorted "runs". Each pass merges adjacent
  // runs pairwise into [_next], which becomes [_runs] for the next pass.
  List<List<T>> _runs;
  final List<List<T>> _next = [];
  int _i = 0; // index of the left run of the pair currently merging

  // The active merge of _runs[_i] and _runs[_i + 1].
  List<T> _left = const [];
  List<T> _right = const [];
  int _li = 0;
  int _ri = 0;
  List<T> _merged = [];

  int _comparisons = 0;
  bool _done = false;

  bool get isDone => _done;
  int get comparisons => _comparisons;

  /// The current pair to compare (left, right), or null once [isDone].
  (T, T)? get pair => _done ? null : (_left[_li], _right[_ri]);

  /// The ranking, best first. Meaningful once [isDone].
  List<T> get ranking => _runs.isNotEmpty ? _runs.first : const [];

  /// Advances internal state until a real comparison is pending or sorting is
  /// complete — draining trivial cases (odd run, finished level) along the way.
  void _prepare() {
    while (true) {
      if (_runs.length <= 1) {
        _done = true;
        return;
      }
      if (_i >= _runs.length) {
        // Pass complete: the merged runs become the current level.
        _runs = List.of(_next);
        _next.clear();
        _i = 0;
        continue;
      }
      if (_i + 1 >= _runs.length) {
        // Odd run with no partner — carry it to the next level untouched.
        _next.add(_runs[_i]);
        _i += 1;
        continue;
      }
      _left = _runs[_i];
      _right = _runs[_i + 1];
      _li = 0;
      _ri = 0;
      _merged = [];
      return; // heads of _left/_right are now the pending comparison
    }
  }

  /// Records that [winner] (one of the current [pair]) ranks higher, then
  /// advances to the next pending comparison.
  void choose(T winner) {
    if (_done) return;
    _comparisons++;
    if (identical(winner, _left[_li])) {
      _merged.add(_left[_li]);
      _li++;
    } else {
      _merged.add(_right[_ri]);
      _ri++;
    }
    if (_li >= _left.length || _ri >= _right.length) {
      // One side exhausted — append the remainder (no comparisons needed).
      _merged
        ..addAll(_left.sublist(_li))
        ..addAll(_right.sublist(_ri));
      _next.add(_merged);
      _i += 2;
      _prepare();
    }
    // Otherwise the same merge continues with the new heads.
  }

  static int _estimate(int n) {
    if (n < 2) return 0;
    var levels = 0;
    var size = 1;
    while (size < n) {
      size *= 2;
      levels++;
    }
    return n * levels; // ~ n·ceil(log2 n), an upper bound
  }
}
