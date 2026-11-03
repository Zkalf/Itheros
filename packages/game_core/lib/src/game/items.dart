part of '../game.dart';

/// Items: salvage, materials, the bag after the queue, equipping.
extension GameItems on Game {
  /// Breaks the bag item [key] down at a forge into one dust of its quality,
  /// with a roll for a boss shard on the profession stream (spec 0010
  /// §7.1). Throws [ActivityError] if it can't.
  SalvageResult salvage(GameState s, String key) {
    if (!atForge(s)) throw ActivityError('Salvage at a forge');
    _checkSalvage(s, key);
    final n = s.copy()..addItem(key, -1);
    return _salvageOne(n, key);
  }

  /// Whether a salvage takes the bag item [key]: gear or a tool in the bag,
  /// not a starter tool (spec 0010 §7.1). Worn items are never in the bag.
  bool salvageable(GameState s, String key) => _whyNoSalvage(s, key) == null;

  /// The bag items of [quality] that a batch salvages, in the bag's order
  /// (spec 0010 amendment 9, rule 2).
  List<String> salvageAllOf(GameState s, String quality) => [
    for (final k in bagOrder(data, s.inventory.keys))
      if (salvageable(s, k) && data.qualityOf(k).id == quality) k,
  ];

  /// Salvages every one of each bag item in [keys] at a forge, in the bag's
  /// order: the same as single salvages in that order (spec 0010
  /// amendment 9, rule 5). Throws [ActivityError] if it can't.
  SalvageAllResult salvageAll(GameState s, Iterable<String> keys) {
    if (!atForge(s)) throw ActivityError('Salvage at a forge');
    final order = bagOrder(data, keys.toSet());
    if (order.isEmpty) throw ActivityError('Nothing to salvage');
    for (final k in order) {
      _checkSalvage(s, k);
    }
    var n = s.copy();
    var count = 0;
    final dust = <String, int>{};
    final shards = <String, int>{};
    for (final k in order) {
      for (var i = s.inventory[k]!; i > 0; i--) {
        n.addItem(k, -1);
        final r = _salvageOne(n, k);
        n = r.state;
        count++;
        dust[r.dust] = (dust[r.dust] ?? 0) + 1;
        if (r.shard case final shard?) shards[shard] = (shards[shard] ?? 0) + 1;
      }
    }
    return SalvageAllResult(n, count, dust, shards);
  }

  /// Throws [ActivityError] when a salvage can't take [key].
  void _checkSalvage(GameState s, String key) {
    if (_whyNoSalvage(s, key) case final why?) throw ActivityError(why);
  }

  /// Why a salvage can't take [key], or null when it can.
  String? _whyNoSalvage(GameState s, String key) {
    final item = data.itemOf(key);
    if (item == null || (item.slot == null && item.tool == null)) {
      return 'Only gear and tools can be salvaged';
    }
    if (item.tool?.starter ?? false) {
      return "A teacher's gift can't be salvaged";
    }
    if ((s.inventory[key] ?? 0) < 1) {
      return 'Only items in the bag can be salvaged';
    }
    return null;
  }

  /// Gives [n] the dust of one [key] that left its bag, and rolls for a
  /// shard. Mutates [n].
  SalvageResult _salvageOne(GameState n, String key) {
    final dust = GameData.dustOf(data.qualityOf(key).id);
    n.addItem(dust);
    final rng = Rng.fromState(n.professionRng);
    final shard = rng.nextDouble() < shardChance(key) ? shardFor(key) : null;
    n.professionRng = rng.state;
    if (shard != null) n.addItem(shard);
    return SalvageResult(n, dust, shard);
  }

  /// Settles the Legendary [key]'s waiting stat roll: the new roll takes
  /// its stat's place, or the old one stays (spec 0010 §7.3).
  GameState keepRoll(GameState s, String key, {required bool keepNew}) {
    final pending = data.pendingRoll(key);
    if (pending == null) throw ActivityError('No roll waits on $key');
    final rolls = data.bonusRolls(key);
    if (keepNew) rolls[pending.index] = pending.roll;
    final settled = data.keyFor(
      data.itemOf(key)!.id,
      data.qualityOf(key).id,
      rolls,
    );
    return _replaceItem(s.copy(), key, settled);
  }

  /// Puts [to] where one [from] is, worn or in the bag. Mutates [s].
  GameState _replaceItem(GameState s, String from, String to) {
    for (final MapEntry(:key, :value) in s.equipment.entries) {
      if (value == from) {
        s.equipment[key] = to;
        return s;
      }
    }
    if ((s.inventory[from] ?? 0) < 1) throw ActivityError('No $from');
    return s
      ..addItem(from, -1)
      ..addItem(to);
  }

  /// Whether the player holds one [key], worn or in the bag.
  bool holds(GameState s, String key) =>
      (s.inventory[key] ?? 0) > 0 || s.equipment.containsValue(key);

  /// Character XP for [steps] of [profession] work at [fade] percent: a
  /// share of an even-level fight's XP per step (spec 0010 §2.4).
  int professionCharacterXp(GameState s, int steps, int fade) {
    final xp =
        (steps *
                    data.professionShare *
                    data.fightXpPerStep(level(s)) *
                    fade /
                    100 +
                1e-9)
            .floor();
    final grey = data.professionBands.last.xpPercent;
    return fade > grey ? math.max(1, xp) : xp;
  }

  /// Recipes that use [item], in data order.
  List<String> itemUses(String item) => [
    for (final r in data.recipes.values)
      if (r.inputs.containsKey(item)) r.id,
  ];

  /// [enemy]'s drops the player has found, in [dropItems] order.
  List<String> foundDrops(GameState s, String enemy) => [
    for (final item in dropItems(enemy))
      if ((s.counters[Game.foundCounter(enemy, item)] ?? 0) > 0) item,
  ];

  /// [node]'s countable items the player has found, in [countableItems]
  /// order: its own item always, a catch once gathered or owned (#114).
  List<String> foundCatches(GameState s, String node) => [
    for (final item in countableItems(Activity.gather(node)))
      if (item == data.nodes[node]!.item ||
          (s.counters['gathered.$item'] ?? 0) > 0 ||
          owned(s, item) > 0)
        item,
  ];

  /// Whether the bag (and the bank, for a craft at a place with a bank:
  /// spec 0020) holds the inputs of [recipe].
  bool hasMaterials(GameState s, String recipe) {
    final have = materialsFor(s, recipe);
    return data.recipes[recipe]!.inputs.entries.every(
      (e) => (have[e.key] ?? 0) >= e.value,
    );
  }

  /// How many more of each input [recipe] needs, in recipe order.
  Map<String, int> missingFor(GameState s, String recipe) {
    final have = materialsFor(s, recipe);
    return {
      for (final e in data.recipes[recipe]!.inputs.entries)
        if (e.value - (have[e.key] ?? 0) case final n when n > 0) e.key: n,
    };
  }

  /// How many crafts of [recipe] [bag] allows; null for a recipe with no
  /// inputs (spec 0010 amendment 5 §2.1).
  int? craftsAllowed(Map<String, int> bag, String recipe) {
    int? n;
    data.recipes[recipe]!.inputs.forEach((item, need) {
      final k = (bag[item] ?? 0) ~/ need;
      if (n == null || k < n!) n = k;
    });
    return n;
  }

  /// How many crafts [stop] asks of craft [a], with [bag] before it; null
  /// when the number is unknown (spec 0010 amendment 5 §2.2). [done] counts
  /// the crafts the current action already made.
  int? craftsFor(
    Activity a,
    StopCondition stop,
    Map<String, int> bag, {
    int done = 0,
  }) => switch (stop.kind) {
    StopKind.untilCrafted => math.max(0, stop.count - done),
    StopKind.untilHave => math.max(0, stop.count - (bag[stop.item] ?? 0)),
    _ => null,
  };

  /// The bag by base item id once the current action and the waiting ones
  /// end, as far as the game can know it: it never promises more than the
  /// player will have (spec 0010 amendment 5 §3). It never changes [s].
  /// [withBank] adds the item bank, for a craft at a place with a bank (spec
  /// 0020 §2.7): the waiting crafts then take from the bag and the bank
  /// together, so it still never promises more.
  Map<String, int> bagAfterQueue(GameState s, {bool withBank = false}) {
    final bag = <String, int>{};
    void add(String key, int n) {
      final id = data.itemOf(key)?.id ?? key;
      bag[id] = (bag[id] ?? 0) + n;
    }

    s.inventory.forEach(add);
    if (withBank) s.itemBank.forEach(add);
    if (s.activity case final now?) {
      _afterAction(bag, now.activity, now.stop, done: now.crafted);
    }
    for (final p in s.queue) {
      _afterAction(bag, p.activity, p.stop);
    }
    return bag;
  }

  /// What [a] with [stop] does to [bag] (spec 0010 amendment 5 §3.1-3.2).
  void _afterAction(
    Map<String, int> bag,
    Activity a,
    StopCondition stop, {
    int done = 0,
  }) {
    void take(String item, int n) =>
        bag[item] = math.max(0, (bag[item] ?? 0) - n);
    switch (a.kind) {
      case ActivityKind.craft:
        final recipe = data.recipes[a.target]!;
        final asked = craftsFor(a, stop, bag, done: done);
        final allowed = craftsAllowed(bag, recipe.id);
        // An unknown number uses all the crafts the materials allow.
        final crafts = switch ((asked, allowed)) {
          (null, null) => 0,
          (null, final m?) => m,
          (final k?, null) => k,
          (final k?, final m?) => math.min(k, m),
        };
        recipe.inputs.forEach((item, need) => take(item, need * crafts));
        bag[recipe.output] = (bag[recipe.output] ?? 0) + crafts;
      case ActivityKind.fight || ActivityKind.gather:
        if (stop.kind == StopKind.untilHave) {
          bag[stop.item!] = math.max(bag[stop.item!] ?? 0, stop.count);
        }
      case ActivityKind.reroll:
        take(_rerollDust(a), data.rerollDust);
      case ActivityKind.travel:
        break;
    }
  }

  /// Owned [item]s of every quality, equipped ones included.
  /// How many of [item] (any quality) are in the bag: not worn, not in the
  /// bank. Eating and auto-eat use the bag only (spec 0020 decision 5).
  int inBag(GameState s, String item) {
    var n = 0;
    s.inventory.forEach((key, count) {
      if (data.itemOf(key)?.id == item) n += count;
    });
    return n;
  }

  int owned(GameState s, String item) {
    bool isIt(String key) => data.itemOf(key)?.id == item;
    var n = s.equipment.values.where(isIt).length;
    s.inventory.forEach((key, count) {
      if (isIt(key)) n += count;
    });
    // Owning an item in the bank counts as owning it (spec 0020 rule 10).
    s.itemBank.forEach((key, count) {
      if (isIt(key)) n += count;
    });
    return n;
  }

  /// How many actions the queue holds, the running one and walks included
  /// (spec 0016 §2).
  /// Chieftain's Bane adds one (spec 0017 §3.4), and so does Quartermaster
  /// (spec 0015 §2.4).
  int queueSlots(GameState s) =>
      data.queueSlots +
      _rewards(s).whereType<QueueSlotReward>().length +
      talentSum(s, TalentEffect.queueSlot).round();

  /// The change in stats from wearing [item] in [slot] instead of what it
  /// takes off.
  Stats compare(GameState s, String item, String slot) {
    var off = const Stats();
    for (final id in displaced(s, item, slot)) {
      off += data.bonusOf(s.equipment[id]!);
    }
    return data.bonusOf(item) - off;
  }

  /// Worn slots that wearing [item] in [slot] empties.
  List<String> displaced(GameState s, String item, String slot) {
    bool twoHanded(String? key) =>
        key != null && (data.itemOf(key)?.twoHanded ?? false);
    return {
      slot,
      if (twoHanded(item)) 'offHand',
      if (slot == 'offHand' && twoHanded(s.equipment['mainHand'])) 'mainHand',
    }.where(s.equipment.containsKey).toList();
  }

  GameState unequip(GameState s, String slot) {
    final item = s.equipment[slot];
    if (item == null) throw ActivityError('Nothing equipped in $slot');
    return s.copy()
      ..equipment.remove(slot)
      ..addItem(item);
  }

  /// Applies [walked] real steps, one at a time, as spec 0001 §2.2 says.
  /// The steps into actions count toward the supply chest of the local
  /// [day] (`yyyy-mm-dd`); without a day nothing counts (spec 0013 §2.1).
  StepReport applySteps(GameState input, int walked, {String? day}) {
    if (walked < 0) throw ArgumentError.value(walked, 'walked', 'negative');
    final run = _Run(this, input.copy(), day);
    for (var i = 0; i < walked; i++) {
      run.step();
    }
    return run.report(walked);
  }
}

/// The bag's order (spec 0008 §3.5): gear first, by slot order then best
/// first, then materials in data order. The bank screen (spec 0020 §3.2) and
/// salvage all (spec 0010 amendment 9) use it too.
List<String> bagOrder(GameData data, Iterable<String> keys) {
  // Ties fall back to data order, then quality order, so squares never
  // move when something is equipped (spec 0005 §5).
  final slotRank = <String, int>{};
  for (final g in data.gearSlots) {
    slotRank.putIfAbsent(g.kind, () => slotRank.length);
  }
  final itemRank = {for (final (i, id) in data.items.keys.indexed) id: i};
  final qualityRank = {for (final (i, q) in data.qualities.indexed) q.id: i};
  int stable(String a, String b) {
    final byItem = (itemRank[data.itemOf(a)?.id] ?? 1 << 20).compareTo(
      itemRank[data.itemOf(b)?.id] ?? 1 << 20,
    );
    if (byItem != 0) return byItem;
    return qualityRank[data.qualityOf(a).id]!.compareTo(
      qualityRank[data.qualityOf(b).id]!,
    );
  }

  final gear =
      [
        for (final k in keys)
          if (data.itemOf(k)?.slot != null) k,
      ]..sort((a, b) {
        final bySlot = slotRank[data.itemOf(a)!.slot]!.compareTo(
          slotRank[data.itemOf(b)!.slot]!,
        );
        if (bySlot != 0) return bySlot;
        final byScore = data.scoreOf(b).compareTo(data.scoreOf(a));
        return byScore != 0 ? byScore : stable(a, b);
      });
  final materials = [
    for (final k in keys)
      if (data.itemOf(k)?.slot == null) k,
  ]..sort(stable);

  return [...gear, ...materials];
}
