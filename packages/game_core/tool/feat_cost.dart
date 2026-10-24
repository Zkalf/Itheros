// The cost of each feat in days (plan 0021 M2, spec 0017 §3.3).
//
//   dart run tool/feat_cost.dart [--steps-per-day 5000] [--seed 1]
//                                [--only goblin_slayer_1,wolf_pack]
//
// The walker without feats sets the days to levels 10, 20 and 30. For each
// feat, a walker grinds it from the last level of its stage, then plays on.
// The cost of a feat is its days of grind: from the start of the grind to
// the feat. The days it adds to level 30 also show, but they are noisy: a
// grind shifts the gear that the walker makes later.
// The counts in achievements.json change until each cost fits §3.3.
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:game_core/simulation.dart';

void main(List<String> args) {
  String? opt(String name) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final stepsPerDay = int.parse(opt('steps-per-day') ?? '5000');
  final seed = int.parse(opt('seed') ?? '1');
  final only = opt('only')?.split(',').toSet();
  final files = {
    for (final f in Directory('data').listSync().whereType<File>())
      if (f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
  };
  final game = Game(GameData.fromJsonStrings(files));

  int? dayOf(SimulationResult r, bool Function(DayResult) test) {
    for (final d in r.days) {
      if (test(d)) return d.day;
    }
    return null;
  }

  int? levelDay(SimulationResult r, int level) =>
      dayOf(r, (d) => d.level >= level);

  const days = 200;
  final base = simulate(game, stepsPerDay: stepsPerDay, days: days, seed: seed);
  final l10 = levelDay(base, 10);
  final l20 = levelDay(base, 20);
  final l30 = levelDay(base, 30)!;
  stdout.writeln('Steps per day: $stepsPerDay, seed $seed');
  stdout.writeln(
    'Without feats: level 10 on day $l10, 20 on day $l20, '
    '30 on day $l30',
  );
  stdout.writeln(
    'Feats earned without a grind: '
    '${[for (final a in game.data.achievements.values)
      if (a.kind == AchievementKind.feat && base.days[l30 - 1].achievements.contains(a.id)) a.id].join(', ')}',
  );
  stdout.writeln(
    'feat | stage | count | grind from day | earned on day | '
    'grind days | days later to level 30',
  );
  for (final a in game.data.achievements.values) {
    if (a.kind != AchievementKind.feat) continue;
    if (only != null && !only.contains(a.id)) continue;
    final r = simulate(
      game,
      stepsPerDay: stepsPerDay,
      days: days,
      seed: seed,
      feat: a.id,
    );
    final from = levelDay(r, SensiblePlayer.featFrom[a.stage]!);
    final earned = dayOf(r, (d) => d.achievements.contains(a.id));
    final r30 = levelDay(r, 30);
    final cost = earned != null && from != null ? '${earned - from}' : '-';
    final later = r30 != null ? '${r30 - l30}' : '-';
    final count = switch (a.criterion) {
      CounterCriterion(:final atLeast) => '$atLeast',
      _ => '-',
    };
    stdout.writeln(
      '${a.id} | ${a.stage.name} | $count | ${from ?? '-'} | '
      '${earned ?? 'not in $days days'} | $cost | $later',
    );
  }
}
