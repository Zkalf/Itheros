// How fast the bag fills (spec 0021 §5): the walker at --steps-per-day on
// seeds 1..--seeds for --days. Each day: the kinds of item in the bag (worn
// gear and worn tools take no space), by group. Then the targets of spec
// 0021 §5.3: the day of level 30, the share of steps walked overloaded and
// the gap between bank visits that store.
//
//   dart run tool/bag.dart [--seeds 16] [--steps-per-day 5000] [--days 120]
//                          [--fighter | --gatherer]
import 'dart:io';
import 'dart:math' as math;

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
  final data = game.data;
  final steps = opt('steps-per-day', 5000);
  final days = opt('days', 120);
  final seeds = opt('seeds', 16);
  final walker = args.contains('--fighter')
      ? Walker.fighter
      : args.contains('--gatherer')
      ? Walker.gatherer
      : Walker.mixed;

  String group(String key) {
    final item = data.itemOf(key);
    if (item == null) return '?';
    if (item.slot != null) return 'gear';
    if (item.tool != null) return 'tool';
    if (item.meal != null) return 'meal';
    return 'mat';
  }

  final kinds = [for (var d = 0; d < days; d++) <int>[]];
  final groups = [for (var d = 0; d < days; d++) <String, List<int>>{}];
  final firstOver = <int?>[];
  final overShare = <double>[];
  final level30 = <int>[];
  final gaps = <int>[];
  final stores = <int>[];
  final byKind = <String, int>{};

  for (var seed = 1; seed <= seeds; seed++) {
    final player = SensiblePlayer(game, walker: walker);
    var s = game.makeCharacter(
      game.newGame(seed: seed),
      name: 'Walker',
      gender: Gender.neither,
      origin: 'miners_child',
    );
    if (walker != Walker.fighter) {
      for (final p in data.professions.keys) {
        if (!s.learned.contains(p)) s = game.learn(s, p);
      }
    }
    int? over;
    int? l30;
    int? lastStore;
    var stored = 0;
    var walkedOver = 0;
    for (var day = 1; day <= days; day++) {
      var left = steps;
      while (left > 0) {
        int total() => s.itemBank.values.fold(0, (a, b) => a + b);
        final banked = total();
        s = player.decide(s);
        if (total() > banked) {
          if (lastStore != null && day > lastStore) gaps.add(day - lastStore);
          if (lastStore != day) stored++;
          lastStore = day;
        }
        final n = math.min(100, left);
        if (game.overloaded(s)) walkedOver += n;
        final kind = s.activity?.activity.kind.name ?? 'idle';
        byKind[kind] = (byKind[kind] ?? 0) + n;
        final r = game.applySteps(s, n, day: simDay(day));
        player.observe(r);
        s = r.state;
        left -= n;
        if (over == null && game.overloaded(s)) over = day;
      }
      if (l30 == null && game.level(s) >= 30) l30 = day;
      kinds[day - 1].add(game.spacesUsed(s));
      final g = <String, int>{};
      for (final key in s.inventory.keys) {
        g[group(key)] = (g[group(key)] ?? 0) + 1;
      }
      for (final e in g.entries) {
        groups[day - 1].putIfAbsent(e.key, () => []).add(e.value);
      }
    }
    firstOver.add(over);
    overShare.add(walkedOver / (steps * days));
    level30.add(l30 ?? 999);
    stores.add(stored);
    stderr.write('.');
  }
  stderr.writeln();

  double median(List<num> v) {
    if (v.isEmpty) return 0;
    final s = [...v]..sort();
    final n = s.length;
    return (s[(n - 1) ~/ 2] + s[n ~/ 2]) / 2;
  }

  String pct(double x) => '${(x * 1000).round() / 10}%';

  stdout.writeln('walker ${walker.name}, $steps steps a day, $seeds seeds');
  stdout.writeln(
    '| day | kinds (median) | min-max | gear | mat | tool | meal |',
  );
  stdout.writeln('|---|---|---|---|---|---|---|');
  for (final d in [7, 14, 30, 45, 60, 90, 120]) {
    if (d > days) break;
    final k = kinds[d - 1];
    final g = groups[d - 1];
    double gm(String n) =>
        median([...?g[n], for (var i = g[n]?.length ?? 0; i < seeds; i++) 0]);
    stdout.writeln(
      '| $d | ${median(k)} | ${k.reduce(math.min)}-${k.reduce(math.max)} | '
      '${gm('gear')} | ${gm('mat')} | ${gm('tool')} | ${gm('meal')} |',
    );
  }
  stdout.writeln(
    'First day overloaded: ${firstOver.map((d) => d ?? '-').join(', ')}',
  );
  stdout.writeln('Days that stored in the bank: ${stores.join(', ')}');
  stdout.writeln(
    'Day of level 30: median ${median(level30)}, per seed ${level30.join(', ')}',
  );
  stdout.writeln(
    'Steps walked overloaded: median ${pct(median(overShare))}, '
    'per seed ${overShare.map(pct).join(', ')}',
  );
  stdout.writeln('Gap between days that stored: median ${median(gaps)} days');
  final all = byKind.values.fold(0, (a, b) => a + b);
  stdout.writeln(
    'Steps by action: ${[for (final e in byKind.entries) '${e.key} ${pct(e.value / all)}'].join(', ')}',
  );
}
