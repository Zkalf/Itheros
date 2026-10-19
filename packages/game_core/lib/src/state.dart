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
  RunningActivity(
    this.activity, {
    StopCondition? stop,
    this.progress = 0,
    this.fight,
    this.leg,
    this.lossStreak = 0,
    this.crafted = 0,
  }) : stop = stop ?? StopCondition.defaultFor(activity);

  factory RunningActivity.fromJson(Map<String, Object?> json) =>
      RunningActivity(
        Activity.fromJson(json),
        // Version 2 saves have no stop condition: the default for the kind.
        stop: json['stop'] == null
            ? StopCondition.defaultFor(Activity.fromJson(json))
            : StopCondition.fromJson(json['stop'] as Map<String, Object?>),
        progress: json['progress'] as int,
        fight: json['fight'] == null
            ? null
            : FightState.fromJson(json['fight'] as Map<String, Object?>),
        leg: json['leg'] as String?,
        lossStreak: json['lossStreak'] as int? ?? 0,
        crafted: json['crafted'] as int? ?? 0,
      );

  final Activity activity;

  /// When it ends by itself (spec 0003 §3).
  final StopCondition stop;

  /// Steps paid toward the next unit (fight round, ore, item, travel leg).
  int progress;

  /// Only set for fights, between a fight's first and last round.
  FightState? fight;

  /// The next location on the way to where the action happens, or null once
  /// there (spec 0003 §4). While set, the unit being paid is this leg.
  String? leg;

  /// Fights lost in a row (spec 0003 §5).
  int lossStreak;

  /// Items this action crafted.
  int crafted;

  Map<String, Object?> toJson() => {
    ...activity.toJson(),
    'stop': stop.toJson(),
    'progress': progress,
    'fight': fight?.toJson(),
    'leg': leg,
    'lossStreak': lossStreak,
    'crafted': crafted,
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
    List<PlannedAction>? queue,
    Map<String, int>? inventory,
    Map<String, String>? equipment,
    Map<String, int>? counters,
    Set<String>? achievements,
    this.loadedVersion = schemaVersion,
  }) : queue = queue ?? [],
       inventory = inventory ?? {},
       equipment = equipment ?? {},
       counters = counters ?? {},
       achievements = achievements ?? {};

  factory GameState.fromJson(Map<String, Object?> json) {
    final version = json['version'];
    if (version is! int || version < 1 || version > schemaVersion) {
      throw FormatException('Unsupported save version: $version');
    }
    return GameState(
      loadedVersion: version,
      location: json['location'] as String,
      rngState: json['rng'] as int,
      xp: json['xp'] as int,
      bank: json['bank'] as int,
      activity: json['activity'] == null
          ? null
          : RunningActivity.fromJson(json['activity'] as Map<String, Object?>),
      queue: [
        for (final p in json['queue'] as List<Object?>? ?? const [])
          PlannedAction.fromJson(p! as Map<String, Object?>),
      ],
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

  /// 4: visited areas are counted (spec 0004); same format as 3.
  /// 3: the queue (spec 0003). 2: spec 0002's XP table and fight rounds.
  /// Version 1 saves load, and `Game.migrate` moves their XP to the new
  /// table.
  static const schemaVersion = 4;

  /// The save version this state was read from; not saved.
  final int loadedVersion;

  String location;
  int xp;
  int bank;

  /// The running action: the head of the queue.
  RunningActivity? activity;

  /// Actions waiting after [activity], in order (spec 0003 §2).
  final List<PlannedAction> queue;

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
    'queue': [for (final p in queue) p.toJson()],
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
