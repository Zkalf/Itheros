part of '../data.dart';

/// The supply chest's numbers (spec 0013 §2): `supplyChest` in
/// `economy.json`.
class SupplyChestRules {
  SupplyChestRules._(Map<String, Object?> j)
    : goal = _int(j, 'goal'),
      materials = _int(j, 'materials'),
      meals = _int(j, 'meals'),
      gearChance = _num(j, 'gearChance'),
      shardChance = _num(j, 'shardChance'),
      qualityBoost = _num(j, 'qualityBoost'),
      qualityBoostFrom = _str(j, 'qualityBoostFrom'),
      gearWindow = _int(j, 'gearWindow'),
      keptDays = _int(j, 'keptDays'),
      exclude = Set.unmodifiable(_strList(j, 'exclude'));

  /// The steps into actions of one local day that earn its chest.
  final int goal;

  /// The count of the plain item of a gathering profession's best spot.
  final int materials;

  /// The count of one meal.
  final int meals;

  /// The chance of a piece of gear, and of a boss shard.
  final double gearChance;
  final double shardChance;

  /// Multiplies the chances of rare and better qualities of chest gear.
  final double qualityBoost;

  /// The lowest quality [qualityBoost] applies to: it and every better one.
  final String qualityBoostFrom;

  /// How many of the most recent days the count and the paid days keep.
  final int keptDays;

  /// Gear comes from the player's level minus this up to the level.
  final int gearWindow;

  /// Gear that never comes from a chest: the chase items (§2.4).
  final Set<String> exclude;
}
