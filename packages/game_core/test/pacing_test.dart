// Pacing, played by the scripted sensible player in lib/simulation.dart:
// spec 0001 acceptance criterion 5 and spec 0002 criterion 3 (which replaces
// spec 0001 criterion 6), as spec 0009 criterion 16 sets them: seeds 1-8,
// level 5 on day 1-2; level 30 as spec 0009 amendment 1 sets it.
import 'package:game_core/simulation.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final level30 = <int?>[];

  for (var seed = 1; seed <= 8; seed++) {
    group('seed $seed', () {
      final result = simulate(game, stepsPerDay: 5000, days: 100, seed: seed);
      level30.add(result.dayReached(30));

      test('spec 0001 criterion 5: level 2 within 350 walked steps', () {
        expect(result.walkedToLevel2, isNotNull);
        expect(result.walkedToLevel2, lessThanOrEqualTo(350));
      });

      // Spec 0009 decision 1: crafting all three copper weapons moves it
      // from day 1.
      test('spec 0009 criterion 16: level 5 on day 1-2 at 5,000 steps/day', () {
        expect(result.dayReached(5), inInclusiveRange(1, 2));
      });

      test('spec 0002 criterion 3: level 10 on day 12-16', () {
        expect(result.dayReached(10), inInclusiveRange(12, 16));
      });

      // A lucky walker may be up to 10 days sooner (spec 0009 amendment 1).
      test('spec 0009 amendment 1: level 30 on day 70-100', () {
        expect(result.dayReached(30), inInclusiveRange(70, 100));
      });
    });
  }

  test('spec 0009 amendment 1: the median seed reaches level 30 on day '
      '80-100', () {
    expect(level30, everyElement(isNotNull));
    final days = level30.cast<int>()..sort();
    expect((days[3] + days[4]) / 2, inInclusiveRange(80, 100));
  });
}
