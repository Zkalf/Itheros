import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';

/// Loads the real slice data from `data/*.json`. [overrides] replaces whole
/// files by name (without extension), for tests that need special content.
GameData loadGameData({Map<String, Object> overrides = const {}}) {
  final files = <String, String>{
    for (final f in Directory('data').listSync().whereType<File>())
      if (f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
  };
  overrides.forEach((name, json) => files[name] = jsonEncode(json));
  return GameData.fromJsonStrings(files);
}

/// One real data file, decoded, for tests that tweak a few values.
Map<String, Object?> dataJson(String name) =>
    jsonDecode(File('data/$name.json').readAsStringSync())
        as Map<String, Object?>;

/// A game with one location, `arena`, holding [enemies], and no damage
/// variance, so fights are exact. [economy] values replace real ones.
Game arenaGame(
  List<Map<String, Object?>> enemies, {
  Map<String, Object?> economy = const {},
}) {
  return newTestGame(
    overrides: {
      'economy': {...dataJson('economy'), 'damageVariance': 0, ...economy},
      'enemies': {'enemies': enemies},
      'world': {
        'startLocation': 'arena',
        'locations': [
          {
            'id': 'arena',
            'name': 'Arena',
            'unlockLevel': 1,
            'enemies': [for (final e in enemies) e['id']],
          },
        ],
        'routes': <Object>[],
        'nodes': <Object>[],
      },
    },
  );
}

/// An arena monster: level 1, no drops, unless [extra] says otherwise.
Map<String, Object?> monster(
  String id, {
  int hp = 1,
  int attack = 0,
  int defense = 0,
  int xp = 10,
  Map<String, Object?> extra = const {},
}) => {
  'id': id,
  'name': id,
  'unlockLevel': 1,
  'level': 1,
  'hp': hp,
  'attack': attack,
  'defense': defense,
  'xp': xp,
  'drops': <Object>[],
  ...extra,
};

Game newTestGame({Map<String, Object> overrides = const {}}) =>
    Game(loadGameData(overrides: overrides));

/// A fresh state at [location] with enough XP for [level].
GameState stateAt(
  Game game, {
  String location = 'camp',
  int level = 1,
  int bank = 0,
  int seed = 1,
  Map<String, int> inventory = const {},
}) {
  return game.newGame(seed: seed)
    ..location = location
    ..xp = game.data.xpForLevel(level)
    ..bank = bank
    ..inventory.addAll(inventory);
}
