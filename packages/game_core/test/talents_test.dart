// Talent trees: spec 0015 criteria 1-12, 14-47 and 55-61 in the rules
// (plan 0031 M1). The screens (criteria 13, 48-54) are in the app's tests.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;

  /// [s] with [ranks] set directly, prerequisites and rows not checked.
  GameState withRanks(GameState s, Map<String, int> ranks) =>
      s..talents.addAll(ranks);

  /// A level [level] player in camp with every profession learned.
  GameState at(int level, [Map<String, int> ranks = const {}]) =>
      withRanks(stateAt(game, level: level), ranks);

  /// A full tree: every talent of [tree] with all its ranks.
  Map<String, int> full(String tree) => {
    for (final t in data.talents.values)
      if (t.tree == tree) t.id: t.ranks,
  };

  group('points and rows', () {
    test('criterion 1: 0 points at level 9, 3 at level 12', () {
      expect(game.talentPointsLeft(at(9)), 0);
      expect(game.talentPointsLeft(at(12)), 3);
    });

    test('criterion 2: a rank costs 1 point', () {
      final s = game.takeRank(at(12), 'might');
      expect(s.talents['might'], 1);
      expect(game.talentPointsLeft(s), 2);
    });

    test('criterion 3: no rank with 0 points left', () {
      expect(game.whyNotRank(at(9), 'might'), 'No points left');
      expect(
        () => game.takeRank(at(9), 'might'),
        throwsA(isA<ActivityError>()),
      );
    });

    test('criterion 4: a row 2 talent needs 5 ranks in its tree', () {
      final s = at(20, {'might': 4});
      // Amendment 4 criterion 107: the points in the tree too.
      expect(
        game.whyNotRank(s, 'guard'),
        'Opens at 5 points in Combat. You have 4/5.',
      );
    });

    test('criterion 5: a row 2 talent opens with 5 ranks', () {
      final s = game.takeRank(at(20, {'might': 4, 'toughness': 1}), 'guard');
      expect(s.talents['guard'], 1);
    });

    test('criterion 6: Utility ranks open no Combat row', () {
      final s = at(30, {'deep_pockets': 5, 'nimble_hands': 5});
      expect(game.ranksIn(s, 'combat'), 0);
      // Amendment 4 criterion 108: no ranks in Combat.
      expect(
        game.whyNotRank(s, 'guard'),
        'Opens at 5 points in Combat. You have 0/5.',
      );
      expect(game.whyNotRank(s, 'bountiful'), isNull);
    });

    test('criterion 7: no rank past the last one', () {
      final s = at(20, {'might': 5});
      expect(game.whyNotRank(s, 'might'), 'All ranks taken');
    });

    // Criterion 8 as amendment 1 has it (criterion 65).
    test('criteria 8, 65: Combat holds 30 points, Utility 33', () {
      int points(String tree) => [
        for (final t in data.talents.values)
          if (t.tree == tree) t.ranks,
      ].fold(0, (a, b) => a + b);
      expect(points('combat'), 30);
      expect(points('utility'), 33);
    });

    test('criteria 9-10: Impale needs Keen eye 3/3', () {
      final open = {...full('combat')}
        ..remove('impale')
        ..['keen_eye'] = 2
        ..['swift_strikes'] = 5;
      expect(game.ranksIn(at(40, open), 'combat'), greaterThanOrEqualTo(25));
      expect(game.whyNotRank(at(40, open), 'impale'), 'Needs Keen eye 3/3');
      final ready = {...open, 'keen_eye': 3};
      expect(game.whyNotRank(at(40, ready), 'impale'), isNull);
    });

    test('criterion 11: Lucky hammer needs Master crafter 3/3', () {
      final open = {...full('utility')}
        ..remove('lucky_hammer')
        ..remove('wayfarer')
        ..['master_crafter'] = 2;
      expect(
        game.whyNotRank(at(40, open), 'lucky_hammer'),
        'Needs Master crafter 3/3',
      );
    });

    test('criterion 12: Wayfarer needs Light pack 5/5', () {
      final open = {...full('utility')}
        ..remove('wayfarer')
        ..['light_pack'] = 4;
      expect(game.whyNotRank(at(40, open), 'wayfarer'), 'Needs Light pack 5/5');
    });
  });

  // The numbers the sim tuned, as amendment 2 has them: the tests of
  // criteria 14, 18, 26 and 66 follow the data, so these pin it.
  test('amendment 2 criteria 70-74: the tuned numbers', () {
    expect(data.talents['might']!.value, 0.008);
    expect(data.talents['swift_strikes']!.value, 0.005);
    expect(data.talents['nimble_hands']!.value, 0.01);
    expect(data.talents['practised_hands']!.value, 0.02);
    expect(data.talents['practised_hands']!.row, 2);
    expect(data.talents['impale']!.value, 0.5);
    // Criterion 72: 100 steps with a starter tool cost 95.
    expect(
      game.professionSteps(at(20, {'nimble_hands': 5}), 'mining', 100),
      95,
    );
  });

  group('combat effects', () {
    // Level 20, no gear: Attack 24, HP 220, Defense 21.
    // The percents follow the data: amendment 1 lets the sim tune them
    // (plan 0031 results).
    /// [talent] with all its ranks, as a share: Might 0.04 for +4%.
    double fullShare(String talent) =>
        data.talents[talent]!.value * data.talents[talent]!.ranks;

    /// [v] times [talent]'s full share, rounded down.
    int of(int v, String talent) => (v * fullShare(talent) + 1e-9).floor();

    test('criteria 14-16: Might, Toughness and Guard, rounded down', () {
      final plain = game.stats(at(20));
      final s = game.stats(at(20, {'might': 5, 'toughness': 5, 'guard': 3}));
      expect(s.attack, plain.attack + of(plain.attack, 'might'));
      expect(s.hp, plain.hp + of(plain.hp, 'toughness'));
      expect(s.defense, plain.defense + of(plain.defense, 'guard'));
      expect(s.hp, greaterThan(plain.hp));
    });

    test('criterion 17: Keen eye, Precision and Evasion add points', () {
      final plain = at(20);
      final s = at(20, {'keen_eye': 3, 'precision': 3, 'evasion': 2});
      expect(game.critChance(s), game.critChance(plain) + 3);
      expect(game.stats(s).hit, game.stats(plain).hit + 3);
      expect(game.dodgeChance(s), game.dodgeChance(plain) + 2);
    });

    // The arena fight: Attack 5 against 30 HP, sure hits, no crits: six
    // rounds of 10 steps.
    final arena = arenaGame([monster('dummy', hp: 30)]);
    GameState fighter(Map<String, int> ranks) {
      final s = arena.newGame(seed: 1)..talents.addAll(ranks);
      return arena.startActivity(s, const Activity.fight('dummy'));
    }

    // Spec 0015 had 15% (9 steps); the sim tuned it (plan 0031 results).
    test('criterion 18: Swift strikes gives steps back after 6 rounds', () {
      final r = arena.applySteps(fighter({'swift_strikes': 5}), 60);
      expect(r.events.whereType<FightWon>(), hasLength(1));
      expect(r.state.activity!.progress, of(60, 'swift_strikes'));
      final plain = arena.applySteps(fighter({}), 60);
      expect(plain.state.activity!.progress, 0);
    });

    test('criterion 19: a lost fight also gives its steps back', () {
      // 3 damage a round against 30 HP: lost in round 10, after 100 steps.
      final tough = arenaGame([monster('brute', hp: 1000, attack: 4)]);
      var s = tough.newGame(seed: 1)..talents['swift_strikes'] = 5;
      s = tough.startActivity(s, const Activity.fight('brute'));
      final r = tough.applySteps(s, 100);
      expect(r.events.whereType<FightLost>(), hasLength(1));
      expect(r.state.activity!.progress, of(100, 'swift_strikes'));
      expect(r.state.activity!.progress, greaterThan(0));
    });

    test('criterion 20: Treasure hunter boosts drop quality by 1.3', () {
      final s = at(20, {'treasure_hunter': 3});
      expect(game.qualityBoost(s, QualityRoll.drop), closeTo(1.3, 1e-9));
      expect(game.qualityBoost(at(20), QualityRoll.drop), 1);
    });

    // A monster that always drops a sword: the share of Uncommon-or-better.
    final dropper = arenaGame([
      monster(
        'squire',
        extra: {
          'drops': [
            {'item': 'copper_sword', 'chance': 1.0},
          ],
        },
      ),
    ]);
    (int drops, int better) swords(Map<String, int> ranks) {
      var s = dropper.newGame(seed: 3)..talents.addAll(ranks);
      s = dropper.startActivity(s, const Activity.fight('squire'));
      final r = dropper.applySteps(s, 10 * 6000);
      var drops = 0, better = 0;
      for (final MapEntry(:key, :value) in r.state.inventory.entries) {
        if (dropper.data.itemOf(key)?.id != 'copper_sword') continue;
        drops += value;
        if (dropper.data.qualityOf(key) != dropper.data.qualities.first) {
          better += value;
        }
      }
      return (drops, better);
    }

    test('criteria 20-21: more quality, the same number of drops', () {
      final (plainDrops, plainBetter) = swords({});
      final (drops, better) = swords({'treasure_hunter': 3});
      expect(drops, plainDrops);
      expect(better / plainBetter, inInclusiveRange(1.2, 1.4));
    });

    test('criterion 22: Treasure hunter does not change crafted quality', () {
      final s = at(20, {'treasure_hunter': 3});
      expect(game.qualityBoost(s, QualityRoll.craft), 1);
      expect(game.qualityBoost(s, QualityRoll.reroll), 1);
    });

    test('criteria 23-24: Impale crits 2.5x; monsters as before', () {
      final crits = arenaGame(
        [monster('dummy', hp: 1000, attack: 4)],
        economy: {
          'combat': {...sureHits, 'critBase': 100, 'critCap': 100},
        },
      );
      int dealt(Map<String, int> ranks) {
        var s = crits.newGame(seed: 1)..talents.addAll(ranks);
        s = crits.startActivity(s, const Activity.fight('dummy'));
        final log = crits.applySteps(s, 10).state.activity!.log.single;
        expect(log.mine, Swing.crit);
        return log.dealt!;
      }

      int taken(Map<String, int> ranks) {
        var s = crits.newGame(seed: 1)..talents.addAll(ranks);
        s = crits.startActivity(s, const Activity.fight('dummy'));
        return crits.applySteps(s, 10).state.activity!.log.single.taken!;
      }

      expect(dealt({}), 10);
      expect(dealt({'impale': 1}), 13);
      expect(
        crits.critDamage(crits.newGame(seed: 1)..talents['impale'] = 1),
        2.5,
      );
      expect(taken({'impale': 1}), taken({}));
    });
  });

  group('utility effects', () {
    // One copper vein action from Mining 1: its profession and character XP.
    (int, int) mine(Map<String, int> ranks) {
      var s = stateAt(game, location: 'copper_hills', professionLevel: 1)
        ..talents.addAll(ranks);
      s = game.startActivity(s, const Activity.gather('copper_vein'));
      final before = s.professions['mining'] ?? 0;
      final r = game.applySteps(s, 100);
      return (
        (r.state.professions['mining'] ?? 0) - before,
        r.events.whereType<Gathered>().first.xp,
      );
    }

    // Amendment 1 starts at +12%; the sim tuned it (plan 0031 results).
    test('amendment 1 criterion 66: Practised hands, more profession XP', () {
      final (plain, _) = mine({});
      final (more, _) = mine({'practised_hands': 3});
      final share = data.talents['practised_hands']!.value * 3;
      expect(more, (plain * (1 + share) + 1e-9).floor());
      expect(more, greaterThan(plain));
    });

    test('amendment 1 criterion 67: the same character XP', () {
      final (_, plain) = mine({});
      final (_, more) = mine({'practised_hands': 3});
      expect(more, plain);
    });

    test('criterion 25: Deep pockets adds 3,000 to the bank cap', () {
      expect(
        game.bankCap(at(20, {'deep_pockets': 5})),
        game.bankCap(at(20)) + 3000,
      );
    });

    // Spec 0015 had 90 (10% off); the sim tuned it (plan 0031 results).
    test('criterion 26: Nimble hands: fewer steps for 100', () {
      final s = at(20, {'nimble_hands': 5});
      expect(game.professionSteps(at(20), 'mining', 100), 100);
      final share = data.talents['nimble_hands']!.value * 5;
      expect(
        game.professionSteps(s, 'mining', 100),
        (100 * (1 - share) - 1e-9).ceil(),
      );
      expect(game.professionSteps(s, 'mining', 100), lessThan(100));
    });

    test('criterion 27: Nimble hands leaves travel and fights', () {
      final s = at(20, {'nimble_hands': 5});
      expect(game.travelCost(s, 500), 500);
      // Six rounds of 10 steps still take 60 steps.
      final arena = arenaGame([monster('dummy', hp: 30)]);
      var f = arena.newGame(seed: 1)..talents['nimble_hands'] = 5;
      f = arena.startActivity(f, const Activity.fight('dummy'));
      expect(arena.applySteps(f, 59).events.whereType<FightWon>(), isEmpty);
      expect(
        arena.applySteps(f, 60).events.whereType<FightWon>(),
        hasLength(1),
      );
    });

    // 2,000 actions at the copper vein, from Mining 1 with the starter tool.
    int ore(Map<String, int> ranks) {
      var s = stateAt(game, location: 'copper_hills', professionLevel: 1)
        ..talents.addAll(ranks);
      s = game.startActivity(s, const Activity.gather('copper_vein'));
      final r = game.applySteps(s, 100 * 2000);
      return r.state.inventory['copper_ore'] ?? 0;
    }

    test('criterion 28: Bountiful gives about 15% more ore at rank 5', () {
      final plain = ore({});
      final more = ore({'bountiful': 5});
      expect((more - plain) / plain, inInclusiveRange(0.12, 0.18));
    });

    test('criterion 29: Bountiful leaves fights and drops as they were', () {
      final arena = arenaGame([
        monster(
          'squire',
          hp: 12,
          attack: 2,
          extra: {
            'drops': [
              {'item': 'copper_sword', 'chance': 0.5},
            ],
          },
        ),
      ]);
      StepReport run(Map<String, int> ranks) {
        var s = arena.newGame(seed: 5)..talents.addAll(ranks);
        s = arena.startActivity(s, const Activity.fight('squire'));
        return arena.applySteps(s, 5000);
      }

      final plain = run({});
      final more = run({'bountiful': 5});
      expect(more.state.inventory, plain.state.inventory);
      expect(more.state.xp, plain.state.xp);
      expect(more.state.rngState, plain.state.rngState);
    });

    test('criterion 30: Wary pays a lost fight 0.95, not 0.75', () {
      final tough = arenaGame([
        monster('brute', hp: 1000, attack: 100, xp: 10000),
      ]);
      int lostXp(Map<String, int> ranks) {
        var s = tough.newGame(seed: 1)..talents.addAll(ranks);
        s = tough.startActivity(s, const Activity.fight('brute'));
        return tough.applySteps(s, 10).events.whereType<FightLost>().single.xp;
      }

      // 5 of 1,000 HP knocked off: 10,000 × 0.005 × the share.
      expect(lostXp({}), 37);
      expect(lostXp({'wary': 2}), 47);
    });

    test('criteria 31-32: Wary warns before an orange fight', () {
      // A level 1 player meets the level 4 Goblin brute: orange.
      final s = stateAt(game);
      expect(game.enemyBand(s, 'goblin_brute').colour, LevelColour.orange);
      expect(game.deadlyWarning(s, 'goblin_brute'), isFalse);
      expect(
        game.deadlyWarning(s..talents['wary'] = 1, 'goblin_brute'),
        isTrue,
      );
      expect(game.deadlyWarning(stateAt(game), 'goblin'), isFalse);
    });

    test('criterion 33: Master crafter boosts craft quality by 1.3', () {
      final s = at(20, {'master_crafter': 3});
      expect(game.qualityBoost(s, QualityRoll.craft), closeTo(1.3, 1e-9));
      expect(game.qualityBoost(s, QualityRoll.drop), 1);
    });

    test('criterion 34: Quartermaster adds a slot, with the Bane too', () {
      final s = at(20);
      final qm = at(20, {'quartermaster': 1});
      expect(game.queueSlots(qm), game.queueSlots(s) + 1);
      expect(
        game.queueSlots(qm..achievements.add('chieftains_bane')),
        game.queueSlots(s) + 2,
      );
    });

    test('criteria 35-37: Light pack and Wayfarer on a 500-step road', () {
      expect(game.travelCost(at(20, {'light_pack': 5}), 500), 400);
      expect(game.travelCost(at(20, {'wayfarer': 1}), 500), 250);
      expect(
        game.travelCost(at(20, {'light_pack': 5, 'wayfarer': 1}), 500),
        200,
      );
    });

    test('a road walked with Wayfarer costs half its steps', () {
      var s = at(20, {'wayfarer': 1});
      s = game.startActivity(s, const Activity.travel('old_graveyard'));
      final r = game.applySteps(s, 250);
      expect(r.state.location, 'old_graveyard');
    });

    test('criterion 38: Lucky hammer boosts a reroll by 1.45', () {
      final s = at(20, {'lucky_hammer': 3});
      expect(game.qualityBoost(s, QualityRoll.reroll), closeTo(1.45, 1e-9));
      // Amendment 2: Master crafter does not multiply in.
      final both = at(20, {'lucky_hammer': 3, 'master_crafter': 3});
      expect(game.qualityBoost(both, QualityRoll.reroll), closeTo(1.45, 1e-9));
    });
  });

  group('reset', () {
    /// A level 20 player in camp with [bank] steps and one rank of Might.
    GameState ready({int bank = 50000}) =>
        at(20, {'might': 1})..stepBank = bank;

    GameState reset(GameState s) => game.resetTalents(s);

    test('criterion 39: the first reset is free and returns every point', () {
      final s = reset(ready());
      expect(s.talents, isEmpty);
      expect(s.stepBank, 50000);
      expect(game.talentPointsLeft(s), game.talentPoints(20));
      expect(s.talentResets, 1);
    });

    test('criterion 40: the second costs 2,000, the third 4,000', () {
      var s = reset(ready());
      s = reset(s..talents['might'] = 1);
      expect(s.stepBank, 48000);
      s = reset(s..talents['might'] = 1);
      expect(s.stepBank, 44000);
    });

    test('criterion 41: the price stops at 10,000', () {
      var s = reset(ready(bank: 200000));
      for (var i = 0; i < 8; i++) {
        s = reset(s..talents['might'] = 1);
      }
      expect(game.resetPriceNow(s), 10000);
    });

    test('criteria 42-43: walking lowers the price, not below 2,000', () {
      var s = reset(ready());
      s = reset(s..talents['might'] = 1); // 2,000; next 4,000
      s = reset(s..talents['might'] = 1); // 4,000; next 6,000
      expect(game.resetPriceNow(s), 6000);
      // Walked steps count, also those that go to the bank.
      s = game.applySteps(s, 35000).state;
      expect(s.walkedSinceReset, 35000);
      expect(game.resetPriceNow(s), 4000);
      s = game.applySteps(s, 35000 * 3).state;
      expect(game.resetPriceNow(s), 2000);
    });

    test('criterion 44: after a fallen price of 2,000, the next is 4,000', () {
      var s = reset(ready());
      s = reset(s..talents['might'] = 1);
      s = reset(s..talents['might'] = 1);
      s = game.applySteps(s, 35000 * 3).state;
      final bank = s.stepBank;
      s = reset(s..talents['might'] = 1);
      expect(s.stepBank, bank - 2000);
      expect(s.walkedSinceReset, 0);
      expect(game.resetPriceNow(s), 4000);
    });

    test('criterion 45: too few steps in the bank: refused, no change', () {
      final s = reset(ready(bank: 1999));
      s.talents['might'] = 1;
      expect(
        () => reset(s),
        throwsA(
          isA<ActivityError>().having(
            (e) => e.message,
            'message',
            'You need 2,000 steps in the bank.',
          ),
        ),
      );
      expect(s.talents, {'might': 1});
      expect(s.stepBank, 1999);
    });

    test('criterion 46: only in Camp', () {
      final s = ready()..location = 'goblin_woods';
      expect(() => reset(s), throwsA(isA<ActivityError>()));
    });

    test('criterion 47: no ranks, no reset', () {
      expect(() => reset(at(20)), throwsA(isA<ActivityError>()));
    });
  });

  group('review of PR 151', () {
    test('a reset never takes banked steps that Deep pockets held', () {
      // A cap of 14,500 + 3,000 with 17,000 banked; a reset drops the cap.
      var s = at(10, {'deep_pockets': 5})..stepBank = 17000;
      expect(game.bankCap(s), 17500);
      s = game.resetTalents(s);
      expect(game.bankCap(s), 14500);
      expect(s.stepBank, 17000);
      // The next action that ends with progress left keeps the bank.
      s = game.startActivity(
        s..location = 'copper_hills',
        const Activity.gather('copper_vein'),
      );
      s = game.applySteps(s, 3).state;
      // The 3 steps drew 3 from the bank as a boost; the stop takes no more.
      final before = s.stepBank;
      expect(before, 16997);
      s = game.stopActivity(s);
      expect(s.stepBank, greaterThanOrEqualTo(before));
    });

    test('planned walks show the steps the travel talents leave', () {
      final s = at(20, {'light_pack': 5, 'wayfarer': 1});
      expect(game.walkSteps(s, 'camp', 'old_graveyard'), 200);
      expect(game.openLocationsByDistance(s)['old_graveyard'], 200);
    });

    test('migrate does not change the state it is given', () {
      final s = GameState.fromJson(
        at(12, {'might': 1, 'gone_talent': 1}).toJson(),
      );
      game.migrate(s);
      expect(s.talents, {'might': 1, 'gone_talent': 1});
    });

    test('an unknown talent id is an ActivityError', () {
      expect(
        () => game.takeRank(at(12), 'gone_talent'),
        throwsA(isA<ActivityError>()),
      );
    });

    test("the trainer's place must be known", () {
      final json = dataJson('talents');
      (json['trainer']! as Map<String, Object?>)['location'] = 'Camp';
      expect(
        () => loadGameData(overrides: {'talents': json}),
        throwsFormatException,
      );
    });

    test('the first paid reset costs the base of the data', () {
      final json = dataJson('talents');
      (json['reset']! as Map<String, Object?>)['base'] = 1000;
      final cheap = Game(loadGameData(overrides: {'talents': json}));
      var s = stateAt(cheap, level: 20)
        ..talents['might'] = 1
        ..stepBank = 50000;
      s = cheap.resetTalents(s);
      expect(cheap.resetPriceNow(s), 1000);
    });

    test('amendment 2: Master crafter does not boost a reroll', () {
      final s = at(20, {'master_crafter': 3});
      expect(game.qualityBoost(s, QualityRoll.reroll), 1);
    });
  });

  group('save', () {
    test('criterion 55: an old save loads with no ranks and its points', () {
      final json = at(12).toJson()
        ..['version'] = 12
        ..remove('talents')
        ..remove('talentResets')
        ..remove('resetPrice')
        ..remove('walkedSinceReset');
      final s = game.migrate(GameState.fromJson(json));
      expect(s.talents, isEmpty);
      expect(s.talentResets, 0);
      // No saved price yet: the first paid reset costs the base.
      expect(game.resetPriceNow(s.copy()..talentResets = 1), 2000);
      expect(s.walkedSinceReset, 0);
      expect(game.talentPointsLeft(s), 3);
    });

    test('criterion 56: ranks, resets and steps survive a round trip', () {
      final s = at(20, {'might': 3, 'deep_pockets': 2})
        ..talentResets = 2
        ..resetPrice = 6000
        ..walkedSinceReset = 1234;
      final back = GameState.fromJson(s.toJson());
      expect(back.talents, {'might': 3, 'deep_pockets': 2});
      expect(back.talentResets, 2);
      expect(back.resetPrice, 6000);
      expect(back.walkedSinceReset, 1234);
    });

    test('criterion 57: a rank of an unknown talent is dropped on load', () {
      final s = at(12, {'might': 1, 'gone_talent': 2});
      final back = game.migrate(GameState.fromJson(s.toJson()));
      expect(back.talents, {'might': 1});
      expect(game.talentPointsLeft(back), 2);
    });
  });

  group('data', () {
    /// `talents.json` changed by [edit].
    void refused(void Function(Map<String, Object?> json) edit) {
      final json = dataJson('talents');
      edit(json);
      expect(
        () => loadGameData(overrides: {'talents': json}),
        throwsFormatException,
      );
    }

    List<Map<String, Object?>> talentsOf(Map<String, Object?> json) =>
        (json['talents']! as List).cast<Map<String, Object?>>();

    test('criterion 59: an unknown effect is refused', () {
      refused((j) => talentsOf(j).first['effect'] = 'flying');
    });

    test('criterion 60: a tree under 28 points is refused', () {
      refused(
        (j) => talentsOf(j).removeWhere((t) => t['id'] == 'swift_strikes'),
      );
    });

    test('criterion 61: a talent that needs another tree is refused', () {
      refused(
        (j) => talentsOf(j).firstWhere((t) => t['id'] == 'impale')['needs'] =
            'light_pack',
      );
    });

    test('a talent that needs one of a lower row is fine; the real data', () {
      expect(loadGameData().talents, hasLength(19));
      expect(data.talents['impale']!.needs, 'keen_eye');
      expect(data.talents['lucky_hammer']!.needs, 'master_crafter');
      expect(data.talents['wayfarer']!.needs, 'light_pack');
    });

    /// Sets the column of talent [id] in [json].
    void column(Map<String, Object?> json, String id, int column) =>
        talentsOf(json).firstWhere((t) => t['id'] == id)['column'] = column;

    test('criterion 98: each talent has a column from 1 to 3', () {
      for (final t in data.talents.values) {
        expect(t.column, inInclusiveRange(1, 3), reason: t.id);
      }
      // The places of amendment 3, change 7.
      final places = {
        for (final t in data.talents.values) t.id: (t.row, t.column),
      };
      expect(places, {
        'might': (1, 1),
        'toughness': (1, 3),
        'guard': (2, 1),
        'keen_eye': (2, 3),
        'swift_strikes': (3, 2),
        'precision': (4, 1),
        'evasion': (4, 2),
        'treasure_hunter': (5, 2),
        'impale': (6, 3),
        'deep_pockets': (1, 1),
        'nimble_hands': (1, 3),
        'practised_hands': (2, 1),
        'bountiful': (2, 2),
        'wary': (2, 3),
        'master_crafter': (3, 1),
        'quartermaster': (3, 3),
        'light_pack': (4, 3),
        'lucky_hammer': (5, 1),
        'wayfarer': (6, 3),
      });
    });

    test('criterion 99: a talent in column 4 is refused', () {
      refused((j) => column(j, 'might', 4));
    });

    test('a talent with no column is refused', () {
      refused(
        (j) =>
            talentsOf(j).firstWhere((t) => t['id'] == 'might').remove('column'),
      );
    });

    test('criterion 100: two talents at one place are refused', () {
      refused((j) => column(j, 'toughness', 1));
    });

    test('criterion 101: a needed talent in another column is refused', () {
      refused((j) => column(j, 'impale', 1));
    });

    test('criterion 102: a talent on the line between two is refused', () {
      // Precision in row 4 of column 3, between Keen eye and Impale.
      refused((j) => column(j, 'precision', 3));
    });
  });
}
