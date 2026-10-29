// Pacing, played by the scripted sensible player in lib/simulation.dart:
// spec 0001 acceptance criterion 5 and spec 0002 criterion 3 (which replaces
// spec 0001 criterion 6), as spec 0009 criterion 16 sets them: seeds 1-8,
// level 5 on day 1-2; level 30 as spec 0009 amendment 1 sets it. Spec 0010
// Â§9.3: the walker's professions (target 2), the fighter (target 3) and the
// gatherer (target 4), seed 1 here; all seeds in tool/seeds.dart. Spec 0011
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
  int days = 100,
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
  late SimulationResult fighter;
  late SimulationResult gatherer;

  setUpAll(() async {
    final runs = await Future.wait([
      for (final seed in _seeds) _run(seed: seed),
      for (final seed in _seeds) _run(seed: seed, noBonuses: true),
      for (final seed in _seeds)
        _run(seed: seed, noBonuses: true, meals: false),
      _run(days: 120, walker: Walker.fighter),
      _run(days: 90, walker: Walker.gatherer),
    ]);
    for (final (i, seed) in _seeds.indexed) {
      walker[seed] = runs[i];
      withMeals[seed] = runs[_seeds.length + i];
      noMeals[seed] = runs[2 * _seeds.length + i];
    }
    fighter = runs[3 * _seeds.length];
    gatherer = runs[3 * _seeds.length + 1];
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

      // A lucky walker may be up to 10 days sooner (spec 0009 amendment 1).
      test('spec 0009 amendment 1: level 30 on day 70-100', () {
        expect(result().dayReached(30), inInclusiveRange(70, 100));
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

  // Days 16, 50 and 84: seed 1 before spec 0017. The run of seed 1 above is
  // this run: the same seed, walker and meals.
  test('spec 0017 criterion 31: without feats, seed 1 reaches levels 10, 20 '
      'and 30 within 5% of days 16, 50 and 84', () {
    final seed1 = walker[1]!;
    for (final (level, day) in [(10, 16), (20, 50), (30, 84)]) {
      expect(
        seed1.dayReached(level),
        inInclusiveRange(day * .95, day * 1.05),
        reason: 'level $level',
      );
    }
  });

  test('spec 0009 amendment 1: the median seed reaches level 30 on day '
      '80-100', () {
    expect(median(level30(walker)), inInclusiveRange(80, 100));
  });

  test('spec 0011 Â§9.3 target 5: with meals the median level 30 day is no '
      'later than without, and at most 5 days sooner', () {
    final gain = median(level30(noMeals)) - median(level30(withMeals));
    expect(gain, inInclusiveRange(0, 5));
  });

  // The walkers start Mining at 5 as Miner's children (spec 0012 amendment
  // 1), so it may reach 10 from day 5.
  test('spec 0010 amendment 1: Mining and Crafting 10 by day 8-22 (Mining '
      '5-22), 20 by day 45-65 (medians)', () {
    for (final p in ['mining', 'crafting']) {
      for (final l in [10, 20]) {
        final range = l == 10 ? (p == 'mining' ? 5 : 8, 22) : (45, 65);
        expect(
          median(walker.values.map((r) => r.professionDay(p, l))),
          inInclusiveRange(range.$1, range.$2),
          reason: '$p $l',
        );
      }
    }
  });

  test('spec 0010 Â§9.3 target 3: the fighter is at least 15% later to level '
      '30 (seed 1)', () {
    final day = fighter.dayReached(30);
    if (day != null) {
      expect(day, greaterThanOrEqualTo(median(level30(walker)) * 1.15));
    }
  });

  test('spec 0010 amendment 1, target 4: the gatherer-crafter is level 6-10 '
      'on day 90 (seed 1)', () {
    expect(gatherer.days.last.level, inInclusiveRange(6, 10));
  });
}
