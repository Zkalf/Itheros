// Searches boss stats that pass spec 0002 §5.3's gear checks (as amended by
// amendment 1) with average damage, hardest-hitting first (plan 0003 M3).
// Confirm the pick with tool/tune.dart, which fights with damage rolls.
//
//   dart run tool/boss_search.dart <boss id>
import 'dart:io';

import 'package:game_core/game_core.dart';
import 'package:game_core/simulation.dart';

void main(List<String> args) {
  final files = {
    for (final f in Directory('data').listSync().whereType<File>())
      if (f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
  };
  final game = Game(GameData.fromJsonStrings(files));
  final boss = game.data.enemies[args.single]!;
  final own = bossOnlyItems(game, boss.id);
  final lvl = boss.level;
  // The first boss keeps the out-levelling route (amendment 1).
  final first = boss.id == 'graveyard_king';
  final bare = game.stats(referencePlayer(game, lvl, geared: false));
  final geared = game.stats(referencePlayer(game, lvl, without: own));
  final other = first
      ? game.stats(referencePlayer(game, lvl + 5, geared: false))
      : game.stats(referencePlayer(game, lvl - 3, without: own));
  stdout.writeln('bare $bare\ngeared $geared\nother $other');

  final found = <(int, int, int, int, int)>[];
  final regens = boss.has(Trait.regenerates) ? [2, 4, 6, 8, 10, 12, 15] : [0];
  for (var hp = 200; hp <= 1500; hp += 50) {
    for (var def = 0; def <= 80; def += 2) {
      for (var atk = 5; atk <= 120; atk++) {
        for (final regen in regens) {
          final e = EnemyDef.fromJson({
            'id': boss.id,
            'name': boss.name,
            'unlockLevel': 1,
            'level': lvl,
            'hp': hp,
            'attack': atk,
            'defense': def,
            'xp': 1,
            'traits': [for (final t in boss.traits) t.name],
            'regen': regen,
          });
          final b = estimateFight(bare, e);
          if (b.win && b.hpLeft > 0.05) continue;
          final g = estimateFight(geared, e);
          if (!g.win || g.hpLeft < 0.3 || g.rounds < 27 || g.rounds > 38) {
            continue;
          }
          final o = estimateFight(other, e);
          if (first
              ? (!o.win || o.hpLeft < 0.15)
              : (o.win && o.hpLeft > 0.05)) {
            continue;
          }
          found.add((atk, hp, def, regen, g.rounds));
        }
      }
    }
  }
  found.sort((x, y) => y.$1.compareTo(x.$1));
  for (final f in found.take(15)) {
    stdout.writeln(
      'attack ${f.$1} hp ${f.$2} defense ${f.$3} regen ${f.$4} '
      'geared rounds ${f.$5}',
    );
  }
}
