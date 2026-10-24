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
      studyKills = _int(j, 'studyKills'),
      loreChance = (j['loreChance'] as num).toDouble(),
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

  /// Kills of a monster that show its weakness and stats (spec 0009 §7.1).
  final int studyKills;

  /// The chance a kill drops its monster's lore note, until found (§7.2).
  final double loreChance;

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
      fire = j['fire'] as bool? ?? false,
      hidden = j['hidden'] as bool? ?? false,
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

  /// A camp fire: cooking happens only here (spec 0011 §5.1).
  final bool fire;

  /// Off the map, out of every list and route until revealed (spec 0011
  /// §6.2).
  final bool hidden;
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
      profession = _str(j, 'profession'),
      rareFind = j['rareFind'] as String?,
      rareBase = (j['rareBase'] as num?)?.toDouble(),
      rareAnimal = j['rareAnimal'] as String?,
      rareWith = _strList(j, 'rareWith'),
      catches = List.unmodifiable(_maps(j, 'catches').map(CatchDef._)),
      bottle = j['bottle'] as bool? ?? false,
      chest = j['chest'] as String?,
      xp = _int(j, 'xp');

  final String id;
  final String name;

  /// The profession that works it (spec 0010 §2.1).
  final String profession;

  /// The rare item each action may find (spec 0010 §5.1). At a spot with
  /// [catches] it is the table's top row: a trophy (spec 0011 §3.2, §4).
  final String? rareFind;

  /// The spot's own base chance for [rareFind], if not the usual one.
  final double? rareBase;

  /// The rare animal tracked to get [rareFind], for its news.
  final String? rareAnimal;

  /// Items that come with [rareFind]: a rare animal's meat (spec 0011 §4).
  final List<String> rareWith;

  /// The fish or animals one action rolls from, besides [item] (spec 0011
  /// §3.2, §4); empty for veins and trees.
  final List<CatchDef> catches;

  /// Each action rolls for a message in a bottle (spec 0011 §3.3).
  final bool bottle;

  /// The item a sunken chest holds, rolled for each action (§6.3).
  final String? chest;

  /// The profession level it can be worked from, also its level for the
  /// profession fade (spec 0010 §2.2).
  final int level;
  final int steps;
  final String item;

  /// Profession XP per action (spec 0010 §2.2).
  final int xp;

  /// About how many [item]s one action gives, the rare find left out: 1 for
  /// [item], a row's chance for a catch.
  double yieldOf(String what) {
    if (what == item) return 1;
    final rest = 1 - catches.fold(0.0, (t, c) => t + (c.chance ?? 0));
    return catches
        .where((c) => c.item == what)
        .fold(0.0, (t, c) => t + (c.chance ?? rest));
  }
}

/// A row of a spot's catch table: the fish or the meat of an animal. The
/// row without a [chance] takes what the others leave (spec 0011 §3.2, §4).
class CatchDef {
  CatchDef._(Map<String, Object?> j)
    : item = _str(j, 'item'),
      animal = j['animal'] as String?,
      chance = (j['chance'] as num?)?.toDouble();

  final String item;
  final String? animal;
  final double? chance;
}

/// What makes an item a meal: its tier and buffs (spec 0011 §5.2).
class MealDef {
  MealDef._(Map<String, Object?> j)
    : tier = _int(j, 'tier'),
      buffs = _strList(j, 'buffs');

  final int tier;

  /// hp, attack, defense, crit or steps; a feast has two.
  final List<String> buffs;

  static const kinds = {'hp', 'attack', 'defense', 'crit', 'steps'};
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

/// A lore note (spec 0009 §7.2): dropped by one monster, it tells the armour
/// and weakness of the monster it is [about].
class LoreDef {
  LoreDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      about = _str(j, 'about'),
      title = _str(j, 'title'),
      text = _str(j, 'text');

  final String id;
  final String about;
  final String title;
  final String text;
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
      lore = switch (j['lore']) {
        final Map<String, Object?> m => LoreDef._(m),
        _ => null,
      },
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

  /// The note it may drop (spec 0009 §7.2).
  final LoreDef? lore;

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
      rare = j['rare'] as bool? ?? false,
      reference = j['reference'] as bool? ?? true,
      level = j['level'] as int?,
      weight = switch (j['weight']) {
        [final num lo, final num hi] => (lo.toDouble(), hi.toDouble()),
        _ => null,
      },
      meal = switch (j['meal']) {
        final Map<String, Object?> m => MealDef._(m),
        _ => null,
      },
      tool = switch (j['tool']) {
        final Map<String, Object?> t => ToolDef._(t),
        _ => null,
      },
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

  /// Set for a profession's tool (spec 0010 §3).
  final ToolDef? tool;

  /// A rare find or a boss shard (spec 0010 §5, §7.1): recipes using one
  /// roll on the profession stream and aren't the reference player's gear.
  final bool rare;

  /// False for gear the spec 0002 reference player never wears: the hide,
  /// scale and trophy pieces (spec 0011 §7). Their crafts roll on the
  /// profession stream.
  final bool reference;

  /// Its item level when no recipe or monster gives one (spec 0011 §6.3).
  final int? level;

  /// A fish's weight range in kg (spec 0011 §3.4).
  final (double, double)? weight;

  /// Set for a meal (spec 0011 §5.2).
  final MealDef? meal;
  final Stats bonus;

  /// How it ranks against other gear for the same slot.
  int get score => GameData.scoreStats(bonus);
}

/// What makes an item a tool (spec 0010 §3).
class ToolDef {
  ToolDef._(Map<String, Object?> j)
    : profession = _str(j, 'profession'),
      stepFactor = (j['stepFactor'] as num).toDouble(),
      starter = j['starter'] as bool? ?? false;

  final String profession;

  /// The share of an action's steps it costs at Common quality.
  final double stepFactor;

  /// A teacher's gift: it can't be salvaged (spec 0010 §3.1).
  final bool starter;
}

/// A profession's teacher in camp (spec 0010 §6).
class TeacherDef {
  TeacherDef._(Map<String, Object?> j)
    : name = _str(j, 'name'),
      title = _str(j, 'title'),
      location = _str(j, 'location'),
      starterTool = _str(j, 'starterTool'),
      learnLine = _str(j, 'learnLine'),
      greeting = _str(j, 'greeting'),
      kinLine = _str(j, 'kinLine'),
      tips = List.unmodifiable(_maps(j, 'tips').map(TipDef._));

  final String name;
  final String title;
  final String location;
  final String starterTool;
  final String learnLine;

  /// What they say to a player of another origin, and to one of theirs in
  /// place of [learnLine] (spec 0012 §3.1).
  final String greeting;
  final String kinLine;

  /// Lowest level first (spec 0010 §6.2).
  final List<TipDef> tips;
}

/// A teacher's tip about [enemy], told from profession [level]: it reveals
/// the monster's armour and weakness (spec 0010 §6.2).
class TipDef {
  TipDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      level = _int(j, 'level'),
      enemy = _str(j, 'enemy'),
      title = _str(j, 'title'),
      text = _str(j, 'text');

  final String id;
  final int level;
  final String enemy;
  final String title;
  final String text;
}

/// A material tier of a profession, open from [level] (spec 0010 §2.1).
class TierDef {
  TierDef._(Map<String, Object?> j)
    : level = _int(j, 'level'),
      name = _str(j, 'name');

  final int level;
  final String name;
}

class ProfessionDef {
  ProfessionDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      name = _str(j, 'name'),
      icon = _str(j, 'icon'),
      toolName = _str(j, 'tool'),
      tiers = List.unmodifiable(_maps(j, 'tiers').map(TierDef._)),
      teacher = TeacherDef._(_map(j, 'teacher'));

  final String id;
  final String name;
  final String icon;

  /// What its tool slot is called: Pickaxe.
  final String toolName;

  /// Lowest first.
  final List<TierDef> tiers;
  final TeacherDef teacher;

  List<TipDef> get tips => teacher.tips;

  /// The tier held at profession [level].
  TierDef tierAt(int level) => tiers.lastWhere((t) => t.level <= level);
}

class RecipeDef {
  RecipeDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      level = _int(j, 'level'),
      craftingLevel = _intOr(j, 'crafting', _int(j, 'level')),
      steps = _int(j, 'steps'),
      xp = _int(j, 'xp'),
      profession = j['profession'] as String? ?? 'crafting',
      inputs = (j['inputs'] as Map<String, Object?>).map(
        (k, v) => MapEntry(k, v as int),
      ),
      output = _str(j, 'output');

  final String id;

  /// Its level for the profession fade and the item level of its quality
  /// roll; the Crafting level it needs unless [craftingLevel] says less
  /// (spec 0010 §2.2).
  final int level;

  /// The level of [profession] it needs: `crafting` in data, else [level].
  /// The first recipes need Crafting 1 (spec 0010 amendment 1).
  final int craftingLevel;

  /// Crafting's, or Cooking's for a meal (spec 0011 §5.1).
  final String profession;
  final int steps;

  /// Crafting XP per craft (spec 0010 §2.2).
  final int xp;
  final Map<String, int> inputs;
  final String output;
}

/// Where the character comes from (spec 0012 §2.1): [profession] starts at
/// [GameData.headStartLevel]. [title] may hold gendered words.
class OriginDef {
  OriginDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      title = _str(j, 'title'),
      line = _str(j, 'line'),
      profession = _str(j, 'profession');

  final String id;
  final String title;
  final String line;
  final String profession;
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
    required Map<String, Object?> professions,
    required Map<String, Object?> origins,
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
       professionXpToReachLevel = List.unmodifiable(
         (economy['professionXpToReachLevel'] as List<Object?>).cast<int>(),
       ),
       professionXpGrowthAfterList =
           (economy['professionXpGrowthAfterList'] as num).toDouble(),
       professionBands = List.unmodifiable(
         _maps(economy, 'professionBands').map(LevelBand._),
       ),
       professionShare = (economy['professionShare'] as num).toDouble(),
       toolQualityStep = (economy['toolQualityStep'] as num).toDouble(),
       rareBase = _num(_map(economy, 'rareFind'), 'base'),
       rarePerToolQualityStep = _num(
         _map(economy, 'rareFind'),
         'perToolQualityStep',
       ),
       rarePerLevelAbove = _num(_map(economy, 'rareFind'), 'perLevelAbove'),
       rareMaxLevelBonus = _num(_map(economy, 'rareFind'), 'maxLevelBonus'),
       shardBase = _num(_map(economy, 'salvage'), 'shardBase'),
       shardPerQualityStep = _num(
         _map(economy, 'salvage'),
         'shardPerQualityStep',
       ),
       shards = _strList(_map(economy, 'salvage'), 'shards'),
       rerollSteps = _int(_map(economy, 'reroll'), 'steps'),
       rerollDust = _int(_map(economy, 'reroll'), 'dust'),
       mealSteps = _int(_map(economy, 'meals'), 'steps'),
       mealPercent = List.unmodifiable(
         (_map(economy, 'meals')['percent'] as List<Object?>).cast<int>(),
       ),
       mealCrit = List.unmodifiable(
         (_map(economy, 'meals')['crit'] as List<Object?>).cast<int>(),
       ),
       perfectBase = _num(_map(economy, 'perfectDish'), 'base'),
       perfectPerToolQualityStep = _num(
         _map(economy, 'perfectDish'),
         'perToolQualityStep',
       ),
       perfectPerLevelAbove = _num(
         _map(economy, 'perfectDish'),
         'perLevelAbove',
       ),
       perfectMaxLevelBonus = _num(
         _map(economy, 'perfectDish'),
         'maxLevelBonus',
       ),
       bottleChance = _num(_map(economy, 'bottle'), 'chance'),
       bottleReveals = _str(_map(economy, 'bottle'), 'reveals'),
       bottleLater = _str(_map(economy, 'bottle'), 'later'),
       chestChance = _num(economy, 'chestChance'),
       fightXpPerStepList = List.unmodifiable([
         for (final v in economy['fightXpPerStep'] as List<Object?>)
           (v! as num).toDouble(),
       ]),
       levelBands = List.unmodifiable(
         _maps(economy, 'levelBands').map(LevelBand._),
       ),
       gearSlots = List.unmodifiable(
         _maps(economy, 'gearSlots').map(GearSlotDef._),
       ),
       ranks = List.unmodifiable(_maps(economy, 'ranks').map(RankDef._)),
       talentPointsFrom = _int(economy, 'talentPointsFrom'),
       queueSlots = _int(economy, 'queueSlots'),
       headStartLevel = _int(economy, 'headStartLevel'),
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
       ),
       professions = _byId(
         _maps(professions, 'professions').map(ProfessionDef._),
         (d) => d.id,
       ),
       origins = _byId(
         _maps(origins, 'origins').map(OriginDef._),
         (d) => d.id,
       ) {
    _validate();
  }

  /// [files] maps a data file name without extension (`economy`, `world`,
  /// `enemies`, `items`, `achievements`, `professions`, `origins`) to its
  /// JSON text.
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
      professions: file('professions'),
      origins: file('origins'),
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

  /// Total profession XP needed to reach level `i + 1`, and the growth of
  /// each level's cost past the list (spec 0010 §2.2).
  final List<int> professionXpToReachLevel;
  final double professionXpGrowthAfterList;

  /// The profession fade by action level against profession level, like
  /// [levelBands] (spec 0010 §2.3).
  final List<LevelBand> professionBands;

  /// A profession step's share of a fight step's character XP (spec 0010
  /// §2.4).
  final double professionShare;

  /// The share of an action's steps each tool quality step takes off
  /// (spec 0010 §3.2).
  final double toolQualityStep;

  /// The rare-find chance per gathering action and its nudges: per tool
  /// quality step, per profession level above the spot, and the cap of the
  /// level nudge (spec 0010 §5.1).
  final double rareBase;
  final double rarePerToolQualityStep;
  final double rarePerLevelAbove;
  final double rareMaxLevelBonus;

  /// Salvage's boss shard chance and its rise per quality step; [shards]
  /// holds the shard of each bonus stat tier's boss (spec 0010 §7.1).
  final double shardBase;
  final double shardPerQualityStep;
  final List<String> shards;

  /// A reroll's forge steps and the dust it takes (spec 0010 §7.2).
  final int rerollSteps;
  final int rerollDust;

  /// How long a meal lasts, in action and travel steps; a perfect dish
  /// twice as long (spec 0011 §5.3).
  final int mealSteps;

  /// A stat buff's percent and a Crit buff's points, by meal tier from 1.
  final List<int> mealPercent;
  final List<int> mealCrit;

  /// A cook's perfect-dish chance and its nudges, as [rareBase] (§5.3).
  final double perfectBase;
  final double perfectPerToolQualityStep;
  final double perfectPerLevelAbove;
  final double perfectMaxLevelBonus;

  /// A cast's bottle chance; the area the first one reveals and the item
  /// each later one holds (spec 0011 §6.1).
  final double bottleChance;
  final String bottleReveals;
  final String bottleLater;

  /// A sunken chest's chance per cast where there is one (§6.3).
  final double chestChance;

  /// Marks a perfect dish's key: `grilled_perch@perfect` (spec 0011 §5.3).
  static const perfect = 'perfect';

  static String perfectKey(String meal) => '$meal$qualityMark$perfect';

  bool isPerfect(String key) =>
      plainKey(key).split(qualityMark).skip(1).firstOrNull == perfect;

  /// How long the meal with [key] lasts.
  int mealStepsOf(String key) => isPerfect(key) ? mealSteps * 2 : mealSteps;

  /// The profession the tool with [key] serves, or null for anything else.
  String? toolProfession(String key) => itemOf(key)?.tool?.profession;

  /// The dust salvage gives for [quality] (an id): `rare_dust`.
  static String dustOf(String quality) => '${quality}_dust';

  /// Comes before a Legendary's waiting stat roll in its key:
  /// `+~1.hit4` replaces roll 1 with Hit 4 once kept (spec 0010 §7.3).
  static const pendingMark = '~';

  static final _pending = RegExp(r'^~(\d+)\.([a-z]+)(\d+)$');

  /// A key's waiting stat roll, or null.
  ({int index, BonusRoll roll})? pendingRoll(String key) {
    for (final part in key.split(bonusMark).skip(1)) {
      if (_pending.firstMatch(part) case final m?) {
        return (
          index: int.parse(m[1]!),
          roll: (stat: m[2]!, value: int.parse(m[3]!)),
        );
      }
    }
    return null;
  }

  /// [key] with the waiting [roll] for stat [index].
  String withPending(String key, int index, BonusRoll roll) =>
      '$key$bonusMark$pendingMark$index.${roll.stat}${roll.value}';

  /// The bonus stat tier of [itemLevel], 0 first.
  int bonusTierIndex(int itemLevel) =>
      bonusTiers.indexOf(bonusTierFor(itemLevel));

  /// Character XP per step against even-level monsters, by character
  /// level from 1 (spec 0010 §2.4); see [fightXpPerStep].
  final List<double> fightXpPerStepList;

  /// [fightXpPerStepList] at [level], growing by [xpGrowthAfterList] past
  /// its end.
  double fightXpPerStep(int level) {
    final n = fightXpPerStepList.length;
    if (level <= n) return fightXpPerStepList[level - 1];
    return fightXpPerStepList[n - 1] *
        math.pow(xpGrowthAfterList, level - n).toDouble();
  }

  /// The paper doll's slots, in display order.
  final List<GearSlotDef> gearSlots;

  /// The slot ids that items of [kind] fit, in display order.
  List<String> slotsOfKind(String kind) => [
    for (final g in gearSlots)
      if (g.kind == kind) g.id,
  ];

  /// Titles by level, lowest first; the first is held from level 1.
  final List<RankDef> ranks;

  /// Origins in screen order (spec 0012 §2.1).
  final Map<String, OriginDef> origins;

  /// The level an origin's profession starts at (spec 0012 decision 1).
  final int headStartLevel;

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

  /// Every lore note, in data order.
  late final List<LoreDef> loreNotes = [
    for (final e in enemies.values) ?e.lore,
  ];

  /// The pool of gear of [itemLevel].
  BonusTier bonusTierFor(int itemLevel) => bonusTiers.firstWhere(
    (t) => t.upToLevel == null || itemLevel <= t.upToLevel!,
  );

  /// The level [item] is made or found at: its recipe's, else the lowest
  /// monster dropping it, else 1 (spec 0005 decision 2).
  int itemLevel(String item) {
    if (items[item]?.level case final l?) return l;
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
    return baseStatsOf(key) + rolled;
  }

  /// An item's stats with its quality, without its bonus stats: what list
  /// rows and the card's first line show (spec 0009 §8.2).
  Stats baseStatsOf(String key) {
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

  /// Mining, Woodcutting, Crafting, in screen order (spec 0010 §8.1).
  final Map<String, ProfessionDef> professions;

  /// [professionXpToReachLevel], extended on demand past its end.
  late final List<int> _professionThresholds = List.of(
    professionXpToReachLevel,
  );

  int professionXpForLevel(int level) =>
      _extend(_professionThresholds, level, professionXpGrowthAfterList);

  int professionLevelForXp(int xp) {
    var level = 1;
    while (xp >= professionXpForLevel(level + 1)) {
      level++;
    }
    return level;
  }

  /// The fade row for an action at [level], worked at profession level
  /// [professionLevel].
  LevelBand professionBandFor(int level, int professionLevel) {
    final diff = level - professionLevel;
    return professionBands.firstWhere(
      (b) => b.atLeast == null || diff >= b.atLeast!,
    );
  }

  /// [xpToReachLevel], extended on demand past its end.
  late final List<int> _thresholds = List.of(xpToReachLevel);

  int xpForLevel(int level) => _extend(_thresholds, level, xpGrowthAfterList);

  static int _extend(List<int> thresholds, int level, double growth) {
    while (thresholds.length < level) {
      final n = thresholds.length;
      final cost = thresholds[n - 1] - thresholds[n - 2];
      thresholds.add(thresholds[n - 1] + (cost * growth).round());
    }
    return thresholds[level - 1];
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
    check(queueSlots >= 2, 'queueSlots must be >= 2');
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
      check(
        professions.containsKey(n.profession),
        'node ${n.id}: unknown profession ${n.profession}',
      );
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
      if (e.lore case final note?) {
        check(
          enemies.containsKey(note.about) && note.about != e.id,
          'enemy ${e.id}: its lore note is about an unknown monster',
        );
      }
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
    check(
      professions.containsKey('crafting'),
      'professions: recipes need crafting',
    );
    for (final p in professions.values) {
      check(
        p.tiers.isNotEmpty && p.tiers.first.level == 1,
        'profession ${p.id}: tiers must start at level 1',
      );
      check(
        locations.containsKey(p.teacher.location),
        'profession ${p.id}: unknown teacher location',
      );
      check(
        items[p.teacher.starterTool]?.tool?.profession == p.id,
        'profession ${p.id}: the starter tool must be its tool',
      );
    }
    for (final o in origins.values) {
      check(
        professions.containsKey(o.profession),
        'origin ${o.id}: unknown profession ${o.profession}',
      );
    }
    check(
      origins.values.map((o) => o.profession).toSet().length == origins.length,
      'origins: one per profession',
    );
    check(headStartLevel >= 1, 'headStartLevel must be >= 1');
    // Lines the game fills for the player (spec 0012 §2.3).
    for (final line in [
      for (final o in origins.values) ...[o.title, o.line],
      for (final p in professions.values) ...[
        p.teacher.learnLine,
        p.teacher.greeting,
        p.teacher.kinLine,
        for (final t in p.tips) t.text,
      ],
      for (final r in ranks) r.line,
    ]) {
      for (final m in RegExp(r'\{([^{}]*)\}').allMatches(line)) {
        final t = m[1]!;
        check(
          t == 'name' || t.split('|').length == 3,
          'line "$line": {$t} needs {name} or three choices',
        );
      }
    }
    for (final i in items.values) {
      if (i.tool case final t?) {
        check(
          professions.containsKey(t.profession) && i.slot == null,
          'item ${i.id}: a tool needs a known profession and no gear slot',
        );
      }
    }
    check(
      professionXpToReachLevel.length >= 2 &&
          professionXpToReachLevel.first == 0,
      'professionXpToReachLevel must start with 0 and list at least 2 levels',
    );
    for (var i = 1; i < professionXpToReachLevel.length; i++) {
      check(
        professionXpToReachLevel[i] > professionXpToReachLevel[i - 1],
        'professionXpToReachLevel must increase',
      );
    }
    check(
      professionBands.isNotEmpty && professionBands.last.atLeast == null,
      'professionBands must end with a row without atLeast',
    );
    check(
      fightXpPerStepList.isNotEmpty && fightXpPerStepList.every((v) => v > 0),
      'fightXpPerStep must list positive numbers',
    );
    for (final n in nodes.values) {
      check(
        n.rareFind == null || items.containsKey(n.rareFind),
        'node ${n.id}: unknown rare find',
      );
      for (final i in [
        for (final c in n.catches) c.item,
        ...n.rareWith,
        ?n.chest,
      ]) {
        check(items.containsKey(i), 'node ${n.id}: unknown item $i');
      }
      check(
        n.catches.isEmpty ||
            n.catches.where((c) => c.chance == null).length == 1,
        'node ${n.id}: one catch row takes the rest',
      );
    }
    for (final i in items.values) {
      if (i.meal case final m?) {
        check(
          m.buffs.isNotEmpty && m.buffs.every(MealDef.kinds.contains),
          'item ${i.id}: unknown meal buff',
        );
        check(
          m.tier >= 1 &&
              m.tier <= mealPercent.length &&
              m.tier <= mealCrit.length,
          'item ${i.id}: meal tier out of range',
        );
      }
    }
    for (final r in recipes.values) {
      check(
        professions.containsKey(r.profession),
        'recipe ${r.id}: unknown profession ${r.profession}',
      );
      check(
        (r.profession == 'cooking') == (items[r.output]!.meal != null),
        'recipe ${r.id}: meals, and only meals, are cooked',
      );
    }
    for (final l in locations.values.where((l) => l.hidden)) {
      check(
        destinationsFrom(l.id).any((d) => !locations[d]!.hidden),
        'location ${l.id}: a hidden area needs a route',
      );
    }
    check(
      !nodes.values.any((n) => n.bottle) ||
          (locations[bottleReveals]?.hidden ?? false),
      'bottle: it must reveal a hidden area',
    );
    check(items.containsKey(bottleLater), 'bottle: unknown item');
    check(
      shards.length == bonusTiers.length && shards.every(items.containsKey),
      'salvage: one known shard per bonus stat tier',
    );
    for (final q in qualities) {
      check(items.containsKey(dustOf(q.id)), 'no dust item for ${q.id}');
    }
    for (final p in professions.values) {
      for (final t in p.tips) {
        check(enemies.containsKey(t.enemy), 'tip ${t.id}: unknown monster');
      }
    }
    check(rerollSteps > 0 && rerollDust > 0, 'reroll: steps and dust > 0');
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

double _num(Map<String, Object?> j, String key) => (j[key] as num).toDouble();

int _intOr(Map<String, Object?> j, String key, [int fallback = 0]) =>
    j[key] as int? ?? fallback;
