// Roster tuning report (plan 0003 M3): for each monster, an even-level
// player with that stretch's gear fights it 200 times. Prints win rate,
// rounds, XP per step against spec 0002's target, and the step up from the
// previous normal monster; then the boss gear checks (amendment 1) and the
// two-hander / shield targets (spec 0009 §4.2). The player wields the
// one-hander of the strong type with a shield (spec 0009 §9.1). Last, the
// `fightXpPerStep` list for `economy.json` (spec 0010 §2.4): the measured
// XP per step of every monster but the lurkers, by level, between them on a log
// scale and beyond them at the end slopes.
//
//   dart run tool/tune.dart
import 'dart:io';
import 'dart:math' as math;

import 'package:game_core/game_core.dart';
import 'package:game_core/simulation.dart';

void main() {
  final files = {
    for (final f in Directory('data').listSync().whereType<File>())
      if (f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
  };
  final game = Game(GameData.fromJsonStrings(files));
  final bossIds = {for (final b in bosses(game.data)) b.id};
  final enemies = game.data.enemies.values.toList()
    ..sort((a, b) => a.level.compareTo(b.level));

  double target(int level) => 0.2 * math.pow(1.1, level - 1);
  String pct(double v) => '${(v * 100).round()}%'.padLeft(5);

  stdout.writeln(
    'monster            lvl   win  rounds  xp/step  target  step-up',
  );
  double? previous;
  final measured = <int, double>{};
  for (final e in enemies) {
    final player = referencePlayer(
      game,
      e.level,
      without: bossOnlyItems(game, e.id),
      vs: e.id,
    );
    final r = measureFights(game, player, e.id);
    final normal = !bossIds.contains(e.id) && !e.lurker;
    final up = previous == null || !normal
        ? ''
        : pct(r.xpPerStep / previous - 1);
    if (normal) previous = r.xpPerStep;
    if (!e.lurker) measured[e.level] = r.xpPerStep;
    stdout.writeln(
      '${e.name.padRight(18)} ${e.level.toString().padLeft(3)} '
      '${pct(r.winRate)} ${r.roundsPerFight.toStringAsFixed(1).padLeft(7)} '
      '${r.xpPerStep.toStringAsFixed(3).padLeft(8)} '
      '${target(e.level).toStringAsFixed(3).padLeft(7)}  $up',
    );
  }

  stdout.writeln(
    '\nboss          bare<=10%  geared>=70%  other (first: +5 bare >=50%, '
    'later: -3 geared <=10%)  rounds',
  );
  for (final b in bosses(game.data)) {
    final c = bossCheck(game, b.id);
    stdout.writeln(
      '${b.id.padRight(16)} ${pct(c.bare.winRate)}     ${pct(c.geared.winRate)}'
      '        ${pct(c.other.winRate)}'
      '${c.geared.roundsPerFight.toStringAsFixed(1).padLeft(40)}'
      '${c.passes ? '' : '  FAILS'}',
    );
  }

  stdout.writeln('\n"fightXpPerStep": ${fightXpPerStep(measured, 30)},');

  stdout.writeln(
    '\ntwo-hander           fewer rounds (~25%, >=15%)  '
    'shield: less damage (>=20%)  monsters',
  );
  for (final h in handsChecks(game)) {
    stdout.writeln(
      '${h.twoHander.padRight(20)} ${pct(h.roundsCut).padLeft(14)}'
      '${pct(h.shieldCut).padLeft(29)}  ${h.monsters.join(', ')}'
      '${h.passes ? '' : '  FAILS'}',
    );
  }
}

/// XP per step for levels 1 to [levels] from [measured] levels: geometric
/// between them, and along the first and last slopes outside them.
List<double> fightXpPerStep(Map<int, double> measured, int levels) {
  final known = measured.keys.toList()..sort();
  double at(int level) {
    var i = 0;
    while (i < known.length - 2 && level > known[i + 1]) {
      i++;
    }
    final (a, b) = (known[i], known[i + 1]);
    final (va, vb) = (math.log(measured[a]!), math.log(measured[b]!));
    return math.exp(va + (vb - va) * (level - a) / (b - a));
  }

  return [for (var l = 1; l <= levels; l++) (at(l) * 1000).round() / 1000];
}
