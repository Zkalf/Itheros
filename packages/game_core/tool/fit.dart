// Fits each monster's HP so the reference player of spec 0009 §9.1 earns the
// XP per step it earned before spec 0009 (main at plan 0011's start, from
// tool/tune.dart): monsters keep their XP and get new HP (spec 0009 §9.3).
// Prints old and new HP; --write puts the new HP in data/enemies.json.
//
//   dart run tool/fit.dart [--write] [monster ids...]
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:game_core/simulation.dart';

/// XP per step on main before spec 0009 (tool/tune.dart, 200 fights).
const before = {
  'goblin': 0.203,
  'goblin_brute': 0.253,
  'skeleton': 0.312,
  'zombie': 0.383,
  'graveyard_king': 0.456,
  'wolf': 0.489,
  'ghost': 0.605,
  'bandit': 0.760,
  'old_bear': 0.845,
  'giant_spider': 0.827,
  'troll': 1.033,
  'ogre_chieftain': 1.213,
  'stone_golem': 1.320,
  'harpy': 1.556,
  'wraith': 1.962,
  'wyvern': 2.207,
  'fire_drake': 2.609,
  'young_dragon': 3.229,
};

void main(List<String> args) {
  final write = args.contains('--write');
  final only = args.where((a) => !a.startsWith('--')).toSet();
  final files = {
    for (final f in Directory('data').listSync().whereType<File>())
      if (f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
  };
  var enemies = files['enemies']!;

  String withHp(String json, String id, int hp) => json.replaceFirstMapped(
    RegExp('("id": "$id"[\\s\\S]*?"hp": )\\d+'),
    (m) => '${m[1]}$hp',
  );

  stdout.writeln('monster            old hp  new hp  xp/step  target');
  for (final MapEntry(key: id, value: target) in before.entries) {
    if (only.isNotEmpty && !only.contains(id)) continue;
    var game = Game(GameData.fromJsonStrings(files));
    final old = game.data.enemies[id]!.stats.hp;
    var hp = old;
    var rate = 0.0;
    // xp per step falls as HP rises; a few proportional steps settle it.
    for (var i = 0; i < 8; i++) {
      game = Game(
        GameData.fromJsonStrings({
          ...files,
          'enemies': withHp(enemies, id, hp),
        }),
      );
      final e = game.data.enemies[id]!;
      final player = referencePlayer(
        game,
        e.level,
        without: bossOnlyItems(game, id),
        vs: id,
      );
      rate = measureFights(game, player, id, fights: 400).xpPerStep;
      if ((rate / target - 1).abs() < 0.01) break;
      hp = (hp * rate / target).round();
    }
    enemies = withHp(enemies, id, hp);
    stdout.writeln(
      '${id.padRight(18)} ${old.toString().padLeft(6)}  '
      '${hp.toString().padLeft(6)}  ${rate.toStringAsFixed(3).padLeft(7)}  '
      '${target.toStringAsFixed(3).padLeft(6)}',
    );
  }
  if (write) File('data/enemies.json').writeAsStringSync(enemies);
}
