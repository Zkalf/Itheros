// The pace report (plan 0066, issue #185): a bigger sim now and then, so slow
// drift of the pace shows. It runs the mixed walker and the fighter on many
// seeds at 5,000 steps a day, prints one table and puts it at the top of the
// report file, with the change since the last report. It never fails on a
// number: the owner reads it and decides.
//
//   dart run tool/pace_report.dart --commit <sha> [--seeds 32]
//                                  [--file ../../docs/sim/pace-reports.md]
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:game_core/game_core.dart';
import 'package:game_core/simulation.dart';

/// A move of this many days or more gets a mark (owner, plan 0066).
const markDays = 5;

/// One line of the report.
class PaceRow {
  const PaceRow(
    this.measure,
    this.value, {
    required this.day,
    this.percent = false,
  });

  final String measure;
  final double value;

  /// A day number: only these get a mark on a big move.
  final bool day;

  /// Shown with a "%" (the value is already times 100).
  final bool percent;

  String get shown => '${value.toStringAsFixed(1)}${percent ? '%' : ''}';
}

/// The median of [days], with a missed seed (null) counted as [missed].
double medianDays(Iterable<int?> days, {required int missed}) =>
    median([for (final d in days) d ?? missed]);

/// The median of [xs]: the mean of the two middle values of an even list.
double median(List<num> xs) {
  final s = [...xs]..sort();
  final m = s.length ~/ 2;
  return s.length.isOdd ? s[m].toDouble() : (s[m - 1] + s[m]) / 2;
}

/// The values of the newest report in [file], by measure; empty without one.
Map<String, double> lastValues(String file) {
  final values = <String, double>{};
  var inReport = false;
  for (final line in file.split('\n')) {
    if (line.startsWith('## ')) {
      if (inReport) break;
      inReport = true;
      continue;
    }
    if (!inReport || !line.startsWith('|')) continue;
    final cells = line.split('|').map((c) => c.trim()).toList();
    if (cells.length < 3) continue;
    final value = double.tryParse(cells[2].replaceAll('%', ''));
    if (value != null) values[cells[1]] = value;
  }
  return values;
}

/// The change of [row] since [before], with a mark on a big move of a day.
String changeCell(PaceRow row, double? before) {
  if (before == null) return 'new';
  final change = row.value - before;
  final sign = change >= 0 ? '+' : '-';
  final mark = row.day && change.abs() >= markDays ? ' ⚠' : '';
  return '$sign${change.abs().toStringAsFixed(1)}$mark';
}

/// The report as markdown. Without [last] values it is a first report and
/// has no change column.
String reportTable(
  String heading,
  List<PaceRow> rows,
  Map<String, double> last,
) {
  final first = last.isEmpty;
  return [
    '## $heading',
    '',
    first ? '| Measure | Value |' : '| Measure | Value | Change |',
    first ? '|---|---|' : '|---|---|---|',
    for (final r in rows)
      first
          ? '| ${r.measure} | ${r.shown} |'
          : '| ${r.measure} | ${r.shown} | ${changeCell(r, last[r.measure])} |',
    '',
  ].join('\n');
}

/// [file] with [report] above its older reports, under its intro.
String withReport(String file, String report) {
  if (file.startsWith('## ')) return '$report\n$file';
  final at = file.indexOf('\n## ');
  if (at < 0) return '${file.trimRight()}\n\n$report';
  return '${file.substring(0, at).trimRight()}\n\n$report\n${file.substring(at + 1)}';
}

/// The real data, optionally without the bonuses of feats (as the pacing
/// test compares meals: spec 0017 amendment 3).
Game _game({required bool noBonuses}) {
  final files = {
    for (final f in Directory('data').listSync().whereType<File>())
      if (f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
  };
  final game = Game(GameData.fromJsonStrings(files));
  if (!noBonuses) return game;
  return Game(
    GameData.fromJsonStrings({
      ...files,
      'achievements': _withoutBonuses(files['achievements']!, game),
    }),
  );
}

String _withoutBonuses(String json, Game game) {
  final data = jsonDecode(json) as Map<String, Object?>;
  return jsonEncode({
    ...data,
    'achievements': [
      for (final a in data['achievements']! as List)
        {
          ...a as Map<String, Object?>,
          if (game.data.achievements[a['id']]!.reward is BonusReward)
            'reward': {'bankCap': 0},
        },
    ],
  });
}

Future<SimulationResult> _run(
  int seed, {
  int days = 105,
  Walker walker = Walker.mixed,
  bool meals = true,
  bool noBonuses = false,
}) => Isolate.run(
  () => simulate(
    _game(noBonuses: noBonuses),
    stepsPerDay: 5000,
    days: days,
    seed: seed,
    walker: walker,
    meals: meals,
  ),
);

/// The rows of the report from the runs on [seeds].
Future<List<PaceRow>> paceRows(List<int> seeds) async {
  final runs = await Future.wait([
    for (final s in seeds) _run(s),
    for (final s in seeds) _run(s, days: 120, walker: Walker.fighter),
    for (final s in seeds) _run(s, noBonuses: true),
    for (final s in seeds) _run(s, noBonuses: true, meals: false),
  ]);
  final n = seeds.length;
  final mixed = runs.sublist(0, n);
  final fighter = runs.sublist(n, 2 * n);
  final withMeals = runs.sublist(2 * n, 3 * n);
  final noMeals = runs.sublist(3 * n);
  final fights = [for (final r in mixed) ...r.fights];
  final king = [
    for (final f in fights)
      if (f.enemy == 'graveyard_king') f.rounds,
  ];
  double l30(List<SimulationResult> rs) =>
      medianDays(rs.map((r) => r.dayReached(30)), missed: 106);
  return [
    for (final l in [10, 20, 30])
      PaceRow(
        'Mixed L$l',
        medianDays(mixed.map((r) => r.dayReached(l)), missed: 106),
        day: true,
      ),
    for (final l in [10, 20, 30])
      PaceRow(
        'Fighter L$l',
        medianDays(fighter.map((r) => r.dayReached(l)), missed: 121),
        day: true,
      ),
    PaceRow('Meal gain', l30(noMeals) - l30(withMeals), day: true),
    PaceRow(
      'Fight rounds',
      median([for (final f in fights) f.rounds]),
      day: false,
    ),
    PaceRow(
      'Fight HP taken',
      100 * median([for (final f in fights) f.taken]),
      day: false,
      percent: true,
    ),
    PaceRow(
      'Hard fights',
      100 * fights.where((f) => f.taken > 0.5).length / fights.length,
      day: false,
      percent: true,
    ),
    if (king.isNotEmpty) PaceRow('King rounds', median(king), day: false),
  ];
}

Future<void> main(List<String> args) async {
  String opt(String name, String fallback) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : fallback;
  }

  final seeds = int.parse(opt('seeds', '32'));
  final commit = opt('commit', 'unknown');
  final path = opt('file', '../../docs/sim/pace-reports.md');
  final file = File(path);
  final old = file.existsSync() ? file.readAsStringSync() : _intro;
  final rows = await paceRows([for (var s = 1; s <= seeds; s++) s]);
  final day = DateTime.now().toIso8601String().substring(0, 10);
  final report = reportTable(
    '$day · $commit · $seeds seeds',
    rows,
    lastValues(old),
  );
  stdout.writeln(report);
  file.writeAsStringSync(withReport(old, report));
  stdout.writeln('Written to $path');
}

const _intro = '''
# Pace reports

A bigger sim now and then (plan 0066, issue #185). Each report runs the mixed walker and the fighter at 5,000
steps a day on many seeds and shows the medians. The change column compares with the report below it. "⚠" marks
a day number that moved 5 days or more. The report never fails: the owner reads it and decides.

- Run it with `.\\scripts\\pace-report.ps1 [-Seeds 32]`. It takes the CPU for a few minutes, so not during a check.
- A missed seed counts as day 106 for the mixed walker and day 121 for the fighter, as in the pacing test.
- Meal gain: the median level 30 day without meals minus the one with meals, without the bonuses of feats.
- The fight numbers come from the mixed walker's fights. "Hard fights" take more than half its HP.
- Newest report first.
''';
