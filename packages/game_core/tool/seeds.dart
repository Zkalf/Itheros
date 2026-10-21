// Pacing over seeds (plan 0011, plan 0012): the simulated walker at 5,000
// steps a day on seeds 1-8, with the day it reaches levels 5, 10, 20 and 30
// (spec 0009 criterion 16 and amendment 1: 1-2, 12-16, -, 70-100), the day
// its Mining and Crafting reach 10 and 20 and their levels on day 90 (spec
// 0010 §9.3 target 2); then the fighter's level 30 day (target 3) and the
// gatherer-crafter's level on day 90 (target 4). Medians last.
//
//   dart run tool/seeds.dart [--seeds 8] [--steps-per-day 5000] [--mixed-only]
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
  const levels = [5, 10, 20, 30];
  const professions = [('mining', 'Mi'), ('crafting', 'Cr')];
  final heads = [
    for (final l in levels) 'L$l',
    for (final (_, short) in professions) ...['$short 10', '$short 20'],
    for (final (_, short) in professions) '$short@90',
  ];

  final mixedOnly = args.contains('--mixed-only');
  if (!mixedOnly) heads.addAll(['fighter L30', 'gatherer L@90']);
  final columns = [for (final _ in heads) <int?>[]];

  stdout.writeln('| seed | ${heads.join(' | ')} |');
  stdout.writeln('|---|${heads.map((_) => '---').join('|')}|');
  for (var seed = 1; seed <= opt('seeds', 8); seed++) {
    final r = simulate(
      game,
      stepsPerDay: opt('steps-per-day', 5000),
      days: 120,
      seed: seed,
    );
    final day90 = r.days.where((d) => d.day == 90).firstOrNull;
    final values = <int?>[
      for (final l in levels) r.dayReached(l),
      for (final (p, _) in professions)
        for (final l in [10, 20]) r.professionDay(p, l),
      for (final (p, _) in professions) day90?.professions[p],
    ];
    if (!mixedOnly) {
      SimulationResult run(Walker w) => simulate(
        game,
        stepsPerDay: opt('steps-per-day', 5000),
        days: 120,
        seed: seed,
        walker: w,
      );
      values
        ..add(run(Walker.fighter).dayReached(30))
        ..add(run(Walker.gatherer).days.where((d) => d.day == 90).first.level);
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
