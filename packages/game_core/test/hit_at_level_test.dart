// Hit as a chance, and the sources of the stats: spec 0009 amendment 4
// criteria 1-4 and 16 (plan 0060). The stats block and the sheets (criteria
// 5-15) are in the app's stat_sheet_test.dart.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final combat = game.data.combat;

  GameState at({int level = 12, Map<String, String> worn = const {}}) =>
      stateAt(game, level: level)..equipment.addAll(worn);

  group('Hit shows a chance', () {
    test('criterion 1: with no Hit it is the base chance of the data', () {
      expect(game.hitChanceAtLevel(at()), combat.hitBase);
      expect(combat.hitBase, 75);
    });

    test('criterion 2: +4% Hit from gear adds 4', () {
      final s = at(worn: {'mainHand': 'bone_sword@rare+hit4'});
      expect(game.stats(s).hit, 4);
      expect(game.hitChanceAtLevel(s), 79);
    });

    test('criterion 3: it never goes above the top of the data', () {
      final s = at(
        worn: {
          'mainHand': 'bone_sword@rare+hit4+hit4',
          'offHand': 'bone_shield@rare+hit4+hit4',
          'chest': 'hide_vest@rare+hit4+hit4',
        },
      )..talents['precision'] = 3;
      expect(game.stats(s).hit, greaterThan(combat.hitMax - combat.hitBase));
      expect(game.hitChanceAtLevel(s), combat.hitMax);
    });

    test('criterion 4: Slayer does not change it', () {
      final s = at()..counters['kills.goblin'] = combat.slayerKills;
      expect(game.slayer(s, 'goblin'), isTrue);
      expect(game.hitChanceAtLevel(s), combat.hitBase);
    });

    test('criterion 16: the chance in a fight still follows the monster', () {
      final s = at(worn: {'mainHand': 'bone_sword@rare+hit4'});
      for (final e in game.data.enemies.values) {
        expect(
          game.playerHitChance(s, e.id),
          combat.hitChance(12 - e.level, 4),
          reason: e.id,
        );
      }
      // Slayer still counts against its own monster.
      final slayer = at()..counters['kills.goblin'] = combat.slayerKills;
      expect(
        game.playerHitChance(slayer, 'goblin'),
        combat.hitChance(12 - game.data.enemies['goblin']!.level, 5),
      );
    });
  });

  group('the sources of the stats', () {
    test('the parts add up to the stats, for a player with gear, talents and '
        'a meal', () {
      final s =
          at(
              worn: {
                'mainHand': 'bone_sword@rare+hit4',
                'offHand': 'bone_shield@rare+block5+crit2',
                'chest': 'hide_vest',
              },
            )
            ..talents['toughness'] = 5
            ..talents['precision'] = 2
            ..meal = ActiveMeal('grilled_perch', 6000);
      final p = game.statParts(s);
      final sum = p.level + p.gear + p.talents + p.meal + p.achievements;
      expect(sum, game.stats(s));
      // Each source holds its own share.
      expect(p.level.hp, greaterThan(0));
      expect(p.level.hit, 0);
      expect(p.gear.hit, 4);
      expect(p.gear.block, greaterThan(0));
      expect(p.talents.hp, greaterThan(0));
      expect(p.talents.hit, greaterThan(0));
      expect(p.meal.hp, greaterThan(0));
      expect(p.meal.attack, 0);
    });

    test('a new player has the level alone', () {
      final p = game.statParts(game.newGame(seed: 1));
      expect(p.level, game.data.baseStats);
      for (final other in [p.gear, p.talents, p.meal, p.achievements]) {
        expect(other, const Stats());
      }
    });
  });
}
