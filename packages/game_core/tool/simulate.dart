// Pacing simulator CLI (plan 0001, M3).
//
//   dart run tool/simulate.dart [--steps-per-day 5000] [--days 14]
//                               [--seed 1] [--check-every 100]
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:game_core/simulation.dart';

void main(List<String> args) {
  int opt(String name, int fallback) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? int.parse(args[i + 1]) : fallback;
  }

  final stepsPerDay = opt('steps-per-day', 5000);
  final days = opt('days', 14);
  final files = {
    for (final f in Directory('data').listSync().whereType<File>())
      if (f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
  };
  final game = Game(GameData.fromJsonStrings(files));

  final result = simulate(
    game,
    stepsPerDay: stepsPerDay,
    days: days,
    seed: opt('seed', 1),
    checkEvery: opt('check-every', 100),
  );

  stdout.writeln('Steps per day: $stepsPerDay');
  stdout.writeln('Walked steps to level 2: ${result.walkedToLevel2}');
  stdout.writeln('day  level     xp   bank  gear');
  for (final d in result.days) {
    stdout.writeln(
      '${d.day.toString().padLeft(3)}  ${d.level.toString().padLeft(5)}  '
      '${d.xp.toString().padLeft(5)}  ${d.bank.toString().padLeft(5)}  '
      '${d.equipment.values.join(', ')}',
    );
  }
  final c = result.finalState.counters;
  stdout.writeln(
    'Totals: ${c['kills.goblin'] ?? 0} goblins, '
    '${c['kills.goblin_brute'] ?? 0} brutes, '
    '${c['gathered.copper_ore'] ?? 0} ore, ${c['crafted.total'] ?? 0} crafted',
  );
}
