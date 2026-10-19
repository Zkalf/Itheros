import 'activity.dart';

/// HP of both sides in the fight currently being resolved.
class FightState {
  FightState({required this.playerHp, required this.enemyHp, this.round = 0});

  factory FightState.fromJson(Map<String, Object?> json) => FightState(
    playerHp: json['playerHp'] as int,
    enemyHp: json['enemyHp'] as int,
    round: json['round'] as int? ?? 0,
  );

  int playerHp;
  int enemyHp;

  /// Rounds already fought.
  int round;

  Map<String, Object?> toJson() => {
    'playerHp': playerHp,
    'enemyHp': enemyHp,
    'round': round,
  };
}

/// The activity in progress, with steps paid toward its current unit.
class RunningActivity {
  RunningActivity(this.activity, {this.progress = 0, this.fight});

  factory RunningActivity.fromJson(Map<String, Object?> json) =>
      RunningActivity(
        Activity.fromJson(json),
        progress: json['progress'] as int,
        fight: json['fight'] == null
            ? null
            : FightState.fromJson(json['fight'] as Map<String, Object?>),
      );

  final Activity activity;

  /// Steps paid toward the next unit (fight round, ore, item, travel leg).
  int progress;

  /// Only set for fights, between a fight's first and last round.
  FightState? fight;

  Map<String, Object?> toJson() => {
    ...activity.toJson(),
    'progress': progress,
    'fight': fight?.toJson(),
  };
}

/// Everything saved for one player. Level is derived from [xp].
class GameState {
  GameState({
    required this.location,
    required this.rngState,
    this.xp = 0,
    this.bank = 0,
    this.activity,
    Map<String, int>? inventory,
    Map<String, String>? equipment,
    Map<String, int>? counters,
    Set<String>? achievements,
    this.loadedVersion = schemaVersion,
  }) : inventory = inventory ?? {},
       equipment = equipment ?? {},
       counters = counters ?? {},
       achievements = achievements ?? {};

  factory GameState.fromJson(Map<String, Object?> json) {
    final version = json['version'];
    if (version != 1 && version != schemaVersion) {
      throw FormatException('Unsupported save version: $version');
    }
    return GameState(
      loadedVersion: version as int,
      location: json['location'] as String,
      rngState: json['rng'] as int,
      xp: json['xp'] as int,
      bank: json['bank'] as int,
      activity: json['activity'] == null
          ? null
          : RunningActivity.fromJson(json['activity'] as Map<String, Object?>),
      inventory: _intMap(json['inventory']),
      equipment: (json['equipment'] as Map<String, Object?>).map(
        (k, v) => MapEntry(k, v as String),
      ),
      counters: _intMap(json['counters']),
      achievements: (json['achievements'] as List<Object?>)
          .cast<String>()
          .toSet(),
    );
  }

  /// 2: spec 0002's XP table and fight rounds. Version 1 saves load, and
  /// `Game.migrate` moves their XP to the new table.
  static const schemaVersion = 2;

  /// The save version this state was read from; not saved.
  final int loadedVersion;

  String location;
  int xp;
  int bank;
  RunningActivity? activity;

  /// Item id to count. Items with count 0 are removed.
  final Map<String, int> inventory;

  /// Slot to item id.
  final Map<String, String> equipment;

  /// State of the seeded random generator (see `Rng`).
  int rngState;

  /// Lifetime counters such as `steps.walked` and `kills.goblin`.
  final Map<String, int> counters;
  final Set<String> achievements;

  GameState copy() => GameState.fromJson(toJson());

  Map<String, Object?> toJson() => {
    'version': schemaVersion,
    'location': location,
    'xp': xp,
    'bank': bank,
    'activity': activity?.toJson(),
    'inventory': Map.of(inventory),
    'equipment': Map.of(equipment),
    'rng': rngState,
    'counters': Map.of(counters),
    'achievements': achievements.toList()..sort(),
  };

  void addItem(String item, [int count = 1]) {
    final n = (inventory[item] ?? 0) + count;
    if (n > 0) {
      inventory[item] = n;
    } else {
      inventory.remove(item);
    }
  }

  void count(String counter, [int by = 1]) =>
      counters[counter] = (counters[counter] ?? 0) + by;
}

Map<String, int> _intMap(Object? json) =>
    (json as Map<String, Object?>).map((k, v) => MapEntry(k, v as int));
