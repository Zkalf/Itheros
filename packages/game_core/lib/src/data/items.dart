part of '../data.dart';

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

/// A place on the paper doll (spec 0008 §2.1). Items of [kind] fit it.
class GearSlotDef {
  GearSlotDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      kind = j['kind'] as String? ?? _str(j, 'id');

  final String id;
  final String kind;
}
