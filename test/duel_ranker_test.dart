import 'package:flutter_test/flutter_test.dart';
import 'package:margin/utils/duel_ranker.dart';

/// Drive the ranker with a deterministic oracle (bigger int = better) and read
/// back the ranking.
List<int> _rank(List<int> items) {
  final ranker = DuelRanker<int>(items);
  var guard = 0;
  while (!ranker.isDone) {
    final pair = ranker.pair!;
    ranker.choose(pair.$1 >= pair.$2 ? pair.$1 : pair.$2);
    if (++guard > 10000) fail('ranker did not terminate');
  }
  return ranker.ranking;
}

void main() {
  test('empty and single lists are immediately done', () {
    expect(DuelRanker<int>([]).isDone, isTrue);
    expect(DuelRanker<int>([]).ranking, isEmpty);

    final one = DuelRanker<int>([7]);
    expect(one.isDone, isTrue);
    expect(one.ranking, [7]);
  });

  test('fully sorts by the user preference (best first)', () {
    expect(_rank([3, 1, 2]), [3, 2, 1]);
    expect(_rank([5, 4, 3, 2, 1]), [5, 4, 3, 2, 1]);
    expect(_rank([1, 2, 3, 4, 5, 6, 7]), [7, 6, 5, 4, 3, 2, 1]);
    expect(_rank([2, 7, 1, 9, 4]), [9, 7, 4, 2, 1]);
  });

  test('comparison count stays within the estimate and is positive', () {
    final ranker = DuelRanker<int>([1, 2, 3, 4, 5, 6, 7, 8]);
    var guard = 0;
    while (!ranker.isDone) {
      final p = ranker.pair!;
      ranker.choose(p.$1 >= p.$2 ? p.$1 : p.$2);
      if (++guard > 10000) fail('ranker did not terminate');
    }
    expect(ranker.comparisons, greaterThan(0));
    expect(ranker.comparisons, lessThanOrEqualTo(ranker.estimatedTotal));
  });
}
