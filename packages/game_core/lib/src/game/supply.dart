part of '../game.dart';

/// The supply chest (spec 0013): the daily goal of steps into actions, the
/// contents rolled when a chest is earned, and opening.
extension GameSupply on Game {
  /// The supply stream's first state, a fixed hash of [from] (a game seed,
  /// or an old save's generator state): no draw from the shared generator
  /// (spec 0013 §2.3).
  static int supplyStream(int from) =>
      Rng.fromState(((from ^ 0x27D4EB2F) * 0x165667B1) & 0xFFFFFFFF).state;

  /// Today's steps into actions and whether [day] paid its chest.
  ({int steps, bool paid}) supplyToday(GameState s, String day) =>
      (steps: s.supplySteps[day] ?? 0, paid: s.supplyPaid.contains(day));

  /// The gear a chest can give a player of [level], in data order: item
  /// level from [level] minus the window up to [level], without the chase
  /// items (spec 0013 §2.4).
  List<String> supplyWindow(int level) {
    final rules = data.supplyChest;
    return [
      for (final i in data.items.values)
        if (i.slot != null && !rules.exclude.contains(i.id))
          if (data.itemLevel(i.id) case final l
              when l <= level && l >= level - rules.gearWindow)
            i.id,
    ];
  }

  /// The contents of one chest for [s] as it stands, drawn from [rng]: the
  /// common roll, then maybe a piece of gear, then maybe a boss shard (spec
  /// 0013 §2.4). Talents play no part (decision 8).
  Map<String, int> rollSupplyChest(GameState s, Rng rng) {
    final rules = data.supplyChest;
    final level = this.level(s);
    final tier = data.bonusTierIndex(level);
    final items = <String, int>{};
    void add(String key, int n) => items[key] = (items[key] ?? 0) + n;

    // The common roll: one learned gathering profession, Crafting or a
    // meal, evenly.
    final spots = [
      for (final p in data.professions.values)
        if (s.learned.contains(p.id)) ?_bestSpot(s, p.id),
    ];
    final crafts = s.learned.contains('crafting')
        ? supplyCrafts(professionLevel(s, 'crafting'))
        : const <RecipeDef>[];
    final choices = spots.length + (crafts.isEmpty ? 0 : 1) + 1;
    final pick = rng.nextInt(choices);
    if (pick < spots.length) {
      add(spots[pick].item, rules.materials);
    } else if (pick == spots.length && crafts.isNotEmpty) {
      // The inputs of one craft at the player's Crafting level.
      final r = crafts[rng.nextInt(crafts.length)];
      r.inputs.forEach(add);
    } else {
      final mealTier = math.min(tier + 1, data.mealPercent.length);
      final meals = [
        for (final i in data.items.values)
          if (i.meal?.tier == mealTier) i.id,
      ];
      add(meals[rng.nextInt(meals.length)], rules.meals);
    }

    // The gear and the shard always draw, so one never shifts the other.
    final gearRoll = rng.nextDouble();
    final gearPick = rng.nextDouble();
    final gearRng = Rng.fromState(rng.nextUint32());
    final shardRoll = rng.nextDouble();

    final window = gearRoll < rules.gearChance
        ? supplyWindow(level)
        : const <String>[];
    if (window.isNotEmpty) {
      final id = window[(gearPick * window.length).floor()];
      final itemLevel = data.itemLevel(id);
      final q = rollQuality(
        gearRng,
        playerLevel: level,
        itemLevel: itemLevel,
        highBoost: rules.qualityBoost,
      );
      final own = Rng.fromState(gearRng.nextUint32());
      add(data.keyFor(id, q, rollBonus(own, id, q, itemLevel)), 1);
    }
    if (shardRoll < rules.shardChance) add(data.shards[tier], 1);
    return items;
  }

  /// The gear recipes whose inputs the Crafting choice can give at
  /// [crafting] level, in data order: the Crafting level they need from
  /// [crafting] minus the window up to [crafting], without the chase items.
  List<RecipeDef> supplyCrafts(int crafting) {
    final rules = data.supplyChest;
    return [
      for (final r in data.recipes.values)
        if (r.profession == 'crafting' &&
            data.items[r.output]!.slot != null &&
            !rules.exclude.contains(r.output) &&
            r.craftingLevel <= crafting &&
            r.craftingLevel >= crafting - rules.gearWindow)
          r,
    ];
  }

  /// The spot of [profession] with the highest level the player can work:
  /// open to its level and out of the fog. Null for a profession without
  /// spots (Crafting, Cooking).
  NodeDef? _bestSpot(GameState s, String profession) {
    NodeDef? best;
    for (final n in data.nodes.values) {
      if (n.profession == profession &&
          nodeLevelMet(s, n.id) &&
          !nodeFogged(s, n.id) &&
          (best == null || n.level > best.level)) {
        best = n;
      }
    }
    return best;
  }

  /// Opens the oldest waiting chest: its contents go into the bag (spec
  /// 0013 §2.6). No steps, no roll. Throws [ActivityError] with none.
  GameState openSupplyChest(GameState s) {
    if (s.supplyChests.isEmpty) {
      throw ActivityError('No supply chest waiting.');
    }
    final n = s.copy();
    _unpack(n, n.supplyChests.removeAt(0));
    return n;
  }

  /// Opens every waiting chest. Throws [ActivityError] with none.
  GameState openAllSupplyChests(GameState s) {
    if (s.supplyChests.isEmpty) {
      throw ActivityError('No supply chest waiting.');
    }
    final n = s.copy();
    for (final c in n.supplyChests) {
      _unpack(n, c);
    }
    n.supplyChests.clear();
    return n;
  }

  void _unpack(GameState s, SupplyChest c) {
    c.items.forEach((key, count) {
      s.addItem(key, count);
      if (data.itemOf(key)?.slot != null) _foundQuality(s, key);
    });
  }

  /// Drops the count and the paid days from before the `keptDays` days
  /// that end on [day]. Later days stay: a clock once set ahead must never
  /// push out the day being walked, or it could pay again.
  void _pruneSupply(GameState s, String day) {
    final from = DateTime.parse(day)
        .subtract(Duration(days: data.supplyChest.keptDays - 1));
    String two(int n) => '$n'.padLeft(2, '0');
    final cutoff = '${from.year}-${two(from.month)}-${two(from.day)}';
    s.supplySteps.removeWhere((d, _) => d.compareTo(cutoff) < 0);
    s.supplyPaid.removeWhere((d) => d.compareTo(cutoff) < 0);
  }
}
