import 'dart:convert';
import 'dart:io';

import 'package:game_core/game_core.dart';

/// The real slice data, read from the game_core package on disk. [items] are
/// added to `items.json`, for tests that need gear the data doesn't have yet
/// (rings, two-handers).
Game loadTestGame({List<Map<String, Object?>> items = const []}) {
  final dir = Directory('../packages/game_core/data');
  final files = {
    for (final f in dir.listSync().whereType<File>())
      if (f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
  };
  if (items.isNotEmpty) {
    final json = jsonDecode(files['items']!) as Map<String, Object?>;
    (json['items']! as List<Object?>).addAll(items);
    files['items'] = jsonEncode(json);
  }
  return Game(GameData.fromJsonStrings(files));
}
