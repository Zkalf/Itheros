// Pacing, played by the scripted sensible player in lib/simulation.dart:
// spec 0001 acceptance criterion 5 and spec 0002 criterion 3 (which replaces
// spec 0001 criterion 6), as spec 0009 criterion 16 sets them: seeds 1-8,
// level 5 on day 1-2; level 30 as spec 0009 amendment 1 sets it. Spec 0010
// §9.3: the walker's professions (target 2) and the fighter (target 3, seed
// 1 here; all seeds in tool/seeds.dart).
import 'package:game_core/simulation.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final level30 = <int?>[];
  final professionDays = <(String, int), List<int?>>{
    for (final p in ['mining', 'crafting'])
      for (final l in [10, 20]) (p, l): [],
  };

  for (var seed = 1; seed <= 8; seed++) {
    group('seed $seed', () {
      final result = simulate(game, stepsPerDay: 5000, days: 100, seed: seed);
      level30.add(result.dayReached(30));
      professionDays.forEach(
        (k, days) => days.add(result.professionDay(k.$1, k.$2)),
      );

      test('spec 0001 criterion 5: level 2 within 350 walked steps', () {
        expect(result.walkedToLevel2, isNotNull);
        expect(result.walkedToLevel2, lessThanOrEqualTo(350));
      });

      // Spec 0009 decision 1: crafting all three copper weapons moves it
      // from day 1.
      test('spec 0009 criterion 16: level 5 on day 1-2 at 5,000 steps/day', () {
        expect(result.dayReached(5), inInclusiveRange(1, 2));
      });

      // Early luck may be a day faster (spec 0010 amendment 1).
      test('spec 0010 amendment 1: level 10 on day 11-16', () {
        expect(result.dayReached(10), inInclusiveRange(11, 16));
      });

      // A lucky walker may be up to 10 days sooner (spec 0009 amendment 1).
      test('spec 0009 amendment 1: level 30 on day 70-100', () {
        expect(result.dayReached(30), inInclusiveRange(70, 100));
      });
    });
  }

  double median(List<int?> days) {
    expect(days, everyElement(isNotNull));
    final sorted = days.cast<int>()..sort();
    return (sorted[3] + sorted[4]) / 2;
  }

  test('spec 0009 amendment 1: the median seed reaches level 30 on day '
      '80-100', () {
    expect(median(level30), inInclusiveRange(80, 100));
  });

  test('spec 0010 amendment 1: Mining and Crafting 10 by day 8-22, 20 by '
      'day 45-65 (medians)', () {
    professionDays.forEach((k, days) {
      final range = k.$2 == 10 ? (8, 22) : (45, 65);
      expect(
        median(days),
        inInclusiveRange(range.$1, range.$2),
        reason: '${k.$1} ${k.$2}',
      );
    });
  });

  test('spec 0010 §9.3 target 3: the fighter is at least 15% later to level '
      '30 (seed 1)', () {
    final fighter = simulate(
      game,
      stepsPerDay: 5000,
      days: 120,
      walker: Walker.fighter,
    ).dayReached(30);
    if (fighter != null) {
      expect(fighter, greaterThanOrEqualTo(median(level30) * 1.15));
    }
  });
}
