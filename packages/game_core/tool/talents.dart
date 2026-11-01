// The talent builds of spec 0015 §5 as amendment 1 has it (plan 0031 M1).
//
//   dart run tool/talents.dart [--seeds 12] [--data <folder>]
//
// Part A: a new character plays 120 days with each build. Part B: the
// no-talent walker of part A on day 120 takes each build and plays 60 more
// days. Prints the means over the seeds and checks the targets.
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:game_core/simulation.dart';

/// The walker's talent order per build: each point goes to the first
/// talent in the list that can take it (spec 0015 §5). Combat and Utility
/// go row by row, in data order within a row.
Map<String, List<String>> buildsOf(GameData data) {
  List<String> tree(String id) =>
      (data.talents.values.where((t) => t.tree == id).toList()
            ..sort((a, b) => a.row.compareTo(b.row)))
          .map((t) => t.id)
          .toList();
  final combat = tree('combat');
  final split = [
    'might',
    'toughness',
    'deep_pockets',
    'nimble_hands',
    'quartermaster',
    ...combat.where((t) => t != 'might' && t != 'toughness'),
  ];
  return {
    'none': const [],
    'combat': combat,
    'utility': tree('utility'),
    'split': split,
  };
}

void main(List<String> args) {
  String? opt(String name) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final seeds = int.parse(opt('seeds') ?? '12');
  // Another data folder, for a tuning try.
  final dir = opt('data') ?? 'data';
  final files = {
    for (final f in Directory(dir).listSync().whereType<File>())
      if (f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
  };
  final game = Game(GameData.fromJsonStrings(files));
  final builds = buildsOf(game.data);
  double mean(Iterable<num> v) => v.fold(0.0, (a, b) => a + b) / v.length;
  String pct(double a, double b) =>
      '${a >= b ? '+' : ''}${((a / b - 1) * 100).toStringAsFixed(1)}%';

  // Part A.
  final a = <String, List<SimulationResult>>{
    for (final MapEntry(key: name, value: order) in builds.entries)
      name: [
        for (var seed = 1; seed <= seeds; seed++)
          simulate(
            game,
            stepsPerDay: 5000,
            days: 120,
            seed: seed,
            talentOrder: order,
          ),
      ],
  };
  double xp50(String b) => mean(a[b]!.map((r) => r.days[49].xp));
  double prof60(String b) => mean(
    a[b]!.map((r) => r.days[59].professions.values.fold(0, (x, y) => x + y)),
  );
  stdout.writeln('Part A: a new character, 120 days, mean of $seeds seeds');
  stdout.writeln('build    xp day 50   vs none  professions day 60  rare+');
  for (final b in builds.keys) {
    stdout.writeln(
      '${b.padRight(8)} ${xp50(b).round().toString().padLeft(9)}  '
      '${pct(xp50(b), xp50('none')).padLeft(7)}  '
      '${prof60(b).toStringAsFixed(1).padLeft(18)}  '
      '${mean(a[b]!.map((r) => r.rareDrops)).toStringAsFixed(1).padLeft(5)}',
    );
  }

  // Part B.
  final gained = <String, double>{};
  final rare = <String, double>{};
  for (final MapEntry(key: name, value: order) in builds.entries) {
    final xp = <int>[], drops = <int>[];
    for (final start in a['none']!) {
      final player = SensiblePlayer(game, talentOrder: order);
      var s = start.finalState.copy();
      final before = s.xp;
      for (var step = 0; step < 60 * 5000; step += 100) {
        s = player.decide(s);
        final r = game.applySteps(s, 100);
        player.observe(r);
        s = r.state;
      }
      xp.add(s.xp - before);
      drops.add(player.rareDrops);
    }
    gained[name] = mean(xp);
    rare[name] = mean(drops);
  }
  stdout.writeln();
  stdout.writeln('Part B: full builds from day 120, 60 more days');
  stdout.writeln('build    xp gained   vs none  vs utility  rare+');
  for (final b in builds.keys) {
    stdout.writeln(
      '${b.padRight(8)} ${gained[b]!.round().toString().padLeft(9)}  '
      '${pct(gained[b]!, gained['none']!).padLeft(7)}  '
      '${pct(gained[b]!, gained['utility']!).padLeft(10)}  '
      '${rare[b]!.toStringAsFixed(1).padLeft(5)}',
    );
  }

  // The targets of amendment 1, change 4.
  final gap = gained['combat']! / gained['utility']! - 1;
  final checks = {
    '1. B: Combat +10-15% XP over Utility': gap >= 0.10 && gap <= 0.15,
    '2. B: Combat rare+ >= Utility': rare['combat']! >= rare['utility']!,
    '3. B: no build 2% under none': builds.keys.every(
      (b) => gained[b]! >= gained['none']! * 0.98,
    ),
    '4. A: Combat XP day 50 > Utility': xp50('combat') > xp50('utility'),
    '5. A: no build 2% under none on day 50': builds.keys.every(
      (b) => xp50(b) >= xp50('none') * 0.98,
    ),
    '6. A: Utility professions day 60 > none':
        prof60('utility') > prof60('none'),
  };
  stdout.writeln();
  for (final MapEntry(:key, :value) in checks.entries) {
    stdout.writeln('${value ? 'met    ' : 'NOT MET'}  $key');
  }
}
