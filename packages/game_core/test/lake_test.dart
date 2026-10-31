// Fishing, Hunting, the bottle, the hidden cove, the §7 gear, the stream and
// save version 9: spec 0011 criteria 1-8 and 12-14 (plan 0013 M1). Meals
// and cooking (criteria 9-11) are in meals_test.dart.
import 'dart:math' as math;

import 'package:game_core/game_core.dart';
import 'package:game_core/simulation.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;

  /// Runs [a] from [s] for [steps].
  StepReport work(GameState s, Activity a, int steps) =>
      game.applySteps(game.startActivity(s, a), steps);

  /// [casts] actions at [node] from [location] at [level] in its
  /// profession, every profession learned with its starter tool.
  StepReport many(String node, String location, int level, int casts) {
    final s = stateAt(game, location: location, professionLevel: level)
      ..revealed.add('smugglers_cove');
    return work(s, Activity.gather(node), data.nodes[node]!.steps * casts);
  }

  // The long runs, shared by the tests that read them.
  late final lake = many('lake_shore', 'mirror_lake', 1, 40000);
  late final cove = many('cove_rocks', 'smugglers_cove', 15, 20000);
  late final deer = many('deer_trail', 'goblin_woods', 1, 20000);

  group('criterion 1: three more professions', () {
    test('six professions in screen order (spec 0011 §8.1)', () {
      expect(data.professions.keys, [
        'mining',
        'woodcutting',
        'fishing',
        'hunting',
        'crafting',
        'cooking',
      ]);
      for (final (id, tool, tiers) in [
        ('fishing', 'Rod', [1, 10, 20]),
        ('hunting', 'Bow', [1, 10, 20]),
        ('cooking', 'Cooking pot', [1, 10, 20]),
      ]) {
        final p = data.professions[id]!;
        expect(p.toolName, tool);
        expect([for (final t in p.tiers) t.level], tiers);
      }
      expect(
        [for (final t in data.professions['fishing']!.tiers) t.name],
        ['Lake', 'River', 'Tarn'],
      );
      expect(
        [for (final t in data.professions['hunting']!.tiers) t.name],
        ['Deer', 'Elk', 'Ibex'],
      );
    });

    test('a cast pays its Fishing XP and a quarter of a fight per step', () {
      final s = stateAt(
        game,
        location: 'mirror_lake',
        level: 12,
        professionLevel: 8,
      );
      final before = s.professions['fishing']!;
      final r = work(s, const Activity.gather('lake_shore'), 100);
      // Fishing 8 on a level 1 spot: 50% (spec 0010 §2.3).
      expect(r.state.professions['fishing']! - before, 10);
      final xp = (100 * 0.25 * data.fightXpPerStep(12) * 0.5).floor();
      expect(r.state.xp - s.xp, math.max(1, xp));
    });

    test('the fade and levels come from the one table', () {
      final s = stateAt(game, professionLevel: 1)
        ..professions['hunting'] = data.professionXpForLevel(10);
      expect(game.professionLevel(s, 'hunting'), 10);
      expect(game.professionFade(s, 'hunting', 1), 50);
      expect(game.professionNews('fishing', 10), [
        const LevelNews(NewsKind.gatheringSpot, 'under_the_bridge'),
      ]);
    });
  });

  group('criterion 2: teachers, tips and tools', () {
    test('Wen, Sigrun and Marta teach once in camp with a starter tool', () {
      var s = game.newGame(seed: 1);
      for (final (id, teacher, tool) in [
        ('fishing', 'Wen', 'old_rod'),
        ('hunting', 'Sigrun', 'old_bow'),
        ('cooking', 'Marta', 'old_pot'),
      ]) {
        expect(data.professions[id]!.teacher.name, teacher);
        expect(data.professions[id]!.teacher.location, 'camp');
        s = game.learn(s, id);
        expect(s.tools[id], tool);
        expect(data.items[tool]!.tool!.starter, isTrue);
        expect(data.qualityOf(tool), data.qualities.first);
        expect(() => game.learn(s, id), throwsA(isA<ActivityError>()));
      }
    });

    // Spot tips (spec 0010 amendment 8) are in spot_tips_test.dart.
    test('Sigrun tells monster tips at Hunting 1, 10 and 20; Wen and Marta '
        'tell no monster tips', () {
      List<TipDef> monsterTips(String p) => [
        for (final t in data.professions[p]!.tips)
          if (t.enemy != null) t,
      ];
      expect(
        [for (final t in monsterTips('hunting')) (t.level, t.enemy)],
        [(1, 'goblin_brute'), (10, 'wolf'), (20, 'wyvern')],
      );
      expect(monsterTips('fishing'), isEmpty);
      expect(data.professions['cooking']!.tips, isEmpty);
      final s = stateAt(game, professionLevel: 10);
      expect(
        [
          for (final t in game.tipsWaiting(s, 'hunting'))
            if (t.enemy != null) t.enemy,
        ],
        ['goblin_brute', 'wolf'],
      );
      final told = game.talk(s, 'hunting');
      expect(game.knowledge(told, 'wolf').weakness, isTrue);
    });

    test('crafted rods, bows and pots match the pickaxe', () {
      for (final tier in ['copper', 'iron', 'mithril']) {
        final pick = data.recipes['${tier}_pickaxe']!;
        for (final (tool, profession) in [
          ('${tier}_rod', 'fishing'),
          ('${tier}_bow', 'hunting'),
          ('${tier}_pot', 'cooking'),
        ]) {
          final r = data.recipes[tool]!;
          expect(r.profession, 'crafting');
          expect((r.level, r.steps), (pick.level, pick.steps));
          expect(r.inputs, pick.inputs);
          final t = data.items[tool]!.tool!;
          expect(t.profession, profession);
          expect(t.stepFactor, data.items['${tier}_pickaxe']!.tool!.stepFactor);
        }
      }
    });

    test('the rod cuts a cast\'s steps, by tier and quality', () {
      final s = stateAt(game, location: 'mirror_lake')
        ..tools['fishing'] = 'iron_rod@rare';
      // 80% less 2 points per quality step: 76 steps.
      expect(
        game.unitCost(
          game.startActivity(s, const Activity.gather('lake_shore')),
        ),
        76,
      );
    });

    test('no rod, no fishing; the old rod can\'t be salvaged', () {
      final s = stateAt(game, location: 'mirror_lake')..tools.remove('fishing');
      expect(
        () => game.startActivity(s, const Activity.gather('lake_shore')),
        throwsA(
          isA<ActivityError>().having(
            (e) => e.message,
            'message',
            contains('rod'),
          ),
        ),
      );
      final camp = stateAt(game, inventory: {'old_rod': 1});
      expect(
        () => game.salvage(camp, 'old_rod'),
        throwsA(isA<ActivityError>()),
      );
    });
  });

  group('criterion 3: Mirror Lake, the waters and the hunting spots', () {
    test('Mirror Lake joins Camp and Copper Hills, with no monsters', () {
      final lake = data.locations['mirror_lake']!;
      expect(lake.enemies, isEmpty);
      expect(lake.hidden, isFalse);
      expect(data.route('camp', 'mirror_lake')!.steps, 300);
      expect(data.route('copper_hills', 'mirror_lake')!.steps, 300);
      expect(data.route('mirror_lake', 'smugglers_cove')!.steps, 700);
      expect(data.locations['smugglers_cove']!.hidden, isTrue);
      expect(data.locations['smugglers_cove']!.enemies, isEmpty);
    });

    test('spots: area, profession, level, steps, XP and what each gives', () {
      for (final (id, area, profession, level, steps, xp, item) in [
        ('lake_shore', 'mirror_lake', 'fishing', 1, 100, 20, 'lake_scale'),
        (
          'under_the_bridge',
          'troll_bridge',
          'fishing',
          10,
          120,
          55,
          'river_scale',
        ),
        ('cove_rocks', 'smugglers_cove', 'fishing', 15, 130, 90, 'river_scale'),
        ('cold_tarn', 'mountain_pass', 'fishing', 20, 150, 175, 'tarn_scale'),
        ('deer_trail', 'goblin_woods', 'hunting', 1, 100, 20, 'deer_hide'),
        ('moor_tracks', 'grey_moor', 'hunting', 10, 120, 55, 'elk_hide'),
        ('high_crags', 'mountain_pass', 'hunting', 20, 150, 175, 'ibex_hide'),
      ]) {
        final n = data.nodes[id]!;
        expect(data.locations[area]!.nodes, contains(id), reason: id);
        expect(
          (n.profession, n.level, n.steps, n.xp, n.item),
          (profession, level, steps, xp, item),
          reason: id,
        );
      }
    });

    test('catch tables (spec 0011 §3.2, §4)', () {
      List<String> rows(String node) => [
        for (final c in data.nodes[node]!.catches) c.item,
        data.nodes[node]!.rareFind!,
      ];
      expect(rows('lake_shore'), [
        'perch',
        'pike',
        'golden_carp',
        'old_mossback',
      ]);
      expect(rows('under_the_bridge'), [
        'brown_trout',
        'eel',
        'silver_salmon',
        'river_king',
      ]);
      expect(rows('cove_rocks'), [
        'sea_bass',
        'mackerel',
        'moonfish',
        'old_one_eye',
      ]);
      expect(rows('cold_tarn'), [
        'arctic_char',
        'frostfin',
        'glacier_pike',
        'the_pale_one',
      ]);
      expect(rows('deer_trail'), ['venison', 'boar_meat', 'golden_antler']);
      expect(rows('moor_tracks'), [
        'elk_meat',
        'black_boar_meat',
        'old_tusks_tusk',
      ]);
      expect(rows('high_crags'), ['ibex_meat', 'grouse', 'snow_lynx_pelt']);
      expect(data.items['perch']!.weight, (0.2, 1.5));
      expect(data.items['the_pale_one']!.weight, (15.0, 40.0));
      expect(data.items['venison']!.weight, isNull);
    });
  });

  group('criterion 4: the catch', () {
    const casts = 40000;
    late final r = lake;
    int got(String item) => r.state.inventory[item] ?? 0;

    test('one fish and one scale per cast', () {
      expect(got('lake_scale'), casts);
      expect(
        got('perch') + got('pike') + got('golden_carp') + got('old_mossback'),
        casts,
      );
    });

    test('rows at 75 / 20 / 4.5% and the trophy at 0.5%', () {
      expect(got('perch') / casts, closeTo(0.75, 0.01));
      expect(got('pike') / casts, closeTo(0.20, 0.01));
      expect(got('golden_carp') / casts, closeTo(0.045, 0.01));
      expect(got('old_mossback') / casts, closeTo(0.005, 0.001));
      expect(
        r.events.whereType<RareFound>().where((e) => e.item == 'old_mossback'),
        hasLength(got('old_mossback')),
      );
    });

    test('the trophy chance follows spec 0010 §5.1 with the spot\'s base', () {
      final s = stateAt(game, professionLevel: 1);
      expect(game.rareFindChance(s, 'lake_shore'), closeTo(0.005, 1e-12));
      expect(game.rareFindChance(s, 'cove_rocks'), closeTo(0.015, 1e-12));
      s.tools['fishing'] = 'copper_rod@uncommon';
      s.professions['fishing'] = data.professionXpForLevel(4);
      expect(
        game.rareFindChance(s, 'lake_shore'),
        closeTo(0.005 * 1.05 * 1.03, 1e-12),
      );
    });

    test('the cove has trophies three times as often', () {
      const n = 20000;
      expect(
        (cove.state.inventory['old_one_eye'] ?? 0) / n,
        closeTo(0.015, 0.003),
      );
    });

    group('criterion 6: weights and records', () {
      // Each fish's weights in tenths of a kg, in catch order.
      late final weights = () {
        final w = <String, List<int>>{};
        for (final e in lake.events) {
          final (item, tenths) = switch (e) {
            Gathered(:final item, :final weight) => (item, weight),
            RareFound(:final item, :final weight) => (item, weight),
            _ => ('', null),
          };
          if (tenths != null) (w[item] ??= []).add(tenths);
        }
        return w;
      }();

      test('every fish has a weight in its range, heavy ones rarer', () {
        expect(weights.keys, containsAll(['perch', 'pike', 'golden_carp']));
        weights.forEach((item, w) {
          final (lo, hi) = data.items[item]!.weight!;
          expect(
            w.every((t) => t >= (lo * 10).round() && t <= (hi * 10).round()),
            isTrue,
            reason: item,
          );
        });
        // min + (max - min) × u²: the mean is a third of the way up.
        final perch = weights['perch']!;
        final mean = perch.reduce((a, b) => a + b) / perch.length / 10;
        expect(mean, closeTo(0.2 + 1.3 / 3, 0.02));
        expect(weights['venison'], isNull);
      });

      test('the save keeps the heaviest of each species', () {
        weights.forEach((item, w) {
          expect(r.state.records[item], w.reduce(math.max), reason: item);
        });
      });

      test('beating a record is news; the first catch isn\'t', () {
        final beaten = r.events.whereType<RecordBeaten>().toList();
        var expected = 0;
        weights.forEach((item, w) {
          var best = w.first;
          for (final t in w.skip(1)) {
            if (t > best) {
              expected++;
              best = t;
            }
          }
        });
        expect(beaten, hasLength(expected));
        expect(beaten.every((e) => e.weight > e.was), isTrue);
        final first = work(
          stateAt(game, location: 'mirror_lake'),
          const Activity.gather('lake_shore'),
          100,
        );
        expect(first.events.whereType<RecordBeaten>(), isEmpty);
        expect(first.state.records, hasLength(1));
      });
    });

    group('criterion 7: the bottle', () {
      test('about 1 in 2,000 casts; the first reveals the cove, later ones '
          'hold Rare dust', () {
        final bottles = r.events.whereType<BottleFound>().toList();
        expect(bottles.length / casts, closeTo(0.0005, 0.0003));
        expect(bottles.first.revealed, 'smugglers_cove');
        expect(bottles.skip(1).every((b) => b.revealed == null), isTrue);
        expect(r.state.bottles, bottles.length);
        expect(got('rare_dust'), bottles.length - 1);
      });

      test('the first bottle reveals the cove (every cast a bottle)', () {
        final sure = newTestGame(
          overrides: {
            'economy': {
              ...dataJson('economy'),
              'bottle': {
                ...(dataJson('economy')['bottle']! as Map<String, Object?>),
                'chance': 1.0,
              },
            },
          },
        );
        var s = stateAt(sure, location: 'mirror_lake');
        expect(sure.isHidden(s, 'smugglers_cove'), isTrue);
        s = sure
            .applySteps(
              sure.startActivity(s, const Activity.gather('lake_shore')),
              100,
            )
            .state;
        expect(s.revealed, {'smugglers_cove'});
        expect(sure.isHidden(s, 'smugglers_cove'), isFalse);
        expect(s.inventory['rare_dust'], isNull);
        s = sure.applySteps(s, 100).state;
        expect(s.inventory['rare_dust'], 1);
        expect(s.bottles, 2);
      });

      test('hunting rolls no bottle', () {
        final h = many('deer_trail', 'goblin_woods', 1, 5000);
        expect(h.events.whereType<BottleFound>(), isEmpty);
      });
    });
  });

  group('criterion 5: the hunt', () {
    const hunts = 20000;
    late final r = deer;
    int got(String item) => r.state.inventory[item] ?? 0;

    test('one meat and one hide per hunt; the rare animal brings its trophy, '
        'a hide and a venison', () {
      expect(got('deer_hide'), hunts);
      expect(got('venison') + got('boar_meat'), hunts);
      expect(got('venison') / hunts, closeTo(0.75 + 0.005, 0.01));
      expect(got('golden_antler') / hunts, closeTo(0.005, 0.001));
      expect(r.events.whereType<RareFound>(), hasLength(got('golden_antler')));
    });
  });

  group('criterion 8: the hidden cove and the sunken chest', () {
    GameState atLake() =>
        stateAt(game, location: 'mirror_lake')..explored.add('mirror_lake');

    test('until revealed it is in no list and on no route', () {
      final s = atLake();
      expect(game.isHidden(s, 'smugglers_cove'), isTrue);
      expect(game.isFogged(s, 'smugglers_cove'), isTrue);
      expect(
        game.openLocationsByDistance(s).keys,
        isNot(contains('smugglers_cove')),
      );
      expect(game.nodesAt(s, 'smugglers_cove'), isEmpty);
      expect(
        () => game.startActivity(s, const Activity.travel('smugglers_cove')),
        throwsA(isA<ActivityError>()),
      );
      expect(
        () => game.startActivity(
          s..professions['fishing'] = data.professionXpForLevel(15),
          const Activity.gather('cove_rocks'),
        ),
        throwsA(isA<ActivityError>()),
      );
      // Standing next to it doesn't lift it either.
      expect(
        game.isHidden(s..explored.add('mirror_lake'), 'smugglers_cove'),
        isTrue,
      );
    });

    test('once revealed it follows the fog rules', () {
      final far = stateAt(game)..revealed.add('smugglers_cove');
      expect(game.isHidden(far, 'smugglers_cove'), isFalse);
      expect(game.isFogged(far, 'smugglers_cove'), isTrue);
      final s = atLake()..revealed.add('smugglers_cove');
      expect(game.isFogged(s, 'smugglers_cove'), isFalse);
      final there = work(s, const Activity.travel('smugglers_cove'), 700).state;
      expect(there.location, 'smugglers_cove');
    });

    test('Cove rocks rolls a sunken chest at 0.2%, with the Drowned '
        'Captain\'s ring rolling quality and bonus stats', () {
      const n = 20000;
      final r = cove;
      final chests = r.events.whereType<ChestFound>().toList();
      expect(chests.length / n, closeTo(0.002, 0.0008));
      final ring = data.items['drowned_captains_ring']!;
      expect(ring.slot, 'ring');
      expect(data.itemLevel(ring.id), 20);
      expect((ring.bonus.attack, ring.bonus.crit, ring.bonus.hp), (3, 2, 30));
      for (final c in chests) {
        expect(data.itemOf(c.key)!.id, ring.id);
        expect(
          data.bonusRolls(c.key),
          hasLength(data.qualities.indexOf(data.qualityOf(c.key))),
        );
      }
      expect(game.owned(r.state, ring.id), chests.length);
      final lake = many('lake_shore', 'mirror_lake', 1, 5000);
      expect(lake.events.whereType<ChestFound>(), isEmpty);
    });
  });

  group('criterion 12: gear from hides, scales and trophies', () {
    test('the fifteen pieces (spec 0011 §7)', () {
      for (final (id, slot, crafting, inputs, stats, armour) in [
        ('deer_hide_gloves', 'gloves', 6, {'deer_hide': 4}, (1, 0, 5), 'light'),
        (
          'deer_hide_bracers',
          'bracer',
          6,
          {'deer_hide': 4},
          (0, 1, 5),
          'light',
        ),
        (
          'deer_hide_belt',
          'belt',
          6,
          {'deer_hide': 3, 'copper_ore': 1},
          (0, 0, 10),
          'light',
        ),
        (
          'lake_scale_greaves',
          'legs',
          6,
          {'lake_scale': 6, 'deer_hide': 2},
          (0, 1, 8),
          'medium',
        ),
        (
          'golden_antler_mantle',
          'shoulder',
          8,
          {'golden_antler': 1, 'deer_hide': 4},
          (1, 1, 10),
          'light',
        ),
        ('elk_hide_gloves', 'gloves', 16, {'elk_hide': 5}, (2, 0, 12), 'light'),
        (
          'elk_hide_bracers',
          'bracer',
          16,
          {'elk_hide': 5},
          (0, 2, 12),
          'light',
        ),
        (
          'elk_hide_belt',
          'belt',
          16,
          {'elk_hide': 4, 'iron_ore': 1},
          (0, 0, 25),
          'light',
        ),
        (
          'river_scale_greaves',
          'legs',
          16,
          {'river_scale': 8, 'elk_hide': 2},
          (0, 3, 18),
          'medium',
        ),
        (
          'tusk_mantle',
          'shoulder',
          18,
          {'old_tusks_tusk': 1, 'elk_hide': 5},
          (2, 2, 25),
          'light',
        ),
        (
          'ibex_hide_gloves',
          'gloves',
          26,
          {'ibex_hide': 6},
          (3, 0, 20),
          'light',
        ),
        (
          'ibex_hide_bracers',
          'bracer',
          26,
          {'ibex_hide': 6},
          (0, 3, 20),
          'light',
        ),
        (
          'ibex_hide_belt',
          'belt',
          26,
          {'ibex_hide': 5, 'mithril_ore': 1},
          (0, 0, 40),
          'light',
        ),
        (
          'tarn_scale_greaves',
          'legs',
          26,
          {'tarn_scale': 10, 'ibex_hide': 2},
          (0, 4, 30),
          'medium',
        ),
        (
          'lynx_mantle',
          'shoulder',
          28,
          {'snow_lynx_pelt': 1, 'ibex_hide': 6},
          (3, 3, 45),
          'light',
        ),
      ]) {
        final item = data.items[id]!;
        final r = data.recipes[id]!;
        expect(item.slot, slot, reason: id);
        expect(item.armourType, armour, reason: id);
        expect(item.reference, isFalse, reason: id);
        expect(
          (item.bonus.attack, item.bonus.defense, item.bonus.hp),
          stats,
          reason: id,
        );
        expect((r.level, r.craftingLevel), (crafting, crafting), reason: id);
        expect(r.inputs, inputs, reason: id);
        final (steps, xp) = switch (crafting) {
          6 => (200, 50),
          8 => (250, 70),
          16 => (350, 230),
          18 => (350, 280),
          26 => (500, 860),
          _ => (500, 1050),
        };
        expect((r.steps, r.xp), (steps, xp), reason: id);
      }
    });

    test('they roll quality and bonus stats', () {
      var s = stateAt(
        game,
        professionLevel: 6,
        inventory: {'deer_hide': 4 * 300},
      );
      s = game.startActivity(s, const Activity.craft('deer_hide_gloves'));
      s = game.applySteps(s, 200 * 300).state;
      final keys = s.inventory.keys.where(
        (k) => data.itemOf(k)?.id == 'deer_hide_gloves',
      );
      expect(
        keys.where((k) => data.qualityOf(k) != data.qualities.first),
        isNotEmpty,
      );
      for (final k in keys) {
        expect(
          data.bonusRolls(k),
          hasLength(data.qualities.indexOf(data.qualityOf(k))),
        );
      }
    });

    test('the reference player doesn\'t wear them', () {
      for (final level in [10, 20, 30]) {
        final p = referencePlayer(game, level);
        for (final slot in ['gloves', 'bracer', 'belt', 'legs', 'shoulder']) {
          expect(p.equipment[slot], isNull, reason: 'level $level $slot');
        }
      }
    });
  });

  group('criterion 13: the profession stream', () {
    test('casts, hunts, cooks, the new gear and chests draw nothing from the '
        'shared generator', () {
      for (final (node, location, level) in [
        ('lake_shore', 'mirror_lake', 1),
        ('cove_rocks', 'smugglers_cove', 15),
        ('deer_trail', 'goblin_woods', 1),
      ]) {
        final s = stateAt(game, location: location, professionLevel: level)
          ..revealed.add('smugglers_cove');
        final r = work(
          s,
          Activity.gather(node),
          data.nodes[node]!.steps * 3000,
        );
        expect(r.state.rngState, s.rngState, reason: node);
        expect(r.state.professionRng, isNot(s.professionRng));
      }
      for (final (recipe, inputs) in [
        ('grilled_perch', {'perch': 200}),
        ('deer_hide_gloves', {'deer_hide': 400}),
      ]) {
        final s = stateAt(game, professionLevel: 10, inventory: inputs);
        final r = work(s, Activity.craft(recipe), 400 * 100);
        expect(r.state.rngState, s.rngState, reason: recipe);
      }
    });

    test('the same seed and steps give the same fights whether or not those '
        'rolls happened', () {
      GameState fightAfter(bool gathered) {
        var s = stateAt(game, level: 8, location: 'mirror_lake');
        if (gathered) {
          final xp = s.xp;
          s = work(s, const Activity.gather('lake_shore'), 100 * 300).state;
          s = game.stopActivity(s)
            ..xp = xp
            ..bank = 0;
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
    });
  });

  group('criterion 14: save version 9', () {
    Map<String, Object?> v8(GameState s) => s.toJson()
      ..['version'] = 8
      ..remove('records')
      ..remove('meal')
      ..remove('autoEat')
      ..remove('revealed')
      ..remove('bottles');

    test('an old save loads with nothing new and everything else kept', () {
      var old = game.newGame(seed: 4);
      for (final p in ['mining', 'woodcutting', 'crafting']) {
        old = game.learn(old, p);
      }
      old
        ..xp = data.xpForLevel(9)
        ..inventory['copper_ore'] = 3
        ..professions['mining'] = 500;
      final s = game.migrate(GameState.fromJson(v8(old)));
      expect(s.learned, {'mining', 'woodcutting', 'crafting'});
      expect(s.tools.keys, {'mining', 'woodcutting', 'crafting'});
      expect(s.meal, isNull);
      expect(s.autoEat, isNull);
      expect(s.records, isEmpty);
      expect(s.revealed, isEmpty);
      expect(s.bottles, 0);
      expect(game.isHidden(s, 'smugglers_cove'), isTrue);
      // The quality counter is new in version 12 (spec 0017 §3.2).
      final kept = s.copy()..counters.remove(Game.foundQualityCounter);
      expect(kept.toJson(), old.toJson());
    });

    test('a version 9 save keeps the new fields', () {
      final s = stateAt(game, inventory: {'grilled_perch': 3})
        ..records['pike'] = 63
        ..revealed.add('smugglers_cove')
        ..bottles = 2;
      final fed = game.setAutoEat(
        game.eat(s, 'grilled_perch'),
        'grilled_perch',
        keep: 1,
      );
      final back = GameState.fromJson(fed.toJson());
      expect(back.loadedVersion, GameState.schemaVersion);
      expect(back.toJson(), fed.toJson());
      expect(back.meal!.key, 'grilled_perch');
      expect(back.autoEat!.keep, 1);
      expect(game.migrate(back.copy()).toJson(), fed.toJson());
    });
  });
}
