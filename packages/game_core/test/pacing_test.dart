// Pacing, played by the scripted sensible player in lib/simulation.dart:
// spec 0001 acceptance criterion 5 and spec 0002 criterion 3 (which replaces
// spec 0001 criterion 6).
import 'package:game_core/simulation.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();

  for (final seed in [1, 2, 3]) {
    group('seed $seed', () {
      final result = simulate(game, stepsPerDay: 5000, days: 100, seed: seed);

      test('spec 0001 criterion 5: level 2 within 350 walked steps', () {
        expect(result.walkedToLevel2, isNotNull);
        expect(result.walkedToLevel2, lessThanOrEqualTo(350));
      });

      test('spec 0002 criterion 3: level 5 on day 1 at 5,000 steps/day', () {
        expect(result.dayReached(5), 1);
      });

      test('spec 0002 criterion 3: level 10 on day 12-16', () {
        expect(result.dayReached(10), inInclusiveRange(12, 16));
      });

      test('spec 0002 criterion 3: level 30 on day 80-100', () {
        expect(result.dayReached(30), inInclusiveRange(80, 100));
      });
    });
  }
}
