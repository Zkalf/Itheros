// Writes a sample save of this version for the save fixtures (spec 0007 §8).
//
//   dart run tool/sample_save.dart <out.json>
//
// Plays a fixed seed: three days of 5,000 steps fighting goblins, then a few
// more steps banked, with one journal entry.
import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:walkingrpg/persistence/save_data.dart';
import 'package:walkingrpg/sync/away_summary.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('usage: dart run tool/sample_save.dart <out.json>');
    exit(64);
  }
  final dir = Directory('../packages/game_core/data');
  final game = Game(
    GameData.fromJsonStrings({
      for (final f in dir.listSync().whereType<File>())
        if (f.path.endsWith('.json'))
          f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
    }),
  );

  var state = game.newGame(seed: 1);
  state = game.addAction(state, const Activity.travel('goblin_woods'));
  final reports = <StepReport>[];
  for (var day = 0; day < 3; day++) {
    final r = game.applySteps(state, 5000);
    reports.add(r);
    state = r.state;
    if (state.activity == null) {
      state = game.addAction(state, const Activity.fight('goblin'));
    }
  }
  final save = SaveData(
    game: state,
    firstDay: '2026-10-18',
    credited: const {
      '2026-10-18': 5000,
      '2026-10-19': 5000,
      '2026-10-20': 5000,
    },
    seen: const {'camp', 'goblin_woods'},
    journal: [
      JournalEntry(
        started: DateTime(2026, 10, 20, 18, 30),
        summary: AwaySummary.fromReports(reports),
      ),
    ],
  );
  File(args.single).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(save.toJson()),
  );
}
