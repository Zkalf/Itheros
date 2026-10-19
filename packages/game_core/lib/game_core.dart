/// Pure-Dart game rules for the walking RPG (spec 0001).
///
/// Everything here is deterministic: the same [GameState], data and step
/// count always give the same result, so catch-up after the app was closed
/// can be applied in any number of chunks.
library;

export 'src/activity.dart';
export 'src/data.dart';
export 'src/events.dart';
export 'src/game.dart';
export 'src/goal.dart';
export 'src/news.dart';
export 'src/rng.dart';
export 'src/state.dart';
