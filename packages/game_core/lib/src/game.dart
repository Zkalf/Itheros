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

  GameState newGame({required int seed}) => _visit(
    GameState(
      location: data.startLocation,
      rngState: Rng.seeded(seed).state,
      professionRng: professionStream(seed),
    ),
    data.startLocation,
  );

  /// The profession stream's first state, a fixed hash of [from] (a game
  /// seed, or an old save's generator state): no draw from the shared
  /// generator (spec 0010 §9.1).
  static int professionStream(int from) =>
      Rng.fromState(((from ^ 0x5BD1E995) * 0x85EBCA6B) & 0xFFFFFFFF).state;

  /// Counts [area] as visited, once (spec 0004 §4), and explored (spec
  /// 0008 decision 5). Mutates and returns [s].
  GameState _visit(GameState s, String area) {
    s.explored.add(area);
    if ((s.counters['visited.$area'] ?? 0) == 0) {
      s.counters['visited.$area'] = 1;
      s.count('areas.visited');
    }
    return s;
  }

  int level(GameState s) => data.levelForXp(s.xp);

  /// [profession]'s level (spec 0010 §2.2); 1 before any XP.
  int professionLevel(GameState s, String profession) =>
      data.professionLevelForXp(s.professions[profession] ?? 0);

  /// The share of XP, in percent, an action at [actionLevel] of
  /// [profession] pays (spec 0010 §2.3).
  int professionFade(GameState s, String profession, int actionLevel) => data
      .professionBandFor(actionLevel, professionLevel(s, profession))
      .xpPercent;

  /// Learns [profession] from its teacher, who must be here, and wears the
  /// starter tool (spec 0010 §6.1). Throws [ActivityError] otherwise.
  GameState learn(GameState s, String profession) {
    final p = data.professions[profession];
    if (p == null) throw ActivityError('No profession $profession');
    if (s.learned.contains(profession)) {
      throw ActivityError('You already know ${p.name}');
    }
    if (s.location != p.teacher.location) {
      throw ActivityError(
        '${p.teacher.name} teaches ${p.name} in '
        '${data.locations[p.teacher.location]!.name}',
      );
    }
    return s.copy()
      ..learned.add(profession)
      ..tools[profession] = p.teacher.starterTool;
  }

  /// What reaching [level] in [profession] opens: its spots and recipes of
  /// that level (spec 0010 §2.2).
  List<LevelNews> professionNews(String profession, int level) => [
    for (final n in data.nodes.values)
      if (n.profession == profession && n.level == level && level > 1)
        LevelNews(NewsKind.gatheringSpot, n.id),
    for (final r in data.recipes.values)
      if (r.profession == profession && r.craftingLevel == level && level > 1)
        LevelNews(NewsKind.recipe, r.id),
  ];

  /// Steps one action of [profession] costs, [base] times the worn tool's
  /// share, rounded up (spec 0010 §3.2).
  /// A fewer-steps meal multiplies in (spec 0011 §5.3).
  int professionSteps(GameState s, String profession, int base) =>
      (base * toolFactor(s.tools[profession]) * (1 - mealStepShare(s)) - 1e-9)
          .ceil();

  /// The share of an action's steps the tool with [key] costs: its tier's,
  /// less [GameData.toolQualityStep] per quality step (spec 0010 §3.2).
  double toolFactor(String? key) {
    final tool = key == null ? null : data.itemOf(key)?.tool;
    if (tool == null) return 1;
    return tool.stepFactor - data.toolQualityStep * _qualitySteps(key!);
  }

  int _qualitySteps(String key) => data.qualities.indexOf(data.qualityOf(key));

  /// Wears the tool with [key] from the bag in its profession's slot; the
  /// tool there goes to the bag (spec 0010 §3.2).
  GameState equipTool(GameState s, String key) {
    final profession = data.toolProfession(key);
    if (profession == null) throw ActivityError('$key is not a tool');
    if ((s.inventory[key] ?? 0) < 1) throw ActivityError('No $key to use');
    final n = s.copy()..addItem(key, -1);
    if (n.tools[profession] case final old?) n.addItem(old);
    n.tools[profession] = key;
    return n;
  }

  /// The tips [profession]'s teacher has for the player now, untold (spec
  /// 0010 §6.2).
  List<TipDef> tipsWaiting(GameState s, String profession) {
    if (!s.learned.contains(profession)) return const [];
    final level = professionLevel(s, profession);
    return [
      for (final t in data.professions[profession]!.tips)
        if (t.level <= level && !s.tips.contains(t.id)) t,
    ];
  }

  /// Talks to [profession]'s teacher, who must be here: every waiting tip
  /// is told.
  GameState talk(GameState s, String profession) {
    final p = data.professions[profession]!;
    if (!s.learned.contains(profession) || s.location != p.teacher.location) {
      throw ActivityError('${p.teacher.name} is not here');
    }
    return s.copy()..tips.addAll(tipsWaiting(s, profession).map((t) => t.id));
  }

  /// The chance a gathering action at [node] finds its rare find (spec 0010
  /// §5.1).
  double rareFindChance(GameState s, String node) {
    final n = data.nodes[node]!;
    final tool = s.tools[n.profession];
    final steps = tool == null ? 0 : _qualitySteps(tool);
    final above = math.max(0, professionLevel(s, n.profession) - n.level);
    final levelBonus = math.min(
      data.rareMaxLevelBonus,
      data.rarePerLevelAbove * above,
    );
    return (n.rareBase ?? data.rareBase) *
        (1 + data.rarePerToolQualityStep * steps) *
        (1 + levelBonus);
  }

  /// The chance a cook of [recipe] turns out a perfect dish (spec 0011
  /// §5.3): spec 0010 §5.1's formula with the pot and Cooking.
  double perfectChance(GameState s, String recipe) {
    final r = data.recipes[recipe]!;
    final tool = s.tools[r.profession];
    final steps = tool == null ? 0 : _qualitySteps(tool);
    final above = math.max(0, professionLevel(s, r.profession) - r.level);
    final levelBonus = math.min(
      data.perfectMaxLevelBonus,
      data.perfectPerLevelAbove * above,
    );
    return data.perfectBase *
        (1 + data.perfectPerToolQualityStep * steps) *
        (1 + levelBonus);
  }

  /// Eats the meal [key] from the bag; one running now is replaced (spec
  /// 0011 §5.4). Throws [ActivityError] otherwise.
  GameState eat(GameState s, String key) {
    if (data.itemOf(key)?.meal == null) throw ActivityError('$key is no meal');
    if ((s.inventory[key] ?? 0) < 1) throw ActivityError('No $key to eat');
    return s.copy()
      ..addItem(key, -1)
      ..meal = ActiveMeal(key, data.mealStepsOf(key));
  }

  /// Sets the meal kind [meal] (an item id) to be eaten when the running
  /// one ends, keeping [keep] in the bag; null turns auto-eat off.
  GameState setAutoEat(GameState s, String? meal, {int keep = 0}) {
    if (meal != null && data.items[meal]?.meal == null) {
      throw ActivityError('$meal is no meal');
    }
    if (keep < 0) throw ActivityError('Keep at least 0');
    return s.copy()..autoEat = meal == null ? null : AutoEat(meal, keep);
  }

  /// What the running meal adds to the stats (spec 0011 §5.3): a percent
  /// of the total with gear, rounded down, at least 1; Crit in points.
  Stats mealBonus(GameState s) {
    final meal = s.meal == null ? null : data.itemOf(s.meal!.key)?.meal;
    if (meal == null) return const Stats();
    final gear = _gearStats(s);
    final pct = data.mealPercent[meal.tier - 1];
    int up(int v) => math.max(1, v * pct ~/ 100);
    return Stats(
      hp: meal.buffs.contains('hp') ? up(gear.hp) : 0,
      attack: meal.buffs.contains('attack') ? up(gear.attack) : 0,
      defense: meal.buffs.contains('defense') ? up(gear.defense) : 0,
      crit: meal.buffs.contains('crit') ? data.mealCrit[meal.tier - 1] : 0,
    );
  }

  /// The share of profession and reroll steps the running meal takes off
  /// (spec 0011 §5.3).
  double mealStepShare(GameState s) {
    final meal = s.meal == null ? null : data.itemOf(s.meal!.key)?.meal;
    if (meal == null || !meal.buffs.contains('steps')) return 0;
    return data.mealPercent[meal.tier - 1] / 100;
  }

  /// The chance salvaging [key] gives a boss shard (spec 0010 §7.1).
  double shardChance(String key) =>
      data.shardBase + data.shardPerQualityStep * _qualitySteps(key);

  /// The shard salvaging [key] may give: its tier boss's.
  String shardFor(String key) =>
      data.shards[data.bonusTierIndex(data.itemLevel(data.itemOf(key)!.id))];

  /// Whether the player can salvage and reroll here.
  bool atForge(GameState s) =>
      _here(s).crafting && _canPractise(s, 'crafting', 1);

  /// Breaks the bag item [key] down at a forge into one dust of its quality,
  /// with a roll for a boss shard on the profession stream (spec 0010
  /// §7.1). Throws [ActivityError] if it can't.
  SalvageResult salvage(GameState s, String key) {
    final item = data.itemOf(key);
    if (!atForge(s)) throw ActivityError('Salvage at a forge');
    if (item == null || (item.slot == null && item.tool == null)) {
      throw ActivityError('Only gear and tools can be salvaged');
    }
    if (item.tool?.starter ?? false) {
      throw ActivityError('A teacher\'s gift can\'t be salvaged');
    }
    if ((s.inventory[key] ?? 0) < 1) {
      throw ActivityError('Only items in the bag can be salvaged');
    }
    final n = s.copy()..addItem(key, -1);
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

  int bankCap(GameState s) {
    var cap = data.bankCapBase + data.bankCapPerLevel * level(s);
    for (final id in s.achievements) {
      cap += data.achievements[id]?.bankCapReward ?? 0;
    }
    return cap;
  }

  /// The character's stats: level, gear and the running meal.
  Stats stats(GameState s) => _gearStats(s) + mealBonus(s);

  Stats _gearStats(GameState s) {
    var total = data.baseStats + data.statsPerLevel * (level(s) - 1);
    for (final item in s.equipment.values) {
      total += data.bonusOf(item);
    }
    return total;
  }

  /// The main-hand weapon's damage type; null bare-handed (spec 0009 §3).
  String? damageType(GameState s) => switch (s.equipment['mainHand']) {
    final key? => data.itemOf(key)?.damageType,
    null => null,
  };

  /// What the player knows about [enemy] (spec 0009 §7.1): its armour from
  /// the first fight, its weakness and stats from enough kills; a lore note
  /// about it tells armour and weakness (§7.2).
  Knowledge knowledge(GameState s, String enemy) {
    final kills = s.counters['kills.$enemy'] ?? 0;
    final c = data.combat;
    // A lore note or a teacher's tip about it (spec 0010 §6.2).
    final note =
        data.loreNotes.any((n) => n.about == enemy && s.lore.contains(n.id)) ||
        data.professions.values.any(
          (p) => p.tips.any((t) => t.enemy == enemy && s.tips.contains(t.id)),
        );
    return Knowledge(
      kills: kills,
      armour: note || s.fought.contains(enemy) || kills > 0,
      weakness: note || kills >= c.studyKills,
      stats: kills >= c.studyKills,
      slayer: kills >= c.slayerKills,
      killsToNext: kills < c.studyKills
          ? c.studyKills - kills
          : kills < c.slayerKills
          ? c.slayerKills - kills
          : null,
    );
  }

  /// The damage type [enemy] is weak to: the one strong against its armour.
  String weakness(String enemy) =>
      data.combat.strongAgainst(data.enemies[enemy]!.armour);

  /// Whether the player has earned Slayer against [enemy] (spec 0009 §7.1).
  bool slayer(GameState s, String enemy) =>
      (s.counters['kills.$enemy'] ?? 0) >= data.combat.slayerKills;

  /// The player's chance to hit [enemy], in percent (spec 0009 §2.1). The
  /// monster's Dodge is a roll of its own and doesn't change it.
  int playerHitChance(GameState s, String enemy) {
    final e = data.enemies[enemy]!;
    final slayerHit = slayer(s, enemy) ? data.combat.slayerHit : 0;
    return data.combat.hitChance(level(s) - e.level, stats(s).hit + slayerHit);
  }

  /// [enemy]'s chance to hit the player, in percent. Monsters have no Hit.
  int monsterHitChance(GameState s, String enemy) =>
      data.combat.hitChance(data.enemies[enemy]!.level - level(s), 0);

  /// The player's Crit, Block and Dodge in percent, base Crit included and
  /// each within its cap (spec 0009 §2.1).
  int critChance(GameState s) =>
      math.min(data.combat.critCap, data.combat.critBase + stats(s).crit);

  int blockChance(GameState s) =>
      math.min(data.combat.blockCap, stats(s).block);

  int dodgeChance(GameState s) =>
      math.min(data.combat.dodgeCap, stats(s).dodge);

  /// [enemy]'s Dodge, within the cap.
  int enemyDodge(String enemy) =>
      math.min(data.combat.dodgeCap, data.enemies[enemy]!.stats.dodge);

  /// Picks a quality id for gear of [itemLevel] made or found by a player of
  /// [playerLevel] (spec 0005 §3). Uses one roll of [rng].
  String rollQuality(
    Rng rng, {
    required int playerLevel,
    required int itemLevel,
  }) {
    final above = math.min(
      data.qualityMaxLevels,
      math.max(0, playerLevel - itemLevel),
    );
    final boost = 1 + data.qualityPerLevel * above;
    var roll = rng.nextDouble();
    for (final q in data.qualities.reversed) {
      if (q == data.qualities.first) break;
      roll -= q.chance * boost;
      if (roll < 0) return q.id;
    }
    return data.qualities.first.id;
  }

  /// The bonus stats gear of [quality] rolls when made or found (spec 0009
  /// §5.1): one per quality step above common, each a stat picked from the
  /// pool of [itemLevel]'s tier (Block only for the off hand) and a value
  /// in its range. Repeats can happen.
  List<BonusRoll> rollBonus(
    Rng rng,
    String item,
    String quality,
    int itemLevel,
  ) {
    final steps = data.qualities.indexWhere((q) => q.id == quality);
    return rollBonusStats(rng, item, steps, itemLevel);
  }

  /// [count] bonus stat rolls for gear [item] of [itemLevel] (spec 0009
  /// §5.1).
  List<BonusRoll> rollBonusStats(
    Rng rng,
    String item,
    int count,
    int itemLevel,
  ) {
    final steps = count;
    final offHand = data.items[item]!.slot == 'offHand';
    final pool = [
      for (final MapEntry(key: stat, value: range)
          in data.bonusTierFor(itemLevel).ranges.entries)
        if (stat != 'block' || offHand) (stat, range),
    ];
    return [
      for (var i = 0; i < steps; i++)
        if (pool[rng.nextInt(pool.length)] case (
          final stat,
          (final lo, final hi),
        ))
          (stat: stat, value: lo + rng.nextInt(hi - lo + 1)),
    ];
  }

  /// Total XP needed for the next level. There is no level cap.
  int xpForNextLevel(GameState s) => data.xpForLevel(level(s) + 1);

  /// The slots [key] can be worn in, in display order; empty for materials.
  List<String> slotsFor(String key) => switch (data.itemOf(key)?.slot) {
    final kind? => data.slotsOfKind(kind),
    null => const [],
  };

  /// Colour and XP share of [enemy] for this player (spec 0002 §3).
  LevelBand enemyBand(GameState s, String enemy) =>
      data.bandFor(data.enemies[enemy]!.level, level(s));

  /// The rank held at [level].
  RankDef rank(int level) => data.ranks.lastWhere((r) => r.level <= level);

  /// Talent points earned by [level] (spec 0002 decision 7).
  int talentPoints(int level) => math.max(0, level - data.talentPointsFrom + 1);

  /// What reaching [level] brings, for its level-up card (spec 0002 §9.1).
  /// Spots and recipes open by profession level instead (spec 0010 §2.2).
  /// With [s], monsters in the fog are left out (spec 0008 decision 5).
  List<LevelNews> levelNews(int level, [GameState? s]) {
    final enemies = data.enemies.values.where(
      (e) => s == null || !enemyFogged(s, e.id),
    );
    return [
      for (final r in data.ranks)
        if (r.level == level && level > 1) LevelNews(NewsKind.rank, r.name),
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
    // A weapon only competes with the worn one of its damage type and hands
    // (spec 0009 §5.3).
    final worn = s.equipment['mainHand'];
    final wornWeapon = worn == null ? null : data.itemOf(worn);
    int gain(String key) {
      final item = data.itemOf(key);
      if (item?.damageType != null &&
          wornWeapon != null &&
          (item!.damageType != wornWeapon.damageType ||
              item.twoHanded != wornWeapon.twoHanded)) {
        return 0;
      }
      return gearGain(s, key);
    }

    final better = [
      for (final key in s.inventory.keys)
        if (data.itemOf(key)?.slot != null && gain(key) > 0) key,
    ]..sort((a, b) => gain(b).compareTo(gain(a)));
    if (better.isNotEmpty) return EquipGoal(better.first);
    if (_professionGoal(s, gain) case final g?) return g;

    final upgrades = [
      for (final r in data.recipes.values)
        if (data.items[r.output]!.slot != null &&
            recipeLevelMet(s, r.id) &&
            owned(s, r.output) == 0 &&
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
      if (enemyFogged(s, e.id) ||
          enemyBand(s, e.id).colour != LevelColour.yellow) {
        continue;
      }
      // An average swing: the hit and dodge rolls and the type factor
      // (spec 0009 §2–§3).
      final hit =
          math.max(1, me.attack - e.stats.defense / 2) *
          data.combat.typeFactor(damageType(s), e.armour) *
          playerHitChance(s, e.id) /
          100 *
          (1 - enemyDodge(e.id) / 100);
      final rate = e.xp / (e.stats.hp / hit).ceil();
      if (rate > bestRate) (best, bestRate) = (e, rate);
    }
    return best == null ? null : FightGoal(best.id);
  }

  /// The level to reach when the best upgrade up to the character's level
  /// waits only on a profession level: its recipe's Crafting level, or the
  /// level of the spot its missing input comes from (spec 0010 §8.4).
  ProfessionGoal? _professionGoal(GameState s, int Function(String) gain) {
    RecipeDef? best;
    for (final r in data.recipes.values) {
      if (data.items[r.output]!.slot == null ||
          r.level > level(s) ||
          owned(s, r.output) > 0 ||
          gain(r.output) <= 0) {
        continue;
      }
      if (best == null || gain(r.output) > gain(best.output)) best = r;
    }
    if (best == null) return null;
    ProfessionGoal? need(String profession, int at, Activity target) =>
        // Learning comes first: the screens point to the teacher.
        _canPractise(s, profession, 1)
        ? ProfessionGoal(profession, at, professionLevel(s, profession), target)
        : null;
    if (!recipeLevelMet(s, best.id)) {
      return need(best.profession, best.craftingLevel, Activity.craft(best.id));
    }
    for (final MapEntry(key: input, value: count) in best.inputs.entries) {
      if ((s.inventory[input] ?? 0) >= count || _safeSource(s, input) != null) {
        continue;
      }
      for (final n in data.nodes.values) {
        if (n.item == input && !nodeFogged(s, n.id)) {
          return need(n.profession, n.level, Activity.gather(n.id));
        }
      }
      return null;
    }
    return null;
  }

  /// How much better [key] is than what it takes off in its weakest slot
  /// (an empty slot counts 0; a two-hander also takes off the off hand, an
  /// off-hand item a two-hander).
  int gearGain(GameState s, String key) {
    final slots = slotsFor(key);
    if (slots.isEmpty) return 0;
    int score(String slot) => switch (s.equipment[slot]) {
      final k? => data.scoreOf(k),
      null => 0,
    };
    final into = slots.reduce((a, b) => score(a) <= score(b) ? a : b);
    var worn = 0;
    for (final id in displaced(s, key, into)) {
      worn += score(id);
    }
    return data.scoreOf(key) - worn;
  }

  /// Whether every area holding [enemy] is in the fog.
  bool enemyFogged(GameState s, String enemy) => data.locations.values
      .where((l) => l.enemies.contains(enemy))
      .every((l) => isFogged(s, l.id));

  /// Whether every area holding gathering spot [node] is in the fog.
  bool nodeFogged(GameState s, String node) => data.locations.values
      .where((l) => l.nodes.contains(node))
      .every((l) => isFogged(s, l.id));

  /// A gathering spot for [item], or the most generous monster dropping it
  /// that is at most yellow; never one in the fog.
  Activity? _safeSource(GameState s, String item) {
    final lvl = level(s);
    for (final n in data.nodes.values) {
      if (n.yieldOf(item) > 0 &&
          nodeLevelMet(s, n.id) &&
          !nodeFogged(s, n.id)) {
        return Activity.gather(n.id);
      }
    }
    EnemyDef? best;
    var bestChance = 0.0;
    for (final e in data.enemies.values) {
      if (enemyFogged(s, e.id) || e.level > lvl + 2) continue;
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
  /// 2 saves need nothing more: their activity loaded as a 1-action queue.
  /// Saves before version 4 count the area they are in as visited (spec
  /// 0004 decision 9).
  /// Saves before version 5 count a drop as found if the monster was killed
  /// and the item is owned or worn (spec 0006 decision 6).
  /// Saves before version 6 move their gear onto the paper doll and count
  /// visited areas as explored (spec 0008 §2.4).
  /// Saves before version 7 roll bonus stats for owned gear above Common
  /// and count every monster with a kill as fought (spec 0009 §10).
  /// Saves before version 8 learn Mining and Crafting at the levels their
  /// counters earn, and seed the profession stream (spec 0010 §10).
  /// Saves before version 9 need nothing: no meal, no records, the cove
  /// hidden, the new professions unlearned (spec 0011 §10).
  /// Any save holding a two-hander and an off-hand item puts the off-hand
  /// item in the bag.
  GameState migrate(GameState s) {
    var n = _migrateXp(s);
    if (s.loadedVersion < 4) n = _visit(n.copy(), n.location);
    if (s.loadedVersion < 5) n = _findOwnedDrops(n.copy());
    if (s.loadedVersion < 6) n = _migrateLayout(n.copy());
    if (s.loadedVersion < 7) n = _migrateBonus(n.copy());
    if (s.loadedVersion < 8) n = _migrateProfessions(n.copy());
    return _freeOffHand(n);
  }

  /// Every vein mined and item crafted counts its profession XP, unfaded;
  /// Mining and Crafting are learned with their starter tools.
  GameState _migrateProfessions(GameState s) {
    void earn(String profession, String counter, int xp) {
      final n = s.counters[counter] ?? 0;
      if (n == 0) return;
      s.professions[profession] = (s.professions[profession] ?? 0) + n * xp;
    }

    for (final node in data.nodes.values) {
      earn(node.profession, 'gathered.${node.item}', node.xp);
    }
    final seen = <String>{};
    for (final r in data.recipes.values) {
      if (seen.add(r.output)) earn(r.profession, 'crafted.${r.output}', r.xp);
    }
    for (final id in const ['mining', 'crafting']) {
      if (data.professions[id] case final p?) {
        s.learned.add(id);
        s.tools[id] ??= p.teacher.starterTool;
      }
    }
    s.professionRng = professionStream(s.rngState);
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
        if (owned(s, item) > 0) s.counters[foundCounter(e, item)] = 1;
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

  int _costOf(GameState s, RunningActivity act) {
    final a = act.activity;
    if (act.leg case final leg?) return data.route(s.location, leg)!.steps;
    return switch (a.kind) {
      // A version 2 save walking to a neighbour, with no leg set.
      ActivityKind.travel => data.route(s.location, a.target)!.steps,
      ActivityKind.fight => data.combatRoundSteps,
      ActivityKind.gather => switch (data.nodes[a.target]!) {
        final n => professionSteps(s, n.profession, n.steps),
      },
      ActivityKind.craft => switch (data.recipes[a.target]!) {
        final r => professionSteps(s, r.profession, r.steps),
      },
      ActivityKind.reroll =>
        (data.rerollSteps * (1 - mealStepShare(s)) - 1e-9).ceil(),
    };
  }

  // Queries for the UI. Nothing is locked but gathering spots and recipes,
  // by profession (spec 0010 §2), which still show; fogged areas show
  // nothing.

  List<String> travelDestinations(GameState s) => [
    for (final to in data.destinationsFrom(s.location))
      if (!isFogged(s, to)) to,
  ];

  List<String> availableEnemies(GameState s) => _here(s).enemies;

  /// Spots here, those above the player's level included (see
  /// [nodeLevelMet]).
  List<String> availableNodes(GameState s) => _here(s).nodes;

  /// Recipes made here: crafts at a forge, meals at a fire (spec 0011
  /// §5.1).
  List<String> availableRecipes(GameState s) => [
    for (final id in allRecipes())
      if (_makesHere(_here(s), data.recipes[id]!)) id,
  ];

  bool _makesHere(LocationDef l, RecipeDef r) =>
      r.profession == 'cooking' ? l.fire : l.crafting;

  /// Whether the player has learned [node]'s profession and has the level
  /// to work it (spec 0010 §2.2).
  bool nodeLevelMet(GameState s, String node) {
    final n = data.nodes[node]!;
    return _canPractise(s, n.profession, n.level);
  }

  /// Whether the player has learned Crafting and has the level for
  /// [recipe].
  bool recipeLevelMet(GameState s, String recipe) {
    final r = data.recipes[recipe]!;
    return _canPractise(s, r.profession, r.craftingLevel);
  }

  bool _canPractise(GameState s, String profession, int level) =>
      s.learned.contains(profession) &&
      s.tools.containsKey(profession) &&
      level <= professionLevel(s, profession);

  /// Open locations, nearest first, with their walking distance from here
  /// (spec 0003 §8: plan a day from anywhere).
  Map<String, int> openLocationsByDistance(GameState s) {
    final dist = _paths(s).$1;
    return Map.fromEntries(
      dist.entries.toList()..sort((a, b) => a.value.compareTo(b.value)),
    );
  }

  /// Monsters at [location], unless it is fogged.
  List<String> enemiesAt(GameState s, String location) =>
      isFogged(s, location) ? const [] : data.locations[location]!.enemies;

  /// Gathering spots at [location], unless it is fogged.
  List<String> nodesAt(GameState s, String location) =>
      isFogged(s, location) ? const [] : data.locations[location]!.nodes;

  /// Every recipe (they can be crafted at any crafting place).
  List<String> allRecipes() => data.recipes.keys.toList();

  /// Whether [area] is in the fog: neither explored nor joined by a route to
  /// an explored area (spec 0008 decision 5).
  /// A hidden area is fogged until revealed, whatever its neighbours (spec
  /// 0011 §6.2).
  bool isFogged(GameState s, String area) =>
      isHidden(s, area) ||
      !s.explored.contains(area) &&
          !data.destinationsFrom(area).any(s.explored.contains);

  /// Whether [area] is hidden and not yet revealed: off the map and out of
  /// every list (spec 0011 §6.2).
  bool isHidden(GameState s, String area) =>
      data.locations[area]!.hidden && !s.revealed.contains(area);

  /// The nearest open crafting place and its distance, or null if none is
  /// reachable.
  (String, int)? nearestForge(GameState s) {
    final dist = _paths(s).$1;
    (String, int)? best;
    for (final l in data.locations.values) {
      final d = dist[l.id];
      if (l.crafting && d != null && (best == null || d < best.$2)) {
        best = (l.id, d);
      }
    }
    return best;
  }

  /// Every item [enemy] can drop, boss uniques last, each once.
  List<String> dropItems(String enemy) => {
    for (final d in data.enemies[enemy]!.drops) d.item,
    for (final d in data.enemies[enemy]!.firstKillDrops) d.item,
  }.toList();

  /// The counter set when [item] first drops from [enemy] (spec 0006
  /// decision 5).
  static String foundCounter(String enemy, String item) => 'found.$enemy.$item';

  /// Monsters [item] has dropped from for this player, and the gathering
  /// spots that give it, for the item card (spec 0008 §3.5). Monsters it
  /// hasn't dropped from yet stay hidden (spec 0006 §2.2).
  (List<String>, List<String>) itemSources(GameState s, String item) => (
    [
      for (final e in data.enemies.keys)
        if ((s.counters[foundCounter(e, item)] ?? 0) > 0) e,
    ],
    [
      for (final n in data.nodes.values)
        if ((n.yieldOf(item) > 0 || n.rareFind == item) && !nodeFogged(s, n.id))
          n.id,
    ],
  );

  /// Recipes that use [item], in data order.
  List<String> itemUses(String item) => [
    for (final r in data.recipes.values)
      if (r.inputs.containsKey(item)) r.id,
  ];

  /// [enemy]'s drops the player has found, in [dropItems] order.
  List<String> foundDrops(GameState s, String enemy) => [
    for (final item in dropItems(enemy))
      if ((s.counters[foundCounter(enemy, item)] ?? 0) > 0) item,
  ];

  bool hasMaterials(GameState s, String recipe) => data
      .recipes[recipe]!
      .inputs
      .entries
      .every((e) => (s.inventory[e.key] ?? 0) >= e.value);

  /// How many more of each input [recipe] needs, in recipe order.
  Map<String, int> missingFor(GameState s, String recipe) => {
    for (final e in data.recipes[recipe]!.inputs.entries)
      if (e.value - (s.inventory[e.key] ?? 0) case final n when n > 0) e.key: n,
  };

  /// Owned [item]s of every quality, equipped ones included.
  int owned(GameState s, String item) {
    bool isIt(String key) => data.itemOf(key)?.id == item;
    var n = s.equipment.values.where(isIt).length;
    s.inventory.forEach((key, count) {
      if (isIt(key)) n += count;
    });
    return n;
  }

  /// How many actions the queue holds at the player's level, the running
  /// one included (spec 0003 §2).
  int queueSlots(GameState s) => data.queueSlots;

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
    if (lastNeverStops(s)) {
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
  GameState startActivity(GameState s, Activity a, {StopCondition? stop}) {
    // A reroll is one roll; everything else runs until stopped.
    stop ??= a.kind == ActivityKind.reroll
        ? StopCondition.defaultFor(a)
        : const StopCondition.never();
    _checkStop(s, a, stop);
    if (s.queue.isNotEmpty &&
        stop.kind == StopKind.never &&
        a.kind != ActivityKind.travel) {
      throw ActivityError(
        'Actions are waiting after this one, so it needs a stop condition.',
      );
    }
    final why = _cannotStart(s, a, stop);
    if (why != null) throw ActivityError(_explain(s, a, stop, why));
    final n = _refundProgress(s.copy())
      ..activity = RunningActivity(a, stop: stop);
    n.activity!.leg = _nextLeg(n, a);
    return n;
  }

  /// Ends the running action and starts the next one; with nothing next the
  /// character rests. Unspent progress goes to the bank (spec 0001
  /// amendment 2). Waiting actions that can't start are skipped and added
  /// to [events].
  GameState stopActivity(GameState s, {List<GameEvent>? events}) {
    if (s.activity == null) throw ActivityError('Nothing to stop');
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

  String _explain(GameState s, Activity a, StopCondition stop, SkipReason r) {
    final name =
        switch (a.kind) {
          ActivityKind.travel => data.locations[a.target]?.name,
          ActivityKind.fight => data.enemies[a.target]?.name,
          ActivityKind.gather => data.nodes[a.target]?.name,
          ActivityKind.craft =>
            data.items[data.recipes[a.target]?.output]?.name,
          ActivityKind.reroll => data.itemOf(a.rerollKey)?.name,
        } ??
        a.target;
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
  (Map<String, int>, Map<String, String>) _paths(GameState s) {
    final dist = {s.location: 0};
    final previous = <String, String>{};
    final todo = {s.location};
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
      final why = _cannotStart(s, p.activity, p.stop);
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

/// What [Game.salvage] made: the new state, the dust and a boss shard, if
/// one came (spec 0010 §7.1).
class SalvageResult {
  const SalvageResult(this.state, this.dust, this.shard);

  final GameState state;
  final String dust;
  final String? shard;
}

/// What the player knows about a monster (spec 0009 §7.1).
class Knowledge {
  const Knowledge({
    required this.kills,
    required this.armour,
    required this.weakness,
    required this.stats,
    required this.slayer,
    required this.killsToNext,
  });

  final int kills;
  final bool armour;
  final bool weakness;
  final bool stats;
  final bool slayer;

  /// Kills until the next thing is learned (weakness and stats, then
  /// Slayer); null once Slayer is earned.
  final int? killsToNext;
}

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
    s.location = area;
    game._visit(s, area);
    events.add(Arrived(area));
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
  void _gain(RunningActivity act, String key) =>
      act.gained[key] = (act.gained[key] ?? 0) + 1;

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
