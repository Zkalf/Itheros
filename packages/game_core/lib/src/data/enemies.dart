part of '../data.dart';

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
