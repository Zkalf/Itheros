import 'dart:math' as math;

import 'activity.dart';
import 'data.dart';
import 'events.dart';
import 'goal.dart';
import 'news.dart';
import 'rng.dart';
import 'state.dart';

part 'game/progress.dart';
part 'game/odds.dart';
part 'game/items.dart';
part 'game/migrate.dart';
part 'game/world.dart';
part 'game/achievements.dart';
part 'game/queue.dart';
part 'game/run.dart';

/// The game rules. Stateless: every method takes a [GameState] and returns a
/// new one, leaving its input untouched.
class Game {
  Game(this.data);

  final GameData data;

  GameState newGame({required int seed}) => _visit(
    GameState(
      location: data.startLocation,
      rngState: Rng.seeded(seed).state,
      professionRng: professionStream(seed),
    ),
    data.startLocation,
  );

  /// The profession stream's first state, a fixed hash of [from] (a game
  /// seed, or an old save's generator state): no draw from the shared
  /// generator (spec 0010 §9.1).
  static int professionStream(int from) =>
      Rng.fromState(((from ^ 0x5BD1E995) * 0x85EBCA6B) & 0xFFFFFFFF).state;

  /// The name a character gets for [raw] (spec 0012 decision 7): trimmed,
  /// at most 20 characters, [defaultName] when empty.
  static String characterName(String raw) {
    final runes = raw.trim().runes;
    if (runes.isEmpty) return defaultName;
    return String.fromCharCodes(runes.take(maxNameLength)).trimRight();
  }

  static const defaultName = 'Wanderer';
  static const maxNameLength = 20;

  /// The counter set when [item] first drops from [enemy] (spec 0006
  /// decision 5).
  static String foundCounter(String enemy, String item) => 'found.$enemy.$item';

  /// The best quality found, as its index in the quality list plus one; none
  /// before any item (spec 0017 §3.2).
  static const foundQualityCounter = 'quality.best';

  LocationDef _here(GameState s) => data.locations[s.location]!;
}

/// What [Game.salvage] made: the new state, the dust and a boss shard, if
/// one came (spec 0010 §7.1).
class SalvageResult {
  const SalvageResult(this.state, this.dust, this.shard);

  final GameState state;
  final String dust;
  final String? shard;
}

/// What the player knows about a monster (spec 0009 §7.1).
class Knowledge {
  const Knowledge({
    required this.kills,
    required this.armour,
    required this.weakness,
    required this.stats,
    required this.slayer,
    required this.killsToNext,
  });

  final int kills;
  final bool armour;
  final bool weakness;
  final bool stats;
  final bool slayer;

  /// Kills until the next thing is learned (weakness and stats, then
  /// Slayer); null once Slayer is earned.
  final int? killsToNext;
}
