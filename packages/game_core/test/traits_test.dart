// Monster twists and boss first-kill drops: spec 0002 §5, acceptance
// criteria 5 and 7. Arena fights have no damage variance. A level 1 player
// has 30 HP, 5 Attack and 2 Defense.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  /// The fight state after [rounds] rounds against [m].
  FightState? afterRounds(Map<String, Object?> m, int rounds) {
    final g = arenaGame([m]);
    var s = stateAt(g, location: 'arena');
    s = g.startActivity(s, Activity.fight(m['id']! as String));
    return g.applySteps(s, rounds * 10).state.activity?.fight;
  }

  group('quick', () {
    Map<String, Object?> glassImp(List<String> traits) =>
        monster('imp', hp: 1, attack: 100, extra: {'traits': traits});

    test('without it, the player strikes first and wins', () {
      final g = arenaGame([glassImp([])]);
      var s = g.startActivity(stateAt(g, location: 'arena'), const Activity.fight('imp'));
      final r = g.applySteps(s, 10);
      expect(r.events.whereType<FightWon>(), hasLength(1));
    });

    test('the monster strikes first in each round', () {
      final g = arenaGame([glassImp(['quick'])]);
      var s = g.startActivity(stateAt(g, location: 'arena'), const Activity.fight('imp'));
      final r = g.applySteps(s, 10);
      expect(r.events.whereType<FightLost>(), hasLength(1));
      expect(r.events.whereType<FightWon>(), isEmpty);
    });
  });

  test('slow: the monster attacks only every second round', () {
    // 12 attack against 2 defense: 11 damage a hit.
    final zombie = monster(
      'zombie',
      hp: 1000,
      attack: 12,
      extra: {
        'traits': ['slow'],
      },
    );
    expect([
      for (var r = 1; r <= 4; r++) afterRounds(zombie, r)!.playerHp,
    ], [30, 19, 19, 8]);
  });

  test('ghostly: its hits ignore the player\'s defense', () {
    final ghost = monster('ghost', hp: 1000, attack: 4);
    expect(afterRounds(ghost, 1)!.playerHp, 30 - 3);
    final ghostly = {
      ...ghost,
      'traits': ['ghostly'],
    };
    expect(afterRounds(ghostly, 1)!.playerHp, 30 - 4);
  });

  group('regenerates', () {
    test('heals after its turn', () {
      final troll = monster(
        'troll',
        hp: 100,
        extra: {
          'traits': ['regenerates'],
          'regen': 3,
        },
      );
      expect(afterRounds(troll, 1)!.enemyHp, 100 - 5 + 3);
      expect(afterRounds(troll, 2)!.enemyHp, 100 - 10 + 6);
    });

    test('never above its full HP', () {
      final troll = monster(
        'troll',
        hp: 100,
        extra: {
          'traits': ['regenerates'],
          'regen': 10,
        },
      );
      expect(afterRounds(troll, 3)!.enemyHp, 100);
    });
  });

  test('unknown traits are rejected when data loads', () {
    expect(
      () => arenaGame([
        monster(
          'imp',
          extra: {
            'traits': ['sneaky'],
          },
        ),
      ]),
      throwsFormatException,
    );
  });

  test('criterion 7: the first-kill item drops once, on the first kill', () {
    final g = arenaGame([
      monster(
        'king',
        extra: {
          'firstKillDrops': [
            {'item': 'copper_sword', 'count': 1},
          ],
        },
      ),
    ]);
    var s = g.startActivity(stateAt(g, location: 'arena'), const Activity.fight('king'));
    final r = g.applySteps(s, 300);
    final won = r.events.whereType<FightWon>().toList();
    expect(won.length, 30);
    expect(won.first.drops, {'copper_sword': 1});
    expect(won.skip(1).every((e) => e.drops.isEmpty), isTrue);
    expect(r.state.inventory['copper_sword'], 1);
  });
}
