// Profession levels, character XP from professions, woodcutting, save version
// 8: spec 0010 criteria 1-3, 6, 13 and the stream part of 12 (plan 0012 M1).
import 'dart:math' as math;

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;

  /// A state at [location] of character [level] that has learned every
  /// profession, with [prof] profession levels.
  GameState worker({
    String location = 'camp',
    int level = 1,
    Map<String, int> prof = const {},
    Map<String, int> inventory = const {},
  }) {
    var s = game.newGame(seed: 1);
    for (final p in data.professions.keys) {
      s = game.learn(s, p);
    }
    return s
      ..location = location
      ..xp = data.xpForLevel(level)
      ..inventory.addAll(inventory)
      ..professions.addAll({
        for (final MapEntry(:key, :value) in prof.entries)
          key: data.professionXpForLevel(value),
      });
  }

  /// Runs the started action for one unit of [steps].
  StepReport work(GameState s, Activity a, int steps) =>
      game.applySteps(game.startActivity(s, a), steps);

  group('criterion 1: profession levels gate spots and recipes', () {
    test('Mining, Woodcutting and Crafting have levels from the table', () {
      expect(data.professions.keys, ['mining', 'woodcutting', 'crafting']);
      final s = worker(prof: {'mining': 7});
      expect(game.professionLevel(s, 'mining'), 7);
      expect(game.professionLevel(s, 'woodcutting'), 1);
      s.professions['mining'] = data.professionXpForLevel(8) - 1;
      expect(game.professionLevel(s, 'mining'), 7);
    });

    test('a new game has learned nothing; spots and recipes say whom to '
        'learn from', () {
      final s = game.newGame(seed: 1)..location = 'copper_hills';
      expect(s.learned, isEmpty);
      expect(
        () => game.startActivity(s, const Activity.gather('copper_vein')),
        throwsA(
          isA<ActivityError>().having(
            (e) => e.message,
            'message',
            contains('Hilde'),
          ),
        ),
      );
    });

    test('learning in camp gives the starter tool; elsewhere it is refused',
        () {
      final s = game.learn(game.newGame(seed: 1), 'mining');
      expect(s.learned, {'mining'});
      expect(s.tools, {'mining': 'old_pick'});
      expect(
        () => game.learn(
          game.newGame(seed: 1)..location = 'goblin_woods',
          'woodcutting',
        ),
        throwsA(isA<ActivityError>()),
      );
      expect(() => game.learn(s, 'mining'), throwsA(isA<ActivityError>()));
    });

    test('the Iron vein needs Mining 10, not a character level', () {
      final low = worker(location: 'iron_ridge', level: 30, prof: {'mining': 9});
      expect(game.nodeLevelMet(low, 'iron_vein'), isFalse);
      expect(
        () => game.startActivity(low, const Activity.gather('iron_vein')),
        throwsA(
          isA<ActivityError>().having(
            (e) => e.message,
            'message',
            'Iron vein needs Mining 10',
          ),
        ),
      );
      final ok = worker(location: 'iron_ridge', prof: {'mining': 10});
      expect(game.nodeLevelMet(ok, 'iron_vein'), isTrue);
      expect(work(ok, const Activity.gather('iron_vein'), 120).state.inventory,
          {'iron_ore': 1});
    });

    test('the Copper vein opens at Mining 1 and character level 1', () {
      final s = worker(location: 'copper_hills');
      expect(work(s, const Activity.gather('copper_vein'), 100).state.inventory,
          {'copper_ore': 1});
    });

    test('the Iron sword needs Crafting 14, not a character level', () {
      final low = worker(level: 30, prof: {'crafting': 13}, inventory: {
        'iron_ore': 8,
      });
      expect(game.recipeLevelMet(low, 'iron_sword'), isFalse);
      expect(
        () => game.startActivity(low, const Activity.craft('iron_sword')),
        throwsA(
          isA<ActivityError>().having(
            (e) => e.message,
            'message',
            'Iron sword needs Crafting 14',
          ),
        ),
      );
      final ok = worker(prof: {'crafting': 14}, inventory: {'iron_ore': 8});
      expect(game.recipeLevelMet(ok, 'iron_sword'), isTrue);
    });

    test('character level-ups no longer name spots or recipes', () {
      for (var l = 2; l <= 30; l++) {
        expect(
          game.levelNews(l).map((n) => n.kind),
          isNot(anyOf(contains(NewsKind.gatheringSpot),
              contains(NewsKind.recipe))),
        );
      }
    });

    test('a profession level-up is an event naming what it opens', () {
      final s = worker(location: 'copper_hills')
        ..professions['mining'] = data.professionXpForLevel(10) - 1;
      final r = work(s, const Activity.gather('copper_vein'), 100);
      expect(
        r.events.whereType<ProfessionLevelUp>().single,
        isA<ProfessionLevelUp>()
            .having((e) => e.profession, 'profession', 'mining')
            .having((e) => e.level, 'level', 10),
      );
      expect(
        game.professionNews('mining', 10),
        [const LevelNews(NewsKind.gatheringSpot, 'iron_vein')],
      );
      expect(
        game.professionNews('crafting', 14).map((n) => n.id),
        containsAll(['iron_sword', 'iron_spear', 'iron_mace', 'iron_shield']),
      );
    });
  });

  group('criterion 2: profession XP and the fade', () {
    test('fade table: full to 5 below, half to 9 below, then 10%', () {
      final s = worker();
      for (final (prof, pct) in [
        (1, 100), (6, 100), (7, 50), (10, 50), (11, 10), (40, 10), //
      ]) {
        s.professions['mining'] = data.professionXpForLevel(prof);
        expect(game.professionFade(s, 'mining', 1), pct, reason: 'Mining $prof');
      }
    });

    test('a gather pays its xp, faded', () {
      for (final (prof, gained) in [(1, 20), (8, 10), (12, 2)]) {
        final s = worker(location: 'copper_hills', prof: {'mining': prof});
        final before = s.professions['mining']!;
        final r = work(s, const Activity.gather('copper_vein'), 100);
        expect(r.state.professions['mining']! - before, gained,
            reason: 'Mining $prof');
      }
    });

    test('a craft pays Crafting XP', () {
      final s = worker(prof: {'crafting': 3}, inventory: {'copper_ore': 5});
      final r = work(s, const Activity.craft('copper_sword'), 150);
      expect(
        r.state.professions['crafting']! - s.professions['crafting']!,
        30,
      );
      expect(r.state.professions['mining'] ?? 0, 0);
    });
  });

  group('criterion 3: a quarter of a fight per step', () {
    int expected(int level, int steps, int fade) {
      final v = (steps *
              data.professionShare *
              data.fightXpPerStep(level) *
              fade /
              100)
          .floor();
      return fade > data.professionBands.last.xpPercent ? math.max(1, v) : v;
    }

    test('gathering pays 25% of the level\'s fight XP per step', () {
      expect(data.professionShare, 0.25);
      for (final level in [1, 5, 12, 25, 31]) {
        final s = worker(location: 'copper_hills', level: level);
        final r = work(s, const Activity.gather('copper_vein'), 100);
        final xp = r.events.whereType<Gathered>().single.xp;
        expect(xp, expected(level, 100, 100), reason: 'level $level');
        expect(r.state.xp - s.xp, xp);
      }
    });

    test('the fade applies to the character XP too', () {
      final s = worker(location: 'copper_hills', level: 20, prof: {
        'mining': 8,
      });
      final r = work(s, const Activity.gather('copper_vein'), 100);
      expect(r.events.whereType<Gathered>().single.xp, expected(20, 100, 50));
    });

    test('crafting pays by steps, not by the recipe\'s xp', () {
      final s = worker(level: 10, prof: {'crafting': 30}, inventory: {
        'dragon_scale': 4,
        'mithril_ore': 4,
      });
      final r = work(s, const Activity.craft('dragon_helm'), 500);
      expect(r.events.whereType<Crafted>().single.xp, expected(10, 500, 100));
    });

    test('fightXpPerStep grows past its list', () {
      final n = data.fightXpPerStepList.length;
      expect(
        data.fightXpPerStep(n + 1),
        closeTo(data.fightXpPerStep(n) * data.xpGrowthAfterList, 1e-9),
      );
    });
  });

  group('criterion 6: woodcutting', () {
    test('the trees and their logs', () {
      for (final (id, area, level, steps, item, xp) in [
        ('oak_tree', 'goblin_woods', 1, 100, 'oak_log', 20),
        ('ash_tree', 'grey_moor', 10, 120, 'ash_log', 55),
        ('pine_tree', 'mountain_pass', 20, 150, 'pine_log', 175),
      ]) {
        final n = data.nodes[id]!;
        expect(n.profession, 'woodcutting');
        expect(data.locations[area]!.nodes, contains(id));
        expect((n.level, n.steps, n.item, n.xp), (level, steps, item, xp));
      }
      for (final v in ['copper_vein', 'iron_vein', 'mithril_vein']) {
        expect(data.nodes[v]!.profession, 'mining');
      }
      expect([for (final v in ['copper_vein', 'iron_vein', 'mithril_vein'])
        data.nodes[v]!.level], [1, 10, 20]);
    });

    test('logs go into hafts and shields; swords keep their recipes', () {
      final logs = {
        'copper_spear': {'oak_log': 1}, 'copper_mace': {'oak_log': 1},
        'bone_spear': {'oak_log': 1}, 'bone_club': {'oak_log': 1},
        'bone_greataxe': {'oak_log': 2}, 'bone_shield': {'oak_log': 2},
        'iron_spear': {'ash_log': 1}, 'iron_mace': {'ash_log': 1},
        'iron_pike': {'ash_log': 3}, 'troll_bone_maul': {'ash_log': 3},
        'iron_shield': {'ash_log': 2},
        'mithril_spear': {'pine_log': 1}, 'mithril_mace': {'pine_log': 1},
        'drake_fang_spear': {'pine_log': 1},
        'drake_fang_hammer': {'pine_log': 1},
        'mithril_greatsword': {'pine_log': 2},
        'drake_fang_halberd': {'pine_log': 3},
        'golem_core_shield': {'pine_log': 2},
      };
      const woods = {'oak_log', 'ash_log', 'pine_log'};
      for (final r in data.recipes.values) {
        final wood = {
          for (final MapEntry(:key, :value) in r.inputs.entries)
            if (woods.contains(key)) key: value,
        };
        if (data.items[r.output]!.tool != null) continue;
        expect(wood, logs[r.id] ?? isEmpty, reason: r.id);
      }
      expect(data.recipes['copper_sword']!.inputs, {'copper_ore': 5});
    });
  });

  group('save version 8 (criterion 13)', () {
    Map<String, Object?> v7(GameState s) => s.toJson()
      ..['version'] = 7
      ..remove('professions')
      ..remove('learned')
      ..remove('tools')
      ..remove('professionRng')
      ..remove('tips');

    test('an old save earns its profession levels from its counters', () {
      final old = stateAt(game, level: 9)
        ..counters.addAll({
          'gathered.copper_ore': 30,
          'gathered.iron_ore': 4,
          'crafted.copper_sword': 2,
          'crafted.bone_shield': 1,
        });
      final s = game.migrate(GameState.fromJson(v7(old)));
      expect(s.learned, {'mining', 'crafting'});
      expect(s.tools, {'mining': 'old_pick', 'crafting': 'old_hammer'});
      expect(s.professions['mining'], 30 * 20 + 4 * 55);
      expect(s.professions['crafting'], 2 * 30 + 55);
      expect(s.professions['woodcutting'] ?? 0, 0);
      expect(s.xp, old.xp);
      expect(s.rngState, old.rngState);
    });

    test('a save without counters starts its professions at 0', () {
      final s = game.migrate(GameState.fromJson(v7(stateAt(game))));
      expect(s.learned, {'mining', 'crafting'});
      expect(s.professions.values.fold(0, (a, b) => a + b), 0);
    });

    test('a version 8 save keeps everything', () {
      final s = worker(prof: {'mining': 12})..tips.add('hilde_1');
      final back = GameState.fromJson(s.toJson());
      expect(back.toJson(), s.toJson());
      expect(game.migrate(back.copy()).toJson(), s.toJson());
    });
  });

  group('criterion 12: the profession stream', () {
    test('a new game seeds it from the seed, without a draw', () {
      final a = game.newGame(seed: 1);
      final b = game.newGame(seed: 2);
      expect(a.rngState, Rng.seeded(1).state);
      expect(a.professionRng, isNot(a.rngState));
      expect(a.professionRng, isNot(b.professionRng));
      expect(game.newGame(seed: 1).professionRng, a.professionRng);
    });

    test('an old save seeds it from its generator, which stays as it was', () {
      final old = stateAt(game, seed: 3);
      final json = old.toJson()
        ..['version'] = 7
        ..remove('professionRng');
      final s = game.migrate(GameState.fromJson(json));
      expect(s.rngState, old.rngState);
      expect(s.professionRng, isNot(0));
      expect(s.professionRng, isNot(old.rngState));
    });

    test('learning, gathering and crafting draw nothing from the shared '
        'generator', () {
      final s = worker(location: 'copper_hills');
      final r = work(s, const Activity.gather('copper_vein'), 300);
      expect(r.state.rngState, s.rngState);
    });
  });
}
