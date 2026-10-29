part of '../game.dart';

/// Achievements: criteria, progress, rewards earned and lost.
extension GameAchievements on Game {
  /// Counts the quality of [key] for the quality criteria (spec 0017 §3.2).
  void _foundQuality(GameState s, String key) {
    final q = data.qualities.indexOf(data.qualityOf(key)) + 1;
    if (q > (s.counters[Game.foundQualityCounter] ?? 0)) {
      s.counters[Game.foundQualityCounter] = q;
    }
  }

  /// Whether [s] meets the criterion of [a] (spec 0017 §3.1).
  bool achievementMet(GameState s, AchievementDef a) {
    final (:have, :need) = _progress(s, a);
    return have >= need;
  }

  /// How far [s] is towards the achievement [id]: a count, a level, or 0 or
  /// 1 for a quality.
  ({int have, int need}) achievementProgress(GameState s, String id) =>
      _progress(s, data.achievements[id]!);

  ({int have, int need}) _progress(GameState s, AchievementDef a) =>
      switch (a.criterion) {
        CounterCriterion(:final counter, :final atLeast) => (
          have: s.counters[counter] ?? 0,
          need: atLeast,
        ),
        LevelCriterion(:final level) => (have: this.level(s), need: level),
        ProfessionCriterion(:final profession, :final level) => (
          have: professionLevel(s, profession),
          need: level,
        ),
        // The lowest level of the list (spec 0017 amendment 1).
        EachProfessionCriterion(:final professions, :final level) => (
          have: professions.map((p) => professionLevel(s, p)).reduce(math.min),
          need: level,
        ),
        QualityCriterion(:final quality) => (
          have:
              (s.counters[Game.foundQualityCounter] ?? 0) >
                  data.qualities.indexWhere((q) => q.id == quality)
              ? 1
              : 0,
          need: 1,
        ),
      };

  /// Earns [a] and gives its reward. A reward item does not count for the
  /// quality criteria (spec 0017 §3.2).
  void _earn(GameState s, AchievementDef a, List<GameEvent> events) {
    s.achievements.add(a.id);
    if (a.reward case ItemReward(:final item, :final quality)) {
      s.addItem(data.keyFor(item, quality));
    }
    events.add(AchievementUnlocked(a.id));
  }

  /// Loses [a] and takes its reward (spec 0017 §5).
  void _lose(GameState s, AchievementDef a, List<GameEvent> events) {
    s.achievements.remove(a.id);
    var bankSteps = 0;
    String? item;
    var actions = 0;
    switch (a.reward) {
      case BankCapReward():
        final cap = bankCap(s);
        if (s.bank > cap) {
          bankSteps = s.bank - cap;
          s.bank = cap;
        }
      case ItemReward(item: final id, :final quality):
        final key = data.keyFor(id, quality);
        final worn = [
          for (final e in s.equipment.entries)
            if (e.value == key) e.key,
        ];
        if ((s.inventory[key] ?? 0) > 0) {
          s.addItem(key, -1);
          item = key;
        } else if (worn.isNotEmpty) {
          s.equipment.remove(worn.first);
          item = key;
        }
      case QueueSlotReward():
        // The current action stays; waiting actions go from the back.
        while (s.queue.isNotEmpty && s.queue.length > queueSlots(s) - 1) {
          s.queue.removeLast();
          actions++;
        }
      case BonusReward():
        break;
    }
    events.add(
      AchievementLost(a.id, bankSteps: bankSteps, item: item, actions: actions),
    );
  }

  /// A saved state ready to play: [migrate], then each achievement checked
  /// by its criterion (spec 0017 §4). The events name the achievements
  /// earned and lost.
  ({GameState state, List<GameEvent> events}) load(GameState loaded) {
    final s = migrate(loaded).copy();
    final events = <GameEvent>[];
    for (final a in data.achievements.values) {
      if (s.achievements.contains(a.id) && !achievementMet(s, a)) {
        _lose(s, a, events);
      }
    }
    for (final a in data.achievements.values) {
      if (!s.achievements.contains(a.id) && achievementMet(s, a)) {
        _earn(s, a, events);
      }
    }
    return (state: s, events: events);
  }

  /// Monsters [item] has dropped from for this player, and the gathering
  /// spots that give it, for the item card (spec 0008 §3.5). Monsters it
  /// hasn't dropped from yet stay hidden (spec 0006 §2.2).
  (List<String>, List<String>) itemSources(GameState s, String item) => (
    [
      for (final e in data.enemies.keys)
        if ((s.counters[Game.foundCounter(e, item)] ?? 0) > 0) e,
    ],
    [
      for (final n in data.nodes.values)
        if ((n.yieldOf(item) > 0 || n.rareFind == item) && !nodeFogged(s, n.id))
          n.id,
    ],
  );
}
