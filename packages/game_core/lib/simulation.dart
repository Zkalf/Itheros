/// Pacing simulator (plan 0001 M3, plan 0003 M3): a scripted sensible player
/// walks a fixed number of steps per day, so XP curves, monsters and costs can
/// be tuned against the specs' pacing targets.
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

/// The expected outcome of one fight, with every swing at its average.
class FightEstimate {
  FightEstimate(this.win, this.rounds, this.hpLeft);

  final bool win;
  final int rounds;

  /// Share of the player's HP left at the end (0 on a loss).
  final double hpLeft;

  /// Comfortably won: damage rolls won't often turn it into a loss.
  bool get safe => win && hpLeft >= 0.25;
}

/// Plays one fight of [s] against [e] with average swings, following the
/// combat rules in `Game` (spec 0001 §4, spec 0002 §5.1, spec 0009 §2): each
/// side's damage is scaled by its chance to land, crits and blocks.
FightEstimate estimateFight(Game game, GameState s, EnemyDef e) {
  final c = game.data.combat;
  final me = game.stats(s);
  final level = game.level(s);
  final slayerHit = game.slayer(s, e.id) ? c.slayerHit : 0;
  double hit(int attack, int defense) => math.max(1, attack - defense / 2);
  double lands(int hitChance, int dodge) =>
      hitChance / 100 * (1 - math.min(c.dodgeCap, dodge) / 100);

  final crit = math.min(c.critCap, c.critBase + me.crit) / 100;
  final block = math.min(c.blockCap, me.block) / 100;
  final mine =
      hit(me.attack, e.stats.defense) *
      c.typeFactor(game.damageType(s), e.armour) *
      lands(c.hitChance(level - e.level, me.hit + slayerHit), e.stats.dodge) *
      (1 + crit * (c.critDamage - 1));
  final theirs =
      hit(e.stats.attack, e.has(Trait.ghostly) ? 0 : me.defense) *
      lands(c.hitChance(e.level - level, 0), me.dodge) *
      (1 - block * (1 - c.blockShare));
  var hp = me.hp.toDouble();
  var enemyHp = e.stats.hp.toDouble();

  for (var round = 1; round <= 1000; round++) {
    bool monsterTurn() {
      if (!e.has(Trait.slow) || round.isEven) {
        hp -= theirs;
        if (hp <= 0) return true;
      }
      enemyHp = math.min(e.stats.hp.toDouble(), enemyHp + e.regen);
      return false;
    }

    if (e.has(Trait.quick) && monsterTurn()) {
      return FightEstimate(false, round, 0);
    }
    enemyHp -= mine;
    if (enemyHp <= 0) return FightEstimate(true, round, hp / me.hp);
    if (!e.has(Trait.quick) && monsterTurn()) {
      return FightEstimate(false, round, 0);
    }
  }
  return FightEstimate(false, 1000, 0);
}

/// The better of two estimates: safe first, then fewer rounds, then more HP
/// left; between unsafe ones, a win, then more HP left.
bool _better(FightEstimate a, FightEstimate b) {
  if (a.safe != b.safe) return a.safe;
  if (a.safe) {
    return a.rounds < b.rounds || (a.rounds == b.rounds && a.hpLeft > b.hpLeft);
  }
  if (a.win != b.win) return a.win;
  return a.hpLeft > b.hpLeft;
}

/// What a weapon is compared within: its damage type and hands (spec 0009
/// §5.3). Null for anything that isn't a weapon.
(String, bool)? weaponGroup(GameData data, String key) {
  final item = data.itemOf(key);
  final type = item?.damageType;
  return type == null ? null : (type, item!.twoHanded);
}

/// The main hand and off hand [s] would arm against [enemy] from what it
/// owns, and the fight's estimate (spec 0009 §9.2): the weapon (and shield,
/// or two-hander) that wins fastest and safely.
(String?, String?, FightEstimate) bestArms(Game game, GameState s, EnemyDef e) {
  final data = game.data;
  final owned = {...s.inventory.keys, ...s.equipment.values};
  // The best weapon of each damage type and hands, and every off-hand item.
  final mains = <(String, bool), String>{};
  final offs = <String?>{null};
  for (final key in owned) {
    final item = data.itemOf(key);
    if (item?.slot == 'offHand') offs.add(key);
    final group = weaponGroup(data, key);
    if (group == null) continue;
    final best = mains[group];
    if (best == null || data.scoreOf(key) > data.scoreOf(best)) {
      mains[group] = key;
    }
  }
  final armed = s.copy();
  (String?, String?, FightEstimate)? best;
  for (final main in <String?>[null, ...mains.values]) {
    final twoHanded = main != null && data.itemOf(main)!.twoHanded;
    for (final off in twoHanded ? const <String?>[null] : offs) {
      _wield(armed, main, off);
      final f = estimateFight(game, armed, e);
      if (best == null || _better(f, best.$3)) best = (main, off, f);
    }
  }
  return best!;
}

/// Sets [s]'s hands without the bag (for estimates only).
void _wield(GameState s, String? main, String? off) {
  for (final (slot, key) in [('mainHand', main), ('offHand', off)]) {
    if (key == null) {
      s.equipment.remove(slot);
    } else {
      s.equipment[slot] = key;
    }
  }
}

/// [s] holding [main] and [off] in its hands, moved from and to the bag.
GameState armWith(Game game, GameState s, String? main, String? off) {
  for (final (slot, key) in [('mainHand', main), ('offHand', off)]) {
    if (s.equipment[slot] == key) continue;
    if (key == null) {
      if (s.equipment.containsKey(slot)) s = game.unequip(s, slot);
    } else {
      s = game.equip(s, key, slot: slot);
    }
  }
  return s;
}

/// [s] armed for [enemy] with [bestArms].
GameState armFor(Game game, GameState s, String enemy) {
  final (main, off, _) = bestArms(game, s, game.data.enemies[enemy]!);
  return armWith(game, s, main, off);
}

/// A player at [level] wearing, per open slot, the best item a recipe up to
/// [level] makes ("the gear of that stretch"), or no gear at all. Recipes
/// needing any of [without] are skipped (a boss's own drops). The weapon is
/// the best crafted one-hander, of the type strong against [vs] when given,
/// with a shield (spec 0009 §9.1). All of it is common.
GameState referencePlayer(
  Game game,
  int level, {
  bool geared = true,
  Set<String> without = const {},
  String? vs,
}) {
  final data = game.data;
  final s = game.newGame(seed: 1)..xp = data.xpForLevel(level);
  if (!geared) return s;
  final strong = vs == null
      ? null
      : data.combat.strongAgainst(data.enemies[vs]!.armour);
  final weapons = <ItemDef>[];
  for (final r in data.recipes.values) {
    if (r.level > level || r.inputs.keys.any(without.contains)) continue;
    final item = data.items[r.output]!;
    if (item.slot == null || item.twoHanded) continue;
    if (item.damageType != null) {
      weapons.add(item);
      continue;
    }
    final slot = game.slotsFor(item.id).first;
    final current = s.equipment[slot];
    if (current == null || item.score > data.scoreOf(current)) {
      s.equipment[slot] = item.id;
    }
  }
  final typed = weapons.where((w) => w.damageType == strong).toList();
  final pick = typed.isNotEmpty ? typed : weapons;
  if (pick.isNotEmpty) {
    s.equipment['mainHand'] = pick
        .reduce((a, b) => b.score > a.score ? b : a)
        .id;
  }
  return s;
}

/// Materials only [boss] drops: gear made from them can't be worn for its
/// first kill.
Set<String> bossOnlyItems(Game game, String boss) => {
  for (final d in game.data.enemies[boss]!.drops)
    if (!game.data.nodes.values.any((n) => n.item == d.item) &&
        !game.data.enemies.values.any(
          (e) => e.id != boss && e.drops.any((o) => o.item == d.item),
        ))
      d.item,
};

/// Monsters with a first-kill item, lowest level first.
List<EnemyDef> bosses(GameData data) =>
    data.enemies.values.where((e) => e.firstKillDrops.isNotEmpty).toList()
      ..sort((a, b) => a.level.compareTo(b.level));

/// A boss's gear checks (spec 0002 §5.3, amendment 1), each over [fights].
class BossCheck {
  BossCheck(this.bare, this.geared, this.other, {required this.first});

  /// Even level, no gear: should win at most 10%.
  final FightRecord bare;

  /// Even level, best crafted gear without the boss's own drops: at least
  /// 70%.
  final FightRecord geared;

  /// First boss: 5 levels above with no gear, at least 50%. Later bosses:
  /// 3 levels below with their own level's gear, at most 10%.
  final FightRecord other;
  final bool first;

  bool get passes =>
      bare.winRate <= 0.1 &&
      geared.winRate >= 0.7 &&
      (first ? other.winRate >= 0.5 : other.winRate <= 0.1);
}

BossCheck bossCheck(Game game, String boss, {int fights = 200}) {
  final lvl = game.data.enemies[boss]!.level;
  final own = bossOnlyItems(game, boss);
  final first = bosses(game.data).first.id == boss;
  FightRecord vs(GameState p) => measureFights(game, p, boss, fights: fights);
  return BossCheck(
    vs(referencePlayer(game, lvl, geared: false)),
    vs(referencePlayer(game, lvl, without: own, vs: boss)),
    first
        ? vs(referencePlayer(game, lvl + 5, geared: false))
        : vs(referencePlayer(game, lvl - 3, without: own, vs: boss)),
    first: first,
  );
}

/// Measured results of many real fights (the rules, with damage rolls).
class FightRecord {
  FightRecord(this.fights, this.wins, this.steps, this.xp, this.taken);

  final int fights;
  final int wins;
  final int steps;
  final int xp;

  /// Damage the player took, all fights together.
  final int taken;

  double get winRate => wins / fights;
  double get takenPerFight => taken / fights;
  double get xpPerStep => xp / steps;
  double get roundsPerFight => steps / fights / 10;
}

/// Fights [enemy] [fights] times from [player], starting again whenever the
/// action gives up after losses, and records the results.
FightRecord measureFights(
  Game game,
  GameState player,
  String enemy, {
  int fights = 200,
  int seed = 1,
}) {
  final home = game.data.locations.values.firstWhere(
    (l) => l.enemies.contains(enemy),
  );
  var s = player.copy()
    ..location = home.id
    ..rngState = game.newGame(seed: seed).rngState;
  final xp0 = s.xp;
  var wins = 0, losses = 0, steps = 0, taken = 0;
  // The level must not change mid-measurement: XP is restored after each
  // fight, and only the gain is counted.
  var gained = 0;
  while (wins + losses < fights) {
    if (s.activity == null) {
      s = game.startActivity(s, Activity.fight(enemy));
    }
    final r = game.applySteps(s, game.data.combatRoundSteps);
    steps += game.data.combatRoundSteps;
    // One round per call; a fight that ends the action leaves no log.
    taken += r.state.activity?.log.lastOrNull?.taken ?? 0;
    for (final e in r.events) {
      if (e is FightWon) {
        wins++;
        gained += e.xp;
      } else if (e is FightLost) {
        losses++;
        gained += e.xp; // losses pay a share of the XP (spec 0003 §5)
      }
    }
    s = r.state
      ..xp = xp0
      ..inventory.clear();
  }
  return FightRecord(fights, wins, steps, gained, taken);
}

/// A two-hander against its tier's one-hander, and that one-hander with and
/// without a shield (spec 0009 §4.2), over the monsters of its stretch.
class HandsCheck {
  HandsCheck(this.twoHander, this.monsters, this.roundsCut, this.shieldCut);

  final String twoHander;
  final List<String> monsters;

  /// How many fewer rounds the two-hander needs (target about 25%, at least
  /// 15%).
  final double roundsCut;

  /// How much less damage the one-hander takes per fight with a shield than
  /// without (at least 20%; the owner's reading of §4.2, plan 0011 M1).
  final double shieldCut;

  bool get passes => roundsCut >= 0.15 && shieldCut >= 0.2;
}

/// One [HandsCheck] per two-hander. Its tier's one-handers are those of the
/// latest weapon recipe level up to the two-hander's. Its stretch is the
/// monsters (no lurkers) from that tier's level (or the two-hander's own,
/// when the tier's one-handers came before the previous two-hander) up to
/// the next weapon recipe's level; each is fought by an even-level player
/// with the stretch's gear. Rounds: the two-hander against the tier's
/// one-hander of the same damage type (so types don't tip it: decision 9),
/// on the monsters that one-hander beats at least 90% of the time. Damage:
/// the reference player (spec 0009 §9.1) with and without its shield.
List<HandsCheck> handsChecks(Game game, {int fights = 200}) {
  final data = game.data;
  final weaponRecipes = [
    for (final r in data.recipes.values)
      if (data.items[r.output]!.damageType != null) r,
  ];
  final checks = <HandsCheck>[];
  var previous = 0;
  for (final r in weaponRecipes) {
    final two = data.items[r.output]!;
    if (!two.twoHanded) continue;
    final next = weaponRecipes
        .map((w) => w.level)
        .where((l) => l > r.level)
        .fold<int?>(null, (m, l) => m == null || l < m ? l : m);
    final tierLevel = weaponRecipes
        .where((w) => w.level <= r.level && !data.items[w.output]!.twoHanded)
        .map((w) => w.level)
        .reduce(math.max);
    final one = weaponRecipes
        .map((w) => data.items[w.output]!)
        .firstWhere(
          (w) =>
              !w.twoHanded &&
              data.recipes[w.id]?.level == tierLevel &&
              w.damageType == two.damageType,
        );
    final from = tierLevel > previous ? tierLevel : r.level;
    previous = r.level;
    final monsters =
        data.enemies.values
            .where(
              (e) =>
                  !e.lurker &&
                  e.level >= from &&
                  (next == null || e.level < next),
            )
            .toList()
          ..sort((a, b) => a.level.compareTo(b.level));
    var rounds = 0.0, taken = 0.0, beaten = 0;
    for (final e in monsters) {
      final base = referencePlayer(
        game,
        e.level,
        without: bossOnlyItems(game, e.id),
        vs: e.id,
      );
      final shielded = base.copy()..equipment['mainHand'] = one.id;
      final twoHanded = base.copy()
        ..equipment['mainHand'] = r.output
        ..equipment.remove('offHand');
      final a = measureFights(game, shielded, e.id, fights: fights);
      if (a.winRate >= 0.9) {
        final b = measureFights(game, twoHanded, e.id, fights: fights);
        rounds += 1 - b.roundsPerFight / a.roundsPerFight;
        beaten++;
      }
      final alone = base.copy()..equipment.remove('offHand');
      final withShield = measureFights(game, base, e.id, fights: fights);
      final without = measureFights(game, alone, e.id, fights: fights);
      taken += 1 - withShield.takenPerFight / without.takenPerFight;
    }
    checks.add(
      HandsCheck(
        r.output,
        [for (final e in monsters) e.id],
        beaten == 0 ? 0 : rounds / beaten,
        taken / monsters.length,
      ),
    );
  }
  return checks;
}

/// Opens the app every so often and picks what to do: equips the best gear,
/// crafts each upgrade it can (farming its materials, even from grey
/// monsters), otherwise fights the monster with the most XP per step that it
/// safely beats. Travels leg by leg along the shortest route.
class SensiblePlayer {
  SensiblePlayer(this.game);

  final Game game;
  final _lostAtLevel = <String, int>{};

  /// This decision's best arms per monster (see [bestArms]).
  final _arms = <String, (String?, String?, FightEstimate)>{};

  GameData get data => game.data;

  void observe(StepReport r) {
    for (final e in r.events) {
      if (e is FightLost) _lostAtLevel[e.enemy] = game.level(r.state);
    }
  }

  GameState decide(GameState s) {
    s = _equipBest(s);
    _arms.clear();
    final goal = _goal(s);
    if (goal.kind == ActivityKind.fight) {
      final (main, off, _) = _armed(s, data.enemies[goal.target]!);
      s = armWith(game, s, main, off);
    }
    final current = s.activity?.activity;
    if (current == goal) return s;

    final where = _locationFor(s, goal);
    if (where == s.location) return game.startActivity(s, goal);
    final hop = Activity.travel(_nextHop(s, where));
    if (current == hop) return s;
    return game.startActivity(s, hop);
  }

  int _have(GameState s, String item) => game.owned(s, item);

  /// Gear rank with quality (spec 0005 criterion 7).
  int _score(String? key) => key == null ? 0 : data.scoreOf(key);

  (String?, String?, FightEstimate) _armed(GameState s, EnemyDef e) =>
      _arms[e.id] ??= bestArms(game, s, e);

  /// How much better [key] is than what it would replace. Weapons are
  /// compared within their damage type and hands, off-hand items with the
  /// best one owned: each type is crafted once per tier (spec 0009 §9.2).
  int _gain(GameState s, String key) {
    final group = weaponGroup(data, key);
    final hand = data.itemOf(key)?.slot == 'offHand';
    if (group == null && !hand) return game.gearGain(s, key);
    var best = 0;
    for (final k in {...s.inventory.keys, ...s.equipment.values}) {
      final same = group == null
          ? data.itemOf(k)?.slot == 'offHand'
          : weaponGroup(data, k) == group;
      if (same) best = math.max(best, _score(k));
    }
    return _score(key) - best;
  }

  Activity _goal(GameState s) {
    int gain(RecipeDef r) => _gain(s, r.output);
    final upgrades = data.recipes.values.where((r) {
      return data.items[r.output]!.slot != null &&
          game.recipeLevelMet(s, r.id) &&
          _have(s, r.output) == 0 &&
          gain(r) > 0;
    }).toList()..sort((a, b) => gain(b).compareTo(gain(a)));

    for (final r in upgrades) {
      if (game.hasMaterials(s, r.id)) return Activity.craft(r.id);
      final missing = r.inputs.entries.firstWhere(
        (e) => (s.inventory[e.key] ?? 0) < e.value,
      );
      final source = _sourceOf(s, missing.key);
      if (source != null) return source;
    }
    return _bestFight(s);
  }

  bool _canFight(GameState s, EnemyDef e) =>
      !game.enemyFogged(s, e.id) &&
      _lostAtLevel[e.id] != game.level(s) &&
      _armed(s, e).$3.safe;

  /// The fastest safe way to get [item], or null.
  Activity? _sourceOf(GameState s, String item) {
    Activity? best;
    var bestRate = 0.0;
    for (final n in data.nodes.values) {
      if (n.item != item ||
          !game.nodeLevelMet(s, n.id) ||
          game.nodeFogged(s, n.id)) {
        continue;
      }
      final rate = 1 / n.steps;
      if (rate > bestRate) (best, bestRate) = (Activity.gather(n.id), rate);
    }
    for (final e in data.enemies.values) {
      final per = e.drops
          .where((d) => d.item == item)
          .fold(0.0, (sum, d) => sum + d.chance * d.count);
      if (per == 0 || !_canFight(s, e)) continue;
      final rounds = _armed(s, e).$3.rounds;
      final rate = per / (rounds * data.combatRoundSteps);
      if (rate > bestRate) (best, bestRate) = (Activity.fight(e.id), rate);
    }
    return best;
  }

  Activity _bestFight(GameState s) {
    EnemyDef? best;
    var bestRate = -1.0;
    for (final e in data.enemies.values) {
      if (!_canFight(s, e)) continue;
      final f = _armed(s, e).$3;
      final xp = e.xp * game.enemyBand(s, e.id).xpPercent / 100;
      final rate = math.max(1, xp) / (f.rounds * data.combatRoundSteps);
      if (rate > bestRate) (best, bestRate) = (e, rate);
    }
    return Activity.fight((best ?? data.enemies.values.first).id);
  }

  String _locationFor(GameState s, Activity a) {
    if (a.kind == ActivityKind.craft) {
      final dist = _distances(s);
      return data.locations.values
          .where((l) => l.crafting && dist.containsKey(l.id))
          .reduce((a, b) => dist[a.id]! <= dist[b.id]! ? a : b)
          .id;
    }
    return data.locations.values.firstWhere((l) {
      return switch (a.kind) {
        ActivityKind.fight => l.enemies.contains(a.target),
        ActivityKind.gather => l.nodes.contains(a.target),
        _ => l.id == a.target,
      };
    }).id;
  }

  /// Shortest walking distance from here to every reachable open location.
  Map<String, int> _distances(GameState s) => _paths(s).$1;

  String _nextHop(GameState s, String to) {
    final previous = _paths(s).$2;
    var at = to;
    while (previous[at] != s.location) {
      at = previous[at]!;
    }
    return at;
  }

  (Map<String, int>, Map<String, String>) _paths(GameState s) {
    final dist = {s.location: 0};
    final previous = <String, String>{};
    final todo = {s.location};
    while (todo.isNotEmpty) {
      final at = todo.reduce((a, b) => dist[a]! <= dist[b]! ? a : b);
      todo.remove(at);
      for (final to in data.destinationsFrom(at)) {
        if (game.isFogged(s, to)) continue;
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

  /// Wears the best gear, hands aside: those are armed per fight.
  GameState _equipBest(GameState s) {
    for (final item in s.inventory.keys.toList()) {
      final slot = data.itemOf(item)?.slot;
      if (slot == 'mainHand' || slot == 'offHand') continue;
      if (game.gearGain(s, item) <= 0) continue;
      final slots = game.slotsFor(item);
      final weakest = slots.reduce(
        (a, b) => _score(s.equipment[a]) <= _score(s.equipment[b]) ? a : b,
      );
      s = game.equip(s, item, slot: weakest);
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
