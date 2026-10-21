// Bonus stats on gear above Common: spec 0009 §5, §10, acceptance criteria
// 7-10.
import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;
  const qualities = ['common', 'uncommon', 'rare', 'epic', 'legendary'];

  group('criterion 7: rolling', () {
    // Item level -> the §5.1 table's tier.
    const tierRanges = {
      5: {'crit': (1, 2), 'hp': (4, 8)},
      15: {
        'crit': (1, 3),
        'hp': (10, 18),
        'hit': (2, 4),
        'dodge': (2, 4),
        'block': (3, 5),
      },
      25: {
        'crit': (2, 4),
        'hp': (20, 34),
        'hit': (3, 5),
        'dodge': (3, 5),
        'block': (3, 6),
      },
    };

    test('the pools and tiers of §5.1', () {
      expect(data.bonusTierFor(1).ranges, tierRanges[5]);
      expect(data.bonusTierFor(9).ranges, tierRanges[5]);
      expect(data.bonusTierFor(10).ranges, tierRanges[15]);
      expect(data.bonusTierFor(19).ranges, tierRanges[15]);
      expect(data.bonusTierFor(20).ranges, tierRanges[25]);
      expect(data.bonusTierFor(30).ranges, tierRanges[25]);
    });

    test('one roll per quality step, from the tier\'s pool, in range; '
        'Block only off hand; repeats happen', () {
      final rng = Rng.seeded(7);
      var repeats = 0;
      final blocks = <String, int>{};
      for (final MapEntry(key: level, value: ranges) in tierRanges.entries) {
        for (final item in ['iron_sword', 'iron_shield', 'iron_helm']) {
          for (var i = 0; i < 400; i++) {
            for (final (steps, q) in qualities.indexed) {
              final rolls = game.rollBonus(rng, item, q, level);
              expect(rolls, hasLength(steps), reason: '$item $q');
              for (final r in rolls) {
                final (lo, hi) = ranges[r.stat]!;
                expect(r.value, inInclusiveRange(lo, hi), reason: '$r');
                if (r.stat == 'block') {
                  blocks[item] = (blocks[item] ?? 0) + 1;
                }
              }
              if (rolls.map((r) => r.stat).toSet().length < rolls.length) {
                repeats++;
              }
            }
          }
        }
      }
      expect(blocks.keys, ['iron_shield']);
      expect(repeats, greaterThan(0));
    });

    test('crafted gear carries its rolls in its key; Common has none', () {
      var s = stateAt(game, level: 3, inventory: {'copper_ore': 5 * 150});
      s = game.startActivity(
        s,
        const Activity.craft('copper_sword'),
        stop: StopCondition.untilCrafted(150),
      );
      s = game.applySteps(s, 150 * 150).state;
      final swords = [
        for (final k in s.inventory.keys)
          if (data.itemOf(k)?.id == 'copper_sword') k,
      ];
      expect(swords.where((k) => data.qualityOf(k).id != 'common'), isNotEmpty);
      for (final k in swords) {
        final steps = data.qualities.indexOf(data.qualityOf(k));
        expect(data.bonusRolls(k), hasLength(steps), reason: k);
        if (steps == 0) expect(k, 'copper_sword');
      }
      expect(game.owned(s, 'copper_sword'), 150);
    });

    test('a key\'s bonus stats add to its quality stats', () {
      // Rare bone shield: Defense 3 -> 5 (+2 for 2 quality steps), Block
      // isn't raised by quality (§5.2).
      final b = data.bonusOf('bone_shield@rare+block5+crit2');
      expect(b.defense, 5);
      expect(b.block, data.items['bone_shield']!.bonus.block + 5);
      expect(b.crit, 2);
      expect(data.qualityOf('bone_shield@rare+block5+crit2').id, 'rare');
      expect(data.itemOf('bone_shield@rare+block5+crit2')!.id, 'bone_shield');
      expect(
        data.plainKey('bone_shield@rare+block5+crit2'),
        'bone_shield@rare',
      );
    });

    test('repeats stack in the key and the stats', () {
      final key = data.keyFor('iron_sword', 'epic', [
        (stat: 'crit', value: 2),
        (stat: 'hp', value: 12),
        (stat: 'crit', value: 3),
      ]);
      expect(key, 'iron_sword@epic+crit3+crit2+hp12');
      expect(data.bonusRolls(key), hasLength(3));
      expect(data.bonusOf(key).crit, 5);
      expect(data.bonusOf(key).hp, 12);
    });
  });

  test('criterion 8: the same save and steps give the same items', () {
    GameState run() {
      var s = stateAt(
        game,
        level: 3,
        inventory: {'copper_ore': 5 * 60, 'oak_log': 60},
      );
      s = game.startActivity(
        s,
        const Activity.craft('copper_mace'),
        stop: StopCondition.untilCrafted(60),
      );
      return game.applySteps(s, 150 * 60).state;
    }

    final a = run();
    expect(a.inventory.keys.where((k) => k.contains('+')), isNotEmpty);
    expect(a.inventory, run().inventory);
  });

  group('criterion 9: stacks, equip and swap', () {
    const four = 'iron_shield@legendary+crit3+hp12+dodge4+block5';

    test('the same rolls in any order make one key', () {
      final a = data.keyFor('iron_shield', 'legendary', [
        (stat: 'block', value: 5),
        (stat: 'crit', value: 3),
        (stat: 'dodge', value: 4),
        (stat: 'hp', value: 12),
      ]);
      expect(a, four);
    });

    test('items stack only with the same item, quality and bonus stats', () {
      final s = stateAt(game)
        ..addItem('iron_sword@rare+crit2+hp12')
        ..addItem('iron_sword@rare+crit2+hp12')
        ..addItem('iron_sword@rare+crit3+hp12')
        ..addItem('iron_sword')
        ..addItem('iron_sword');
      expect(s.inventory, {
        'iron_sword@rare+crit2+hp12': 2,
        'iron_sword@rare+crit3+hp12': 1,
        'iron_sword': 2,
      });
    });

    test('equip, swap, unequip and save never lose an item or a roll', () {
      var s = stateAt(game, level: 14, inventory: {four: 1, 'iron_shield': 1});
      int total(GameState s) =>
          s.equipment.length + s.inventory.values.fold(0, (a, b) => a + b);

      s = game.equip(s, four);
      expect(s.equipment['offHand'], four);
      expect(game.stats(s).block, 32 + 5);
      s = game.equip(s, 'iron_shield');
      expect(s.inventory, {four: 1});
      s = game.equip(s, four);
      s = GameState.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, Object?>,
      );
      expect(s.equipment['offHand'], four);
      s = game.unequip(s, 'offHand');
      expect(s.inventory, {four: 1, 'iron_shield': 1});
      expect(total(s), 2);
    });
  });

  group('criterion 10: an existing save', () {
    GameState load(Map<String, Object?> game) => newTestGame().migrate(
      GameState.fromJson(jsonDecode(jsonEncode(game)) as Map<String, Object?>),
    );

    Map<String, Object?> v6() => newTestGame().newGame(seed: 3).toJson()
      ..['version'] = 6
      ..remove('fought')
      ..remove('lore')
      ..['equipment'] = {
        'mainHand': 'bone_sword@epic',
        'chest': 'hide_vest',
        'offHand': 'ectoplasm_ward@uncommon',
      }
      ..['inventory'] = {
        'rusty_dagger@rare': 3,
        'rusty_dagger': 2,
        'goblin_hide': 7,
      }
      ..['counters'] = {'kills.goblin': 12, 'kills.skeleton': 1};

    test('every item above Common rolls once; Common gear is unchanged', () {
      final s = load(v6());
      expect(data.bonusRolls(s.equipment['mainHand']!), hasLength(3));
      expect(data.qualityOf(s.equipment['mainHand']!).id, 'epic');
      expect(data.bonusRolls(s.equipment['offHand']!), hasLength(1));
      expect(s.equipment['chest'], 'hide_vest');
      expect(s.inventory['rusty_dagger'], 2);
      expect(s.inventory['goblin_hide'], 7);
      final daggers = {
        for (final MapEntry(:key, :value) in s.inventory.entries)
          if (data.qualityOf(key).id == 'rare') key: value,
      };
      expect(daggers.values.fold(0, (a, b) => a + b), 3, reason: 'none lost');
      for (final k in daggers.keys) {
        expect(data.bonusRolls(k), hasLength(2), reason: k);
        // A dagger drops from level 1 goblins: tier 1.
        for (final r in data.bonusRolls(k)) {
          expect(['crit', 'hp'], contains(r.stat));
        }
      }
    });

    test('rolled with the save\'s generator, once', () {
      final a = load(v6());
      final b = load(v6());
      expect(a.toJson(), b.toJson());
      expect(a.rngState, isNot(v6()['rng']));
      final again = newTestGame().migrate(
        GameState.fromJson(
          jsonDecode(jsonEncode(a.toJson())) as Map<String, Object?>,
        ),
      );
      expect(again.toJson(), a.toJson(), reason: 'a version 7 save is kept');
    });

    test('every monster with a kill counts as fought', () {
      expect(load(v6()).fought, {'goblin', 'skeleton'});
    });

    test('a fight, won or lost, marks the monster as fought', () {
      var s = stateAt(game, location: 'goblin_woods');
      expect(s.fought, isEmpty);
      s = game.startActivity(s, const Activity.fight('goblin'));
      s = game.applySteps(s, 200).state;
      expect(s.fought, {'goblin'});
    });
  });
}
