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
