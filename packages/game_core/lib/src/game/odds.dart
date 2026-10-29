part of '../game.dart';

/// Chances and rolls: finds, perfect crafts, meals, fights, quality and bonus stats.
extension GameOdds on Game {
  /// The chance a cook of [recipe] turns out a perfect dish (spec 0011
  /// §5.3): spec 0010 §5.1's formula with the pot and Cooking.
  double perfectChance(GameState s, String recipe) {
    final r = data.recipes[recipe]!;
    final tool = s.tools[r.profession];
    final steps = tool == null ? 0 : _qualitySteps(tool);
    final above = math.max(0, professionLevel(s, r.profession) - r.level);
    final levelBonus = math.min(
      data.perfectMaxLevelBonus,
      data.perfectPerLevelAbove * above,
    );
    return data.perfectBase *
        (1 + data.perfectPerToolQualityStep * steps) *
        (1 + levelBonus);
  }

  /// Eats the meal [key] from the bag; one running now is replaced (spec
  /// 0011 §5.4). Throws [ActivityError] otherwise.
  GameState eat(GameState s, String key) {
    if (data.itemOf(key)?.meal == null) throw ActivityError('$key is no meal');
    if ((s.inventory[key] ?? 0) < 1) throw ActivityError('No $key to eat');
    return s.copy()
      ..addItem(key, -1)
      ..meal = ActiveMeal(key, data.mealStepsOf(key));
  }

  /// Sets the meal kind [meal] (an item id) to be eaten when the running
  /// one ends, keeping [keep] in the bag; null turns auto-eat off.
  GameState setAutoEat(GameState s, String? meal, {int keep = 0}) {
    if (meal != null && data.items[meal]?.meal == null) {
      throw ActivityError('$meal is no meal');
    }
    if (keep < 0) throw ActivityError('Keep at least 0');
    return s.copy()..autoEat = meal == null ? null : AutoEat(meal, keep);
  }

  /// What the running meal adds to the stats (spec 0011 §5.3): a percent
  /// of the total with gear, rounded down, at least 1; Crit in points.
  Stats mealBonus(GameState s) {
    final meal = s.meal == null ? null : data.itemOf(s.meal!.key)?.meal;
    if (meal == null) return const Stats();
    final gear = _gearStats(s);
    final pct = data.mealPercent[meal.tier - 1];
    int up(int v) => math.max(1, v * pct ~/ 100);
    return Stats(
      hp: meal.buffs.contains('hp') ? up(gear.hp) : 0,
      attack: meal.buffs.contains('attack') ? up(gear.attack) : 0,
      defense: meal.buffs.contains('defense') ? up(gear.defense) : 0,
      crit: meal.buffs.contains('crit') ? data.mealCrit[meal.tier - 1] : 0,
    );
  }

  /// The share of profession and reroll steps the running meal takes off
  /// (spec 0011 §5.3).
  double mealStepShare(GameState s) {
    final meal = s.meal == null ? null : data.itemOf(s.meal!.key)?.meal;
    if (meal == null || !meal.buffs.contains('steps')) return 0;
    return data.mealPercent[meal.tier - 1] / 100;
  }

  /// The chance salvaging [key] gives a boss shard (spec 0010 §7.1).
  double shardChance(String key) =>
      data.shardBase + data.shardPerQualityStep * _qualitySteps(key);

  /// The shard salvaging [key] may give: its tier boss's.
  String shardFor(String key) =>
      data.shards[data.bonusTierIndex(data.itemLevel(data.itemOf(key)!.id))];

  /// Whether the player can salvage and reroll here.
  bool atForge(GameState s) =>
      _here(s).crafting && _canPractise(s, 'crafting', 1);

  /// What the player knows about [enemy] (spec 0009 §7.1): its armour from
  /// the first fight, its weakness and stats from enough kills; a lore note
  /// about it tells armour and weakness (§7.2).
  Knowledge knowledge(GameState s, String enemy) {
    final kills = s.counters['kills.$enemy'] ?? 0;
    final c = data.combat;
    // A lore note or a teacher's tip about it (spec 0010 §6.2).
    final note =
        data.loreNotes.any((n) => n.about == enemy && s.lore.contains(n.id)) ||
        data.professions.values.any(
          (p) => p.tips.any((t) => t.enemy == enemy && s.tips.contains(t.id)),
        );
    return Knowledge(
      kills: kills,
      armour: note || s.fought.contains(enemy) || kills > 0,
      weakness: note || kills >= c.studyKills,
      stats: kills >= c.studyKills,
      slayer: kills >= c.slayerKills,
      killsToNext: kills < c.studyKills
          ? c.studyKills - kills
          : kills < c.slayerKills
          ? c.slayerKills - kills
          : null,
    );
  }

  /// The damage type [enemy] is weak to: the one strong against its armour.
  String weakness(String enemy) =>
      data.combat.strongAgainst(data.enemies[enemy]!.armour);

  /// Whether the player has earned Slayer against [enemy] (spec 0009 §7.1).
  bool slayer(GameState s, String enemy) =>
      (s.counters['kills.$enemy'] ?? 0) >= data.combat.slayerKills;

  /// The player's chance to hit [enemy], in percent (spec 0009 §2.1). The
  /// monster's Dodge is a roll of its own and doesn't change it.
  int playerHitChance(GameState s, String enemy) {
    final e = data.enemies[enemy]!;
    final slayerHit = slayer(s, enemy) ? data.combat.slayerHit : 0;
    return data.combat.hitChance(level(s) - e.level, stats(s).hit + slayerHit);
  }

  /// [enemy]'s chance to hit the player, in percent. Monsters have no Hit.
  int monsterHitChance(GameState s, String enemy) =>
      data.combat.hitChance(data.enemies[enemy]!.level - level(s), 0);

  /// The player's Crit, Block and Dodge in percent, base Crit included and
  /// each within its cap (spec 0009 §2.1).
  int critChance(GameState s) =>
      math.min(data.combat.critCap, data.combat.critBase + stats(s).crit);

  int blockChance(GameState s) =>
      math.min(data.combat.blockCap, stats(s).block);

  int dodgeChance(GameState s) =>
      math.min(data.combat.dodgeCap, stats(s).dodge);

  /// [enemy]'s Dodge, within the cap.
  int enemyDodge(String enemy) =>
      math.min(data.combat.dodgeCap, data.enemies[enemy]!.stats.dodge);

  /// Picks a quality id for gear of [itemLevel] made or found by a player of
  /// [playerLevel] (spec 0005 §3). Uses one roll of [rng].
  String rollQuality(
    Rng rng, {
    required int playerLevel,
    required int itemLevel,
  }) {
    final above = math.min(
      data.qualityMaxLevels,
      math.max(0, playerLevel - itemLevel),
    );
    final boost = 1 + data.qualityPerLevel * above;
    var roll = rng.nextDouble();
    for (final q in data.qualities.reversed) {
      if (q == data.qualities.first) break;
      roll -= q.chance * boost;
      if (roll < 0) return q.id;
    }
    return data.qualities.first.id;
  }

  /// The bonus stats gear of [quality] rolls when made or found (spec 0009
  /// §5.1): one per quality step above common, each a stat picked from the
  /// pool of [itemLevel]'s tier (Block only for the off hand) and a value
  /// in its range. Repeats can happen.
  List<BonusRoll> rollBonus(
    Rng rng,
    String item,
    String quality,
    int itemLevel,
  ) {
    final steps = data.qualities.indexWhere((q) => q.id == quality);
    return rollBonusStats(rng, item, steps, itemLevel);
  }

  /// [count] bonus stat rolls for gear [item] of [itemLevel] (spec 0009
  /// §5.1).
  List<BonusRoll> rollBonusStats(
    Rng rng,
    String item,
    int count,
    int itemLevel,
  ) {
    final steps = count;
    final offHand = data.items[item]!.slot == 'offHand';
    final pool = [
      for (final MapEntry(key: stat, value: range)
          in data.bonusTierFor(itemLevel).ranges.entries)
        if (stat != 'block' || offHand) (stat, range),
    ];
    return [
      for (var i = 0; i < steps; i++)
        if (pool[rng.nextInt(pool.length)] case (
          final stat,
          (final lo, final hi),
        ))
          (stat: stat, value: lo + rng.nextInt(hi - lo + 1)),
    ];
  }

  /// Total XP needed for the next level. There is no level cap.
  int xpForNextLevel(GameState s) => data.xpForLevel(level(s) + 1);
}
