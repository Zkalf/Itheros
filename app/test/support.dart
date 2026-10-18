import 'dart:io';

import 'package:game_core/game_core.dart';

/// The real slice data, read from the game_core package on disk.
Game loadTestGame() {
  final dir = Directory('../packages/game_core/data');
  return Game(
    GameData.fromJsonStrings({
      for (final f in dir.listSync().whereType<File>())
        if (f.path.endsWith('.json'))
          f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
    }),
  );
}
