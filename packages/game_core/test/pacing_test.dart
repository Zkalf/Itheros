// Pacing, played by the scripted sensible player in lib/simulation.dart:
// spec 0001 acceptance criterion 5 and spec 0002 criterion 3 (which replaces
// spec 0001 criterion 6), as spec 0009 criterion 16 sets them: seeds 1-8,
// level 5 on day 1-2; level 30 as spec 0009 amendment 1 sets it. Spec 0010
// Â§9.3: the walker's professions (target 2) and the fighter (target 3);
// target 4, the gatherer, is dropped (spec 0002 amendment 3, erratum 1). Spec 0011
// Â§9.3 target 5: meals help, they aren't a must. Spec 0017 Â§8 (criteria 31
// and 32): the pace of the walker without feats, and the milestones on the
// way.
//
// The tag `pacing` lets check.ps1 leave this file out when a change does not
// touch packages/; release.ps1 always runs it. Each sim runs in its own
// isolate, so the 26 runs share the cores; the slowest machine (CI, 4 cores)
// needs more than the 30 s of a normal test.
@Tags(['pacing'])
@Timeout(Duration(minutes: 10))
library;

import 'dart:isolate';

import 'package:game_core/game_core.dart';
import 'package:game_core/simulation.dart';
import 'package:test/test.dart';

import 'support.dart';

/// The real data. Meals are compared without the bonuses of feats ([noBonuses]):
/// Legendary Find is luck, and its bonus lands on other days with and without
/// meals (spec 0017 amendment 3).
Game _game({bool noBonuses = false}) {
  if (!noBonuses) return newTestGame();
  final game = newTestGame();
  return newTestGame(
    overrides: {
      'achievements': {
        'achievements': [
          for (final a in dataJson('achievements')['achievements']! as List)
            {
              ...a as Map<String, Object?>,
              if (game.data.achievements[a['id']]!.reward is BonusReward)
                'reward': {'bankCap': 0},
            },
        ],
      },
    },
  );
}

/// One run of 5,000 steps a day, in an isolate of its own.
Future<SimulationResult> _run({
  int seed = 1,
  int days = 105,
  Walker walker = Walker.mixed,
  bool meals = true,
  bool noBonuses = false,
}) => Isolate.run(
  () => simulate(
    _game(noBonuses: noBonuses),
    stepsPerDay: 5000,
    days: days,
    seed: seed,
    walker: walker,
    meals: meals,
  ),
);

const _seeds = [1, 2, 3, 4, 5, 6, 7, 8];

void main() {
  final game = newTestGame();
  final walker = <int, SimulationResult>{};
  final withMeals = <int, SimulationResult>{};
  final noMeals = <int, SimulationResult>{};
  final fighter = <int, SimulationResult>{};

  setUpAll(() async {
    final runs = await Future.wait([
      for (final seed in _seeds) _run(seed: seed),
      for (final seed in _seeds) _run(seed: seed, noBonuses: true),
      for (final seed in _seeds)
        _run(seed: seed, noBonuses: true, meals: false),
      for (final seed in _seeds)
        _run(seed: seed, days: 120, walker: Walker.fighter),
    ]);
    for (final (i, seed) in _seeds.indexed) {
      walker[seed] = runs[i];
      withMeals[seed] = runs[_seeds.length + i];
      noMeals[seed] = runs[2 * _seeds.length + i];
    }
    for (final (i, seed) in _seeds.indexed) {
      fighter[seed] = runs[3 * _seeds.length + i];
    }
  });

  for (final seed in _seeds) {
    group('seed $seed', () {
      SimulationResult result() => walker[seed]!;

      test('spec 0001 criterion 5: level 2 within 350 walked steps', () {
        expect(result().walkedToLevel2, isNotNull);
        expect(result().walkedToLevel2, lessThanOrEqualTo(350));
      });

      // Spec 0009 decision 1: crafting all three copper weapons moves it
      // from day 1.
      test('spec 0009 criterion 16: level 5 on day 1-2 at 5,000 steps/day', () {
        expect(result().dayReached(5), inInclusiveRange(1, 2));
      });

      // Early luck may be a day faster (spec 0010 amendment 1).
      test('spec 0010 amendment 1: level 10 on day 11-16', () {
        expect(result().dayReached(10), inInclusiveRange(11, 16));
      });

      // Smuggler's Secret needs the bottle, and the walker may skip the
      // Graveyard King: both are luck or a choice (spec 0017 amendment 3).
      test(
        'spec 0017 criterion 32: each milestone by the end of its stage',
        () {
          final end = {
            AchievementStage.early: result().dayReached(10)!,
            AchievementStage.mid: result().dayReached(20)!,
            AchievementStage.late: result().dayReached(30)!,
          };
          for (final a in game.data.achievements.values) {
            if (a.kind != AchievementKind.milestone) continue;
            if (a.id == 'smugglers_secret' || a.id == 'kings_bane') continue;
            final day = result().days
                .where((d) => d.achievements.contains(a.id))
                .firstOrNull
                ?.day;
            expect(day, isNotNull, reason: a.id);
            expect(day, lessThanOrEqualTo(end[a.stage]!), reason: a.id);
          }
        },
      );

      // The road across the river opens only on a King kill, so a walker
      // that stood in Grey Moor beat him first (spec 0008 amendment 5).
      test('spec 0008 amendment 5 criterion 25: the walker and the fighter '
          'beat the King and cross the river', () {
        for (final r in [result(), fighter[seed]!]) {
          final s = r.finalState;
          expect(s.counters['kills.graveyard_king'], greaterThan(0));
          expect(s.explored, contains('grey_moor'));
        }
      });

      // A lucky walker may be up to 10 days sooner (spec 0009 amendment 1),
      // an unlucky one 5 days later than the median's end (amendment 3).
      test('spec 0009 amendments 1, 3: level 30 on day 70-105', () {
        expect(result().dayReached(30), inInclusiveRange(70, 105));
      });
    });
  }

  double median(Iterable<int?> days) {
    expect(days, everyElement(isNotNull));
    final sorted = days.cast<int>().toList()..sort();
    return (sorted[3] + sorted[4]) / 2;
  }

  Iterable<int?> level30(Map<int, SimulationResult> runs) =>
      runs.values.map((r) => r.dayReached(30));

  test('spec 0009 amendment 1: the median seed reaches level 30 on day '
      '80-100', () {
    expect(median(level30(walker)), inInclusiveRange(80, 100));
  });

  // Meals help a little: longer meals, and Attack and HP meals give fight
  // steps back. A hand-run sim on 16 seeds gave a mean gain of about 3 days;
  // 8 seeds swing by several (spec 0011 amendment 2, rule 10).
  test('spec 0011 target 5 (amendment 2): with meals the median level 30 '
      'day is 0 to 10 days sooner', () {
    // A seed that misses the 105 days counts as day 106, as the fighter's
    // count as day 121 (owner, 2026-11-09, plan 0056: with stacks a
    // no-meals seed lands on day 105).
    Iterable<int> by106(Map<int, SimulationResult> runs) =>
        level30(runs).map((d) => d ?? 106);
    final gain = median(by106(noMeals)) - median(by106(withMeals));
    expect(gain, inInclusiveRange(0, 10));
  });

  // The walkers start Mining at 5 as Miner's children (spec 0012 amendment
  // 1), so it may reach 10 from day 5. The supply chest's Crafting materials
  // move Crafting 10 to day 6 and Crafting 20 to day 40 at the soonest
  // (spec 0013 amendments 1 and 2).
  test('spec 0010 amendment 1: Mining and Crafting 10 by day 6-22 (Mining '
      '5-22), 20 by day 40-65 (Mining 45-65) (medians)', () {
    for (final p in ['mining', 'crafting']) {
      for (final l in [10, 20]) {
        final range = l == 10
            ? (p == 'mining' ? 5 : 6, 22)
            : (p == 'mining' ? 45 : 40, 65);
        expect(
          median(walker.values.map((r) => r.professionDay(p, l))),
          inInclusiveRange(range.$1, range.$2),
          reason: '$p $l',
        );
      }
    }
  });

  // A pure fighter lives on monster drops, so with the tougher monsters it
  // is slower than the mixed walker (spec 0002 amendment 3, target 2).
  test('spec 0002 amendment 3, target 2: the fighter reaches level 30 on '
      'day 80-120 (median of 8 seeds)', () {
    final days = fighter.values.map((r) => r.dayReached(30) ?? 121);
    expect(median(days), inInclusiveRange(80, 120));
  });

  group('spec 0002 amendment 3: the mixed walker fights (seeds 1-8)', () {
    List<SimFight> all() => [for (final r in walker.values) ...r.fights];

    double mid(List<num> xs) {
      final s = [...xs]..sort();
      final m = s.length ~/ 2;
      return s.length.isOdd ? s[m].toDouble() : (s[m - 1] + s[m]) / 2;
    }

    test('target 3: a fight takes a median 6-12 rounds', () {
      expect(mid([for (final f in all()) f.rounds]), inInclusiveRange(6, 12));
    });

    test('target 4: a fight takes a median 10-25% of its HP', () {
      expect(
        mid([for (final f in all()) f.taken]),
        inInclusiveRange(0.10, 0.25),
      );
    });

    test('target 5: 3-12% of fights take more than half its HP', () {
      final fights = all();
      final hard = fights.where((f) => f.taken > 0.5).length;
      expect(hard / fights.length, inInclusiveRange(0.03, 0.12));
    });

    test('target 6: the Graveyard King takes a median 25-40 rounds', () {
      final king = [
        for (final f in all())
          if (f.enemy == 'graveyard_king') f.rounds,
      ];
      expect(king, isNotEmpty);
      expect(mid(king), inInclusiveRange(25, 40));
    });
  });
}
