import 'dart:convert';

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
      nodes = _strList(j, 'nodes');

  final String id;
  final String name;
  final int unlockLevel;
  final bool crafting;
  final List<String> enemies;
  final List<String> nodes;
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
      chance = (j['chance'] as num).toDouble(),
      count = _intOr(j, 'count', 1);

  final String item;
  final double chance;
  final int count;
}

class EnemyDef {
  EnemyDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      name = _str(j, 'name'),
      unlockLevel = _int(j, 'unlockLevel'),
      stats = Stats.fromJson(j),
      xp = _int(j, 'xp'),
      drops = _maps(j, 'drops').map(DropDef._).toList();

  final String id;
  final String name;
  final int unlockLevel;
  final Stats stats;
  final int xp;
  final List<DropDef> drops;
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

  /// Total XP needed to reach level `i + 1`. Its length is the level cap.
  final List<int> xpToReachLevel;
  final String startLocation;
  final Map<String, LocationDef> locations;
  final List<RouteDef> routes;
  final Map<String, NodeDef> nodes;
  final Map<String, EnemyDef> enemies;
  final Map<String, ItemDef> items;
  final Map<String, RecipeDef> recipes;
  final Map<String, AchievementDef> achievements;

  int get maxLevel => xpToReachLevel.length;

  int xpForLevel(int level) => xpToReachLevel[level - 1];

  int levelForXp(int xp) {
    var level = 1;
    while (level < maxLevel && xp >= xpToReachLevel[level]) {
      level++;
    }
    return level;
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
      xpToReachLevel.isNotEmpty && xpToReachLevel.first == 0,
      'xpToReachLevel must start with 0',
    );
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
      for (final d in e.drops) {
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
