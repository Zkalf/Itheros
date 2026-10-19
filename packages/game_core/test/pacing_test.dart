// Pacing: spec 0001 acceptance criteria 5 and 6, played by the scripted
// sensible player in lib/simulation.dart.
import 'package:game_core/simulation.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();

  for (final seed in [1, 2, 3]) {
    group('seed $seed', () {
      final result = simulate(game, stepsPerDay: 5000, days: 12, seed: seed);

      test('criterion 5: level 2 within 350 walked steps', () {
        expect(result.walkedToLevel2, isNotNull);
        expect(result.walkedToLevel2, lessThanOrEqualTo(350));
      });

      test('criterion 6: level 5 on day 1 at 5,000 steps/day', () {
        expect(result.dayReached(5), 1);
      });

      test(
        'criterion 6: level 10 within days 7-11 at 5,000 steps/day',
        () => expect(result.dayReached(10), inInclusiveRange(7, 11)),
        skip: 'Superseded by spec 0002 (level 10 on day 12-16); '
            'replaced in plan 0003 M3',
      );
    });
  }
}
