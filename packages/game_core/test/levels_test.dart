// Monster levels, colours, XP fade and open-ended levels: spec 0002 §2–§3,
// acceptance criteria 1 and 2.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();

  group('criterion 1: colour and XP multiplier by level difference', () {
    const expected = {
      12: (LevelColour.skull, 100),
      10: (LevelColour.skull, 100),
      9: (LevelColour.red, 100),
      5: (LevelColour.red, 100),
      4: (LevelColour.orange, 100),
      3: (LevelColour.orange, 100),
      2: (LevelColour.yellow, 100),
      0: (LevelColour.yellow, 100),
      -2: (LevelColour.yellow, 100),
      -3: (LevelColour.green, 80),
      -4: (LevelColour.green, 60),
      -5: (LevelColour.green, 40),
      -6: (LevelColour.green, 20),
      -7: (LevelColour.grey, 5),
      -10: (LevelColour.grey, 5),
    };

    for (var diff = -10; diff <= 12; diff++) {
      test('difference $diff', () {
        final want = expected[diff] ?? _between(expected, diff);
        final band = game.data.bandFor(20 + diff, 20);
        expect((band.colour, band.xpPercent), want);
      });
    }

    test('loot is identical at every colour', () {
      final g = arenaGame([
        monster(
          'imp',
          extra: {
            'drops': [
              {'item': 'goblin_hide', 'chance': 0.5},
              {'item': 'rusty_dagger', 'chance': 0.1},
            ],
          },
        ),
      ]);
      GameState after(int level) {
        var s = stateAt(g, location: 'arena', level: level, seed: 7);
        s = g.startActivity(s, const Activity.fight('imp'));
        return g.applySteps(s, 2000).state;
      }

      final yellow = after(1);
      final grey = after(20);
      expect(grey.inventory, yellow.inventory);
      expect(grey.inventory['goblin_hide'], greaterThan(50));
    });
  });

  group('XP fade', () {
    test('a won grey fight gives at least 1 XP', () {
      final g = arenaGame([monster('imp', xp: 10)]);
      var s = stateAt(g, location: 'arena', level: 20);
      final xp0 = s.xp;
      s = g.startActivity(s, const Activity.fight('imp'));
      final r = g.applySteps(s, 100);
      final won = r.events.whereType<FightWon>().toList();
      expect(won, hasLength(10));
      expect(won.map((e) => e.xp).toSet(), {1});
      expect(r.state.xp - xp0, 10);
    });

    test('a green fight gives its share, rounded down', () {
      // Level 1 monster, level 5 player: 4 below, 60%.
      final g = arenaGame([monster('imp', xp: 25)]);
      var s = stateAt(g, location: 'arena', level: 5);
      s = g.startActivity(s, const Activity.fight('imp'));
      final won = g.applySteps(s, 10).events.whereType<FightWon>().single;
      expect(won.xp, 15);
    });

    test('gathering fades by the spot level', () {
      // Copper vein is level 2: full at level 4, grey at level 9.
      for (final (level, xp) in [(4, 20), (9, 1)]) {
        var s = stateAt(game, level: level, location: 'copper_hills');
        s = game.startActivity(s, const Activity.gather('copper_vein'));
        final r = game.applySteps(s, 100);
        expect(r.events.whereType<Gathered>().single.xp, xp, reason: '$level');
      }
    });

    test('crafting fades by the recipe level', () {
      // Hide vest is level 3; at level 9 it is 6 below: 20% of 30.
      var s = stateAt(game, level: 9, inventory: {'goblin_hide': 4});
      s = game.startActivity(s, const Activity.craft('hide_vest'));
      final r = game.applySteps(s, 150);
      expect(r.events.whereType<Crafted>().single.xp, 6);
    });

    test('enemyBand compares the monster with the player', () {
      final s = stateAt(game, level: 9, location: 'goblin_woods');
      expect(game.enemyBand(s, 'goblin').colour, LevelColour.grey);
      expect(game.enemyBand(s, 'goblin_brute').colour, LevelColour.green);
    });
  });

  group('criterion 2: no level cap', () {
    final data = game.data;
    final listed = data.xpToReachLevel.length;

    test('thresholds keep growing past the list', () {
      for (var l = listed + 1; l <= listed + 20; l++) {
        final cost = data.xpForLevel(l) - data.xpForLevel(l - 1);
        final previous = data.xpForLevel(l - 1) - data.xpForLevel(l - 2);
        expect(cost, (previous * data.xpGrowthAfterList).round());
      }
    });

    test('a save with enough XP passes the end of the list', () {
      final s = game.newGame(seed: 1)..xp = data.xpForLevel(listed + 5);
      expect(game.level(s), listed + 5);
      s.xp -= 1;
      expect(game.level(s), listed + 4);
      expect(game.xpForNextLevel(s), data.xpForLevel(listed + 5));
    });

    test('levelling past the list happens during play', () {
      final g = arenaGame([monster('imp', xp: 1000)]);
      var s = stateAt(g, location: 'arena', level: listed)
        ..xp = g.data.xpForLevel(listed + 1) - 1;
      s = g.startActivity(s, const Activity.fight('imp'));
      final r = g.applySteps(s, 10);
      expect(r.events.whereType<LevelUp>().map((e) => e.level), [listed + 1]);
    });
  });
}

/// The expected value for a difference between two listed ones.
(LevelColour, int) _between(Map<int, (LevelColour, int)> table, int diff) {
  final above = table.keys.where((k) => k > diff).reduce((a, b) => a < b ? a : b);
  return table[above]!;
}
