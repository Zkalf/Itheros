import 'dart:convert';
import 'dart:math' as math;

/// Character stats. Also used for gear bonuses and per-level growth. [crit],
/// [hit], [dodge] and [block] are percent points (spec 0009 §2.2).
class Stats {
  const Stats({
    this.hp = 0,
    this.attack = 0,
    this.defense = 0,
    this.crit = 0,
    this.hit = 0,
    this.dodge = 0,
    this.block = 0,
  });

  factory Stats.fromJson(Map<String, Object?> json) => Stats(
    hp: _intOr(json, 'hp'),
    attack: _intOr(json, 'attack'),
    defense: _intOr(json, 'defense'),
    crit: _intOr(json, 'crit'),
    hit: _intOr(json, 'hit'),
    dodge: _intOr(json, 'dodge'),
    block: _intOr(json, 'block'),
  );

  final int hp;
  final int attack;
  final int defense;
  final int crit;
  final int hit;
  final int dodge;
  final int block;

  Stats _zip(Stats o, int Function(int, int) f) => Stats(
    hp: f(hp, o.hp),
    attack: f(attack, o.attack),
    defense: f(defense, o.defense),
    crit: f(crit, o.crit),
    hit: f(hit, o.hit),
    dodge: f(dodge, o.dodge),
    block: f(block, o.block),
  );

  Stats operator +(Stats o) => _zip(o, (a, b) => a + b);

  Stats operator -(Stats o) => _zip(o, (a, b) => a - b);

  Stats operator *(int n) => _zip(this, (a, _) => a * n);

  @override
  String toString() =>
      'Stats(hp: $hp, attack: $attack, defense: $defense, crit: $crit, '
      'hit: $hit, dodge: $dodge, block: $block)';
}

/// The combat numbers of spec 0009 §2.1 and the type table of §3, from
/// `economy.json`. Chances are percent points.
class CombatRules {
  CombatRules._(Map<String, Object?> j)
    : hitBase = _int(j, 'hitBase'),
      hitPerLevel = _int(j, 'hitPerLevel'),
      hitMin = _int(j, 'hitMin'),
      hitMax = _int(j, 'hitMax'),
      critBase = _int(j, 'critBase'),
      critDamage = (j['critDamage'] as num).toDouble(),
      blockShare = (j['blockShare'] as num).toDouble(),
      critCap = _int(j, 'critCap'),
      blockCap = _int(j, 'blockCap'),
      dodgeCap = _int(j, 'dodgeCap'),
      slayerKills = _int(j, 'slayerKills'),
      slayerHit = _int(j, 'slayerHit'),
      typeFactors = Map.unmodifiable(
        _map(j, 'typeFactors').map(
          (armour, row) => MapEntry(
            armour,
            Map<String, double>.unmodifiable(
              (row as Map<String, Object?>).map(
                (type, f) => MapEntry(type, (f as num).toDouble()),
              ),
            ),
          ),
        ),
      );

  final int hitBase;
  final int hitPerLevel;
  final int hitMin;
  final int hitMax;
  final int critBase;

  /// A crit's damage, times a normal hit's.
  final double critDamage;

  /// A blocked hit's share of the damage.
  final double blockShare;
  final int critCap;
  final int blockCap;
  final int dodgeCap;

  /// Kills of a monster that earn Slayer, and the Hit it gives against that
  /// monster (spec 0009 §7.1).
  final int slayerKills;
  final int slayerHit;

  /// Armour type -> damage type -> damage factor.
  final Map<String, Map<String, double>> typeFactors;

  Iterable<String> get armourTypes => typeFactors.keys;

  Set<String> get damageTypes => {
    for (final row in typeFactors.values) ...row.keys,
  };

  /// The attacker's chance to hit, in percent: base, plus per level above
  /// the defender, plus Hit, kept within the bounds.
  int hitChance(int levelDiff, int hit) =>
      (hitBase + hitPerLevel * levelDiff + hit).clamp(hitMin, hitMax);

  /// The damage factor of [damageType] against [armour]; bare hands (null)
  /// are neutral.
  double typeFactor(String? damageType, String armour) =>
      damageType == null ? 1 : typeFactors[armour]![damageType]!;

  /// The damage type that hits [armour] hardest.
  String strongAgainst(String armour) => typeFactors[armour]!.entries
      .reduce((a, b) => a.value >= b.value ? a : b)
      .key;
}

/// One bonus stat roll on a piece of gear (spec 0009 §5): `crit` 3.
typedef BonusRoll = ({String stat, int value});

/// The bonus stats gear of an item level up to [upToLevel] (null: any) can
/// roll, each with its value range (spec 0009 §5.1).
class BonusTier {
  BonusTier._(Map<String, Object?> j)
    : upToLevel = j['upToLevel'] as int?,
      ranges = Map.unmodifiable({
        for (final stat in GameData.bonusStats)
          if (j[stat] case [final int lo, final int hi]) stat: (lo, hi),
      });

  final int? upToLevel;
  final Map<String, (int, int)> ranges;
}

class LocationDef {
  LocationDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      name = _str(j, 'name'),
      crafting = j['crafting'] as bool? ?? false,
      enemies = _strList(j, 'enemies'),
      nodes = _strList(j, 'nodes'),
      flavour = j['flavour'] as String?,
      map = switch (j['map']) {
        final Map<String, Object?> m => MapPoint.fromJson(m),
        _ => null,
      };

  final String id;
  final String name;
  final bool crafting;
  final List<String> enemies;
  final List<String> nodes;

  /// One line shown the first time the area appears (spec 0002 §9.5).
  final String? flavour;

  /// Where the area is drawn on the map (spec 0006 decision 4).
  final MapPoint? map;
}

/// A point on the map: 0-1 across its width ([x]) and down its height ([y]).
class MapPoint {
  const MapPoint(this.x, this.y);

  factory MapPoint.fromJson(Map<String, Object?> j) =>
      MapPoint((j['x'] as num).toDouble(), (j['y'] as num).toDouble());

  final double x;
  final double y;
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
      level = _int(j, 'level'),
      steps = _int(j, 'steps'),
      item = _str(j, 'item'),
      xp = _int(j, 'xp');

  final String id;
  final String name;

  /// The player level it can be worked from (spec 0008 amendment 1), also
  /// its level for the XP fade.
  final int level;
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
      level = _int(j, 'level'),
      stats = Stats.fromJson(j),
      armour = _str(j, 'armour'),
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

  /// The monster's own level, which sets its colour (spec 0002 §3).
  final int level;

  /// Its Dodge is in [stats]; it has no Crit, Hit or Block (spec 0009
  /// decision 7).
  final Stats stats;

  /// light, medium or heavy (spec 0009 §3).
  final String armour;
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
      twoHanded = j['twoHanded'] as bool? ?? false,
      damageType = j['damageType'] as String?,
      armourType = j['armourType'] as String?,
      bonus = Stats.fromJson(j);

  final String id;
  final String name;

  /// The kind of slot it is worn in (a [GearSlotDef.kind]), or null for
  /// materials.
  final String? slot;

  /// A main-hand weapon that also fills the off hand (spec 0008 §2.1).
  final bool twoHanded;

  /// A weapon's slash, pierce or crush (spec 0009 §4).
  final String? damageType;

  /// An armour piece's light, medium or heavy (spec 0009 §6).
  final String? armourType;
  final Stats bonus;

  /// How it ranks against other gear for the same slot.
  int get score => GameData.scoreStats(bonus);
}

class RecipeDef {
  RecipeDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      level = _int(j, 'level'),
      steps = _int(j, 'steps'),
      xp = _int(j, 'xp'),
      inputs = (j['inputs'] as Map<String, Object?>).map(
        (k, v) => MapEntry(k, v as int),
      ),
      output = _str(j, 'output');

  final String id;

  /// Sets its XP fade and the item level of its quality roll; not a gate
  /// (spec 0008 amendment 1).
  final int level;
  final int steps;
  final int xp;
  final Map<String, int> inputs;
  final String output;
}

/// A place on the paper doll (spec 0008 §2.1). Items of [kind] fit it.
class GearSlotDef {
  GearSlotDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      kind = j['kind'] as String? ?? _str(j, 'id');

  final String id;
  final String kind;
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
       gearSlots = List.unmodifiable(
         _maps(economy, 'gearSlots').map(GearSlotDef._),
       ),
       ranks = List.unmodifiable(_maps(economy, 'ranks').map(RankDef._)),
       talentPointsFrom = _int(economy, 'talentPointsFrom'),
       queueSlots = _int(economy, 'queueSlots'),
       lossXpShare = (economy['lossXpShare'] as num).toDouble(),
       lossesToGiveUp = _int(economy, 'lossesToGiveUp'),
       journalEntries = _int(economy, 'journalEntries'),
       qualities = List.unmodifiable(
         _maps(economy, 'qualities').map(QualityDef._),
       ),
       qualityPerLevel = (economy['qualityPerLevel'] as num).toDouble(),
       qualityMaxLevels = _int(economy, 'qualityMaxLevels'),
       fightLogRounds = _int(economy, 'fightLogRounds'),
       combat = CombatRules._(_map(economy, 'combat')),
       bonusTiers = List.unmodifiable(
         _maps(economy, 'bonusStats').map(BonusTier._),
       ),
       startLocation = _str(world, 'startLocation'),
       mapAspect = (world['mapAspect'] as num? ?? 1).toDouble(),
       mapRiver = List.unmodifiable(
         _maps(world, 'mapRiver').map(MapPoint.fromJson),
       ),
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

    for (final name in ['world', 'enemies', 'items']) {
      if (files[name]?.contains('"unlockLevel"') ?? false) {
        throw FormatException(
          'Invalid game data: $name.json has an unlockLevel (spec 0008)',
        );
      }
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

  /// The paper doll's slots, in display order.
  final List<GearSlotDef> gearSlots;

  /// The slot ids that items of [kind] fit, in display order.
  List<String> slotsOfKind(String kind) => [
    for (final g in gearSlots)
      if (g.kind == kind) g.id,
  ];

  /// Titles by level, lowest first; the first is held from level 1.
  final List<RankDef> ranks;

  /// One talent point per level from this level on.
  final int talentPointsFrom;

  /// Actions the queue holds, the running one included (spec 0008
  /// decision 7).
  final int queueSlots;

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

  /// Fight rounds the running action remembers (spec 0006 decision 8).
  final int fightLogRounds;

  /// Hit, crit, block and the type table (spec 0009 §2–§3).
  final CombatRules combat;

  /// Bonus stat pools by item level, lowest first (spec 0009 §5.1).
  final List<BonusTier> bonusTiers;

  /// The bonus stats, in the order a key lists them.
  static const bonusStats = ['crit', 'hp', 'hit', 'dodge', 'block'];

  /// The pool of gear of [itemLevel].
  BonusTier bonusTierFor(int itemLevel) => bonusTiers.firstWhere(
    (t) => t.upToLevel == null || itemLevel <= t.upToLevel!,
  );

  /// The level [item] is made or found at: its recipe's, else the lowest
  /// monster dropping it, else 1 (spec 0005 decision 2).
  int itemLevel(String item) {
    if (recipes.values.where((r) => r.output == item).firstOrNull
        case final r?) {
      return r.level;
    }
    final droppers = [
      for (final e in enemies.values)
        if ([...e.drops, ...e.firstKillDrops].any((d) => d.item == item))
          e.level,
    ];
    return droppers.isEmpty ? 1 : droppers.reduce(math.min);
  }

  /// Separates an item id from its quality in inventory and equipment keys:
  /// `bone_sword@rare`. Common gear and materials use the plain id.
  static const qualityMark = '@';

  /// Comes before each bonus stat roll in a key, in [bonusStats] order and
  /// highest value first: `bone_sword@rare+crit3+hp12` (spec 0009 §5.3).
  static const bonusMark = '+';

  /// A key without its bonus stats: `bone_sword@rare`.
  String plainKey(String key) => key.split(bonusMark).first;

  /// The item a key stands for.
  ItemDef? itemOf(String key) => items[plainKey(key).split(qualityMark).first];

  /// The quality of a key; common when it names none, or one the data no
  /// longer has (an old save must still load).
  QualityDef qualityOf(String key) {
    final parts = plainKey(key).split(qualityMark);
    if (parts.length < 2) return qualities.first;
    return qualities.firstWhere(
      (q) => q.id == parts[1],
      orElse: () => qualities.first,
    );
  }

  /// A key's bonus stat rolls, in key order; unknown ones are skipped.
  List<BonusRoll> bonusRolls(String key) => [
    for (final part in key.split(bonusMark).skip(1))
      if (_roll.firstMatch(part) case final m? when bonusStats.contains(m[1]))
        (stat: m[1]!, value: int.parse(m[2]!)),
  ];

  static final _roll = RegExp(r'^([a-z]+)(\d+)$');

  /// The key for [item] of [quality] (a quality id) with [bonus] rolls, in
  /// any order: the same rolls always make the same key.
  String keyFor(
    String item,
    String quality, [
    List<BonusRoll> bonus = const [],
  ]) {
    final sorted = [...bonus]
      ..sort((a, b) {
        final byStat = bonusStats
            .indexOf(a.stat)
            .compareTo(bonusStats.indexOf(b.stat));
        return byStat != 0 ? byStat : b.value.compareTo(a.value);
      });
    return [
      quality == qualities.first.id ? item : '$item$qualityMark$quality',
      for (final r in sorted) '${r.stat}${r.value}',
    ].join(bonusMark);
  }

  /// An item's stats with its quality and bonus stats. Quality raises each
  /// base HP, Attack and Defense to `max(round(stat × (1 + bonus)), stat +
  /// tier)` (spec 0005 decision 7); the rolls add on top (spec 0009 §5.2).
  Stats bonusOf(String key) => _bonusCache[key] ??= _bonusOf(key);

  final _bonusCache = <String, Stats>{};

  Stats _bonusOf(String key) {
    var rolled = const Stats();
    for (final r in bonusRolls(key)) {
      rolled += Stats.fromJson({r.stat: r.value});
    }
    return _qualityStats(key) + rolled;
  }

  Stats _qualityStats(String key) {
    final base = itemOf(key)?.bonus ?? const Stats();
    final q = qualityOf(key);
    final tier = qualities.indexOf(q);
    int up(int v) => v == 0 || tier == 0
        ? v
        : math.max((v * (1 + q.bonus)).round(), v + tier);
    // Quality doesn't raise Crit, Hit, Dodge or Block (spec 0009 §5.2).
    return Stats(
      hp: up(base.hp),
      attack: up(base.attack),
      defense: up(base.defense),
      crit: base.crit,
      hit: base.hit,
      dodge: base.dodge,
      block: base.block,
    );
  }

  /// How a key ranks against other gear for the same slot, quality included.
  int scoreOf(String key) => scoreStats(bonusOf(key));

  /// Every stat weighed (spec 0009 §5.3).
  static int scoreStats(Stats b) =>
      b.attack * 5 +
      b.defense * 3 +
      b.hp +
      (b.crit + b.hit + b.block) * 2 +
      b.dodge * 3;

  final String startLocation;

  /// The map's height as a share of its width.
  final double mapAspect;

  /// The river, as a line through these points (spec 0006 §2.2).
  final List<MapPoint> mapRiver;
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
    check(
      gearSlots.map((g) => g.id).toSet().length == gearSlots.length,
      'gearSlots: ids must be unique',
    );
    check(queueSlots >= 1, 'queueSlots must be >= 1');
    // The two-hand rule names these slots (spec 0008 §2.1).
    check(
      slotsOfKind('mainHand').contains('mainHand') &&
          slotsOfKind('offHand').contains('offHand'),
      'gearSlots must have mainHand and offHand',
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
        i.slot == null || slotsOfKind(i.slot!).isNotEmpty,
        'item ${i.id}: unknown slot ${i.slot}',
      );
      check(
        !i.twoHanded || i.slot == 'mainHand',
        'item ${i.id}: only main-hand items can be two-handed',
      );
      check(
        (i.slot == 'mainHand') == (i.damageType != null) &&
            (i.damageType == null || combat.damageTypes.contains(i.damageType)),
        'item ${i.id}: every weapon, and only a weapon, has a damage type',
      );
      check(
        i.armourType == null || combat.armourTypes.contains(i.armourType),
        'item ${i.id}: unknown armour type ${i.armourType}',
      );
      // Block comes only from the off hand (spec 0009 §2.1).
      check(
        i.bonus.block == 0 || i.slot == 'offHand',
        'item ${i.id}: only off-hand items have Block',
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
        combat.armourTypes.contains(e.armour),
        'enemy ${e.id}: unknown armour ${e.armour}',
      );
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
    for (final row in combat.typeFactors.values) {
      check(
        row.keys.toSet().containsAll(combat.damageTypes),
        'typeFactors: every armour needs a factor for every damage type',
      );
    }
    check(combat.hitMin <= combat.hitMax, 'combat: hitMin must be <= hitMax');
    check(
      bonusTiers.isNotEmpty && bonusTiers.last.upToLevel == null,
      'bonusStats must end with a tier without upToLevel',
    );
    for (var i = 0; i < bonusTiers.length; i++) {
      final t = bonusTiers[i];
      check(t.ranges.isNotEmpty, 'bonusStats: every tier needs a stat');
      check(
        t.ranges.values.every((r) => 0 < r.$1 && r.$1 <= r.$2),
        'bonusStats: ranges must be 0 < low <= high',
      );
      check(
        i == 0 ||
            t.upToLevel == null ||
            t.upToLevel! > bonusTiers[i - 1].upToLevel!,
        'bonusStats: tiers must go up in level',
      );
    }
    check(fightLogRounds > 0, 'fightLogRounds must be > 0');
    for (final p in [...mapRiver, for (final l in locations.values) ?l.map]) {
      check(
        p.x >= 0 && p.x <= 1 && p.y >= 0 && p.y <= 1,
        'map points must be within 0-1',
      );
    }
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
