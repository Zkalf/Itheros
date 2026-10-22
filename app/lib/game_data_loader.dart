import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

const _files = [
  'economy',
  'world',
  'enemies',
  'items',
  'achievements',
  'professions',
  'origins',
];

/// Loads the game data bundled from `packages/game_core/data/`.
Future<GameData> loadBundledGameData([AssetBundle? bundle]) async {
  final b = bundle ?? rootBundle;
  return GameData.fromJsonStrings({
    for (final name in _files)
      name: await b.loadString('packages/game_core/data/$name.json'),
  });
}
