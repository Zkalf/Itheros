// The talent builds of spec 0015 §5 (plan 0031 M1).
//
//   dart run tool/talents.dart [--build none|combat|utility|split]
//                              [--days 120] [--steps-per-day 5000]
//                              [--seeds 1] [--xp-day 50]
//
// Prints the days to level 25, the level on the last day and the Rare-or-
// better monster drops. Without --build it runs all four, one after the
// other; run them in parallel with one --build each.
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:game_core/simulation.dart';

/// The walker's talent order per build: each point goes to the first
/// talent in the list that can take it (spec 0015 §5).
const builds = {
  'none': <String>[],
  'combat': [
    'might',
    'toughness',
    'guard',
    'keen_eye',
    'swift_strikes',
    'precision',
    'evasion',
    'treasure_hunter',
    'impale',
  ],
  'utility': [
    'deep_pockets',
    'nimble_hands',
    'bountiful',
    'wary',
    'master_crafter',
    'quartermaster',
    'light_pack',
    'lucky_hammer',
    'wayfarer',
  ],
  'split': [
    'might',
    'toughness',
    'deep_pockets',
    'nimble_hands',
    'quartermaster',
    'guard',
    'keen_eye',
    'swift_strikes',
    'precision',
    'evasion',
    'treasure_hunter',
    'impale',
  ],
};

void main(List<String> args) {
  String? opt(String name) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final days = int.parse(opt('days') ?? '120');
  final stepsPerDay = int.parse(opt('steps-per-day') ?? '5000');
  final only = opt('build');
  final files = {
    for (final f in Directory('data').listSync().whereType<File>())
      if (f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
  };
  final game = Game(GameData.fromJsonStrings(files));

  final seeds = int.parse(opt('seeds') ?? '1');
  final at = int.parse(opt('xp-day') ?? '50');
  stdout.writeln(
    'build    day L25  day L30  level  rare+ drops  xp day $at   '
    '(mean of $seeds seeds)',
  );
  for (final MapEntry(key: name, value: order) in builds.entries) {
    if (only != null && only != name) continue;
    var day25 = 0.0, day30 = 0.0, level = 0.0, rare = 0.0, xp = 0.0;
    for (var seed = 1; seed <= seeds; seed++) {
      final r = simulate(
        game,
        stepsPerDay: stepsPerDay,
        days: days,
        seed: seed,
        talentOrder: order,
      );
      day25 += (r.dayReached(25) ?? days + 1) / seeds;
      day30 += (r.dayReached(30) ?? days + 1) / seeds;
      level += r.days.last.level / seeds;
      rare += r.rareDrops / seeds;
      xp += r.days[at - 1].xp / seeds;
    }
    String f(double v) => v.toStringAsFixed(1);
    stdout.writeln(
      '${name.padRight(8)} ${f(day25).padLeft(7)}  ${f(day30).padLeft(7)}  '
      '${f(level).padLeft(5)}  '
      '${f(rare).padLeft(11)}  ${xp.round().toString().padLeft(9)}',
    );
  }
}
