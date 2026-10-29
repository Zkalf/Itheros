part of '../data.dart';

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
