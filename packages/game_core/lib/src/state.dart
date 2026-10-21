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

/// How a fight ended, on the round that ended it.
enum FightOutcome { won, lost }

/// What became of one swing (spec 0009 §2.1).
enum Swing {
  hit,

  /// The player's hit, for double damage.
  crit,
  miss,

  /// The defender slipped a hit.
  dodge,

  /// The player's shield took most of a monster's hit.
  block,
}

/// One fight round, for the fight log (spec 0006 decision 8). [mine] and
/// [theirs] say how each side's swing went, or are null when that side
/// didn't swing; [dealt] and [taken] are the damage (0 on a miss or dodge).
class RoundLog {
  const RoundLog({
    required this.round,
    this.dealt,
    this.taken,
    this.mine,
    this.theirs,
    this.outcome,
  });

  factory RoundLog.fromJson(Map<String, Object?> json) => RoundLog(
    round: json['round'] as int,
    dealt: json['dealt'] as int?,
    taken: json['taken'] as int?,
    // Logs from before spec 0009 knew only hits.
    mine: _swing(json['mine']) ?? (json['dealt'] == null ? null : Swing.hit),
    theirs:
        _swing(json['theirs']) ?? (json['taken'] == null ? null : Swing.hit),
    outcome: switch (json['outcome']) {
      final String o => FightOutcome.values.byName(o),
      _ => null,
    },
  );

  final int round;
  final int? dealt;
  final int? taken;
  final Swing? mine;
  final Swing? theirs;
  final FightOutcome? outcome;

  static Swing? _swing(Object? name) =>
      name is String ? Swing.values.byName(name) : null;

  Map<String, Object?> toJson() => {
    'round': round,
    if (dealt != null) 'dealt': dealt,
    if (taken != null) 'taken': taken,
    if (mine != null) 'mine': mine!.name,
    if (theirs != null) 'theirs': theirs!.name,
    if (outcome != null) 'outcome': outcome!.name,
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
    this.won = 0,
    this.lost = 0,
    Map<String, int>? gained,
    List<RoundLog>? log,
  }) : stop = stop ?? StopCondition.defaultFor(activity),
       gained = gained ?? {},
       log = log ?? [];

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
        // Version 4 saves have no tally: it starts empty.
        won: json['won'] as int? ?? 0,
        lost: json['lost'] as int? ?? 0,
        gained: json['gained'] == null ? null : _intMap(json['gained']),
        log: [
          for (final r in json['log'] as List<Object?>? ?? const [])
            RoundLog.fromJson(r! as Map<String, Object?>),
        ],
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

  /// The tally (spec 0006 decision 7): fights won and lost, and every item
  /// key gained, while this action ran.
  int won;
  int lost;
  final Map<String, int> gained;

  /// The last few fight rounds, oldest first (spec 0006 decision 8).
  final List<RoundLog> log;

  Map<String, Object?> toJson() => {
    ...activity.toJson(),
    'stop': stop.toJson(),
    'progress': progress,
    'fight': fight?.toJson(),
    'leg': leg,
    'lossStreak': lossStreak,
    'crafted': crafted,
    'won': won,
    'lost': lost,
    'gained': Map.of(gained),
    'log': [for (final r in log) r.toJson()],
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
    Set<String>? explored,
    Set<String>? fought,
    Set<String>? lore,
    this.loadedVersion = schemaVersion,
  }) : queue = queue ?? [],
       inventory = inventory ?? {},
       equipment = equipment ?? {},
       counters = counters ?? {},
       achievements = achievements ?? {},
       explored = explored ?? {location},
       fought = fought ?? {},
       lore = lore ?? {};

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
      // Before version 6, `Game.migrate` fills it from the visited areas.
      explored: switch (json['explored']) {
        final List<Object?> l => l.cast<String>().toSet(),
        _ => null,
      },
      fought: _stringSet(json['fought']),
      lore: _stringSet(json['lore']),
    );
  }

  /// 7: bonus stats in item keys, fought monsters, found lore notes (spec
  /// 0009 §10).
  /// 6: paper-doll slot ids and explored areas (spec 0008).
  /// 5: the running action's tally and fight log, found drops (spec 0006).
  /// 4: visited areas are counted (spec 0004); same format as 3.
  /// 3: the queue (spec 0003). 2: spec 0002's XP table and fight rounds.
  /// Version 1 saves load, and `Game.migrate` moves their XP to the new
  /// table.
  static const schemaVersion = 7;

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

  /// Slot id (spec 0008 §2.1) to item key.
  final Map<String, String> equipment;

  /// Areas the player has stood in; the fog lifts around them (spec 0008
  /// decision 5).
  final Set<String> explored;

  /// Monsters fought at least once, won or lost: their armour is known
  /// (spec 0009 §7.1).
  final Set<String> fought;

  /// Lore notes found (spec 0009 §7.2).
  final Set<String> lore;

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
    'explored': explored.toList()..sort(),
    'fought': fought.toList()..sort(),
    // In the order found: the Lore tab lists the newest first.
    'lore': lore.toList(),
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

Set<String> _stringSet(Object? json) =>
    (json as List<Object?>? ?? const []).cast<String>().toSet();

Map<String, int> _intMap(Object? json) =>
    (json as Map<String, Object?>).map((k, v) => MapEntry(k, v as int));
