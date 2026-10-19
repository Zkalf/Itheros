import 'dart:math' as math;

import 'activity.dart';
import 'data.dart';
import 'events.dart';
import 'goal.dart';
import 'news.dart';
import 'rng.dart';
import 'state.dart';

/// The game rules. Stateless: every method takes a [GameState] and returns a
/// new one, leaving its input untouched.
class Game {
  Game(this.data);

  final GameData data;

  GameState newGame({required int seed}) =>
      GameState(location: data.startLocation, rngState: Rng.seeded(seed).state);

  int level(GameState s) => data.levelForXp(s.xp);

  int bankCap(GameState s) {
    var cap = data.bankCapBase + data.bankCapPerLevel * level(s);
    for (final id in s.achievements) {
      cap += data.achievements[id]?.bankCapReward ?? 0;
    }
    return cap;
  }

  Stats stats(GameState s) {
    var total = data.baseStats + data.statsPerLevel * (level(s) - 1);
    final open = openSlots(s);
    s.equipment.forEach((slot, item) {
      if (open.contains(slot)) total += data.items[item]!.bonus;
    });
    return total;
  }

  /// Total XP needed for the next level. There is no level cap.
  int xpForNextLevel(GameState s) => data.xpForLevel(level(s) + 1);

  /// Gear slots open at the player's level, in display order.
  List<String> openSlots(GameState s) => [
    for (final e in data.gearSlots.entries)
      if (e.value <= level(s)) e.key,
  ];

  /// Colour and XP share of [enemy] for this player (spec 0002 §3).
  LevelBand enemyBand(GameState s, String enemy) =>
      data.bandFor(data.enemies[enemy]!.level, level(s));

  /// The rank held at [level].
  RankDef rank(int level) => data.ranks.lastWhere((r) => r.level <= level);

  /// Talent points earned by [level] (spec 0002 decision 7).
  int talentPoints(int level) => math.max(0, level - data.talentPointsFrom + 1);

  /// What reaching [level] brings, for its level-up card (spec 0002 §9.1).
  List<LevelNews> levelNews(int level) {
    final enemies = data.enemies.values.where((e) => e.unlockLevel <= level);
    return [
      for (final r in data.ranks)
        if (r.level == level && level > 1) LevelNews(NewsKind.rank, r.name),
      for (final l in data.locations.values)
        if (l.unlockLevel == level) LevelNews(NewsKind.area, l.id),
      for (final e in data.enemies.values)
        if (e.unlockLevel == level) LevelNews(NewsKind.monster, e.id),
      for (final n in data.nodes.values)
        if (n.unlockLevel == level) LevelNews(NewsKind.gatheringSpot, n.id),
      for (final r in data.recipes.values)
        if (r.unlockLevel == level) LevelNews(NewsKind.recipe, r.id),
      for (final e in data.gearSlots.entries)
        if (e.value == level && level > 1) LevelNews(NewsKind.gearSlot, e.key),
      for (final e in data.queueSlots.entries)
        if (e.key == level && level > 1)
          LevelNews(NewsKind.queueSlots, '${e.value}'),
      if (level == data.untilFromLevel) const LevelNews(NewsKind.untilN, ''),
      if (level >= data.talentPointsFrom)
        const LevelNews(NewsKind.talentPoint, ''),
      for (final e in enemies)
        if (e.level == level) LevelNews(NewsKind.yourLevel, e.id),
      for (final e in enemies)
        if (data.bandFor(e.level, level).colour == LevelColour.grey &&
            data.bandFor(e.level, level - 1).colour != LevelColour.grey)
          LevelNews(NewsKind.turnedGrey, e.id),
    ];
  }

  /// What to do next, or null when nothing applies (spec 0002 §9.3).
  Goal? nextGoal(GameState s) {
    final lvl = level(s);
    final open = openSlots(s);
    int worn(String slot) => data.items[s.equipment[slot]]?.score ?? 0;
    int gain(String item) =>
        data.items[item]!.score - worn(data.items[item]!.slot!);

    final better = [
      for (final item in s.inventory.keys)
        if (data.items[item]?.slot case final slot?)
          if (open.contains(slot) && gain(item) > 0) item,
    ]..sort((a, b) => gain(b).compareTo(gain(a)));
    if (better.isNotEmpty) return EquipGoal(better.first);

    final upgrades = [
      for (final r in data.recipes.values)
        if (r.unlockLevel <= lvl)
          if (data.items[r.output]!.slot case final slot?)
            if (open.contains(slot) &&
                (s.inventory[r.output] ?? 0) == 0 &&
                s.equipment[slot] != r.output &&
                gain(r.output) > 0)
              r,
    ]..sort((a, b) => gain(b.output).compareTo(gain(a.output)));
    for (final r in upgrades) {
      if (hasMaterials(s, r.id)) return CraftGoal(r.id);
    }
    for (final r in upgrades) {
      for (final input in r.inputs.entries) {
        final missing = input.value - (s.inventory[input.key] ?? 0);
        if (missing <= 0) continue;
        final source = _safeSource(s, input.key);
        if (source != null) return CollectGoal(input.key, missing, source);
        break;
      }
    }

    EnemyDef? best;
    var bestRate = 0.0;
    final me = stats(s);
    for (final e in data.enemies.values) {
      if (e.unlockLevel > lvl ||
          enemyBand(s, e.id).colour != LevelColour.yellow) {
        continue;
      }
      final hit = math.max(1, me.attack - e.stats.defense / 2);
      final rate = e.xp / (e.stats.hp / hit).ceil();
      if (rate > bestRate) (best, bestRate) = (e, rate);
    }
    return best == null ? null : FightGoal(best.id);
  }

  /// A gathering spot for [item], or the most generous monster dropping it
  /// that is at most yellow.
  Activity? _safeSource(GameState s, String item) {
    final lvl = level(s);
    for (final n in data.nodes.values) {
      if (n.item == item && n.unlockLevel <= lvl) return Activity.gather(n.id);
    }
    EnemyDef? best;
    var bestChance = 0.0;
    for (final e in data.enemies.values) {
      if (e.unlockLevel > lvl || e.level > lvl + 2) continue;
      for (final d in e.drops) {
        if (d.item == item && d.chance * d.count > bestChance) {
          (best, bestChance) = (e, d.chance * d.count);
        }
      }
    }
    return best == null ? null : Activity.fight(best.id);
  }

  /// Brings a state read from an older save up to date. Version 1 saves
  /// keep their level and their progress through it (spec 0002 §2). Version
  /// 2 saves need nothing: their activity loaded as a 1-action queue.
  GameState migrate(GameState s) {
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

  int _costOf(GameState s, RunningActivity act) {
    final a = act.activity;
    if (act.leg case final leg?) return data.route(s.location, leg)!.steps;
    return switch (a.kind) {
      // A version 2 save walking to a neighbour, with no leg set.
      ActivityKind.travel => data.route(s.location, a.target)!.steps,
      ActivityKind.fight => data.combatRoundSteps,
      ActivityKind.gather => data.nodes[a.target]!.steps,
      ActivityKind.craft => data.recipes[a.target]!.steps,
    };
  }

  // Queries for the UI. Locked content is left out, not greyed out (spec §5).

  List<String> travelDestinations(GameState s) => [
    for (final to in data.destinationsFrom(s.location))
      if (data.locations[to]!.unlockLevel <= level(s)) to,
  ];

  List<String> availableEnemies(GameState s) => [
    for (final e in _here(s).enemies)
      if (data.enemies[e]!.unlockLevel <= level(s)) e,
  ];

  List<String> availableNodes(GameState s) => [
    for (final n in _here(s).nodes)
      if (data.nodes[n]!.unlockLevel <= level(s)) n,
  ];

  List<String> availableRecipes(GameState s) => [
    if (_here(s).crafting)
      for (final r in data.recipes.values)
        if (r.unlockLevel <= level(s)) r.id,
  ];

  /// Open locations, nearest first, with their walking distance from here
  /// (spec 0003 §8: plan a day from anywhere).
  Map<String, int> openLocationsByDistance(GameState s) {
    final dist = _paths(s).$1;
    return Map.fromEntries(
      dist.entries.toList()..sort((a, b) => a.value.compareTo(b.value)),
    );
  }

  /// Unlocked monsters at [location], if it is open.
  List<String> enemiesAt(GameState s, String location) => [
    if (data.locations[location]!.unlockLevel <= level(s))
      for (final e in data.locations[location]!.enemies)
        if (data.enemies[e]!.unlockLevel <= level(s)) e,
  ];

  /// Unlocked gathering spots at [location], if it is open.
  List<String> nodesAt(GameState s, String location) => [
    if (data.locations[location]!.unlockLevel <= level(s))
      for (final n in data.locations[location]!.nodes)
        if (data.nodes[n]!.unlockLevel <= level(s)) n,
  ];

  /// Unlocked recipes (they can be crafted at any crafting place).
  List<String> unlockedRecipes(GameState s) => [
    for (final r in data.recipes.values)
      if (r.unlockLevel <= level(s)) r.id,
  ];

  bool hasMaterials(GameState s, String recipe) => data
      .recipes[recipe]!
      .inputs
      .entries
      .every((e) => (s.inventory[e.key] ?? 0) >= e.value);

  /// Owned [item]s, equipped ones included.
  int owned(GameState s, String item) =>
      (s.inventory[item] ?? 0) +
      s.equipment.values.where((i) => i == item).length;

  /// How many actions the queue holds at the player's level, the running
  /// one included (spec 0003 §2).
  int queueSlots(GameState s) =>
      data.queueSlots.entries.lastWhere((e) => e.key <= level(s)).value;

  /// Whether "until I have N" and "until N crafted" are open.
  bool countConditionsOpen(GameState s) => level(s) >= data.untilFromLevel;

  /// The conditions [a] may stop on; "never" may still be refused by its
  /// place in the queue.
  List<StopKind> stopKindsFor(GameState s, Activity a) => [
    if (a.kind == ActivityKind.fight) StopKind.untilGrey,
    if (countConditionsOpen(s))
      if (a.kind == ActivityKind.fight || a.kind == ActivityKind.gather)
        StopKind.untilHave
      else if (a.kind == ActivityKind.craft)
        StopKind.untilCrafted,
    StopKind.never,
  ];

  /// Items "until I have N" can count for [a]: a monster's drops or a
  /// spot's item.
  List<String> countableItems(Activity a) => switch (a.kind) {
    ActivityKind.fight => {
      for (final d in data.enemies[a.target]!.drops) d.item,
    }.toList(),
    ActivityKind.gather => [data.nodes[a.target]!.item],
    _ => const [],
  };

  // Player actions. Free: they cost no steps.

  /// Adds [a] to the end of the queue with [stop] (default: until grey for
  /// fights, never otherwise). With nothing running, or a 1-slot queue, it
  /// starts now instead (spec 0003 §2). Throws [ActivityError] if the rules
  /// don't allow it.
  GameState addAction(GameState s, Activity a, {StopCondition? stop}) {
    final st = stop ?? StopCondition.defaultFor(a);
    if (s.activity == null || queueSlots(s) == 1) {
      return startActivity(s, a, stop: st);
    }
    _checkStop(s, a, st);
    if (1 + s.queue.length >= queueSlots(s)) {
      throw ActivityError('The queue is full.');
    }
    final last = s.queue.isEmpty
        ? PlannedAction(s.activity!.activity, s.activity!.stop)
        : s.queue.last;
    if (last.stop.kind == StopKind.never &&
        last.activity.kind != ActivityKind.travel) {
      throw ActivityError(
        'The last action never stops. Change its stop condition first.',
      );
    }
    final why = _cannotStart(s, a, st);
    if (why == SkipReason.locked || why == SkipReason.noRoute) {
      throw ActivityError(_explain(s, a, st, why!));
    }
    return s.copy()..queue.add(PlannedAction(a, st));
  }

  /// Starts [a] now with [stop], replacing (and refunding the progress of)
  /// the running action; the rest of the queue stays. If [a] happens
  /// elsewhere, the character walks there first. Throws [ActivityError] if
  /// it can't start.
  GameState startActivity(
    GameState s,
    Activity a, {
    StopCondition stop = const StopCondition.never(),
  }) {
    _checkStop(s, a, stop);
    final why = _cannotStart(s, a, stop);
    if (why != null) throw ActivityError(_explain(s, a, stop, why));
    final n = _refundProgress(s.copy())
      ..activity = RunningActivity(a, stop: stop);
    n.activity!.leg = _nextLeg(n, a);
    return n;
  }

  /// Ends the running action and starts the next one; with nothing next the
  /// character rests. Unspent progress goes to the bank (spec 0001
  /// amendment 2).
  GameState stopActivity(GameState s) {
    if (s.activity == null) throw ActivityError('Nothing to stop');
    final n = _refundProgress(s.copy())..activity = null;
    _startNext(n, null);
    return n;
  }

  /// Removes the action at [index]: 0 is the running one (the same as
  /// [stopActivity]), 1 the first waiting one, and so on.
  GameState removeAction(GameState s, int index) {
    if (index == 0) return stopActivity(s);
    if (index < 1 || index > s.queue.length) {
      throw ActivityError('No action $index in the queue');
    }
    return s.copy()..queue.removeAt(index - 1);
  }

  /// Throws if [stop] doesn't fit [a] (spec 0003 §3).
  void _checkStop(GameState s, Activity a, StopCondition stop) {
    if (!stopKindsFor(s, a).contains(stop.kind)) {
      throw ActivityError('That stop condition is not possible here.');
    }
    if (stop.kind == StopKind.untilHave &&
        (!countableItems(a).contains(stop.item) || stop.count < 1)) {
      throw ActivityError('That item does not come from here.');
    }
    if (stop.kind == StopKind.untilCrafted && stop.count < 1) {
      throw ActivityError('Craft at least one.');
    }
  }

  /// Why [a] can't start now, or null if it can (spec 0003 §4).
  SkipReason? _cannotStart(GameState s, Activity a, StopCondition stop) {
    final lvl = level(s);
    final opensAt = switch (a.kind) {
      ActivityKind.travel => data.locations[a.target]?.unlockLevel,
      ActivityKind.fight => data.enemies[a.target]?.unlockLevel,
      ActivityKind.gather => data.nodes[a.target]?.unlockLevel,
      ActivityKind.craft => data.recipes[a.target]?.unlockLevel,
    };
    if (opensAt == null || opensAt > lvl) return SkipReason.locked;
    if (a.kind == ActivityKind.travel && a.target == s.location) {
      return SkipReason.alreadyDone;
    }
    if (_placeFor(s, a) == null) return SkipReason.noRoute;
    if (a.kind == ActivityKind.craft && !hasMaterials(s, a.target)) {
      return SkipReason.noMaterials;
    }
    if (_stopMet(s, a, stop, crafted: 0) != null) return SkipReason.alreadyDone;
    return null;
  }

  String _explain(GameState s, Activity a, StopCondition stop, SkipReason r) {
    final name =
        switch (a.kind) {
          ActivityKind.travel => data.locations[a.target]?.name,
          ActivityKind.fight => data.enemies[a.target]?.name,
          ActivityKind.gather => data.nodes[a.target]?.name,
          ActivityKind.craft =>
            data.items[data.recipes[a.target]?.output]?.name,
        } ??
        a.target;
    return switch (r) {
      SkipReason.locked => '$name is locked',
      SkipReason.noRoute => 'No open route to $name',
      SkipReason.noMaterials => 'Not enough materials for $name',
      SkipReason.alreadyDone => switch (stop.kind) {
        _ when a.kind == ActivityKind.travel => 'You are already at $name',
        StopKind.untilGrey => 'The $name is already grey',
        _ => 'You already have ${stop.count} ${data.items[stop.item]?.name}',
      },
    };
  }

  /// Why an action stops by its condition now, or null (spec 0003 §3).
  EndReason? _stopMet(
    GameState s,
    Activity a,
    StopCondition stop, {
    required int crafted,
  }) => switch (stop.kind) {
    StopKind.untilGrey =>
      enemyBand(s, a.target).colour == LevelColour.grey ? EndReason.grey : null,
    StopKind.untilHave =>
      owned(s, stop.item!) >= stop.count ? EndReason.enough : null,
    StopKind.untilCrafted => crafted >= stop.count ? EndReason.enough : null,
    StopKind.never => null,
  };

  /// Where [a] happens: its monster's or spot's location, the nearest
  /// crafting place, or the travel target. Null if no open route leads
  /// there.
  String? _placeFor(GameState s, Activity a) {
    final dist = _paths(s).$1;
    final candidates = switch (a.kind) {
      ActivityKind.travel => [a.target],
      ActivityKind.fight => [
        for (final l in data.locations.values)
          if (l.enemies.contains(a.target)) l.id,
      ],
      ActivityKind.gather => [
        for (final l in data.locations.values)
          if (l.nodes.contains(a.target)) l.id,
      ],
      ActivityKind.craft => [
        for (final l in data.locations.values)
          if (l.crafting) l.id,
      ],
    }.where(dist.containsKey).toList();
    if (candidates.isEmpty) return null;
    return candidates.reduce((x, y) => dist[x]! <= dist[y]! ? x : y);
  }

  /// The first leg toward where [a] happens, or null when already there.
  String? _nextLeg(GameState s, Activity a) {
    final to = _placeFor(s, a);
    if (to == null || to == s.location) return null;
    final previous = _paths(s).$2;
    var at = to;
    while (previous[at] != s.location) {
      at = previous[at]!;
    }
    return at;
  }

  /// Shortest walking distances from here to every open location, and the
  /// previous stop on each shortest route.
  (Map<String, int>, Map<String, String>) _paths(GameState s) {
    final lvl = level(s);
    final dist = {s.location: 0};
    final previous = <String, String>{};
    final todo = {s.location};
    while (todo.isNotEmpty) {
      final at = todo.reduce((a, b) => dist[a]! <= dist[b]! ? a : b);
      todo.remove(at);
      for (final to in data.destinationsFrom(at)) {
        if (data.locations[to]!.unlockLevel > lvl) continue;
        final d = dist[at]! + data.route(at, to)!.steps;
        if (d < (dist[to] ?? 1 << 30)) {
          dist[to] = d;
          previous[to] = at;
          todo.add(to);
        }
      }
    }
    return (dist, previous);
  }

  /// Starts the first waiting action that can start, skipping the others
  /// with a reason. Mutates [s].
  void _startNext(GameState s, List<GameEvent>? events) {
    while (s.queue.isNotEmpty) {
      final p = s.queue.removeAt(0);
      final why = _cannotStart(s, p.activity, p.stop);
      if (why != null) {
        events?.add(ActionSkipped(p.activity, why));
        continue;
      }
      s.activity = RunningActivity(p.activity, stop: p.stop)
        ..leg = _nextLeg(s, p.activity);
      events?.add(ActionStarted(p.activity));
      return;
    }
  }

  /// Moves the current activity's unspent progress into the bank, up to the
  /// cap. Mutates and returns [s].
  GameState _refundProgress(GameState s) {
    final progress = s.activity?.progress ?? 0;
    s.bank = math.min(bankCap(s), s.bank + progress);
    s.activity?.progress = 0;
    return s;
  }

  GameState equip(GameState s, String item) {
    final slot = data.items[item]?.slot;
    if (slot == null) throw ActivityError('$item cannot be equipped');
    if (!openSlots(s).contains(slot)) throw ActivityError('$slot is locked');
    if ((s.inventory[item] ?? 0) < 1) throw ActivityError('No $item to equip');
    final n = s.copy()..addItem(item, -1);
    final old = n.equipment[slot];
    if (old != null) n.addItem(old);
    n.equipment[slot] = item;
    return n;
  }

  GameState unequip(GameState s, String slot) {
    final item = s.equipment[slot];
    if (item == null) throw ActivityError('Nothing equipped in $slot');
    return s.copy()
      ..equipment.remove(slot)
      ..addItem(item);
  }

  /// Applies [walked] real steps, one at a time, as spec 0001 §2.2 says.
  StepReport applySteps(GameState input, int walked) {
    if (walked < 0) throw ArgumentError.value(walked, 'walked', 'negative');
    final run = _Run(this, input.copy());
    for (var i = 0; i < walked; i++) {
      run.step();
    }
    return run.report(walked);
  }

  LocationDef _here(GameState s) => data.locations[s.location]!;
}

/// Mutable bookkeeping for one [Game.applySteps] call.
class _Run {
  _Run(this.game, this.s) : rng = Rng.fromState(s.rngState);

  final Game game;
  final GameState s;
  final Rng rng;
  final events = <GameEvent>[];
  var activitySteps = 0;
  var boostUsed = 0;
  var banked = 0;
  var lost = 0;

  GameData get data => game.data;

  void step() {
    s.count('steps.walked');
    final act = s.activity;
    if (act != null) {
      final boost = s.bank > 0 ? 1 : 0;
      s.bank -= boost;
      boostUsed += boost;
      activitySteps += 1 + boost;
      act.progress += 1 + boost;
      _advance(act);
    } else if (s.bank < game.bankCap(s)) {
      s.bank++;
      banked++;
    } else {
      lost++;
    }
    _checkAchievements();
  }

  StepReport report(int walked) {
    s.rngState = rng.state;
    return StepReport(
      state: s,
      walked: walked,
      activitySteps: activitySteps,
      boostUsed: boostUsed,
      banked: banked,
      lost: lost,
      events: events,
    );
  }

  /// Completes every unit the paid progress covers: travel legs first, then
  /// the action's own units. A unit is never left half-paid: when the action
  /// stops (its condition, out of materials, 3 losses, arrival), leftover
  /// progress goes to the bank and the next action starts (spec 0003 §4).
  void _advance(RunningActivity act) {
    while (identical(s.activity, act)) {
      final cost = game._costOf(s, act);
      if (act.progress < cost) return;
      act.progress -= cost;
      if (act.leg case final leg?) {
        s.location = leg;
        events.add(Arrived(leg));
        act.leg = game._nextLeg(s, act.activity);
        if (act.activity.kind == ActivityKind.travel && act.leg == null) {
          _end(act, EndReason.arrived);
        }
        continue;
      }
      final ended = _completeUnit(act);
      if (ended != null) {
        _end(act, ended);
        continue;
      }
      if (act.fight == null) {
        final done = game._stopMet(
          s,
          act.activity,
          act.stop,
          crafted: act.crafted,
        );
        if (done != null) {
          _end(act, done);
          continue;
        }
      }
      if (!_canStartNext(act.activity)) _end(act, EndReason.noMaterials);
    }
  }

  bool _canStartNext(Activity a) =>
      a.kind != ActivityKind.craft || game.hasMaterials(s, a.target);

  /// Returns why the activity ends, or null if it continues.
  EndReason? _completeUnit(RunningActivity act) {
    final a = act.activity;
    switch (a.kind) {
      case ActivityKind.travel:
        s.location = a.target;
        events.add(Arrived(a.target));
        return EndReason.arrived;
      case ActivityKind.fight:
        return _combatRound(act);
      case ActivityKind.gather:
        final node = data.nodes[a.target]!;
        final xp = _faded(node.xp, node.unlockLevel);
        s.addItem(node.item);
        s.count('gathered.${node.item}');
        events.add(Gathered(node.item, xp));
        _gainXp(xp);
        return null;
      case ActivityKind.craft:
        final recipe = data.recipes[a.target]!;
        final xp = _faded(recipe.xp, recipe.unlockLevel);
        recipe.inputs.forEach((item, n) => s.addItem(item, -n));
        s.addItem(recipe.output);
        act.crafted++;
        s.count('crafted.total');
        s.count('crafted.${recipe.output}');
        events.add(Crafted(recipe.output, xp));
        _gainXp(xp);
        return null;
    }
  }

  /// One auto-resolved round. The player strikes first unless the monster is
  /// quick. HP is full at the start of each fight (spec 0001 §4). Traits:
  /// spec 0002 §5.1.
  EndReason? _combatRound(RunningActivity act) {
    final enemy = data.enemies[act.activity.target]!;
    final me = game.stats(s);
    final fight = act.fight ??= FightState(
      playerHp: me.hp,
      enemyHp: enemy.stats.hp,
    );
    fight.round++;

    if (enemy.has(Trait.quick)) {
      if (_monsterTurn(enemy, fight, me)) return _lose(act, enemy);
      if (_playerTurn(enemy, fight, me)) return _win(act, enemy);
    } else {
      if (_playerTurn(enemy, fight, me)) return _win(act, enemy);
      if (_monsterTurn(enemy, fight, me)) return _lose(act, enemy);
    }
    return null;
  }

  /// Returns whether the monster died.
  bool _playerTurn(EnemyDef enemy, FightState fight, Stats me) {
    fight.enemyHp -= _damage(me.attack, enemy.stats.defense);
    return fight.enemyHp <= 0;
  }

  /// Returns whether the player died.
  bool _monsterTurn(EnemyDef enemy, FightState fight, Stats me) {
    if (!enemy.has(Trait.slow) || fight.round.isEven) {
      final defense = enemy.has(Trait.ghostly) ? 0 : me.defense;
      fight.playerHp -= _damage(enemy.stats.attack, defense);
      if (fight.playerHp <= 0) return true;
    }
    fight.enemyHp = math.min(enemy.stats.hp, fight.enemyHp + enemy.regen);
    return false;
  }

  EndReason? _win(RunningActivity act, EnemyDef enemy) {
    act.fight = null;
    act.lossStreak = 0;
    final drops = <String, int>{};
    void drop(DropDef d) {
      drops[d.item] = (drops[d.item] ?? 0) + d.count;
      s.addItem(d.item, d.count);
    }

    for (final d in enemy.drops) {
      if (rng.nextDouble() < d.chance) drop(d);
    }
    if ((s.counters['kills.${enemy.id}'] ?? 0) == 0) {
      enemy.firstKillDrops.forEach(drop);
    }
    final xp = _faded(enemy.xp, enemy.level);
    s.count('kills.${enemy.id}');
    events.add(FightWon(enemy.id, xp, drops));
    _gainXp(xp);
    return null;
  }

  /// A loss keeps everything and pays a share of the XP for the health
  /// knocked off; no loot. The action gives up after a few losses in a row
  /// (spec 0003 §5).
  EndReason? _lose(RunningActivity act, EnemyDef enemy) {
    final share = (enemy.stats.hp - act.fight!.enemyHp) / enemy.stats.hp;
    act.fight = null;
    final pct = data.bandFor(enemy.level, game.level(s)).xpPercent;
    final xp = share <= 0
        ? 0
        : math.max(
            1,
            (enemy.xp * data.lossXpShare * share * pct / 100).floor(),
          );
    events.add(FightLost(enemy.id, xp, share));
    _gainXp(xp);
    act.lossStreak++;
    return act.lossStreak >= data.lossesToGiveUp ? EndReason.defeated : null;
  }

  /// [xp] for something at [level], faded by the colour table; at least 1
  /// (spec 0002 §3).
  int _faded(int xp, int level) {
    final band = data.bandFor(level, game.level(s));
    return math.max(1, xp * band.xpPercent ~/ 100);
  }

  int _damage(int attack, int defense) {
    final base = math.max(1.0, attack - defense / 2);
    final v = data.damageVariance;
    final roll = 1 - v + 2 * v * rng.nextDouble();
    return math.max(1, (base * roll).round());
  }

  void _gainXp(int amount) {
    final before = game.level(s);
    s.xp += amount;
    final after = game.level(s);
    for (var l = before + 1; l <= after; l++) {
      events.add(LevelUp(l));
    }
  }

  void _end(RunningActivity act, EndReason reason) {
    game._refundProgress(s).activity = null;
    events.add(ActivityEnded(act.activity, reason));
    game._startNext(s, events);
  }

  void _checkAchievements() {
    for (final a in data.achievements.values) {
      if (!s.achievements.contains(a.id) &&
          (s.counters[a.counter] ?? 0) >= a.atLeast) {
        s.achievements.add(a.id);
        events.add(AchievementUnlocked(a.id));
      }
    }
  }
}
