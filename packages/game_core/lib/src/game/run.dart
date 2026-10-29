part of '../game.dart';

/// Mutable bookkeeping for one [Game.applySteps] call.
class _Run {
  _Run(this.game, this.s)
    : rng = Rng.fromState(s.rngState),
      stream = Rng.fromState(s.professionRng);

  final Game game;
  final GameState s;
  final Rng rng;

  /// The profession stream: every roll spec 0010 adds (spec 0010 §9.1).
  final Rng stream;
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
      _countMeal(1 + boost);
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
    s.professionRng = stream.state;
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
        _arrive(leg);
        act.leg = game._nextLeg(s, act.activity);
        if (act.leg == null && game._placeFor(s, act.activity) != s.location) {
          _end(act, EndReason.noRoute);
          continue;
        }
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
          gained: act.gained,
        );
        if (done != null) {
          _end(act, done);
          continue;
        }
      }
      if (!_canStartNext(act.activity)) _end(act, EndReason.noMaterials);
    }
  }

  void _arrive(String area) {
    final steps = game.data.route(s.location, area)?.steps ?? 0;
    s.location = area;
    game._visit(s, area);
    events.add(Arrived(area, steps: steps));
  }

  bool _canStartNext(Activity a) =>
      a.kind != ActivityKind.craft || game.hasMaterials(s, a.target);

  /// Returns why the activity ends, or null if it continues.
  EndReason? _completeUnit(RunningActivity act) {
    final a = act.activity;
    switch (a.kind) {
      case ActivityKind.travel:
        _arrive(a.target);
        return EndReason.arrived;
      case ActivityKind.fight:
        return _combatRound(act);
      case ActivityKind.gather:
        final node = data.nodes[a.target]!;
        final xp = _practise(node.profession, node.level, node.xp, node.steps);
        // The rare-find roll is drawn every action (spec 0010 §5.1); at a
        // water or a trail it picks the catch too (spec 0011 §3.2, §4).
        final chance = game.rareFindChance(s, node.id);
        if (node.catches.isNotEmpty) {
          _catch(act, node, chance);
        } else if (stream.nextDouble() < chance && node.rareFind != null) {
          s.addItem(node.rareFind!);
          _gain(act, node.rareFind!);
          events.add(RareFound(node.rareFind!));
        }
        s.addItem(node.item);
        _gain(act, node.item);
        s.count('gathered.${node.item}');
        events.add(Gathered(node.item, xp));
        _gainXp(xp);
        return null;
      case ActivityKind.craft:
        final recipe = data.recipes[a.target]!;
        final xp = _practise(
          recipe.profession,
          recipe.level,
          recipe.xp,
          recipe.steps,
        );
        recipe.inputs.forEach((item, n) => s.addItem(item, -n));
        final made = _crafted(recipe);
        s.addItem(made);
        _gain(act, made);
        act.crafted++;
        s.count('crafted.total');
        s.count('crafted.${recipe.output}');
        events.add(Crafted(made, xp));
        _gainXp(xp);
        return null;
      case ActivityKind.reroll:
        return _reroll(act);
    }
  }

  /// [recipe]'s output with its quality. The overlevel bonus counts
  /// Crafting levels (spec 0010). Tools and recipes from rare inputs roll on
  /// the profession stream, tools without bonus stats (spec 0010 §9.1).
  String _crafted(RecipeDef recipe) {
    final out = data.items[recipe.output]!;
    final crafting = game.professionLevel(s, recipe.profession);
    // A meal may be perfect (spec 0011 §5.3).
    if (out.meal != null) {
      final perfect = stream.nextDouble() < game.perfectChance(s, recipe.id);
      return perfect ? GameData.perfectKey(out.id) : out.id;
    }
    if (out.tool != null) {
      final q = game.rollQuality(
        stream,
        playerLevel: crafting,
        itemLevel: recipe.level,
      );
      return data.keyFor(out.id, q);
    }
    // So do the hide, scale and trophy pieces (spec 0011 §9.1).
    final rare =
        !out.reference || recipe.inputs.keys.any((i) => data.items[i]!.rare);
    return _withQuality(
      out.id,
      recipe.level,
      playerLevel: crafting,
      with_: rare ? stream : rng,
    );
  }

  /// One reroll at the forge: the dust goes, the quality rolls (never
  /// lower) or a Legendary's chosen stat rolls and waits (spec 0010 §7.2,
  /// §7.3).
  EndReason? _reroll(RunningActivity act) {
    final a = act.activity;
    if (game._rerollRefused(s, a) != null) return EndReason.noMaterials;
    final key = a.rerollKey;
    final item = data.itemOf(key)!;
    final itemLevel = data.itemLevel(item.id);
    s.addItem(game._rerollDust(a), -data.rerollDust);
    final String after;
    if (a.rerollStatIndex case final index?) {
      final roll = game.rollBonusStats(stream, item.id, 1, itemLevel).single;
      after = data.withPending(key, index, roll);
    } else {
      final was = data.qualities.indexOf(data.qualityOf(key));
      final rolled = game.rollQuality(
        stream,
        playerLevel: game.professionLevel(s, 'crafting'),
        itemLevel: itemLevel,
      );
      final now = data.qualities.indexWhere((q) => q.id == rolled);
      after = now <= was
          ? key
          : data.keyFor(item.id, rolled, [
              ...data.bonusRolls(key),
              ...game.rollBonusStats(stream, item.id, now - was, itemLevel),
            ]);
    }
    game._replaceItem(s, key, after);
    game._foundQuality(s, after);
    act.crafted++;
    events.add(Rerolled(key, after));
    return null;
  }

  /// One cast or hunt's catch, all on the profession stream (spec 0011
  /// §3-§4, §6): the row (the rare find first, at [rareChance]), a fish's
  /// weight and record, a bottle, a sunken chest.
  void _catch(RunningActivity act, NodeDef node, double rareChance) {
    void give(String item, {int? weight}) {
      s.addItem(item);
      _gain(act, item);
      s.count('gathered.$item');
      events.add(Gathered(item, 0, weight: weight));
    }

    var u = stream.nextDouble();
    final trophy = node.rareFind != null && u < rareChance;
    String? row;
    if (!trophy) {
      if (node.rareFind != null) u -= rareChance;
      for (final c in node.catches) {
        if (c.chance case final p?) {
          if (u < p) {
            row = c.item;
            break;
          }
          u -= p;
        }
      }
      row ??= node.catches.firstWhere((c) => c.chance == null).item;
    }
    final item = row ?? node.rareFind!;
    final weight = switch (data.items[item]!.weight) {
      (final lo, final hi) => (() {
        final w = stream.nextDouble();
        return ((lo + (hi - lo) * w * w) * 10).round();
      })(),
      null => null,
    };
    if (trophy) {
      s.addItem(item);
      _gain(act, item);
      s.count('gathered.$item');
      events.add(RareFound(item, weight: weight));
      node.rareWith.forEach(give);
    } else {
      give(item, weight: weight);
    }
    if (weight != null) {
      final was = s.records[item];
      if (was == null || weight > was) s.records[item] = weight;
      if (was != null && weight > was) {
        act.records++;
        events.add(RecordBeaten(item, weight, was));
      }
    }
    if (node.bottle && stream.nextDouble() < data.bottleChance) {
      s.bottles++;
      if (s.bottles == 1) {
        s.revealed.add(data.bottleReveals);
        events.add(BottleFound(revealed: data.bottleReveals));
      } else {
        s
          ..addItem(data.bottleLater)
          ..count('gathered.${data.bottleLater}');
        _gain(act, data.bottleLater);
        events.add(BottleFound(item: data.bottleLater));
      }
    }
    if (node.chest case final ring?
        when stream.nextDouble() < data.chestChance) {
      final key = _withQuality(ring, data.itemLevel(ring), with_: stream);
      s.addItem(key);
      _gain(act, key);
      events.add(ChestFound(key));
    }
  }

  /// The running meal counts down [steps]; when it ends, the auto-eat meal
  /// follows at once if the bag holds more than its keep number, plain
  /// ones first (spec 0011 §5.4).
  void _countMeal(int steps) {
    final meal = s.meal;
    if (meal == null) return;
    meal.left -= steps;
    if (meal.left > 0) return;
    s.meal = null;
    final auto = s.autoEat;
    if (auto != null) {
      final plain = s.inventory[auto.meal] ?? 0;
      final perfect = s.inventory[GameData.perfectKey(auto.meal)] ?? 0;
      if (plain + perfect > auto.keep) {
        final key = plain > 0 ? auto.meal : GameData.perfectKey(auto.meal);
        s
          ..addItem(key, -1)
          ..meal = ActiveMeal(key, data.mealStepsOf(key));
        events.add(MealEaten(key, left: plain + perfect - 1));
        return;
      }
    }
    events.add(MealsOut(data.itemOf(meal.key)!.id));
  }

  /// One auto-resolved round. The player strikes first unless the monster is
  /// quick. HP is full at the start of each fight (spec 0001 §4). Traits:
  /// spec 0002 §5.1. Each swing can miss, be dodged, crit or be blocked
  /// (spec 0009 §2.1).
  EndReason? _combatRound(RunningActivity act) {
    final enemy = data.enemies[act.activity.target]!;
    final me = game.stats(s);
    final fight = act.fight ??= FightState(
      playerHp: me.hp,
      enemyHp: enemy.stats.hp,
    );
    fight.round++;

    int? dealt;
    int? taken;
    Swing? mine;
    Swing? theirs;
    bool playerTurn() {
      final (swing, hit) = _playerSwing(enemy, me);
      (mine, dealt) = (swing, hit);
      fight.enemyHp -= hit;
      return fight.enemyHp <= 0;
    }

    bool monsterTurn() {
      if (_monsterSwing(enemy, fight, me) case (final swing, final hit)) {
        (theirs, taken) = (swing, hit);
      }
      return fight.playerHp <= 0;
    }

    final FightOutcome? outcome;
    if (enemy.has(Trait.quick)) {
      outcome = monsterTurn()
          ? FightOutcome.lost
          : (playerTurn() ? FightOutcome.won : null);
    } else {
      outcome = playerTurn()
          ? FightOutcome.won
          : (monsterTurn() ? FightOutcome.lost : null);
    }
    act.log.add(
      RoundLog(
        round: fight.round,
        dealt: dealt,
        taken: taken,
        mine: mine,
        theirs: theirs,
        outcome: outcome,
      ),
    );
    while (act.log.length > data.fightLogRounds) {
      act.log.removeAt(0);
    }
    return switch (outcome) {
      FightOutcome.won => _win(act, enemy),
      FightOutcome.lost => _lose(act, enemy),
      null => null,
    };
  }

  /// Whether a roll comes in under [percent]. Uses no roll at 0%.
  bool _chance(int percent) => percent > 0 && rng.nextDouble() * 100 < percent;

  /// The player's swing and its damage: hit roll, the monster's dodge roll,
  /// then damage with the type factor and the crit roll.
  (Swing, int) _playerSwing(EnemyDef enemy, Stats me) {
    if (!_chance(game.playerHitChance(s, enemy.id))) return (Swing.miss, 0);
    if (_chance(game.enemyDodge(enemy.id))) return (Swing.dodge, 0);
    final factor = data.combat.typeFactor(game.damageType(s), enemy.armour);
    final hit = _damage(me.attack, enemy.stats.defense, factor);
    if (_chance(game.critChance(s))) {
      return (Swing.crit, (hit * data.combat.critDamage).round());
    }
    return (Swing.hit, hit);
  }

  /// The monster's swing and its damage, or null when it doesn't swing
  /// (slow). It regenerates if the player survives, hit or miss.
  (Swing, int)? _monsterSwing(EnemyDef enemy, FightState fight, Stats me) {
    (Swing, int)? swing;
    if (!enemy.has(Trait.slow) || fight.round.isEven) {
      swing = _monsterStrike(enemy, me);
      fight.playerHp -= swing.$2;
      if (fight.playerHp <= 0) return swing;
    }
    fight.enemyHp = math.min(enemy.stats.hp, fight.enemyHp + enemy.regen);
    return swing;
  }

  (Swing, int) _monsterStrike(EnemyDef enemy, Stats me) {
    if (!_chance(game.monsterHitChance(s, enemy.id))) return (Swing.miss, 0);
    if (_chance(game.dodgeChance(s))) return (Swing.dodge, 0);
    final defense = enemy.has(Trait.ghostly) ? 0 : me.defense;
    final hit = _damage(enemy.stats.attack, defense);
    if (_chance(game.blockChance(s))) {
      return (Swing.block, math.max(1, (hit * data.combat.blockShare).round()));
    }
    return (Swing.hit, hit);
  }

  /// Adds [key] to the running action's tally.
  void _gain(RunningActivity act, String key) {
    act.gained[key] = (act.gained[key] ?? 0) + 1;
    game._foundQuality(s, key);
  }

  EndReason? _win(RunningActivity act, EnemyDef enemy) {
    act.fight = null;
    s.fought.add(enemy.id);
    act.lossStreak = 0;
    act.won++;
    final drops = <String, int>{};
    void drop(DropDef d) {
      for (var i = 0; i < d.count; i++) {
        final key = _withQuality(d.item, enemy.level);
        drops[key] = (drops[key] ?? 0) + 1;
        s.addItem(key);
        _gain(act, key);
        s.counters[Game.foundCounter(enemy.id, d.item)] = 1;
      }
    }

    for (final d in enemy.drops) {
      if (rng.nextDouble() < d.chance) drop(d);
    }
    // Boss uniques: sure the first time, then now and then (spec 0005 §1).
    final firstKill = (s.counters['kills.${enemy.id}'] ?? 0) == 0;
    for (final d in enemy.firstKillDrops) {
      if (firstKill || rng.nextDouble() < d.repeatChance) drop(d);
    }
    // A lore note, once (spec 0009 §7.2). Its roll comes from a generator
    // derived from this kill, so it never shifts the fights and loot after.
    if (enemy.lore case final note? when !s.lore.contains(note.id)) {
      final kill = (s.counters['kills.${enemy.id}'] ?? 0) + 1;
      final roll = Rng.fromState(rng.state ^ (kill * 0x9E3779B1)).nextDouble();
      if (roll < data.combat.loreChance) {
        s.lore.add(note.id);
        events.add(LoreFound(note.id));
      }
    }
    final xp = _faded(enemy.xp, enemy.level);
    s.count('kills.${enemy.id}');
    events.add(FightWon(enemy.id, xp, drops));
    _gainXp(xp);
    final kills = s.counters['kills.${enemy.id}']!;
    if (kills == data.combat.studyKills) {
      events.add(WeaknessLearned(enemy.id));
    }
    if (kills == data.combat.slayerKills) events.add(SlayerEarned(enemy.id));
    return null;
  }

  /// A loss keeps everything and pays a share of the XP for the health
  /// knocked off; no loot. The action gives up after a few losses in a row
  /// (spec 0003 §5).
  EndReason? _lose(RunningActivity act, EnemyDef enemy) {
    final share = (enemy.stats.hp - act.fight!.enemyHp) / enemy.stats.hp;
    act.fight = null;
    s.fought.add(enemy.id);
    final pct = data.bandFor(enemy.level, game.level(s)).xpPercent;
    final xp = share <= 0
        ? 0
        : math.max(
            1,
            // The epsilon keeps 26.9999... from rounding down to 26.
            (enemy.xp * data.lossXpShare * share * pct / 100 + 1e-9).floor(),
          );
    act.lost++;
    events.add(FightLost(enemy.id, xp, share));
    _gainXp(xp);
    act.lossStreak++;
    return act.lossStreak >= data.lossesToGiveUp ? EndReason.defeated : null;
  }

  /// [item]'s key: gear rolls a quality, then its bonus stats (spec 0009
  /// §5.1); materials stay plain. The bonus stats come from a generator
  /// seeded by one draw, so how many there are never shifts later rolls.
  String _withQuality(
    String item,
    int itemLevel, {
    int? playerLevel,
    Rng? with_,
  }) {
    if (data.items[item]!.slot == null) return item;
    final from = with_ ?? rng;
    final q = game.rollQuality(
      from,
      playerLevel: playerLevel ?? game.level(s),
      itemLevel: itemLevel,
    );
    final own = Rng.fromState(from.nextUint32());
    return data.keyFor(item, q, game.rollBonus(own, item, q, itemLevel));
  }

  /// One action of [profession] at [level]: pays its profession XP [xp]
  /// faded (a [ProfessionLevelUp] per level gained), and returns the
  /// character XP for its steps, from the [base] steps through the tool
  /// (spec 0010 §2).
  int _practise(String profession, int level, int xp, int base) {
    final fade = game.professionFade(s, profession, level);
    final before = game.professionLevel(s, profession);
    s.professions[profession] =
        (s.professions[profession] ?? 0) + xp * fade ~/ 100;
    final after = game.professionLevel(s, profession);
    for (var l = before + 1; l <= after; l++) {
      events.add(ProfessionLevelUp(profession, l));
    }
    final steps = game.professionSteps(s, profession, base);
    return game.professionCharacterXp(s, steps, fade);
  }

  /// [xp] for something at [level], faded by the colour table; at least 1
  /// (spec 0002 §3).
  int _faded(int xp, int level) {
    final band = data.bandFor(level, game.level(s));
    return math.max(1, xp * band.xpPercent ~/ 100);
  }

  int _damage(int attack, int defense, [double factor = 1]) {
    final base = math.max(1.0, attack - defense / 2) * factor;
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

  /// Counters, levels and the quality found never go down in play, so only
  /// a load loses an achievement (spec 0017 §4).
  void _checkAchievements() {
    for (final a in data.achievements.values) {
      if (!s.achievements.contains(a.id) && game.achievementMet(s, a)) {
        game._earn(s, a, events);
      }
    }
  }
}
