import 'dart:convert';
import 'dart:math' as math;

/// Character stats. Also used for gear bonuses and per-level growth.
class Stats {
  const Stats({this.hp = 0, this.attack = 0, this.defense = 0});

  factory Stats.fromJson(Map<String, Object?> json) => Stats(
    hp: _intOr(json, 'hp'),
    attack: _intOr(json, 'attack'),
    defense: _intOr(json, 'defense'),
  );

  final int hp;
  final int attack;
  final int defense;

  Stats operator +(Stats o) => Stats(
    hp: hp + o.hp,
    attack: attack + o.attack,
    defense: defense + o.defense,
  );

  Stats operator *(int n) =>
      Stats(hp: hp * n, attack: attack * n, defense: defense * n);

  @override
  String toString() => 'Stats(hp: $hp, attack: $attack, defense: $defense)';
}

class LocationDef {
  LocationDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      name = _str(j, 'name'),
      unlockLevel = _int(j, 'unlockLevel'),
      crafting = j['crafting'] as bool? ?? false,
      enemies = _strList(j, 'enemies'),
      nodes = _strList(j, 'nodes'),
      flavour = j['flavour'] as String?;

  final String id;
  final String name;
  final int unlockLevel;
  final bool crafting;
  final List<String> enemies;
  final List<String> nodes;

  /// One line shown the first time the area appears (spec 0002 §9.5).
  final String? flavour;
}

/// A title the player earns at [level], with its ceremony line
/// (spec 0002 decision 10).
class RankDef {
  RankDef._(Map<String, Object?> j)
    : level = _int(j, 'level'),
      name = _str(j, 'name'),
      line = _str(j, 'line');

  final int level;
  final String name;
  final String line;
}

/// Routes are walkable in both directions.
class RouteDef {
  RouteDef._(Map<String, Object?> j)
    : from = _str(j, 'from'),
      to = _str(j, 'to'),
      steps = _int(j, 'steps');

  final String from;
  final String to;
  final int steps;
}

class NodeDef {
  NodeDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      name = _str(j, 'name'),
      unlockLevel = _int(j, 'unlockLevel'),
      steps = _int(j, 'steps'),
      item = _str(j, 'item'),
      xp = _int(j, 'xp');

  final String id;
  final String name;
  final int unlockLevel;
  final int steps;
  final String item;
  final int xp;
}

class DropDef {
  DropDef._(Map<String, Object?> j)
    : item = _str(j, 'item'),
      chance = (j['chance'] as num? ?? 1).toDouble(),
      count = _intOr(j, 'count', 1),
      repeatChance = (j['repeatChance'] as num? ?? 0).toDouble();

  final String item;
  final double chance;
  final int count;

  /// For a first-kill drop: the chance it drops again on later kills (spec
  /// 0005 decision 6).
  final double repeatChance;
}

/// A gear quality (spec 0005 §2). [bonus] is the share added to each stat.
class QualityDef {
  QualityDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      name = _str(j, 'name'),
      colour = _str(j, 'colour'),
      bonus = (j['bonus'] as num).toDouble(),
      chance = (j['chance'] as num).toDouble();

  final String id;
  final String name;

  /// `#rrggbb`.
  final String colour;
  final double bonus;
  final double chance;
}

/// Monster twists (spec 0002 §5.1).
enum Trait {
  /// Strikes first in each round.
  quick,

  /// Attacks only every second round.
  slow,

  /// Its hits ignore the player's defense.
  ghostly,

  /// Heals [EnemyDef.regen] after each of its turns.
  regenerates,
}

class EnemyDef {
  /// One `enemies.json` entry; for tuning tools trying variants.
  factory EnemyDef.fromJson(Map<String, Object?> j) = EnemyDef._;

  EnemyDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      name = _str(j, 'name'),
      unlockLevel = _int(j, 'unlockLevel'),
      level = j['level'] as int? ?? _int(j, 'unlockLevel'),
      stats = Stats.fromJson(j),
      xp = _int(j, 'xp'),
      traits = Set.unmodifiable(_strList(j, 'traits').map(_trait)),
      regen = _intOr(j, 'regen'),
      drops = _maps(j, 'drops').map(DropDef._).toList(),
      firstKillDrops = _maps(j, 'firstKillDrops').map(DropDef._).toList(),
      lurker = j['lurker'] as bool? ?? false,
      lossHint = j['lossHint'] as String?,
      flavour = j['flavour'] as String?;

  final String id;
  final String name;

  /// The player level from which it shows.
  final int unlockLevel;

  /// The monster's own level, which sets its colour (spec 0002 §3).
  final int level;
  final Stats stats;
  final int xp;
  final Set<Trait> traits;

  /// HP healed per round when it [Trait.regenerates].
  final int regen;
  final List<DropDef> drops;

  /// Dropped once, on the first kill (spec 0002 §5.3).
  final List<DropDef> firstKillDrops;

  /// Far above its area, there to be seen early (spec 0002 §5.4).
  final bool lurker;

  /// Added to the report after a loss (spec 0002 §9.4).
  final String? lossHint;

  /// One line shown the first time it appears (spec 0002 §9.5).
  final String? flavour;

  bool has(Trait t) => traits.contains(t);
}

Trait _trait(String name) {
  for (final t in Trait.values) {
    if (t.name == name) return t;
  }
  throw FormatException('Invalid game data: unknown trait $name');
}

/// Colour of something's level compared with the player's (spec 0002 §3).
enum LevelColour { grey, green, yellow, orange, red, skull }

/// One row of the colour table: applies from [atLeast] levels above the
/// player (null: any difference).
class LevelBand {
  LevelBand._(Map<String, Object?> j)
    : atLeast = j['atLeast'] as int?,
      colour = LevelColour.values.byName(_str(j, 'colour')),
      xpPercent = _int(j, 'xp');

  final int? atLeast;
  final LevelColour colour;

  /// Share of the normal XP given, in percent.
  final int xpPercent;
}

class ItemDef {
  ItemDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      name = _str(j, 'name'),
      slot = j['slot'] as String?,
      bonus = Stats.fromJson(j);

  final String id;
  final String name;

  /// Equipment slot, or null for materials.
  final String? slot;
  final Stats bonus;

  /// How it ranks against other gear for the same slot.
  int get score => bonus.attack * 5 + bonus.defense * 3 + bonus.hp;
}

class RecipeDef {
  RecipeDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      unlockLevel = _int(j, 'unlockLevel'),
      steps = _int(j, 'steps'),
      xp = _int(j, 'xp'),
      inputs = (j['inputs'] as Map<String, Object?>).map(
        (k, v) => MapEntry(k, v as int),
      ),
      output = _str(j, 'output');

  final String id;
  final int unlockLevel;
  final int steps;
  final int xp;
  final Map<String, int> inputs;
  final String output;
}

class AchievementDef {
  AchievementDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      name = _str(j, 'name'),
      counter = _str(j, 'counter'),
      atLeast = _int(j, 'atLeast'),
      bankCapReward = _intOr(
        j['reward'] as Map<String, Object?>? ?? const {},
        'bankCap',
      );

  final String id;
  final String name;

  /// Name of a [GameState.counters] entry, e.g. `kills.goblin`.
  final String counter;
  final int atLeast;
  final int bankCapReward;
}

/// All tunable game content, loaded from `data/*.json`.
class GameData {
  GameData._({
    required Map<String, Object?> economy,
    required Map<String, Object?> world,
    required Map<String, Object?> enemies,
    required Map<String, Object?> items,
    required Map<String, Object?> achievements,
  }) : bankCapBase = _int(_map(economy, 'bankCap'), 'base'),
       bankCapPerLevel = _int(_map(economy, 'bankCap'), 'perLevel'),
       combatRoundSteps = _int(economy, 'combatRoundSteps'),
       baseStats = Stats.fromJson(_map(economy, 'baseStats')),
       statsPerLevel = Stats.fromJson(_map(economy, 'statsPerLevel')),
       damageVariance = (economy['damageVariance'] as num).toDouble(),
       xpToReachLevel = List.unmodifiable(
         (economy['xpToReachLevel'] as List<Object?>).cast<int>(),
       ),
       xpGrowthAfterList = (economy['xpGrowthAfterList'] as num).toDouble(),
       levelBands = List.unmodifiable(
         _maps(economy, 'levelBands').map(LevelBand._),
       ),
       gearSlots = Map.unmodifiable(
         _map(economy, 'gearSlots').map((k, v) => MapEntry(k, v as int)),
       ),
       ranks = List.unmodifiable(_maps(economy, 'ranks').map(RankDef._)),
       talentPointsFrom = _int(economy, 'talentPointsFrom'),
       queueSlots = Map.unmodifiable({
         for (final q in _maps(economy, 'queueSlots'))
           _int(q, 'level'): _int(q, 'slots'),
       }),
       untilFromLevel = _int(economy, 'untilFromLevel'),
       lossXpShare = (economy['lossXpShare'] as num).toDouble(),
       lossesToGiveUp = _int(economy, 'lossesToGiveUp'),
       journalEntries = _int(economy, 'journalEntries'),
       qualities = List.unmodifiable(
         _maps(economy, 'qualities').map(QualityDef._),
       ),
       qualityPerLevel = (economy['qualityPerLevel'] as num).toDouble(),
       qualityMaxLevels = _int(economy, 'qualityMaxLevels'),
       startLocation = _str(world, 'startLocation'),
       locations = _byId(
         _maps(world, 'locations').map(LocationDef._),
         (d) => d.id,
       ),
       routes = List.unmodifiable(_maps(world, 'routes').map(RouteDef._)),
       nodes = _byId(_maps(world, 'nodes').map(NodeDef._), (d) => d.id),
       enemies = _byId(_maps(enemies, 'enemies').map(EnemyDef._), (d) => d.id),
       items = _byId(_maps(items, 'items').map(ItemDef._), (d) => d.id),
       recipes = _byId(_maps(items, 'recipes').map(RecipeDef._), (d) => d.id),
       achievements = _byId(
         _maps(achievements, 'achievements').map(AchievementDef._),
         (d) => d.id,
       ) {
    _validate();
  }

  /// [files] maps a data file name without extension (`economy`, `world`,
  /// `enemies`, `items`, `achievements`) to its JSON text.
  factory GameData.fromJsonStrings(Map<String, String> files) {
    Map<String, Object?> file(String name) {
      final text = files[name];
      if (text == null) throw FormatException('Missing data file: $name.json');
      return jsonDecode(text) as Map<String, Object?>;
    }

    return GameData._(
      economy: file('economy'),
      world: file('world'),
      enemies: file('enemies'),
      items: file('items'),
      achievements: file('achievements'),
    );
  }

  final int bankCapBase;
  final int bankCapPerLevel;
  final int combatRoundSteps;
  final Stats baseStats;
  final Stats statsPerLevel;

  /// Damage varies by ± this fraction.
  final double damageVariance;

  /// Total XP needed to reach level `i + 1`. Levels go on past the list
  /// (spec 0002 §2): see [xpGrowthAfterList].
  final List<int> xpToReachLevel;

  /// After the list, each level costs the previous level's cost times this.
  final double xpGrowthAfterList;

  /// Colour table, highest difference first; the last row applies to the
  /// rest.
  final List<LevelBand> levelBands;

  /// Gear slot to the level it opens at, in display order.
  final Map<String, int> gearSlots;

  /// Titles by level, lowest first; the first is held from level 1.
  final List<RankDef> ranks;

  /// One talent point per level from this level on.
  final int talentPointsFrom;

  /// Queue size from a level on, lowest level first; the first is level 1
  /// (spec 0003 §2).
  final Map<int, int> queueSlots;

  /// Level from which "until I have N" and "until N crafted" open.
  final int untilFromLevel;

  /// Share of a monster's XP a loss pays, times the health knocked off.
  final double lossXpShare;

  /// Losses in a row that end a fight action.
  final int lossesToGiveUp;

  /// How many reports the app's journal keeps (spec 0004 decision 2).
  final int journalEntries;

  /// Gear qualities, common first (spec 0005 §2).
  final List<QualityDef> qualities;

  /// How much each level above an item raises the better qualities' chances,
  /// and for how many levels at most (spec 0005 §3).
  final double qualityPerLevel;
  final int qualityMaxLevels;

  /// Separates an item id from its quality in inventory and equipment keys:
  /// `bone_sword@rare`. Common gear and materials use the plain id.
  static const qualityMark = '@';

  /// The item a key stands for.
  ItemDef? itemOf(String key) => items[key.split(qualityMark).first];

  /// The quality of a key; common when it names none.
  QualityDef qualityOf(String key) {
    final parts = key.split(qualityMark);
    if (parts.length < 2) return qualities.first;
    return qualities.firstWhere((q) => q.id == parts[1]);
  }

  /// The key for [item] of [quality] (a quality id).
  String keyFor(String item, String quality) =>
      quality == qualities.first.id ? item : '$item$qualityMark$quality';

  /// An item's stats with its quality: each stat it has becomes
  /// `max(round(stat × (1 + bonus)), stat + tier)` (spec 0005 decision 7).
  Stats bonusOf(String key) {
    final base = itemOf(key)!.bonus;
    final q = qualityOf(key);
    final tier = qualities.indexOf(q);
    int up(int v) => v == 0 || tier == 0
        ? v
        : math.max((v * (1 + q.bonus)).round(), v + tier);
    return Stats(
      hp: up(base.hp),
      attack: up(base.attack),
      defense: up(base.defense),
    );
  }

  /// How a key ranks against other gear for the same slot, quality included.
  int scoreOf(String key) {
    final b = bonusOf(key);
    return b.attack * 5 + b.defense * 3 + b.hp;
  }

  final String startLocation;
  final Map<String, LocationDef> locations;
  final List<RouteDef> routes;
  final Map<String, NodeDef> nodes;
  final Map<String, EnemyDef> enemies;
  final Map<String, ItemDef> items;
  final Map<String, RecipeDef> recipes;
  final Map<String, AchievementDef> achievements;

  /// [xpToReachLevel], extended on demand past its end.
  late final List<int> _thresholds = List.of(xpToReachLevel);

  int xpForLevel(int level) {
    while (_thresholds.length < level) {
      final n = _thresholds.length;
      final cost = _thresholds[n - 1] - _thresholds[n - 2];
      _thresholds.add(_thresholds[n - 1] + (cost * xpGrowthAfterList).round());
    }
    return _thresholds[level - 1];
  }

  int levelForXp(int xp) {
    var level = 1;
    while (xp >= xpForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  /// The colour row for something at [level], seen by a player at
  /// [playerLevel].
  LevelBand bandFor(int level, int playerLevel) {
    final diff = level - playerLevel;
    return levelBands.firstWhere(
      (b) => b.atLeast == null || diff >= b.atLeast!,
    );
  }

  RouteDef? route(String from, String to) {
    for (final r in routes) {
      if ((r.from == from && r.to == to) || (r.from == to && r.to == from)) {
        return r;
      }
    }
    return null;
  }

  /// Destinations reachable from [from], in data order.
  Iterable<String> destinationsFrom(String from) => routes
      .where((r) => r.from == from || r.to == from)
      .map((r) => r.from == from ? r.to : r.from);

  void _validate() {
    void check(bool ok, String message) {
      if (!ok) throw FormatException('Invalid game data: $message');
    }

    check(
      xpToReachLevel.length >= 2 && xpToReachLevel.first == 0,
      'xpToReachLevel must start with 0 and list at least 2 levels',
    );
    check(xpGrowthAfterList >= 1, 'xpGrowthAfterList must be >= 1');
    check(
      levelBands.isNotEmpty && levelBands.last.atLeast == null,
      'levelBands must end with a row without atLeast',
    );
    for (var i = 1; i < levelBands.length - 1; i++) {
      check(
        levelBands[i].atLeast! < levelBands[i - 1].atLeast!,
        'levelBands must be ordered from the highest difference down',
      );
    }
    check(gearSlots.values.every((l) => l >= 1), 'gearSlots: levels >= 1');
    check(
      queueSlots.isNotEmpty && queueSlots.keys.first == 1,
      'queueSlots must start at level 1',
    );
    check(lossesToGiveUp >= 1, 'lossesToGiveUp must be >= 1');
    check(journalEntries >= 1, 'journalEntries must be >= 1');
    check(
      qualities.isNotEmpty && qualities.first.bonus == 0,
      'the first quality must be plain (bonus 0)',
    );
    check(
      (qualities.fold(0.0, (t, q) => t + q.chance) - 1).abs() < 1e-9,
      'quality chances must add up to 1',
    );
    for (var i = 1; i < qualities.length; i++) {
      check(
        qualities[i].bonus > qualities[i - 1].bonus,
        'qualities must get better in order',
      );
    }
    check(
      ranks.isNotEmpty && ranks.first.level == 1,
      'ranks must start at level 1',
    );
    for (var i = 1; i < ranks.length; i++) {
      check(ranks[i].level > ranks[i - 1].level, 'ranks must be in order');
    }
    for (final i in items.values) {
      check(
        i.slot == null || gearSlots.containsKey(i.slot),
        'item ${i.id}: unknown slot ${i.slot}',
      );
    }
    for (var i = 1; i < xpToReachLevel.length; i++) {
      check(
        xpToReachLevel[i] > xpToReachLevel[i - 1],
        'xpToReachLevel must increase',
      );
    }
    check(
      locations.containsKey(startLocation),
      'unknown startLocation $startLocation',
    );
    for (final l in locations.values) {
      for (final e in l.enemies) {
        check(enemies.containsKey(e), 'location ${l.id}: unknown enemy $e');
      }
      for (final n in l.nodes) {
        check(nodes.containsKey(n), 'location ${l.id}: unknown node $n');
      }
    }
    for (final r in routes) {
      check(
        locations.containsKey(r.from) && locations.containsKey(r.to),
        'route ${r.from}-${r.to}: unknown location',
      );
      check(r.steps > 0, 'route ${r.from}-${r.to}: steps must be > 0');
    }
    for (final n in nodes.values) {
      check(items.containsKey(n.item), 'node ${n.id}: unknown item ${n.item}');
      check(n.steps > 0, 'node ${n.id}: steps must be > 0');
    }
    for (final e in enemies.values) {
      check(e.level >= 1, 'enemy ${e.id}: level must be >= 1');
      check(
        e.has(Trait.regenerates) == (e.regen > 0),
        'enemy ${e.id}: regen is set exactly when it regenerates',
      );
      for (final d in [...e.drops, ...e.firstKillDrops]) {
        check(
          items.containsKey(d.item),
          'enemy ${e.id}: unknown drop ${d.item}',
        );
      }
    }
    for (final r in recipes.values) {
      check(items.containsKey(r.output), 'recipe ${r.id}: unknown output');
      check(r.steps > 0, 'recipe ${r.id}: steps must be > 0');
      for (final i in r.inputs.keys) {
        check(items.containsKey(i), 'recipe ${r.id}: unknown input $i');
      }
    }
    check(combatRoundSteps > 0, 'combatRoundSteps must be > 0');
  }
}

Map<String, T> _byId<T>(Iterable<T> defs, String Function(T) id) =>
    Map.unmodifiable({for (final d in defs) id(d): d});

Map<String, Object?> _map(Map<String, Object?> j, String key) =>
    j[key] as Map<String, Object?>;

Iterable<Map<String, Object?>> _maps(Map<String, Object?> j, String key) =>
    (j[key] as List<Object?>? ?? const []).cast<Map<String, Object?>>();

List<String> _strList(Map<String, Object?> j, String key) =>
    List.unmodifiable((j[key] as List<Object?>? ?? const []).cast<String>());

String _str(Map<String, Object?> j, String key) => j[key] as String;

int _int(Map<String, Object?> j, String key) => j[key] as int;

int _intOr(Map<String, Object?> j, String key, [int fallback = 0]) =>
    j[key] as int? ?? fallback;
