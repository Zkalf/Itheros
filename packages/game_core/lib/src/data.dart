import 'dart:convert';
import 'dart:math' as math;

part 'data/combat.dart';
part 'data/world.dart';
part 'data/enemies.dart';
part 'data/items.dart';
part 'data/professions.dart';
part 'data/achievements.dart';

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
    for (final a in achievements.values) {
      // Only a feat gives a bonus or the queue slot (spec 0017 §1).
      check(
        a.kind == AchievementKind.feat ||
            a.reward is BankCapReward ||
            a.reward is ItemReward,
        'achievement ${a.id}: a milestone gives only bank cap or an item',
      );
      if (a.reward case ItemReward(:final item, :final quality)) {
        check(items.containsKey(item), 'achievement ${a.id}: unknown $item');
        check(
          qualities.any((q) => q.id == quality),
          'achievement ${a.id}: unknown quality $quality',
        );
      }
      if (a.criterion case QualityCriterion(:final quality)) {
        check(
          qualities.any((q) => q.id == quality),
          'achievement ${a.id}: unknown quality $quality',
        );
      }
    }
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
        check(
          (t.enemy == null) != (t.node == null),
          'tip ${t.id}: needs either enemy or node',
        );
        if (t.enemy case final e?) {
          check(enemies.containsKey(e), 'tip ${t.id}: unknown monster');
        }
        if (t.node case final n?) {
          final spot = nodes[n];
          check(spot?.profession == p.id, 'tip ${t.id}: not a ${p.id} spot');
          check(spot?.level == t.level, "tip ${t.id}: not the spot's level");
        }
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
