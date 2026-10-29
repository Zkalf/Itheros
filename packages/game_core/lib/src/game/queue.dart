part of '../game.dart';

/// The queue: adding, starting, stopping and changing actions, and the walks between them.
extension GameQueue on Game {
  /// The conditions [a] may stop on; "never" may still be refused by its
  /// place in the queue.
  List<StopKind> stopKindsFor(GameState s, Activity a) => [
    if (a.kind == ActivityKind.fight) StopKind.untilGrey,
    if (a.kind == ActivityKind.fight || a.kind == ActivityKind.gather)
      StopKind.untilHave
    else if (a.kind == ActivityKind.craft) ...[
      // Meals: "until I have N" (spec 0011 §5.1).
      if (data.recipes[a.target]?.profession == 'cooking') StopKind.untilHave,
      StopKind.untilCrafted,
      StopKind.untilQuality,
    ],
    // A reroll is one roll (spec 0010 §7.2).
    if (a.kind != ActivityKind.reroll)
      StopKind.never
    else
      StopKind.untilCrafted,
  ];

  /// Items "until I have N" can count for [a]: a monster's drops or a
  /// spot's item.
  List<String> countableItems(Activity a) => switch (a.kind) {
    ActivityKind.fight => {
      for (final d in data.enemies[a.target]!.drops) d.item,
    }.toList(),
    ActivityKind.gather => switch (data.nodes[a.target]!) {
      final n => {
        n.item,
        for (final c in n.catches) c.item,
        if (n.catches.isNotEmpty) ?n.rareFind,
      }.toList(),
    },
    ActivityKind.craft => [data.recipes[a.target]!.output],
    _ => const [],
  };

  /// The last planned action (running or queued) never stops, so nothing
  /// can wait behind it (spec 0003 decision 3). Travel always ends.
  bool lastNeverStops(GameState s) {
    final last = s.queue.isEmpty
        ? switch (s.activity) {
            final run? => PlannedAction(run.activity, run.stop),
            null => null,
          }
        : s.queue.last;
    return last != null &&
        last.stop.kind == StopKind.never &&
        last.activity.kind != ActivityKind.travel;
  }

  // Player actions. Free: they cost no steps.

  /// Adds [a] to the end of the queue with [stop] (default: until grey for
  /// fights, never otherwise), after a walk to its nearest place if it can't
  /// happen where the queue ends (spec 0016 §3.2). With nothing running it
  /// starts now instead. Throws [ActivityError] if the rules don't allow it.
  GameState addAction(GameState s, Activity a, {StopCondition? stop}) {
    final st = stop ?? StopCondition.defaultFor(a);
    if (s.activity == null) return startActivity(s, a, stop: st);
    _checkStop(s, a, st);
    final free = queueSlots(s) - 1 - s.queue.length;
    if (free < 1) throw ActivityError('The queue is full.');
    if (lastNeverStops(s)) {
      throw ActivityError(
        'The last action never stops. Change its stop condition first.',
      );
    }
    final why = _cannotStart(s, a, st);
    if (why == SkipReason.locked || why == SkipReason.noRoute) {
      throw ActivityError(_explain(s, a, st, why!));
    }
    final end = queuePlaces(s).last;
    if (a.kind == ActivityKind.travel && a.target == end) {
      throw ActivityError(
        'The queue already ends at ${data.locations[end]!.name}.',
      );
    }
    if (_happensAt(end, a)) return s.copy()..queue.add(PlannedAction(a, st));
    final place = _placeFor(s, a, from: end);
    if (place == null) {
      throw ActivityError(_explain(s, a, st, SkipReason.noRoute));
    }
    if (free < 2) {
      throw ActivityError(
        'The queue is full. The walk to ${data.locations[place]!.name} '
        'needs a slot too.',
      );
    }
    final walk = Activity.travel(place);
    return s.copy()
      ..queue.addAll([
        PlannedAction(walk, StopCondition.defaultFor(walk)),
        PlannedAction(a, st),
      ]);
  }

  /// Where the queue stands before each waiting action, then where it ends:
  /// a walk moves the place, any other action happens where it stands
  /// (spec 0016 §3.1).
  List<String> queuePlaces(GameState s) {
    var at = switch (s.activity?.activity) {
      Activity(kind: ActivityKind.travel, :final target) => target,
      _ => s.location,
    };
    final places = <String>[];
    for (final p in s.queue) {
      places.add(at);
      if (p.activity.kind == ActivityKind.travel) at = p.activity.target;
    }
    return places..add(at);
  }

  /// The walk that [a] needs first if the player adds it now, from where
  /// the queue ends, or null if it needs none (spec 0016 §7.2).
  ({String place, int steps})? walkFirst(GameState s, Activity a) {
    if (a.kind == ActivityKind.travel) return null;
    final end = queuePlaces(s).last;
    if (_happensAt(end, a)) return null;
    final place = _placeFor(s, a, from: end);
    if (place == null) return null;
    return (place: place, steps: walkSteps(s, end, place)!);
  }

  /// The steps of the shortest open route from [from] to [to], or null if
  /// none leads there.
  int? walkSteps(GameState s, String from, String to) =>
      _paths(s, from: from).$1[to];

  /// Whether the walk at [index] (0: the running one) is still needed: the
  /// action after it can't happen where the queue stands before it (spec
  /// 0016 §4.2).
  bool walkNeeded(GameState s, int index) {
    final walk = index == 0
        ? s.activity?.activity
        : s.queue.elementAtOrNull(index - 1)?.activity;
    if (walk?.kind != ActivityKind.travel) return false;
    final next = s.queue.elementAtOrNull(index)?.activity;
    if (next == null || next.kind == ActivityKind.travel) return false;
    final before = index == 0 ? s.location : queuePlaces(s)[index - 1];
    return !_happensAt(before, next);
  }

  /// Throws if the walk at [index] is still needed (spec 0016 §4.3).
  void _keepNeededWalk(GameState s, int index) {
    if (!walkNeeded(s, index)) return;
    final name = _nameOf(s.queue[index].activity);
    throw ActivityError('$name needs this walk. Remove $name first.');
  }

  /// Whether [a] can happen at [place]. A walk can start anywhere.
  bool _happensAt(String place, Activity a) {
    final l = data.locations[place]!;
    return switch (a.kind) {
      ActivityKind.travel => true,
      ActivityKind.fight => l.enemies.contains(a.target),
      ActivityKind.gather => l.nodes.contains(a.target),
      ActivityKind.craft => switch (data.recipes[a.target]) {
        final r? => _makesHere(l, r),
        null => false,
      },
      ActivityKind.reroll => l.crafting,
    };
  }

  /// Starts [a] now with [stop], replacing (and refunding the progress of)
  /// the running action and clearing the queue (spec 0016 §5). If [a]
  /// happens elsewhere, a walk there runs first and [a] waits after it.
  /// Throws [ActivityError] if it can't start.
  GameState startActivity(GameState s, Activity a, {StopCondition? stop}) {
    // A reroll is one roll; everything else runs until stopped.
    stop ??= a.kind == ActivityKind.reroll
        ? StopCondition.defaultFor(a)
        : const StopCondition.never();
    _checkStop(s, a, stop);
    final why = _cannotStart(s, a, stop);
    if (why != null) throw ActivityError(_explain(s, a, stop, why));
    final n = _refundProgress(s.copy())..queue.clear();
    if (_happensAt(n.location, a)) {
      n.activity = RunningActivity(a, stop: stop);
    } else {
      final walk = Activity.travel(_placeFor(n, a)!);
      n
        ..activity = RunningActivity(walk)
        ..queue.add(PlannedAction(a, stop));
    }
    n.activity!.leg = _nextLeg(n, n.activity!.activity);
    return n;
  }

  /// Ends the running action and starts the next one; with nothing next the
  /// character rests. Unspent progress goes to the bank (spec 0001
  /// amendment 2). Waiting actions that can't start are skipped and added
  /// to [events].
  GameState stopActivity(GameState s, {List<GameEvent>? events}) {
    if (s.activity == null) throw ActivityError('Nothing to stop');
    _keepNeededWalk(s, 0);
    final n = _refundProgress(s.copy())..activity = null;
    _startNext(n, events);
    return n;
  }

  /// Removes the action at [index]: 0 is the running one (the same as
  /// [stopActivity]), 1 the first waiting one, and so on.
  GameState removeAction(GameState s, int index, {List<GameEvent>? events}) {
    if (index == 0) return stopActivity(s, events: events);
    if (index < 1 || index > s.queue.length) {
      throw ActivityError('No action $index in the queue');
    }
    _keepNeededWalk(s, index);
    return s.copy()..queue.removeAt(index - 1);
  }

  /// Gives the action at [index] the stop condition [stop]: 0 is the
  /// running one, 1 the first waiting one, and so on. The action keeps its
  /// place and its progress (spec 0016 amendment 2 §2). A running action
  /// whose new goal is reached ends now, or after the fight in progress
  /// (§3); [events] gets its end and the next action's start. With
  /// [expected], it refuses when another action now holds [index]: a sync
  /// can move the queue after the player picks the action.
  GameState changeStop(
    GameState s,
    int index,
    StopCondition stop, {
    Activity? expected,
    List<GameEvent>? events,
  }) {
    final a = _actionAt(s, index, expected);
    if (a.kind == ActivityKind.travel) {
      throw ActivityError('A walk ends when it arrives.');
    }
    if (a.kind == ActivityKind.reroll) {
      throw ActivityError('A reroll is one roll.');
    }
    _checkStop(s, a, stop);
    if (stop.kind == StopKind.never && index < s.queue.length) {
      throw ActivityError('Only the last action can go on without a stop.');
    }
    final n = s.copy();
    if (index > 0) {
      n.queue[index - 1] = PlannedAction(a, stop);
      return n;
    }
    final run = n.activity!..stop = stop;
    if (run.fight == null && stopReached(n, 0, stop)) {
      final reason = _stopMet(
        n,
        a,
        stop,
        crafted: run.crafted,
        gained: run.gained,
      )!;
      _refundProgress(n).activity = null;
      events?.add(ActivityEnded(a, reason));
      _startNext(n, events);
    }
    return n;
  }

  /// Whether the goal of [stop] is reached already for the action at
  /// [index]. The running action counts what it crafted and gained. False
  /// when [index] holds no action, or not [expected].
  bool stopReached(
    GameState s,
    int index,
    StopCondition stop, {
    Activity? expected,
  }) {
    final Activity a;
    try {
      a = _actionAt(s, index, expected);
    } on ActivityError {
      return false;
    }
    final run = index == 0 ? s.activity : null;
    return _stopMet(
          s,
          a,
          stop,
          crafted: run?.crafted ?? 0,
          gained: run?.gained ?? const {},
        ) !=
        null;
  }

  /// The action at [index] in the queue: 0 is the running one. Throws when
  /// there is none, or when it is not [expected].
  Activity _actionAt(GameState s, int index, [Activity? expected]) {
    final a = switch (index) {
      0 => s.activity?.activity,
      _ when index >= 1 && index <= s.queue.length =>
        s.queue[index - 1].activity,
      _ => null,
    };
    if (expected != null && a != expected) {
      throw ActivityError('The queue changed. Open the action again.');
    }
    return a ?? (throw ActivityError('No action $index in the queue'));
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
    if (stop.kind == StopKind.untilQuality && _tier(stop.item) < 1) {
      throw ActivityError('Pick a quality better than common.');
    }
  }

  /// Why [a] can't start now, or null if it can (spec 0003 §4).
  SkipReason? _cannotStart(GameState s, Activity a, StopCondition stop) {
    final known = switch (a.kind) {
      ActivityKind.travel => data.locations.containsKey(a.target),
      ActivityKind.fight => data.enemies.containsKey(a.target),
      ActivityKind.gather => data.nodes.containsKey(a.target),
      ActivityKind.craft => data.recipes.containsKey(a.target),
      ActivityKind.reroll => data.itemOf(a.rerollKey) != null,
    };
    if (!known) return SkipReason.locked;
    if (a.kind == ActivityKind.reroll) {
      if (_rerollRefused(s, a) case final why?) return why;
    }
    if ((a.kind == ActivityKind.gather && !nodeLevelMet(s, a.target)) ||
        (a.kind == ActivityKind.craft && !recipeLevelMet(s, a.target))) {
      return SkipReason.locked;
    }
    if (a.kind == ActivityKind.travel && a.target == s.location) {
      return SkipReason.alreadyDone;
    }
    if (_placeFor(s, a) == null) return SkipReason.noRoute;
    if (a.kind == ActivityKind.craft && !hasMaterials(s, a.target)) {
      return SkipReason.noMaterials;
    }
    if (_stopMet(s, a, stop, crafted: 0, gained: const {}) != null) {
      return SkipReason.alreadyDone;
    }
    return null;
  }

  /// The name of [a]'s place, monster, spot, crafted item or rerolled item.
  String _nameOf(Activity a) =>
      switch (a.kind) {
        ActivityKind.travel => data.locations[a.target]?.name,
        ActivityKind.fight => data.enemies[a.target]?.name,
        ActivityKind.gather => data.nodes[a.target]?.name,
        ActivityKind.craft => data.items[data.recipes[a.target]?.output]?.name,
        ActivityKind.reroll => data.itemOf(a.rerollKey)?.name,
      } ??
      a.target;

  String _explain(GameState s, Activity a, StopCondition stop, SkipReason r) {
    final name = _nameOf(a);
    return switch (r) {
      SkipReason.locked when a.kind == ActivityKind.reroll => _rerollLock(s, a),
      SkipReason.locked => switch (a.kind) {
        ActivityKind.gather when data.nodes[a.target] != null => _needs(
          s,
          name,
          data.nodes[a.target]!.profession,
          data.nodes[a.target]!.level,
        ),
        ActivityKind.craft when data.recipes[a.target] != null => _needs(
          s,
          name,
          data.recipes[a.target]!.profession,
          data.recipes[a.target]!.craftingLevel,
        ),
        _ => '$name is locked',
      },
      SkipReason.noRoute => 'The way there is in the fog',
      SkipReason.notThere => 'You are not where $name is',
      SkipReason.noMaterials when a.kind == ActivityKind.reroll =>
        'Not enough ${data.items[_rerollDust(a)]?.name ?? 'dust'} for $name',
      SkipReason.noMaterials => 'Not enough materials for $name',
      SkipReason.alreadyDone => switch (stop.kind) {
        _ when a.kind == ActivityKind.travel => 'You are already at $name',
        StopKind.untilGrey => 'The $name is already grey',
        _ => 'You already have ${stop.count} ${data.items[stop.item]?.name}',
      },
    };
  }

  /// Why a gathering spot or recipe [a] is closed to the player ("Iron vein
  /// needs Mining 10", "Learn Mining from Hilde in Camp"), or null.
  String? lockedReason(GameState s, Activity a) {
    final open = switch (a.kind) {
      ActivityKind.gather => nodeLevelMet(s, a.target),
      ActivityKind.craft => recipeLevelMet(s, a.target),
      _ => true,
    };
    return open
        ? null
        : _explain(s, a, const StopCondition.never(), SkipReason.locked);
  }

  /// The profession XP one action of [profession] at [level] paying [xp]
  /// gives now, faded (spec 0010 §2.3).
  int professionXpFor(GameState s, String profession, int level, int xp) =>
      xp * professionFade(s, profession, level) ~/ 100;

  /// The dust a reroll takes: of the item's quality (spec 0010 §7.2).
  String _rerollDust(Activity a) =>
      GameData.dustOf(data.qualityOf(a.rerollKey).id);

  /// Why reroll [a] can't start: the item or the dust is missing, or the
  /// kind of reroll doesn't fit the item; null if it can.
  SkipReason? _rerollRefused(GameState s, Activity a) {
    if (_rerollLock(s, a).isNotEmpty) return SkipReason.locked;
    if ((s.inventory[_rerollDust(a)] ?? 0) < data.rerollDust) {
      return SkipReason.noMaterials;
    }
    return null;
  }

  /// What keeps reroll [a] closed, in words; empty if nothing does.
  String _rerollLock(GameState s, Activity a) {
    final key = a.rerollKey;
    final item = data.itemOf(key)!;
    final legendary = data.qualityOf(key) == data.qualities.last;
    final index = a.rerollStatIndex;
    if (!_canPractise(s, 'crafting', 1)) return 'Rerolls need Crafting';
    if (item.slot == null) return 'Only gear can be rerolled';
    if (!holds(s, key)) return 'You have no ${item.name} like that';
    if (data.pendingRoll(key) != null) {
      return 'Keep the new roll or the old one first';
    }
    if (index == null && legendary) return '${item.name} is Legendary already';
    if (index != null &&
        (!legendary || index < 0 || index >= data.bonusRolls(key).length)) {
      return 'Only a Legendary\'s bonus stats can be rerolled';
    }
    return '';
  }

  /// What [name] lacks: its profession learned, or its level.
  String _needs(GameState s, String name, String profession, int level) {
    final p = data.professions[profession]!;
    if (!s.learned.contains(profession)) {
      return 'Learn ${p.name} from ${p.teacher.name} in '
          '${data.locations[p.teacher.location]!.name}';
    }
    if (!s.tools.containsKey(profession)) {
      return 'You need a ${p.toolName.toLowerCase()}';
    }
    return '$name needs ${p.name} $level';
  }

  /// Why an action stops by its condition now, or null (spec 0003 §3).
  EndReason? _stopMet(
    GameState s,
    Activity a,
    StopCondition stop, {
    required int crafted,
    required Map<String, int> gained,
  }) => switch (stop.kind) {
    StopKind.untilGrey =>
      enemyBand(s, a.target).colour == LevelColour.grey ? EndReason.grey : null,
    StopKind.untilHave =>
      owned(s, stop.item!) >= stop.count ? EndReason.enough : null,
    StopKind.untilCrafted => crafted >= stop.count ? EndReason.enough : null,
    StopKind.untilQuality =>
      gained.keys.any(
            (k) =>
                data.qualities.indexOf(data.qualityOf(k)) >= _tier(stop.item),
          )
          ? EndReason.enough
          : null,
    StopKind.never => null,
  };

  /// The place of quality [id] in the quality order; -1 if unknown.
  int _tier(String? id) => data.qualities.indexWhere((q) => q.id == id);

  /// Where [a] happens: its monster's or spot's location, the nearest
  /// crafting place, or the travel target, from [from] (default: here).
  /// Null if no open route leads there.
  String? _placeFor(GameState s, Activity a, {String? from}) {
    final dist = _paths(s, from: from).$1;
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
          if (_makesHere(l, data.recipes[a.target]!)) l.id,
      ],
      ActivityKind.reroll => [
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
  (Map<String, int>, Map<String, String>) _paths(GameState s, {String? from}) {
    final start = from ?? s.location;
    final dist = {start: 0};
    final previous = <String, String>{};
    final todo = {start};
    while (todo.isNotEmpty) {
      final at = todo.reduce((a, b) => dist[a]! <= dist[b]! ? a : b);
      todo.remove(at);
      for (final to in data.destinationsFrom(at)) {
        if (isFogged(s, to)) continue;
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
      // An action never walks on its own (spec 0016 §3.5).
      final why = _happensAt(s.location, p.activity)
          ? _cannotStart(s, p.activity, p.stop)
          : SkipReason.notThere;
      if (why != null) {
        events?.add(
          ActionSkipped(
            p.activity,
            why,
            missing: why == SkipReason.noMaterials
                ? missingFor(s, p.activity.target)
                : const {},
          ),
        );
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

  /// Wears [item] from the bag in [slot], or in the first free slot it fits
  /// (spec 0008 decision 11). Whatever it replaces goes to the bag: the
  /// worn item, the off hand for a two-hander, a two-hander for an off-hand
  /// item (spec 0008 §2.1).
  GameState equip(GameState s, String item, {String? slot}) {
    final slots = slotsFor(item);
    if (slots.isEmpty) throw ActivityError('$item cannot be equipped');
    if ((s.inventory[item] ?? 0) < 1) throw ActivityError('No $item to equip');
    final free = slots.where((id) => !s.equipment.containsKey(id));
    final String to;
    if (slot != null) {
      to = slot;
    } else if (free.isNotEmpty) {
      to = free.first;
    } else if (slots.length == 1) {
      to = slots.first;
    } else {
      throw ActivityError('Pick the slot to swap with');
    }
    if (!slots.contains(to)) throw ActivityError('$item does not fit $to');
    final n = s.copy()..addItem(item, -1);
    for (final id in displaced(n, item, to)) {
      n.addItem(n.equipment.remove(id)!);
    }
    n.equipment[to] = item;
    return n;
  }
}
