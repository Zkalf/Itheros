// No level gates, the paper doll and fog by exploring: spec 0008 criteria 3-7,
// 11-13 (rules side), with amendments 1 and 2 (gathering spots and recipes keep
// a level).
import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();

  group('criterion 3: open from level 1', () {
    test('all 16 slots exist and none has a level', () {
      expect(game.data.gearSlots.map((g) => g.id), [
        'head', 'neck', 'shoulder', 'cloak', 'chest', 'bracer', //
        'gloves', 'belt', 'legs', 'boots', 'ring1', 'ring2',
        'trinket1', 'trinket2', 'mainHand', 'offHand',
      ]);
    });

    test('the queue takes 3 actions at level 1', () {
      expect(game.queueSlots(stateAt(game)), 3);
      var s = stateAt(game, location: 'goblin_woods');
      const goblins = Activity.fight('goblin');
      s = game.addAction(s, goblins);
      s = game.addAction(s, goblins, stop: const StopCondition.untilGrey());
      expect(s.queue, hasLength(1));
    });

    test('"until I have N" and "until a quality" are offered at level 1', () {
      final s = stateAt(game);
      expect(
        game.stopKindsFor(s, const Activity.fight('goblin')),
        contains(StopKind.untilHave),
      );
      expect(
        game.stopKindsFor(s, const Activity.craft('copper_sword')),
        containsAll([StopKind.untilCrafted, StopKind.untilQuality]),
      );
    });

    test('a shield can be worn at level 1', () {
      var s = stateAt(game, inventory: {'bone_shield': 1});
      s = game.equip(s, 'bone_shield');
      expect(s.equipment['offHand'], 'bone_shield');
    });
  });

  group('criterion 4: no unlock levels (amendment 1)', () {
    test('no data file has an unlockLevel', () {
      for (final f in Directory('data').listSync().whereType<File>()) {
        expect(
          f.readAsStringSync(),
          isNot(contains('unlockLevel')),
          reason: f.path,
        );
      }
    });

    test('the loader rejects an unlockLevel', () {
      final world = dataJson('world');
      final locations = (world['locations'] as List)
          .cast<Map<String, Object?>>();
      locations.first['unlockLevel'] = 1;
      expect(
        () => loadGameData(overrides: {'world': world}),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'at level 1 every monster, spot and recipe shows where not fogged',
      () {
        final s = stateAt(game, location: 'old_graveyard');
        expect(game.availableEnemies(s), [
          'skeleton',
          'zombie',
          'graveyard_king',
        ]);
        expect(game.allRecipes(), game.data.recipes.keys.toList());
        final hills = stateAt(game, location: 'copper_hills');
        expect(game.availableNodes(hills), ['copper_vein']);
      },
    );

    test('a level 1 player can fight the Graveyard King', () {
      final s = game.startActivity(
        stateAt(game, location: 'old_graveyard'),
        const Activity.fight('graveyard_king'),
      );
      expect(s.activity!.activity.target, 'graveyard_king');
    });

    test('a gathering spot needs its level, but shows before it', () {
      final s = stateAt(game, location: 'copper_hills');
      expect(game.nodeLevelMet(s, 'copper_vein'), isFalse);
      expect(
        () => game.startActivity(s, const Activity.gather('copper_vein')),
        throwsA(isA<ActivityError>()),
      );
      final running = game.startActivity(
        stateAt(game, location: 'goblin_woods'),
        const Activity.fight('goblin'),
      );
      expect(
        () => game.addAction(
          running,
          const Activity.gather('copper_vein'),
          stop: const StopCondition.untilHave('copper_ore', 1),
        ),
        throwsA(isA<ActivityError>()),
      );
      final l2 = stateAt(game, level: 2, location: 'copper_hills');
      expect(game.nodeLevelMet(l2, 'copper_vein'), isTrue);
      game.startActivity(l2, const Activity.gather('copper_vein'));
    });

    test('a recipe needs its level, but shows before it (amendment 2)', () {
      final s = stateAt(game, level: 21, inventory: {'mithril_ore': 8});
      expect(game.allRecipes(), contains('mithril_sword'));
      expect(game.recipeLevelMet(s, 'mithril_sword'), isFalse);
      expect(
        () => game.startActivity(s, const Activity.craft('mithril_sword')),
        throwsA(
          isA<ActivityError>().having(
            (e) => e.message,
            'message',
            'Mithril sword needs level 22',
          ),
        ),
      );
      final l22 = stateAt(game, level: 22, inventory: {'mithril_ore': 8});
      game.startActivity(l22, const Activity.craft('mithril_sword'));
    });

    test('a spot reaching its level is level news; nothing else unlocks', () {
      expect(
        game.levelNews(12),
        contains(const LevelNews(NewsKind.gatheringSpot, 'iron_vein')),
      );
      for (var l = 2; l <= 30; l++) {
        expect(
          game.levelNews(l).map((n) => n.kind),
          everyElement(
            isIn([
              NewsKind.rank,
              NewsKind.gatheringSpot,
              NewsKind.recipe,
              NewsKind.talentPoint,
              NewsKind.yourLevel,
              NewsKind.turnedGrey,
            ]),
          ),
          reason: 'level $l',
        );
      }
    });
  });

  group('criterion 5: fog lifts by exploring', () {
    test('a new game sees Camp and its neighbours', () {
      final s = game.newGame(seed: 1);
      expect(s.explored, {'camp'});
      for (final a in [
        'camp',
        'goblin_woods',
        'copper_hills',
        'old_graveyard',
      ]) {
        expect(game.isFogged(s, a), isFalse, reason: a);
      }
      for (final a in ['grey_moor', 'iron_ridge', 'dragons_peak']) {
        expect(game.isFogged(s, a), isTrue, reason: a);
      }
    });

    test('arriving explores the area and lifts the fog next to it', () {
      var s = game.startActivity(
        game.newGame(seed: 1),
        const Activity.travel('old_graveyard'),
      );
      s = game.applySteps(s, 500).state;
      expect(s.explored, contains('old_graveyard'));
      expect(game.isFogged(s, 'grey_moor'), isFalse);
      expect(game.isFogged(s, 'iron_ridge'), isTrue);
    });

    test('a fogged area can not be travelled to, even by auto-travel', () {
      final s = game.newGame(seed: 1);
      expect(
        () => game.startActivity(s, const Activity.travel('grey_moor')),
        throwsA(isA<ActivityError>()),
      );
      expect(
        () => game.startActivity(s, const Activity.fight('wolf')),
        throwsA(isA<ActivityError>()),
      );
      expect(
        game.openLocationsByDistance(s).keys,
        isNot(contains('grey_moor')),
      );
      expect(game.enemiesAt(s, 'grey_moor'), isEmpty);
    });

    test('level-up news leaves out monsters in the fog', () {
      final s = stateAt(game, level: 30);
      final news = game.levelNews(30, s);
      expect(
        news,
        isNot(contains(const LevelNews(NewsKind.yourLevel, 'young_dragon'))),
      );
      expect(
        game.levelNews(30),
        contains(const LevelNews(NewsKind.yourLevel, 'young_dragon')),
      );
    });

    test('refusing a walk into the fog names no fogged place', () {
      expect(
        () => game.startActivity(stateAt(game), const Activity.fight('wolf')),
        throwsA(
          isA<ActivityError>().having(
            (e) => e.message,
            'message',
            'The way there is in the fog',
          ),
        ),
      );
    });

    test('a visible but unexplored area can be walked to', () {
      final s = game.startActivity(
        game.newGame(seed: 1),
        const Activity.fight('skeleton'),
      );
      expect(s.activity!.leg, 'old_graveyard');
    });
  });

  group('criterion 6: two-handed weapons (test data)', () {
    final items = dataJson('items');
    final list = (items['items'] as List).cast<Map<String, Object?>>();
    list.add({
      'id': 'big_axe',
      'name': 'Big axe',
      'slot': 'mainHand',
      // Every weapon has a damage type (spec 0009 §4.1).
      'damageType': 'slash',
      'twoHanded': true,
      // Above the bone shield's score, which counts its Block (spec 0009 §4.2).
      'attack': 20,
    });
    final g = newTestGame(overrides: {'items': items});

    int total(GameState s) =>
        s.equipment.length + s.inventory.values.fold(0, (a, b) => a + b);

    test('a two-hander moves the shield to the bag', () {
      var s = stateAt(
        g,
        inventory: {'big_axe': 1, 'copper_sword': 1, 'bone_shield': 1},
      );
      s = g.equip(s, 'copper_sword');
      s = g.equip(s, 'bone_shield');
      final before = total(s);
      s = g.equip(s, 'big_axe');
      expect(s.equipment['mainHand'], 'big_axe');
      expect(s.equipment['offHand'], isNull);
      expect(s.inventory['bone_shield'], 1);
      expect(s.inventory['copper_sword'], 1);
      expect(total(s), before);
    });

    test('a shield moves the two-hander to the bag', () {
      var s = stateAt(g, inventory: {'big_axe': 1, 'bone_shield': 1});
      s = g.equip(s, 'big_axe');
      final before = total(s);
      s = g.equip(s, 'bone_shield');
      expect(s.equipment['offHand'], 'bone_shield');
      expect(s.equipment['mainHand'], isNull);
      expect(s.inventory['big_axe'], 1);
      expect(total(s), before);
    });

    test('a one-hander replaces a two-hander in the main hand only', () {
      var s = stateAt(g, inventory: {'big_axe': 1, 'copper_sword': 1});
      s = g.equip(s, 'big_axe');
      s = g.equip(s, 'copper_sword');
      expect(s.equipment, {'mainHand': 'copper_sword'});
      expect(s.inventory['big_axe'], 1);
    });

    test('the comparison counts the shield a two-hander takes off', () {
      var s = stateAt(
        g,
        inventory: {'big_axe': 1, 'copper_sword': 1, 'bone_shield': 1},
      );
      s = g.equip(s, 'copper_sword');
      s = g.equip(s, 'bone_shield');
      final d = g.compare(s, 'big_axe', 'mainHand');
      expect(d.attack, 20 - 3);
      expect(d.defense, -3);
    });

    test('a shield next to a two-hander is no upgrade if it costs more', () {
      var s = stateAt(g, inventory: {'big_axe': 1, 'bone_shield': 1});
      s = g.equip(s, 'big_axe');
      expect(g.gearGain(s, 'bone_shield'), lessThan(0));
      expect(g.nextGoal(s), isNot(isA<EquipGoal>()));
    });

    test('twoHanded is only allowed on main-hand items', () {
      final bad = dataJson('items');
      (bad['items'] as List).add({
        'id': 'odd',
        'name': 'Odd',
        'slot': 'chest',
        'twoHanded': true,
      });
      expect(
        () => loadGameData(overrides: {'items': bad}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('criterion 7: rings and trinkets', () {
    final items = dataJson('items');
    (items['items'] as List).addAll([
      {'id': 'ring_a', 'name': 'Ring A', 'slot': 'ring', 'hp': 5},
      {'id': 'ring_b', 'name': 'Ring B', 'slot': 'ring', 'hp': 6},
      {'id': 'ring_c', 'name': 'Ring C', 'slot': 'ring', 'hp': 7},
    ]);
    final g = newTestGame(overrides: {'items': items});

    test('fill the empty slot first, then swap with the one picked', () {
      var s = stateAt(g, inventory: {'ring_a': 1, 'ring_b': 1, 'ring_c': 1});
      s = g.equip(s, 'ring_a');
      s = g.equip(s, 'ring_b');
      expect(s.equipment['ring1'], 'ring_a');
      expect(s.equipment['ring2'], 'ring_b');
      expect(g.slotsFor('ring_c'), ['ring1', 'ring2']);
      expect(() => g.equip(s, 'ring_c'), throwsA(isA<ActivityError>()));
      s = g.equip(s, 'ring_c', slot: 'ring2');
      expect(s.equipment['ring2'], 'ring_c');
      expect(s.inventory['ring_b'], 1);
    });

    test('an item can not go into a slot of another kind', () {
      final s = stateAt(g, inventory: {'ring_a': 1});
      expect(
        () => g.equip(s, 'ring_a', slot: 'trinket1'),
        throwsA(isA<ActivityError>()),
      );
    });
  });

  test('criterion 11: the Bear-pelt cloak is worn with chest armour', () {
    var s = stateAt(game, inventory: {'bear_pelt_cloak': 1, 'hide_vest': 1});
    s = game.equip(s, 'bear_pelt_cloak');
    s = game.equip(s, 'hide_vest');
    expect(s.equipment, {'cloak': 'bear_pelt_cloak', 'chest': 'hide_vest'});
  });

  group('criterion 12: old saves', () {
    Map<String, Object?> v5({
      required Map<String, String> equipment,
      Map<String, int> counters = const {},
      String location = 'goblin_woods',
    }) {
      final json = game.newGame(seed: 1).toJson()
        ..['version'] = 5
        ..['location'] = location
        ..['equipment'] = equipment
        ..['counters'] = {'visited.camp': 1, ...counters}
        ..remove('explored');
      return json;
    }

    GameState load(Map<String, Object?> json) => game.migrate(
      GameState.fromJson(jsonDecode(jsonEncode(json)) as Map<String, Object?>),
    );

    test('gear moves to its new slot', () {
      // Gear above Common also rolls bonus stats (spec 0009 §5.4): compared
      // without them.
      final s = load(
        v5(
          equipment: {
            'weapon': 'kings_blade@rare',
            'shield': 'bone_shield',
            'body': 'stitched_armour',
            'head': 'iron_helm',
            'feet': 'silk_boots',
            'amulet': 'moor_charm@epic',
          },
        ),
      );
      expect(s.equipment.map((k, v) => MapEntry(k, game.data.plainKey(v))), {
        'mainHand': 'kings_blade@rare',
        'offHand': 'bone_shield',
        'chest': 'stitched_armour',
        'head': 'iron_helm',
        'boots': 'silk_boots',
        'neck': 'moor_charm@epic',
      });
    });

    test('a worn Bear-pelt cloak moves to the Cloak slot', () {
      final s = load(v5(equipment: {'body': 'bear_pelt_cloak'}));
      expect(s.equipment, {'cloak': 'bear_pelt_cloak'});
    });

    test('visited areas and the current one count as explored', () {
      final s = load(
        v5(
          equipment: const {},
          counters: {'visited.old_graveyard': 1},
          location: 'goblin_woods',
        ),
      );
      expect(s.explored, {'camp', 'old_graveyard', 'goblin_woods'});
    });

    test(
      'a walk whose goal is now in the fog stops, never fights elsewhere',
      () {
        // An old save at Grey Moor walking to the wyverns: Dragon's Peak is
        // fogged once loaded (Mountain Pass was never visited).
        final json =
            v5(
                equipment: const {},
                counters: {'visited.old_graveyard': 1, 'visited.grey_moor': 1},
                location: 'grey_moor',
              )
              ..['xp'] = game.data.xpForLevel(30)
              ..['activity'] = {
                'kind': 'fight',
                'target': 'wyvern',
                'stop': const StopCondition.never().toJson(),
                'progress': 0,
                'leg': 'troll_bridge',
              };
        final r = game.applySteps(load(json), 900);
        expect(r.state.location, 'troll_bridge');
        expect(r.state.activity, isNull);
        expect(
          r.events.whereType<ActivityEnded>().single.reason,
          EndReason.noRoute,
        );
        expect(r.state.counters['kills.wyvern'], isNull);
        expect(r.events.whereType<FightWon>(), isEmpty);
        expect(r.events.whereType<FightLost>(), isEmpty);
      },
    );

    test('a new save keeps its explored areas', () {
      final s = game.newGame(seed: 1)..explored.add('goblin_woods');
      final back = GameState.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, Object?>,
      );
      expect(back.explored, {'camp', 'goblin_woods'});
    });
  });
}
