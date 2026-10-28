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
    this.records = 0,
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
        records: json['records'] as int? ?? 0,
        gained: json['gained'] == null ? null : _intMap(json['gained']),
        log: [
          for (final r in json['log'] as List<Object?>? ?? const [])
            RoundLog.fromJson(r! as Map<String, Object?>),
        ],
      );

  final Activity activity;

  /// When it ends by itself (spec 0003 §3). The player may change it
  /// (spec 0016 amendment 2).
  StopCondition stop;

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

  /// Fish records beaten while this action ran (spec 0011 §8.2).
  int records;

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
    'records': records,
    'gained': Map.of(gained),
    'log': [for (final r in log) r.toJson()],
  };
}

/// The meal running now and its steps left (spec 0011 §5.4). [key] is the
/// meal's id, with `@perfect` for a perfect dish.
class ActiveMeal {
  ActiveMeal(this.key, this.left);

  factory ActiveMeal.fromJson(Map<String, Object?> json) =>
      ActiveMeal(json['key'] as String, json['left'] as int);

  final String key;
  int left;

  Map<String, Object?> toJson() => {'key': key, 'left': left};
}

/// The meal kind eaten when the running one ends, while the bag holds more
/// than [keep] (spec 0011 §5.4): 0 is "until out".
class AutoEat {
  const AutoEat(this.meal, this.keep);

  factory AutoEat.fromJson(Map<String, Object?> json) =>
      AutoEat(json['meal'] as String, json['keep'] as int? ?? 0);

  final String meal;
  final int keep;

  Map<String, Object?> toJson() => {'meal': meal, 'keep': keep};
}

/// Picks the word in gendered data lines (spec 0012 §2.3).
enum Gender { male, female, neither }

/// Who the player is (spec 0012 §6): [origin] is an origin id.
class Character {
  const Character({
    required this.name,
    required this.gender,
    required this.origin,
  });

  factory Character.fromJson(Map<String, Object?> json) => Character(
    name: json['name'] as String,
    gender: Gender.values.byName(json['gender'] as String),
    origin: json['origin'] as String,
  );

  final String name;
  final Gender gender;
  final String origin;

  Map<String, Object?> toJson() => {
    'name': name,
    'gender': gender.name,
    'origin': origin,
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
    Map<String, int>? professions,
    Set<String>? learned,
    Map<String, String>? tools,
    Set<String>? tips,
    Map<String, int>? records,
    Set<String>? revealed,
    this.meal,
    this.autoEat,
    this.bottles = 0,
    this.character,
    this.professionRng = 0,
    this.loadedVersion = schemaVersion,
  }) : queue = queue ?? [],
       inventory = inventory ?? {},
       equipment = equipment ?? {},
       counters = counters ?? {},
       achievements = achievements ?? {},
       explored = explored ?? {location},
       fought = fought ?? {},
       lore = lore ?? {},
       professions = professions ?? {},
       learned = learned ?? {},
       tools = tools ?? {},
       tips = tips ?? {},
       records = records ?? {},
       revealed = revealed ?? {};

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
      // Before version 8, `Game.migrate` fills these (spec 0010 §10).
      professions: json['professions'] == null
          ? null
          : _intMap(json['professions']),
      learned: _stringSet(json['learned']),
      tools: (json['tools'] as Map<String, Object?>? ?? const {}).map(
        (k, v) => MapEntry(k, v as String),
      ),
      tips: _stringSet(json['tips']),
      professionRng: json['professionRng'] as int? ?? 0,
      // Before version 9: no records, meal or bottles (spec 0011 §10).
      records: json['records'] == null ? null : _intMap(json['records']),
      revealed: _stringSet(json['revealed']),
      meal: switch (json['meal']) {
        final Map<String, Object?> m => ActiveMeal.fromJson(m),
        _ => null,
      },
      autoEat: switch (json['autoEat']) {
        final Map<String, Object?> m => AutoEat.fromJson(m),
        _ => null,
      },
      bottles: json['bottles'] as int? ?? 0,
      // Before version 10: none yet (spec 0012 §6).
      character: switch (json['character']) {
        final Map<String, Object?> m => Character.fromJson(m),
        _ => null,
      },
    );
  }

  /// 12: the achievements of spec 0017 and the quality counter (§3.2); same
  /// format as 11.
  /// 11: walks take a slot in the queue (spec 0016 §6); same format as 10.
  /// 10: the character, or none until Set out (spec 0012 §6).
  /// 9: fish records, the running meal, auto-eat, revealed areas and
  /// bottles found (spec 0011 §10).
  /// 8: profession XP, learned professions, tools, tips and the profession
  /// stream (spec 0010 §10).
  /// 7: bonus stats in item keys, fought monsters, found lore notes (spec
  /// 0009 §10).
  /// 6: paper-doll slot ids and explored areas (spec 0008).
  /// 5: the running action's tally and fight log, found drops (spec 0006).
  /// 4: visited areas are counted (spec 0004); same format as 3.
  /// 3: the queue (spec 0003). 2: spec 0002's XP table and fight rounds.
  /// Version 1 saves load, and `Game.migrate` moves their XP to the new
  /// table.
  static const schemaVersion = 12;

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

  /// Profession XP by profession id (spec 0010 §2.2).
  final Map<String, int> professions;

  /// Professions taught by their teacher (spec 0010 decision 9).
  final Set<String> learned;

  /// Profession id to the worn tool's item key (spec 0010 §3).
  final Map<String, String> tools;

  /// Teachers' tips told (spec 0010 §6.2).
  final Set<String> tips;

  /// Heaviest catch per fish, in tenths of a kg (spec 0011 §3.4).
  final Map<String, int> records;

  /// Hidden areas revealed (spec 0011 §6.2).
  final Set<String> revealed;

  /// The meal running, or null (spec 0011 §5.4).
  ActiveMeal? meal;

  /// The meal eaten when the running one ends, or null.
  AutoEat? autoEat;

  /// Messages in a bottle found (spec 0011 §6.1).
  int bottles;

  /// Who the player is, or null until Set out (spec 0012 §6).
  Character? character;

  /// State of the seeded random generator (see `Rng`).
  int rngState;

  /// State of the profession stream: every roll spec 0010 adds draws from
  /// it, never from [rngState] (spec 0010 §9.1).
  int professionRng;

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
    'professions': Map.of(professions),
    'learned': learned.toList()..sort(),
    'tools': Map.of(tools),
    'tips': tips.toList()..sort(),
    'professionRng': professionRng,
    'records': Map.of(records),
    'meal': meal?.toJson(),
    'autoEat': autoEat?.toJson(),
    'revealed': revealed.toList()..sort(),
    'bottles': bottles,
    'character': character?.toJson(),
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
