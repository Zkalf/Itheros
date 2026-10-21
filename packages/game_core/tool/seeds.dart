// Pacing over seeds (plan 0011): the simulated walker at 5,000 steps a day on
// seeds 1-8, with the day it reaches levels 5, 10, 20 and 30 (spec 0009
// criterion 16: 1-2, 12-16, -, 80-100).
//
//   dart run tool/seeds.dart [--seeds 8] [--steps-per-day 5000]
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

  stdout.writeln('| seed | ${levels.map((l) => 'L$l').join(' | ')} |');
  stdout.writeln('|---|${levels.map((_) => '---').join('|')}|');
  for (var seed = 1; seed <= opt('seeds', 8); seed++) {
    final r = simulate(
      game,
      stepsPerDay: opt('steps-per-day', 5000),
      days: 120,
      seed: seed,
    );
    final days = [for (final l in levels) r.dayReached(l)?.toString() ?? '-'];
    stdout.writeln('| $seed | ${days.join(' | ')} |');
  }
}
