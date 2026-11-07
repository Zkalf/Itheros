// The fighter sim walker focuses on fighting: spec 0010 amendment 11,
// criteria 1-2. Its pace (criterion 3) is in pacing_test.dart.
import 'package:game_core/simulation.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final run = simulate(
    game,
    stepsPerDay: 5000,
    days: 20,
    seed: 1,
    walker: Walker.fighter,
  );
  final s = run.finalState;

  test('criterion 1: the fighter learns every profession', () {
    expect(s.learned, containsAll(game.data.professions.keys));
  });

  // Erratum 1 splits criterion 2 into 2a (crafts) and 2b (never gathers
  // for gear).
  test('criteria 2a-2b: the fighter crafts gear, and mines and chops '
      'nothing', () {
    final crafted = [
      for (final MapEntry(:key, :value) in s.counters.entries)
        if (key.startsWith('crafted.') &&
            value > 0 &&
            game.data.items[key.substring('crafted.'.length)]?.slot != null)
          key,
    ];
    expect(crafted, isNotEmpty);
    // Ore and logs are only for gear: the fighter never gathers them.
    for (final n in game.data.nodes.values) {
      if (n.profession == 'mining' || n.profession == 'woodcutting') {
        expect(s.counters['gathered.${n.item}'] ?? 0, 0, reason: n.id);
      }
    }
  });
}
