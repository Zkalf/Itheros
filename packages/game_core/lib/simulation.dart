/// Pacing simulator (plan 0001, M3): a scripted sensible player walks a fixed
/// number of steps per day, so XP curves and costs can be tuned against the
/// spec's pacing targets.
library;

import 'dart:math' as math;

import 'game_core.dart';

class DayResult {
  DayResult(this.day, this.level, this.xp, this.bank, this.equipment);

  final int day;
  final int level;
  final int xp;
  final int bank;
  final Map<String, String> equipment;
}

class SimulationResult {
  SimulationResult(this.days, this.walkedToLevel2, this.finalState);

  final List<DayResult> days;

  /// Walked steps from a new game until level 2, or null if never reached.
  final int? walkedToLevel2;
  final GameState finalState;

  /// First day that ended at [level] or higher, or null.
  int? dayReached(int level) =>
      days.where((d) => d.level >= level).map((d) => d.day).firstOrNull;
}

/// Opens the app every [checkEvery] walked steps and picks what to do.
class SensiblePlayer {
  SensiblePlayer(this.game);

  final Game game;
  int? _bruteLostAtLevel;

  void observe(StepReport r) {
    for (final e in r.events) {
      if (e is FightLost && e.enemy == 'goblin_brute') {
        _bruteLostAtLevel = game.level(r.state);
      }
    }
  }

  GameState decide(GameState s) {
    s = _equipBest(s);
    final goal = _goal(s);
    final current = s.activity?.activity;
    if (current == goal) return s;

    final where = _locationFor(goal);
    if (where == s.location) return game.startActivity(s, goal);
    final travel = Activity.travel(where);
    if (current == travel) return s;
    return game.startActivity(s, travel);
  }

  Activity _goal(GameState s) {
    final lvl = game.level(s);
    int have(String item) =>
        (s.inventory[item] ?? 0) + (s.equipment.containsValue(item) ? 1 : 0);
    final crafting = game.data.recipes.values.any((r) => r.unlockLevel <= lvl);

    if (crafting && have('hide_vest') == 0 && have('goblin_hide') >= 4) {
      return const Activity.craft('hide_vest');
    }
    if (crafting && have('copper_sword') == 0) {
      return have('copper_ore') >= 5
          ? const Activity.craft('copper_sword')
          : const Activity.gather('copper_vein');
    }
    final bruteOpen = game.data.enemies['goblin_brute']!.unlockLevel <= lvl;
    final geared = have('copper_sword') > 0 && have('hide_vest') > 0;
    final shy = _bruteLostAtLevel != null && _bruteLostAtLevel! >= lvl;
    if (bruteOpen && geared && !shy) {
      return const Activity.fight('goblin_brute');
    }
    return const Activity.fight('goblin');
  }

  String _locationFor(Activity a) {
    for (final l in game.data.locations.values) {
      final here = switch (a.kind) {
        ActivityKind.fight => l.enemies.contains(a.target),
        ActivityKind.gather => l.nodes.contains(a.target),
        ActivityKind.craft => l.crafting,
        ActivityKind.travel => l.id == a.target,
      };
      if (here) return l.id;
    }
    throw StateError('No location for $a');
  }

  GameState _equipBest(GameState s) {
    int score(String? item) {
      if (item == null) return 0;
      final b = game.data.items[item]!.bonus;
      return b.attack * 5 + b.defense * 3 + b.hp;
    }

    for (final item in s.inventory.keys.toList()) {
      final slot = game.data.items[item]?.slot;
      if (slot != null && score(item) > score(s.equipment[slot])) {
        s = game.equip(s, item);
      }
    }
    return s;
  }
}

SimulationResult simulate(
  Game game, {
  required int stepsPerDay,
  required int days,
  int seed = 1,
  int checkEvery = 100,
}) {
  final player = SensiblePlayer(game);
  var s = game.newGame(seed: seed);
  final results = <DayResult>[];
  var walked = 0;
  int? toLevel2;

  for (var day = 1; day <= days; day++) {
    var left = stepsPerDay;
    while (left > 0) {
      s = player.decide(s);
      final n = math.min(checkEvery, left);
      final r = game.applySteps(s, n);
      if (toLevel2 == null && r.events.any((e) => e is LevelUp)) {
        toLevel2 = walked + _stepsUntilLevel(game, s, 2);
      }
      player.observe(r);
      s = r.state;
      walked += n;
      left -= n;
    }
    results.add(
      DayResult(day, game.level(s), s.xp, s.bank, Map.of(s.equipment)),
    );
  }
  return SimulationResult(results, toLevel2, s);
}

int _stepsUntilLevel(Game game, GameState s, int level) {
  var n = 0;
  while (game.level(s) < level) {
    s = game.applySteps(s, 1).state;
    n++;
  }
  return n;
}
