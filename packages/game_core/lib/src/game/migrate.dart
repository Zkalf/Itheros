part of '../game.dart';

/// Old saves: each change of the save brings an old state up to date.
extension GameMigrate on Game {
  /// The quality counter starts at the best quality in the bag and on the
  /// doll (spec 0017 §3.2).
  GameState _migrateQualityFound(GameState s) {
    for (final key in [...s.inventory.keys, ...s.equipment.values]) {
      _foundQuality(s, key);
    }
    return s;
  }

  /// A running action that walks becomes a walk with the action after it,
  /// and each waiting action that can't happen where the queue stands gets
  /// a walk to its nearest place first. The queue may then hold more than
  /// [queueSlots] actions.
  GameState _migrateWalks(GameState s) {
    final run = s.activity;
    final waiting = [...s.queue];
    s.queue.clear();
    if (run != null &&
        run.activity.kind != ActivityKind.travel &&
        run.leg != null) {
      if (_placeFor(s, run.activity) case final place?) {
        s.activity = RunningActivity(
          Activity.travel(place),
          progress: run.progress,
          leg: run.leg,
        );
        waiting.insert(0, PlannedAction(run.activity, run.stop));
      }
    }
    for (final p in waiting) {
      final end = queuePlaces(s).last;
      if (!_happensAt(end, p.activity)) {
        if (_placeFor(s, p.activity, from: end) case final place?) {
          final walk = Activity.travel(place);
          s.queue.add(PlannedAction(walk, StopCondition.defaultFor(walk)));
        }
      }
      s.queue.add(p);
    }
    return s;
  }

  /// Every vein mined and item crafted counts its profession XP, unfaded;
  /// Mining and Crafting are learned with their starter tools.
  GameState _migrateProfessions(GameState s) {
    // Two spots can give one item, and two recipes can make one: each
    // counter earns once, from the first.
    final seen = <String>{};
    void earn(String profession, String counter, int xp) {
      final n = s.counters[counter] ?? 0;
      if (n == 0 || !seen.add(counter)) return;
      s.professions[profession] = (s.professions[profession] ?? 0) + n * xp;
    }

    for (final node in data.nodes.values) {
      earn(node.profession, 'gathered.${node.item}', node.xp);
    }
    for (final r in data.recipes.values) {
      earn(r.profession, 'crafted.${r.output}', r.xp);
    }
    for (final id in const ['mining', 'crafting']) {
      if (data.professions[id] case final p?) {
        s.learned.add(id);
        s.tools[id] ??= p.teacher.starterTool;
      }
    }
    s.professionRng = Game.professionStream(s.rngState);
    return s;
  }

  /// Each owned item above Common rolls its bonus stats once, with the
  /// save's generator: worn ones in doll order, then the bag in key order,
  /// each item of a stack on its own (spec 0009 §5.4).
  GameState _migrateBonus(GameState s) {
    final rng = Rng.fromState(s.rngState);
    bool needs(String key) =>
        data.itemOf(key)?.slot != null &&
        data.qualityOf(key) != data.qualities.first &&
        data.bonusRolls(key).isEmpty;
    String roll(String key) {
      final item = data.itemOf(key)!.id;
      final q = data.qualityOf(key).id;
      return data.keyFor(
        item,
        q,
        rollBonus(rng, item, q, data.itemLevel(item)),
      );
    }

    for (final slot in data.gearSlots) {
      if (s.equipment[slot.id] case final key? when needs(key)) {
        s.equipment[slot.id] = roll(key);
      }
    }
    for (final key in s.inventory.keys.toList()..sort()) {
      if (!needs(key)) continue;
      final n = s.inventory.remove(key)!;
      for (var i = 0; i < n; i++) {
        s.addItem(roll(key));
      }
    }
    s.rngState = rng.state;
    s.fought.addAll([
      for (final e in data.enemies.keys)
        if ((s.counters['kills.$e'] ?? 0) > 0) e,
    ]);
    return s;
  }

  /// A worn two-hander empties the off hand into the bag: an item may have
  /// become two-handed since the save was made (spec 0009 §4.1).
  GameState _freeOffHand(GameState s) {
    final main = s.equipment['mainHand'];
    if (main == null ||
        !(data.itemOf(main)?.twoHanded ?? false) ||
        !s.equipment.containsKey('offHand')) {
      return s;
    }
    final n = s.copy();
    return n..addItem(n.equipment.remove('offHand')!);
  }

  /// Each worn item goes to the first free slot of its item's kind in
  /// `items.json` (a sword to Main hand, the Bear-pelt cloak to Cloak), or
  /// to the bag if none is free.
  GameState _migrateLayout(GameState s) {
    final old = Map.of(s.equipment);
    s.equipment.clear();
    for (final key in old.values) {
      final free = slotsFor(key).where((id) => !s.equipment.containsKey(id));
      if (free.isEmpty) {
        s.addItem(key);
      } else {
        s.equipment[free.first] = key;
      }
    }
    s.explored
      ..clear()
      ..add(s.location)
      ..addAll([
        for (final id in data.locations.keys)
          if ((s.counters['visited.$id'] ?? 0) > 0) id,
      ]);
    return s;
  }

  GameState _findOwnedDrops(GameState s) {
    for (final e in data.enemies.keys) {
      if ((s.counters['kills.$e'] ?? 0) == 0) continue;
      for (final item in dropItems(e)) {
        if (owned(s, item) > 0) s.counters[Game.foundCounter(e, item)] = 1;
      }
    }
    return s;
  }

  GameState _migrateXp(GameState s) {
    if (s.loadedVersion != 1) return s;
    const v1 = [0, 20, 100, 300, 700, 1540, 3390, 7460, 16400, 28000];
    var l = 1;
    while (l < v1.length && s.xp >= v1[l]) {
      l++;
    }
    final floor = data.xpForLevel(l);
    final cost = data.xpForLevel(l + 1) - floor;
    // Version 1 capped at level 10 but kept counting XP: that XP carries
    // into level 10, short of level 11.
    final progress = l < v1.length
        ? (cost * (s.xp - v1[l - 1]) / (v1[l] - v1[l - 1])).floor()
        : math.min(s.xp - v1.last, cost - 1);
    return s.copy()..xp = floor + progress;
  }

  /// Steps the running action's next unit costs (a travel leg, round, ore
  /// or craft), or null when resting.
  int? unitCost(GameState s) {
    final act = s.activity;
    return act == null ? null : _costOf(s, act);
  }
}
