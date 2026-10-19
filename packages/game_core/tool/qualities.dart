// Gear qualities an average walker owns by day 14, 50 and 90 (plan 0006 M1):
// the pacing simulator at 5,000 steps a day, three seeds.
//
//   dart run tool/qualities.dart
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:game_core/simulation.dart';

void main() {
  final files = {
    for (final f in Directory('data').listSync().whereType<File>())
      if (f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
  };
  final game = Game(GameData.fromJsonStrings(files));
  final data = game.data;
  stdout.writeln(
    'day  seed  L   ${data.qualities.map((q) => q.id.padLeft(10)).join()}',
  );
  for (final days in [14, 50, 90]) {
    for (final seed in [1, 2, 3]) {
      final s = simulate(
        game,
        stepsPerDay: 5000,
        days: days,
        seed: seed,
      ).finalState;
      final counts = {for (final q in data.qualities) q.id: 0};
      void add(String key, int n) {
        if (data.itemOf(key)?.slot == null) return;
        final q = data.qualityOf(key).id;
        counts[q] = counts[q]! + n;
      }

      s.inventory.forEach(add);
      for (final key in s.equipment.values) {
        add(key, 1);
      }
      stdout.writeln(
        '${'$days'.padLeft(3)}  ${'$seed'.padLeft(4)}  '
        '${'${game.level(s)}'.padLeft(2)}  '
        '${counts.values.map((n) => '$n'.padLeft(10)).join()}',
      );
    }
  }
}
