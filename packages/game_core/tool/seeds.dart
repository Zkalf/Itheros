// Pacing over seeds (plans 0011-0013): the simulated walker at 5,000 steps
// a day on seeds 1-8, with the day it reaches levels 5, 10, 20 and 30 (spec
// 0010 amendment 1: 1-2, 11-16, -, 70-100), the day its Mining and Crafting
// reach 10 and 20 (target 2), its level 30 day with meals off (spec 0011
// target 5), its Fishing, Hunting and Cooking on days 30, 60 and 90
// (target 6); then the fighter's level 30 day (target 3) and the
// gatherer-crafter's level on day 90 (target 4). Medians last.
//
//   dart run tool/seeds.dart [--seeds 8] [--steps-per-day 5000] [--batch 10]
//                            [--meals-from 10] [--mixed-only]
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:game_core/simulation.dart';

void main(List<String> args) {
  int opt(String name, int fallback) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? int.parse(args[i + 1]) : fallback;
  }

  final files = {
    for (final f in Directory('data').listSync().whereType<File>())
      if (f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
  };
  final game = Game(GameData.fromJsonStrings(files));
  final steps = opt('steps-per-day', 5000);
  final batch = opt('batch', 10);
  final from = opt('meals-from', 10);
  const levels = [5, 10, 20, 30];
  const professions = [('mining', 'Mi'), ('crafting', 'Cr')];
  const lake = [('fishing', 'Fi'), ('hunting', 'Hu'), ('cooking', 'Co')];
  const lakeDays = [30, 60, 90];
  final heads = [
    for (final l in levels) 'L$l',
    for (final (_, short) in professions) ...['$short 10', '$short 20'],
    'L30 no meals',
    for (final (_, short) in lake)
      for (final d in lakeDays) '$short@$d',
  ];

  final mixedOnly = args.contains('--mixed-only');
  if (!mixedOnly) heads.addAll(['fighter L30', 'gatherer L@90']);
  final columns = [for (final _ in heads) <int?>[]];

  SimulationResult run(
    int seed, {
    Walker w = Walker.mixed,
    bool meals = true,
  }) => simulate(
    game,
    stepsPerDay: steps,
    days: 120,
    seed: seed,
    walker: w,
    meals: meals,
    mealBatch: batch,
    mealsFrom: from,
  );

  stdout.writeln('| seed | ${heads.join(' | ')} |');
  stdout.writeln('|---|${heads.map((_) => '---').join('|')}|');
  for (var seed = 1; seed <= opt('seeds', 8); seed++) {
    final r = run(seed);
    int? on(int day, String p) =>
        r.days.where((d) => d.day == day).firstOrNull?.professions[p];
    final values = <int?>[
      for (final l in levels) r.dayReached(l),
      for (final (p, _) in professions)
        for (final l in [10, 20]) r.professionDay(p, l),
      run(seed, meals: false).dayReached(30),
      for (final (p, _) in lake)
        for (final d in lakeDays) on(d, p),
    ];
    if (!mixedOnly) {
      values
        ..add(run(seed, w: Walker.fighter).dayReached(30))
        ..add(
          run(
            seed,
            w: Walker.gatherer,
          ).days.where((d) => d.day == 90).first.level,
        );
    }
    for (var i = 0; i < values.length; i++) {
      columns[i].add(values[i]);
    }
    final days = [for (final v in values) v?.toString() ?? '-'];
    stdout.writeln('| $seed | ${days.join(' | ')} |');
  }
  String median(List<int?> v) {
    if (v.any((x) => x == null)) return '-';
    final sorted = v.cast<int>()..sort();
    final n = sorted.length;
    return '${(sorted[(n - 1) ~/ 2] + sorted[n ~/ 2]) / 2}';
  }

  stdout.writeln('| median | ${columns.map(median).join(' | ')} |');
}
