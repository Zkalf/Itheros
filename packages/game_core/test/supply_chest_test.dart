// The supply chest: spec 0013 criteria 1-6, 8-35, 52, 53 and 55 (plan 0037
// M1). The screens, the sync and the test walk (criteria 7, 36-51, 54) are
// in the app's tests.
import 'package:game_core/game_core.dart';
import 'package:game_core/simulation.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;
  final chest = data.supplyChest;
  const day = '2026-11-01';
  const day2 = '2026-11-02';
  const day3 = '2026-11-03';

  /// Mining copper at Copper Hills: a running action that never stops.
  GameState mining({int level = 1, int bank = 0}) => game.startActivity(
    stateAt(game, location: 'copper_hills', level: level, bank: bank),
    const Activity.gather('copper_vein'),
  );

  GameState walk(GameState s, int steps, [String? on = day]) =>
      game.applySteps(s, steps, day: on).state;

  /// [n] chests rolled for [s], each from its own seed.
  List<Map<String, int>> roll(GameState s, int n) => [
    for (var i = 1; i <= n; i++) game.rollSupplyChest(s, Rng.seeded(i)),
  ];

  bool isGear(String key) => data.itemOf(key)?.slot != null;
  bool isShard(String key) => data.shards.contains(key);
  Iterable<String> gearIn(Map<String, int> c) => c.keys.where(isGear);

  group('the goal', () {
    test('criterion 1: a walked step into an action adds 1', () {
      expect(walk(mining(), 10).supplySteps[day], 10);
    });

    test('criterion 2: a boost step of the bank adds 1 more', () {
      expect(walk(mining(bank: 100), 10).supplySteps[day], 20);
    });

    test('criterion 3: a step into a walk counts', () {
      final s = game.startActivity(
        stateAt(game),
        const Activity.travel('goblin_woods'),
      );
      expect(walk(s, 10).supplySteps[day], 10);
    });

    test('criterion 4: fights, spots, crafts and rerolls count', () {
      final fight = game.startActivity(
        stateAt(game, location: 'goblin_woods'),
        const Activity.fight('goblin'),
      );
      final craft = game.startActivity(
        stateAt(game, inventory: {'copper_ore': 50}),
        const Activity.craft('copper_sword'),
      );
      final reroll = game.startActivity(
        stateAt(
          game,
          level: 10,
          inventory: {'bone_sword': 1, 'common_dust': 30},
        ),
        const Activity.reroll('bone_sword'),
      );
      for (final (name, s) in [
        ('fight', fight),
        ('spot', mining()),
        ('craft', craft),
        ('reroll', reroll),
      ]) {
        expect(walk(s, 10).supplySteps[day], 10, reason: name);
      }
    });

    test('criterion 5: a step into the bank counts nothing', () {
      final s = walk(stateAt(game), 100);
      expect(s.bank, 100);
      expect(s.supplySteps[day] ?? 0, 0);
    });

    test('criterion 6: a step lost to a full bank counts nothing', () {
      final full = stateAt(game);
      full.bank = game.bankCap(full);
      expect(walk(full, 100).supplySteps[day] ?? 0, 0);
    });

    test('criterion 8: applySteps without a day counts nothing', () {
      final s = game.applySteps(mining(), 6000).state;
      expect(s.supplySteps, isEmpty);
      expect(s.supplyChests, isEmpty);
    });
  });

  group('earning', () {
    test('criterion 9: the step that reaches 5,000 earns one chest', () {
      expect(chest.goal, 5000);
      final before = game.applySteps(mining(), 4999, day: day);
      expect(before.state.supplyChests, isEmpty);
      final r = game.applySteps(before.state, 1, day: day);
      expect(r.state.supplyChests, hasLength(1));
      expect(r.state.supplyChests.single.day, day);
      expect(r.state.supplyPaid, {day});
      expect(r.events.whereType<SupplyChestEarned>().single.day, day);
    });

    test('criterion 10: a day never pays a second chest', () {
      var s = walk(mining(), 5000);
      s = walk(s, 10000);
      expect(s.supplyChests, hasLength(1));
    });

    test('criterion 11: 3 days that each reach the goal earn 3 chests', () {
      var s = mining();
      for (final d in [day, day2, day3]) {
        s = walk(s, 5000, d);
      }
      expect([for (final c in s.supplyChests) c.day], [day, day2, day3]);
    });

    test('criterion 12: late steps for an earlier day earn its chest', () {
      var s = walk(mining(), 3000, day);
      s = walk(s, 5000, day2);
      s = walk(s, 2000, day);
      expect(s.supplyPaid, {day, day2});
      expect([for (final c in s.supplyChests) c.day], [day2, day]);
    });

    test('criterion 13: steps credited before the update count nothing', () {
      // A version 13 save has no count: only steps after the update count.
      final json = walk(mining(), 3000).toJson()
        ..['version'] = 13
        ..remove('supplySteps')
        ..remove('supplyPaid')
        ..remove('supplyChests')
        ..remove('supplyRng');
      var s = game.migrate(GameState.fromJson(json));
      expect(s.supplySteps, isEmpty);
      s = walk(s, 4999);
      expect(s.supplyChests, isEmpty);
    });
  });

  group('contents', () {
    /// [s] without Crafting: its choice gives several inputs at once, and a
    /// copper sword's (5 Copper ore) look like Mining's.
    GameState noCrafting(GameState s) => s..learned.remove('crafting');

    // Level 1, every profession but Crafting learned at 1: the window holds
    // only the Rusty dagger, so its quality rolls get no level boost.
    late final low = roll(noCrafting(stateAt(game)), 200000);
    late final mid = roll(noCrafting(stateAt(game, level: 16)), 20000);

    Map<String, int> commonOf(Map<String, int> c) => {
      for (final e in c.entries)
        if (!isGear(e.key) && !isShard(e.key)) e.key: e.value,
    };

    test('criterion 14: each chest holds exactly one common roll', () {
      for (final c in [...low.take(2000), ...mid.take(2000)]) {
        expect(commonOf(c), hasLength(1), reason: '$c');
      }
    });

    test('criterion 15 (amendment 1 criterion 2): the common roll picks '
        'evenly among the learned gathering professions, Crafting and a '
        'meal', () {
      // Crafting 30 and the rest at 1: its inputs are never 5 of one spot's
      // item.
      final s = stateAt(game)
        ..professions['crafting'] = data.professionXpForLevel(30);
      const spots = {'copper_ore', 'oak_log', 'lake_scale', 'deer_hide'};
      final picks = <String, int>{};
      final chests = roll(s, 60000);
      for (final c in chests) {
        final common = commonOf(c);
        final first = common.keys.first;
        final pick = data.itemOf(first)!.meal != null
            ? 'meal'
            : common.length == 1 && spots.contains(first) && common[first] == 5
            ? first
            : 'crafting';
        picks[pick] = (picks[pick] ?? 0) + 1;
      }
      expect(picks.keys.toSet(), {...spots, 'crafting', 'meal'});
      for (final n in picks.values) {
        expect(n / chests.length, closeTo(1 / 6, 0.01));
      }
    });

    test('amendment 1 criteria 3 and 4: Crafting gives the inputs of one '
        'gear recipe at its level, never one of a chase item', () {
      for (final crafting in [1, 12, 20, 30]) {
        final s = stateAt(game)
          ..learned.removeAll(['mining', 'woodcutting', 'fishing', 'hunting'])
          ..professions['crafting'] = data.professionXpForLevel(crafting);
        final crafts = game.supplyCrafts(crafting);
        expect(crafts, isNotEmpty, reason: 'Crafting $crafting');
        for (final r in crafts) {
          expect(data.items[r.output]!.slot, isNotNull);
          expect(r.profession, 'crafting');
          expect(r.craftingLevel, inInclusiveRange(crafting - 4, crafting));
          expect(chest.exclude, isNot(contains(r.output)));
        }
        final seen = <String>{};
        for (final c in roll(s, 600)) {
          final common = commonOf(c);
          if (data.itemOf(common.keys.first)!.meal != null) continue;
          final r = crafts.where((r) => _same(r.inputs, common)).toList();
          expect(r, isNotEmpty, reason: 'Crafting $crafting: $common');
          seen.add(r.first.id);
        }
        expect(seen, isNotEmpty);
      }
    });

    // "Best spot that the player can work" (spec 0013 §2.4 point 21): a spot
    // in the fog is not one the player can work.
    test('criterion 16: the best spot is never one in the fog', () {
      final s = noCrafting(stateAt(game, level: 20));
      expect(game.nodeFogged(s, 'mithril_vein'), isTrue);
      final ores = {
        for (final c in roll(s, 600))
          for (final k in commonOf(c).keys)
            if (data.nodes.values.any(
              (n) => n.profession == 'mining' && n.item == k,
            ))
              k,
      };
      expect(ores, isNotEmpty);
      expect(ores, isNot(contains('mithril_ore')));
      s.explored.add('mithril_deep');
      final open = {for (final c in roll(s, 600)) ...commonOf(c).keys};
      expect(open, contains('mithril_ore'));
    });

    test('criterion 16: a profession gives 5 of its best spot\'s item', () {
      expect(chest.materials, 5);
      // The level 10 spots, out of the fog (point 21: spots the player can
      // work).
      final s = noCrafting(stateAt(game, level: 12))
        ..explored.addAll(['iron_ridge', 'grey_moor', 'troll_bridge']);
      final seen = <String>{};
      for (final c in roll(s, 500)) {
        final common = commonOf(c);
        final item = common.keys.single;
        if (data.itemOf(item)!.meal != null) continue;
        expect(common[item], 5);
        seen.add(item);
      }
      // Level 12: the level 10 spots of each gathering profession.
      expect(seen, {'iron_ore', 'ash_log', 'river_scale', 'elk_hide'});
    });

    test('criterion 17: a meal gives 2 of one meal of the level\'s tier', () {
      expect(chest.meals, 2);
      for (final (level, tier) in [(1, 1), (12, 2), (25, 3)]) {
        final s = game.newGame(seed: 1)..xp = data.xpForLevel(level);
        for (final c in roll(s, 200)) {
          final common = commonOf(c);
          final meal = data.itemOf(common.keys.single)!.meal;
          expect(meal, isNotNull);
          expect(meal!.tier, tier, reason: 'level $level');
          expect(common.values.single, 2);
        }
      }
    });

    test('criterion 18 (amendment 1 criterion 5): no gathering profession '
        'and no Crafting always gives a meal', () {
      final s = game.newGame(seed: 1);
      expect(s.learned, isEmpty);
      for (final c in roll(s, 500)) {
        expect(data.itemOf(commonOf(c).keys.single)!.meal, isNotNull);
      }
      // Cooking alone is not a choice either.
      final cook = game.learn(game.newGame(seed: 1), 'cooking');
      for (final c in roll(cook, 500)) {
        expect(data.itemOf(commonOf(c).keys.single)!.meal, isNotNull);
      }
    });

    test('criterion 19 (amendment 1 criterion 1): about 1 chest in 10 holds '
        'gear', () {
      expect(chest.gearChance, 0.1);
      final n = low.where((c) => gearIn(c).isNotEmpty).length;
      expect(n / low.length, closeTo(0.1, 0.005));
    });

    test('criterion 20: about 1 chest in 50 holds a boss shard', () {
      expect(chest.shardChance, 0.02);
      final n = low.where((c) => c.keys.any(isShard)).length;
      expect(n / low.length, closeTo(0.02, 0.003));
    });

    test('criterion 21: the shard is the one of the level\'s tier', () {
      for (final (level, shard) in [
        (1, 'kings_shard'),
        (12, 'chieftains_shard'),
        (25, 'dragons_shard'),
      ]) {
        final shards = {
          for (final c in roll(stateAt(game, level: level), 3000))
            ...c.keys.where(isShard),
        };
        expect(shards, {shard}, reason: 'level $level');
      }
    });

    test('criteria 22 and 23: gear from the level minus 4 up to the level, '
        'never above', () {
      expect(chest.gearWindow, 4);
      final levels = {
        for (final c in mid)
          for (final g in gearIn(c)) data.itemLevel(data.itemOf(g)!.id),
      };
      expect(levels, isNotEmpty);
      for (final l in levels) {
        expect(l, inInclusiveRange(12, 16));
      }
      for (var level = 1; level <= 30; level++) {
        for (final id in game.supplyWindow(level)) {
          expect(data.itemLevel(id), lessThanOrEqualTo(level));
          expect(data.itemLevel(id), greaterThanOrEqualTo(level - 4));
        }
      }
    });

    test('criterion 24: a level 1 player only gets the Rusty dagger', () {
      expect(game.supplyWindow(1), ['rusty_dagger']);
      final gear = {
        for (final c in low)
          for (final g in gearIn(c)) data.itemOf(g)!.id,
      };
      expect(gear, {'rusty_dagger'});
    });

    test('criterion 25: no excluded gear comes from a chest', () {
      expect(chest.exclude, {
        'kings_blade',
        'chieftains_amulet',
        'dragons_heart',
        'golden_antler_mantle',
        'tusk_mantle',
        'lynx_mantle',
        'drowned_captains_ring',
      });
      for (var level = 1; level <= 40; level++) {
        expect(
          game.supplyWindow(level).toSet().intersection(chest.exclude),
          isEmpty,
          reason: 'level $level',
        );
      }
      for (final level in [10, 20, 30]) {
        for (final c in roll(stateAt(game, level: level), 3000)) {
          for (final g in gearIn(c)) {
            expect(chest.exclude, isNot(contains(data.itemOf(g)!.id)));
          }
        }
      }
    });

    group('quality', () {
      late final qualities = <String, int>{
        for (final q in data.qualities) q.id: 0,
      };
      late final gear = [for (final c in low) ...gearIn(c)];
      setUpAll(() {
        for (final g in gear) {
          final q = data.qualityOf(g).id;
          qualities[q] = qualities[q]! + 1;
        }
      });
      double share(String q) => qualities[q]! / gear.length;
      double drop(String q) =>
          data.qualities.firstWhere((x) => x.id == q).chance;

      test('criterion 26: rare, epic and legendary at twice a drop\'s '
          'chance', () {
        expect(chest.qualityBoost, 2);
        expect(share('rare'), closeTo(2 * drop('rare'), 0.01));
        expect(share('epic'), closeTo(2 * drop('epic'), 0.006));
        expect(share('legendary'), closeTo(2 * drop('legendary'), 0.003));
      });

      test('criterion 27: uncommon at a drop\'s chance', () {
        expect(share('uncommon'), closeTo(drop('uncommon'), 0.012));
      });
    });

    test('criterion 28: a talent does not change the quality roll', () {
      final plain = stateAt(game, level: 30);
      final talented = stateAt(game, level: 30)..talents['treasure_hunter'] = 3;
      for (var i = 1; i <= 3000; i++) {
        expect(
          game.rollSupplyChest(talented, Rng.seeded(i)),
          game.rollSupplyChest(plain, Rng.seeded(i)),
        );
      }
    });

    test('criterion 29: chest gear has the bonus stats of a drop', () {
      for (final c in mid) {
        for (final g in gearIn(c)) {
          final steps = data.qualities.indexOf(data.qualityOf(g));
          expect(data.bonusRolls(g), hasLength(steps), reason: g);
        }
      }
    });
  });

  group('rolled at once', () {
    /// A level 5 player's first chest that holds gear, earned by mining.
    (GameState, SupplyChest) earnGear() {
      for (var seed = 1; ; seed++) {
        final s = game.startActivity(
          stateAt(game, location: 'copper_hills', level: 5, seed: seed),
          const Activity.gather('copper_vein'),
        );
        final after = walk(s, 5000);
        final c = after.supplyChests.single;
        if (gearIn(c.items).isNotEmpty) return (after, c);
      }
    }

    test('criterion 30: the contents are fixed when the chest is earned', () {
      final (s, c) = earnGear();
      for (final g in gearIn(c.items)) {
        expect(data.itemLevel(data.itemOf(g)!.id), inInclusiveRange(1, 5));
      }
      final again = walk(s, 3000, day);
      expect(again.supplyChests.single.items, c.items);
    });

    test('criterion 31: a level up does not change the contents', () {
      final (s, c) = earnGear();
      final up = s.copy()..xp = data.xpForLevel(30);
      final opened = game.openSupplyChest(up).state;
      for (final e in c.items.entries) {
        expect(
          (opened.inventory[e.key] ?? 0) - (up.inventory[e.key] ?? 0),
          e.value,
        );
      }
    });

    test('criterion 32: a chest roll does not change the fights after it', () {
      GameState fights(String? on) => game
          .applySteps(
            game.startActivity(
              stateAt(game, location: 'goblin_woods', level: 3),
              const Activity.fight('goblin'),
            ),
            8000,
            day: on,
          )
          .state;
      final withChest = fights(day);
      final without = fights(null);
      expect(withChest.supplyChests, hasLength(1));
      expect(without.supplyChests, isEmpty);
      expect(withChest.rngState, without.rngState);
      expect(withChest.inventory, without.inventory);
      expect(withChest.xp, without.xp);
      expect(withChest.counters, without.counters);
    });
  });

  group('opening', () {
    GameState twoChests() {
      var s = mining();
      s = walk(s, 5000, day);
      return walk(s, 5000, day2);
    }

    test('criterion 33: Open moves the oldest chest into the bag', () {
      final s = twoChests();
      final oldest = s.supplyChests.first;
      final opened = game.openSupplyChest(s).state;
      expect([for (final c in opened.supplyChests) c.day], [day2]);
      for (final e in oldest.items.entries) {
        expect(
          (opened.inventory[e.key] ?? 0) - (s.inventory[e.key] ?? 0),
          e.value,
        );
      }
    });

    test('criterion 34: Open all moves every chest into the bag', () {
      final s = twoChests();
      final all = <String, int>{};
      for (final c in s.supplyChests) {
        c.items.forEach((k, v) => all[k] = (all[k] ?? 0) + v);
      }
      final opened = game.openAllSupplyChests(s).state;
      expect(opened.supplyChests, isEmpty);
      for (final e in all.entries) {
        expect(
          (opened.inventory[e.key] ?? 0) - (s.inventory[e.key] ?? 0),
          e.value,
        );
      }
    });

    test('criterion 35: opening uses no steps', () {
      final s = twoChests();
      final opened = game.openAllSupplyChests(s).state;
      expect(opened.bank, s.bank);
      expect(opened.activity!.progress, s.activity!.progress);
      expect(opened.supplySteps, s.supplySteps);
      expect(opened.supplyRng, s.supplyRng);
    });

    test('Open returns one chest and what it held (#169)', () {
      final s = twoChests();
      final r = game.openSupplyChest(s);
      expect(r.count, 1);
      expect(r.items, s.supplyChests.first.items);
    });

    test('Open all returns how many chests and what they held (#169)', () {
      final s = twoChests();
      final all = <String, int>{};
      for (final c in s.supplyChests) {
        c.items.forEach((k, v) => all[k] = (all[k] ?? 0) + v);
      }
      final r = game.openAllSupplyChests(s);
      expect(r.count, 2);
      expect(r.items, all);
    });

    test('with no chest waiting, Open is refused', () {
      expect(
        () => game.openSupplyChest(mining()),
        throwsA(isA<ActivityError>()),
      );
    });
  });

  group('save', () {
    // Spec 0013 raised the version to 14; later specs raise it further.
    test('criterion 52: the save version is 14 or later', () {
      expect(GameState.schemaVersion, greaterThanOrEqualTo(14));
      expect(mining().toJson()['version'], GameState.schemaVersion);
    });

    test('criterion 53: a version 13 save loads with no chest and no paid '
        'day', () {
      final json = mining().toJson()
        ..['version'] = 13
        ..remove('supplySteps')
        ..remove('supplyPaid')
        ..remove('supplyChests')
        ..remove('supplyRng');
      final s = game.migrate(GameState.fromJson(json));
      expect(s.supplyChests, isEmpty);
      expect(s.supplyPaid, isEmpty);
      expect(s.supplySteps, isEmpty);
      // The same save gives the same stream at each load.
      expect(s.supplyRng, isNot(0));
      expect(game.migrate(GameState.fromJson(json)).supplyRng, s.supplyRng);
    });

    test('criterion 55: waiting chests survive a save and a load', () {
      var s = mining(level: 16);
      final days = [
        for (var d = 1; d <= 20; d++) '2026-10-${'$d'.padLeft(2, '0')}',
      ];
      for (final d in days) {
        s = walk(s, 5000, d);
      }
      expect(s.supplyChests.any((c) => gearIn(c.items).isNotEmpty), isTrue);
      final back = game.migrate(GameState.fromJson(s.toJson()));
      // Maps inside records compare by identity, so each part on its own.
      expect(
        [for (final c in back.supplyChests) c.day],
        [for (final c in s.supplyChests) c.day],
      );
      expect(
        [for (final c in back.supplyChests) c.items],
        [for (final c in s.supplyChests) c.items],
      );
    });

    test('the count and the paid days keep the 14 most recent days', () {
      var s = mining();
      for (var d = 1; d <= 20; d++) {
        s = walk(s, 100, '2026-10-${'$d'.padLeft(2, '0')}');
      }
      expect(s.supplySteps.keys, hasLength(14));
      expect(
        s.supplySteps.keys.reduce((a, b) => a.compareTo(b) < 0 ? a : b),
        '2026-10-07',
      );
    });

    // A clock once set ahead leaves later day keys behind; they must not
    // push out the day being walked, or it could pay again.
    test('later day keys never prune the day being walked', () {
      var s = mining();
      for (var d = 1; d <= 14; d++) {
        s = walk(s, 100, '2027-01-${'$d'.padLeft(2, '0')}');
      }
      s = walk(s, 5000, day);
      expect(s.supplyPaid, contains(day));
      s = walk(s, 5000, day);
      expect(s.supplyChests.where((c) => c.day == day), hasLength(1));
    });
  });

  test('criterion 56: the pacing walkers earn and open chests', () {
    final r = simulate(game, stepsPerDay: 5000, days: 3);
    expect(r.chestDays, 3);
    expect(r.finalState.supplyChests, hasLength(lessThanOrEqualTo(1)));
  });
}

/// Whether [a] and [b] hold the same items and counts.
bool _same(Map<String, int> a, Map<String, int> b) =>
    a.length == b.length && a.entries.every((e) => b[e.key] == e.value);
