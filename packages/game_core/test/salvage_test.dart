// Tools, rare finds, rings and trinkets, salvage, rerolls, shards and tips:
// spec 0010 criteria 4-5, 7-12 (plan 0012 M2).
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;

  StepReport work(GameState s, Activity a, int steps) =>
      game.applySteps(game.startActivity(s, a), steps);

  group('criterion 4: teachers tell tips', () {
    test('a tip waits until the level, then talking tells it', () {
      var s = game.learn(game.newGame(seed: 1), 'mining');
      final first = data.professions['mining']!.tips.first;
      expect(first.level, 1);
      expect(game.tipsWaiting(s, 'mining').map((t) => t.id), [first.id]);
      s = game.talk(s, 'mining');
      expect(s.tips, {first.id});
      expect(game.tipsWaiting(s, 'mining'), isEmpty);
      expect(game.knowledge(s, first.enemy).armour, isTrue);
      expect(game.knowledge(s, first.enemy).weakness, isTrue);
      expect(game.knowledge(s, first.enemy).stats, isFalse);
    });

    test('three tips each, at levels 1, 10 and 20', () {
      for (final p in data.professions.values) {
        expect(p.tips.map((t) => t.level), [1, 10, 20], reason: p.id);
      }
      final s = stateAt(game, professionLevel: 10);
      expect(game.tipsWaiting(s, 'crafting'), hasLength(2));
      expect(
        () => game.talk(s..location = 'goblin_woods', 'crafting'),
        throwsA(isA<ActivityError>()),
      );
    });
  });

  group('criterion 5: tools', () {
    test('step cost by tier and quality, rounded up', () {
      for (final (tool, steps) in [
        ('old_pick', 100),
        ('copper_pickaxe', 90),
        ('iron_pickaxe', 80),
        ('mithril_pickaxe', 70),
        ('copper_pickaxe@rare', 86),
        ('mithril_pickaxe@legendary', 62),
      ]) {
        final s = stateAt(game)..tools['mining'] = tool;
        expect(game.professionSteps(s, 'mining', 100), steps, reason: tool);
      }
      final s = stateAt(game)..tools['mining'] = 'copper_pickaxe@uncommon';
      expect(game.professionSteps(s, 'mining', 150), 132); // 150 x 0.88
    });

    test('a better tool swaps in; the old one goes to the bag', () {
      var s = stateAt(game)..addItem('iron_pickaxe@rare');
      s = game.equipTool(s, 'iron_pickaxe@rare');
      expect(s.tools['mining'], 'iron_pickaxe@rare');
      expect(s.inventory, {'old_pick': 1});
    });

    test('tools are crafted, roll quality and have no bonus stats', () {
      var s = stateAt(
        game,
        professionLevel: 3,
        inventory: {'copper_ore': 4 * 200, 'oak_log': 2 * 200},
      );
      s = game.startActivity(
        s,
        const Activity.craft('copper_pickaxe'),
        stop: const StopCondition.untilCrafted(200),
      );
      final made = game
          .applySteps(s, 150 * 200)
          .state
          .inventory
          .keys
          .where((k) => data.itemOf(k)?.id == 'copper_pickaxe');
      expect(made.where((k) => k.contains('@')), isNotEmpty);
      expect(made.every((k) => data.bonusRolls(k).isEmpty), isTrue);
    });

    test('no tool, no work', () {
      final s = stateAt(game, location: 'copper_hills')..tools.remove('mining');
      expect(game.nodeLevelMet(s, 'copper_vein'), isFalse);
      expect(
        game.lockedReason(s, const Activity.gather('copper_vein')),
        'You need a pickaxe',
      );
    });
  });

  group('criterion 7: rare finds, rings and trinkets', () {
    test('about 1 in 200 actions with a Common tool at the spot\'s level', () {
      var s = stateAt(game, location: 'copper_hills', professionLevel: 1);
      s = game.startActivity(s, const Activity.gather('copper_vein'));
      final r = game.applySteps(s, 100 * 20000);
      final found = r.events.whereType<RareFound>().length;
      expect(found / 20000, closeTo(0.005, 0.001));
      expect(r.state.inventory['garnet'], found);
    });

    test('the chance: tool quality and levels above the spot', () {
      final s = stateAt(game, professionLevel: 1)..tools['mining'] = 'old_pick';
      expect(game.rareFindChance(s, 'copper_vein'), closeTo(0.005, 1e-12));
      s.tools['mining'] = 'copper_pickaxe@legendary';
      expect(game.rareFindChance(s, 'copper_vein'), closeTo(0.006, 1e-12));
      s.professions['mining'] = data.professionXpForLevel(30);
      expect(
        game.rareFindChance(s, 'copper_vein'),
        closeTo(0.005 * 1.2 * 1.1, 1e-12),
      );
    });

    test('each spot has its find', () {
      expect(
        {for (final n in data.nodes.values) n.id: n.rareFind},
        {
          'copper_vein': 'garnet',
          'iron_vein': 'sapphire',
          'mithril_vein': 'star_diamond',
          'oak_tree': 'oak_heartwood',
          'ash_tree': 'ash_heartwood',
          'pine_tree': 'pine_heartwood',
        },
      );
    });

    test('ring and trinket recipes', () {
      for (final (id, crafting, inputs, slot) in [
        ('garnet_ring', 5, {'garnet': 1, 'copper_ore': 3}, 'ring'),
        ('oak_charm', 5, {'oak_heartwood': 1, 'goblin_hide': 2}, 'trinket'),
        ('sapphire_ring', 15, {'sapphire': 1, 'iron_ore': 4}, 'ring'),
        ('ash_totem', 15, {'ash_heartwood': 1, 'ectoplasm': 2}, 'trinket'),
        (
          'star_diamond_ring',
          25,
          {'star_diamond': 1, 'mithril_ore': 4},
          'ring',
        ),
        ('pine_idol', 25, {'pine_heartwood': 1, 'feathers': 2}, 'trinket'),
      ]) {
        final r = data.recipes[id]!;
        expect((r.craftingLevel, r.inputs), (crafting, inputs), reason: id);
        expect(data.items[id]!.slot, slot);
      }
      expect(game.slotsFor('garnet_ring'), ['ring1', 'ring2']);
    });
  });

  group('criterion 8: salvage', () {
    GameState atForge(Map<String, int> bag) =>
        stateAt(game, level: 20, inventory: bag);

    test('1 dust of the item\'s quality, Legendary too', () {
      for (final (key, dust) in [
        ('bone_sword', 'common_dust'),
        ('bone_sword@rare+crit1+hp5', 'rare_dust'),
        ('iron_sword@legendary+crit1+crit2+hp10+hp11', 'legendary_dust'),
        ('copper_pickaxe@epic', 'epic_dust'),
      ]) {
        final r = game.salvage(atForge({key: 1}), key);
        expect(r.state.inventory[dust], 1, reason: key);
        expect(r.state.inventory.containsKey(key), isFalse);
        expect(r.dust, dust);
      }
    });

    test('only at a forge, only bag items, never a starter tool', () {
      final away = atForge({'bone_sword': 1})..location = 'goblin_woods';
      expect(
        () => game.salvage(away, 'bone_sword'),
        throwsA(isA<ActivityError>()),
      );
      final worn = atForge({})..equipment['mainHand'] = 'bone_sword';
      expect(
        () => game.salvage(worn, 'bone_sword'),
        throwsA(isA<ActivityError>()),
      );
      expect(
        () => game.salvage(atForge({'old_pick': 1}), 'old_pick'),
        throwsA(isA<ActivityError>()),
      );
      expect(
        () => game.salvage(atForge({'bones': 1}), 'bones'),
        throwsA(isA<ActivityError>()),
      );
    });

    test('a shard of the tier\'s boss at 2% + 0.5 points a quality step', () {
      for (final (key, shard, chance) in [
        ('bone_sword', 'kings_shard', 0.02),
        ('iron_sword@epic+crit1+crit1+hp10', 'chieftains_shard', 0.035),
        ('mithril_sword@legendary+hp20+hp20+hp20+hp20', 'dragons_shard', 0.04),
      ]) {
        expect(game.shardChance(key), closeTo(chance, 1e-12), reason: key);
        var s = atForge({key: 4000});
        var shards = 0;
        for (var i = 0; i < 4000; i++) {
          final r = game.salvage(s, key);
          if (r.shard != null) {
            expect(r.shard, shard);
            shards++;
          }
          s = r.state;
        }
        expect(shards / 4000, closeTo(chance, 0.01), reason: key);
        expect(s.inventory[shard] ?? 0, shards);
      }
    });
  });

  group('criterion 9: quality rerolls', () {
    test('3 dust of its quality; never lower; new steps add a bonus stat', () {
      const key = 'bone_sword@uncommon+crit2';
      var s = stateAt(
        game,
        level: 10,
        inventory: {key: 1, 'uncommon_dust': 3 * 300},
      );
      var rises = 0;
      for (var i = 0; i < 300; i++) {
        final held = s.inventory.keys.firstWhere(
          (k) => data.itemOf(k)?.id == 'bone_sword',
        );
        if (data.qualityOf(held).id != 'uncommon') break;
        s = work(s, Activity.reroll(held), data.rerollSteps).state;
        final now = s.inventory.keys.firstWhere(
          (k) => data.itemOf(k)?.id == 'bone_sword',
        );
        final steps = data.qualities.indexOf(data.qualityOf(now));
        expect(steps, greaterThanOrEqualTo(1));
        expect(data.bonusRolls(now), hasLength(steps));
        expect(data.bonusRolls(now), contains((stat: 'crit', value: 2)));
        if (steps > 1) rises++;
      }
      expect(rises, 1, reason: 'stops rerolling once it rose');
      expect(s.inventory['uncommon_dust']! % 3, 0);
    });

    test('a worn item rerolls where it is', () {
      var s = stateAt(game, level: 10, inventory: {'common_dust': 3})
        ..equipment['mainHand'] = 'bone_sword';
      s = work(s, const Activity.reroll('bone_sword'), data.rerollSteps).state;
      expect(data.itemOf(s.equipment['mainHand']!)!.id, 'bone_sword');
      expect(s.inventory['common_dust'] ?? 0, 0);
    });

    test('no dust, a Legendary or a tool: refused', () {
      final s = stateAt(
        game,
        level: 10,
        inventory: {
          'bone_sword': 1,
          'iron_sword@legendary+hp1+hp1+hp1+hp1': 1,
          'copper_pickaxe': 1,
          'legendary_dust': 9,
          'common_dust': 9,
        },
      );
      for (final key in [
        'iron_sword@legendary+hp1+hp1+hp1+hp1',
        'copper_pickaxe',
      ]) {
        expect(
          () => game.startActivity(s, Activity.reroll(key)),
          throwsA(isA<ActivityError>()),
          reason: key,
        );
      }
      final poor = stateAt(game, level: 10, inventory: {'bone_sword': 1});
      expect(
        () => game.startActivity(poor, const Activity.reroll('bone_sword')),
        throwsA(isA<ActivityError>()),
      );
    });
  });

  group('criterion 10: Legendary stat rerolls', () {
    const key = 'iron_sword@legendary+crit1+crit2+hp10+hp11';

    test('one chosen stat rolls; keep new or old', () {
      var s = stateAt(
        game,
        level: 20,
        inventory: {key: 1, 'legendary_dust': 3},
      );
      // The second roll in key order: crit2.
      s = work(s, Activity.rerollStat(key, 1), data.rerollSteps).state;
      expect(s.inventory['legendary_dust'] ?? 0, 0);
      final waiting = s.inventory.keys.firstWhere((k) => k.startsWith('iron'));
      final pending = data.pendingRoll(waiting)!;
      expect(pending.index, 1);
      expect(data.bonusRolls(waiting), data.bonusRolls(key));
      // Until chosen, the old stat counts.
      expect(data.bonusOf(waiting).toString(), data.bonusOf(key).toString());

      final kept = game.keepRoll(s, waiting, keepNew: false);
      expect(kept.inventory, {key: 1});
      final taken = game.keepRoll(s, waiting, keepNew: true);
      final newKey = taken.inventory.keys.single;
      final rolls = data.bonusRolls(newKey);
      expect(rolls, hasLength(4));
      expect(
        rolls,
        containsAll([
          (stat: 'crit', value: 1),
          (stat: 'hp', value: 10),
          (stat: 'hp', value: 11),
          pending.roll,
        ]),
      );
    });

    test('no second reroll while one waits; needs Legendary dust', () {
      final s = stateAt(
        game,
        level: 20,
        inventory: {'$key+~1.hit4': 1, 'legendary_dust': 3},
      );
      expect(
        () => game.startActivity(s, Activity.rerollStat('$key+~1.hit4', 0)),
        throwsA(isA<ActivityError>()),
      );
      final poor = stateAt(game, level: 20, inventory: {key: 1});
      expect(
        () => game.startActivity(poor, Activity.rerollStat(key, 0)),
        throwsA(isA<ActivityError>()),
      );
    });
  });

  group('criterion 11: shard uniques', () {
    test('ten shards make the boss\'s unique at its Crafting level', () {
      for (final (id, shard, crafting) in [
        ('kings_blade', 'kings_shard', 10),
        ('chieftains_amulet', 'chieftains_shard', 20),
        ('dragons_heart', 'dragons_shard', 30),
      ]) {
        final r = data.recipes.values.firstWhere((r) => r.output == id);
        expect(r.inputs, {shard: 10}, reason: id);
        expect(r.craftingLevel, crafting);
      }
    });
  });

  group('criterion 12: the profession stream', () {
    test('salvaging leaves the fights and drops as they were', () {
      GameState fightAfter(bool salvage) {
        var s = stateAt(game, level: 8, inventory: {'bone_sword': 20});
        if (salvage) {
          for (var i = 0; i < 20; i++) {
            s = game.salvage(s, 'bone_sword').state;
          }
        }
        s = game.startActivity(
          s..location = 'goblin_woods',
          const Activity.fight('goblin'),
        );
        return game.applySteps(s, 3000).state;
      }

      final a = fightAfter(false);
      final b = fightAfter(true);
      expect(b.rngState, a.rngState);
      expect(b.counters['kills.goblin'], a.counters['kills.goblin']);
      expect(b.xp, a.xp);
      expect(b.professionRng, isNot(a.professionRng));
    });

    test('rare-find rolls and tool crafts draw nothing from the shared '
        'generator', () {
      final s = stateAt(game, location: 'copper_hills');
      final r = work(s, const Activity.gather('copper_vein'), 100 * 50);
      expect(r.state.rngState, s.rngState);
      final c = stateAt(
        game,
        professionLevel: 3,
        inventory: {'copper_ore': 4, 'oak_log': 2},
      );
      final made = work(c, const Activity.craft('copper_pickaxe'), 150);
      expect(made.state.rngState, c.rngState);
    });
  });
}
