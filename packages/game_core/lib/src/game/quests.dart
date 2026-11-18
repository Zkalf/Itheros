part of '../game.dart';

/// Where a quest stands (spec 0024 §2.2).
enum QuestState { closed, offered, taken, done }

/// Quests (spec 0024): taking, the count from the moment of taking, hand-in
/// and its reward.
extension GameQuests on Game {
  QuestState questState(GameState s, String id) {
    if (s.quests[id] case final p?) {
      return p.done ? QuestState.done : QuestState.taken;
    }
    final after = data.quests[id]!.after;
    return after == null || (s.quests[after]?.done ?? false)
        ? QuestState.offered
        : QuestState.closed;
  }

  /// The place of [quest]'s giver, where it is taken and handed in.
  String questPlace(String quest) =>
      data.giverPlace(data.quests[quest]!.giver)!;

  /// How much of [quest]'s task is met, from 0 to its count (§2.3). A done
  /// quest counts full; a quest not taken counts 0.
  int questCount(GameState s, String quest) {
    final task = data.quests[quest]!.task;
    final p = s.quests[quest];
    if (p == null) return 0;
    if (p.done) return task.count;
    final n = switch (task.kind) {
      TaskKind.wear => _wears(s, task.target) ? 1 : 0,
      TaskKind.visit => p.base,
      // Only what came into the bag after taking, and only while the bag
      // still holds it.
      TaskKind.bring => math.min(
        _taskCounter(s, task) - p.base,
        inBag(s, task.target),
      ),
      TaskKind.kill ||
      TaskKind.gather ||
      TaskKind.craft => _taskCounter(s, task) - p.base,
    };
    return n.clamp(0, task.count);
  }

  /// A taken quest whose task is met: it can be handed in.
  bool questReady(GameState s, String quest) =>
      questState(s, quest) == QuestState.taken &&
      questCount(s, quest) >= data.quests[quest]!.task.count;

  /// Takes [quest] at its giver (§2.2): its count starts now.
  GameState takeQuest(GameState s, String quest) {
    final q = data.quests[quest] ?? (throw ActivityError('No quest $quest'));
    if (questState(s, quest) != QuestState.offered) {
      throw ActivityError('${q.title} is not offered');
    }
    _atGiver(s, q);
    final n = s.copy();
    n.quests[quest] = QuestProgress.taken(
      q.task.kind == TaskKind.visit
          ? (n.location == q.task.target ? 1 : 0)
          : _taskCounter(n, q.task),
    );
    return n;
  }

  /// Hands a ready [quest] in at its giver (§2.4). A bring quest gives its
  /// items, the lowest quality first. The hero gets the XP and a supply
  /// chest rolled now on the supply stream, so no fight, drop, catch or
  /// craft moves.
  ({GameState state, List<GameEvent> events}) handIn(
    GameState s,
    String quest,
  ) {
    final q = data.quests[quest] ?? (throw ActivityError('No quest $quest'));
    if (!questReady(s, quest)) throw ActivityError('${q.title} is not ready');
    _atGiver(s, q);
    final n = s.copy();
    final events = <GameEvent>[];
    if (q.task.kind == TaskKind.bring) {
      _giveFromBag(n, q.task.target, q.task.count);
    }
    // Last in the map: the save keeps the order of hand-in, newest last.
    n.quests
      ..remove(quest)
      ..[quest] = const QuestProgress.done();
    final before = level(n);
    n.xp += q.xp;
    for (var l = before + 1; l <= level(n); l++) {
      events.add(LevelUp(l));
    }
    // One draw seeds the chest, as a day's chest does (spec 0013 §2.3).
    final supply = Rng.fromState(n.supplyRng);
    final own = Rng.fromState(supply.nextUint32());
    final chest = rollSupplyChest(n, own);
    n.supplyChests.add(SupplyChest('', chest, quest: quest));
    n.supplyRng = supply.state;
    events.add(QuestDone(quest, q.xp, chest));
    // The new level may complete an achievement.
    for (final a in data.achievements.values) {
      if (!n.achievements.contains(a.id) && achievementMet(n, a)) {
        _earn(n, a, events);
      }
    }
    return (state: n, events: events);
  }

  void _atGiver(GameState s, QuestDef q) {
    if (s.location != data.giverPlace(q.giver)) {
      throw ActivityError('${data.giverName(q.giver)} is not here');
    }
  }

  /// The counter a task reads; 0 for a wear or a visit task.
  int _taskCounter(GameState s, QuestTask task) {
    int c(String name) => s.counters['$name.${task.target}'] ?? 0;
    return switch (task.kind) {
      TaskKind.kill => c('kills'),
      TaskKind.gather => c('gathered'),
      TaskKind.craft => c('crafted'),
      TaskKind.bring => c('gathered') + c('dropped'),
      TaskKind.wear || TaskKind.visit => 0,
    };
  }

  bool _wears(GameState s, String item) =>
      s.equipment.values.any((key) => data.itemOf(key)?.id == item);

  /// Takes [count] of [item] from the bag, the lowest quality first.
  void _giveFromBag(GameState s, String item, int count) {
    int rank(String key) => data.qualities.indexOf(data.qualityOf(key));
    final keys = [
      for (final key in s.inventory.keys)
        if (data.itemOf(key)?.id == item) key,
    ]..sort((a, b) => rank(a).compareTo(rank(b)));
    var left = count;
    for (final key in keys) {
      if (left == 0) break;
      final n = math.min(left, s.inventory[key]!);
      s.addItem(key, -n);
      left -= n;
    }
  }

  /// Marks the taken visit quests to [area] as met on arrival (§2.3).
  void _arriveForQuests(GameState s, String area) {
    for (final MapEntry(key: id, value: p) in s.quests.entries.toList()) {
      final task = data.quests[id]?.task;
      if (!p.done && task?.kind == TaskKind.visit && task!.target == area) {
        s.quests[id] = const QuestProgress.taken(1);
      }
    }
  }
}
