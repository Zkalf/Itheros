// Roster tuning report (plan 0003 M3): for each monster, an even-level
// player with that stretch's gear fights it 200 times. Prints win rate,
// rounds, XP per step against spec 0002's target, and the step up from the
// previous normal monster; then the boss gear checks (amendment 1).
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
  for (final e in enemies) {
    final r = measureFights(game, referencePlayer(game, e.level), e.id);
    final normal = !bossIds.contains(e.id) && !e.lurker;
    final up = previous == null || !normal
        ? ''
        : pct(r.xpPerStep / previous - 1);
    if (normal) previous = r.xpPerStep;
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
}
