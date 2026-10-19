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
  /// keep their level and their progress through it (spec 0002 §2).
  GameState migrate(GameState s) {
    if (s.loadedVersion == GameState.schemaVersion) return s;
    const v1 = [0, 20, 100, 300, 700, 1540, 3390, 7460, 16400, 28000];
    var l = 1;
    while (l < v1.length && s.xp >= v1[l]) {
      l++;
    }
    final fraction = l < v1.length
        ? (s.xp - v1[l - 1]) / (v1[l] - v1[l - 1])
        : 0.0;
    final floor = data.xpForLevel(l);
    final n = s.copy()
      ..xp = floor + ((data.xpForLevel(l + 1) - floor) * fraction).floor();
    return n;
  }

  /// Steps the current activity's next unit costs, or null when idle.
  int? unitCost(GameState s) {
    final a = s.activity?.activity;
    return a == null ? null : _costOf(s, a);
  }

  int _costOf(GameState s, Activity a) => switch (a.kind) {
    ActivityKind.travel => data.route(s.location, a.target)!.steps,
    ActivityKind.fight => data.combatRoundSteps,
    ActivityKind.gather => data.nodes[a.target]!.steps,
    ActivityKind.craft => data.recipes[a.target]!.steps,
  };

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

  bool hasMaterials(GameState s, String recipe) => data
      .recipes[recipe]!
      .inputs
      .entries
      .every((e) => (s.inventory[e.key] ?? 0) >= e.value);

  // Player actions. Free: they cost no steps.

  /// Starts [a], replacing (and discarding the progress of) any current
  /// activity. Throws [ActivityError] if the rules don't allow it.
  GameState startActivity(GameState s, Activity a) {
    final lvl = level(s);
    switch (a.kind) {
      case ActivityKind.travel:
        if (data.route(s.location, a.target) == null) {
          throw ActivityError('No route from ${s.location} to ${a.target}');
        }
        if (data.locations[a.target]!.unlockLevel > lvl) {
          throw ActivityError('${a.target} is locked');
        }
      case ActivityKind.fight:
        if (!_here(s).enemies.contains(a.target)) {
          throw ActivityError('No ${a.target} at ${s.location}');
        }
        if (data.enemies[a.target]!.unlockLevel > lvl) {
          throw ActivityError('${a.target} is locked');
        }
      case ActivityKind.gather:
        if (!_here(s).nodes.contains(a.target)) {
          throw ActivityError('No ${a.target} at ${s.location}');
        }
        if (data.nodes[a.target]!.unlockLevel > lvl) {
          throw ActivityError('${a.target} is locked');
        }
      case ActivityKind.craft:
        final recipe = data.recipes[a.target];
        if (recipe == null) throw ActivityError('Unknown recipe ${a.target}');
        if (!_here(s).crafting) {
          throw ActivityError('Crafting is not possible at ${s.location}');
        }
        if (recipe.unlockLevel > lvl) {
          throw ActivityError('${a.target} is locked');
        }
        if (!hasMaterials(s, a.target)) {
          throw ActivityError('Not enough materials for ${a.target}');
        }
    }
    return _refundProgress(s.copy())..activity = RunningActivity(a);
  }

  /// Ends the current activity; the character rests. Unspent progress goes
  /// to the bank (spec 0001 amendment 2).
  GameState stopActivity(GameState s) {
    if (s.activity == null) throw ActivityError('Nothing to stop');
    return _refundProgress(s.copy())..activity = null;
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

  /// Completes every unit the paid progress covers. A unit is never left
  /// half-paid: if the next one can't start, the activity ends and leftover
  /// progress goes to the bank.
  void _advance(RunningActivity act) {
    while (identical(s.activity, act)) {
      final cost = game._costOf(s, act.activity);
      if (act.progress < cost) return;
      act.progress -= cost;
      final ended = _completeUnit(act);
      if (ended != null) {
        _end(act, ended);
      } else if (!_canStartNext(act.activity)) {
        _end(act, EndReason.noMaterials);
      }
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

  EndReason _lose(RunningActivity act, EnemyDef enemy) {
    act.fight = null;
    events.add(FightLost(enemy.id));
    return EndReason.defeated;
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
