// Visited areas and Travelling Salesman: spec 0004 §4, acceptance criteria
// 6 and 7.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  const salesman = 'travelling_salesman';

  int visited(GameState s) => s.counters['areas.visited'] ?? 0;

  test('a new game has visited Camp', () {
    final s = game.newGame(seed: 1);
    expect(s.counters['visited.camp'], 1);
    expect(visited(s), 1);
  });

  test('arriving somewhere new counts it once; coming back does not', () {
    var s = stateAt(game);
    s = game.startActivity(s, const Activity.travel('goblin_woods'));
    s = game.applySteps(s, 200).state;
    expect(s.location, 'goblin_woods');
    expect(s.counters['visited.goblin_woods'], 1);
    expect(visited(s), 2);

    s = game.startActivity(s, const Activity.travel('camp'));
    s = game.applySteps(s, 200).state;
    s = game.startActivity(s, const Activity.travel('goblin_woods'));
    s = game.applySteps(s, 200).state;
    expect(s.counters['visited.goblin_woods'], 1);
    expect(visited(s), 2);
  });

  test('passing through on a longer walk counts', () {
    // Grey Moor shows once the Old Graveyard is explored (spec 0008).
    var s = stateAt(game)..explored.add('old_graveyard');
    s = game.startActivity(s, const Activity.travel('grey_moor'));
    s = game.applySteps(s, 1300).state;
    expect(s.location, 'grey_moor');
    expect(s.counters['visited.old_graveyard'], 1);
    expect(visited(s), 3);
  });

  test('arriving at the last unvisited area unlocks Travelling Salesman', () {
    final s = stateAt(game);
    for (final id in game.data.locations.keys) {
      if (id != 'goblin_woods') s.counters['visited.$id'] = 1;
    }
    s.counters['areas.visited'] = game.data.locations.length - 1;
    final started = game.startActivity(
      s,
      const Activity.travel('goblin_woods'),
    );
    final r = game.applySteps(started, 200);
    expect(r.state.achievements, contains(salesman));
    expect(
      r.events.whereType<AchievementUnlocked>().map((e) => e.id),
      contains(salesman),
    );
  });

  // A hidden area is a bonus: the owner's choice in plan 0013 M1.
  test('Travelling Salesman asks for every area that isn\'t hidden', () {
    final a = game.data.achievements[salesman]!;
    expect(
      a.criterion,
      CounterCriterion(
        'areas.visited',
        game.data.locations.values.where((l) => !l.hidden).length,
      ),
    );
  });

  test('an older save counts the area it is in, and nothing is lost', () {
    final s = stateAt(game, level: 6, location: 'old_graveyard', bank: 77);
    final json = s.toJson()
      ..['version'] = 3
      ..['counters'] = {'steps.walked': 5000};
    final migrated = game.migrate(GameState.fromJson(json));
    expect(migrated.counters['visited.old_graveyard'], 1);
    expect(visited(migrated), 1);
    expect(migrated.counters['steps.walked'], 5000);
    expect(migrated.xp, s.xp);
    expect(migrated.bank, 77);
  });

  test('the journal keeps 20 entries (data)', () {
    expect(game.data.journalEntries, 20);
  });
}
