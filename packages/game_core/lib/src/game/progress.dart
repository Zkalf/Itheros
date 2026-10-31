part of '../game.dart';

/// Levels, XP, professions, the character, teachers, stats and the next goal.
extension GameProgress on Game {
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

  /// Makes the character on Set out (spec 0012 §2.2): the origin's
  /// profession is learned with its starter tool if it wasn't, and its XP
  /// raised to [GameData.headStartLevel]'s only if lower. No news, no
  /// character XP, no draws. Throws [ActivityError] for a second character
  /// or an unknown origin.
  GameState makeCharacter(
    GameState s, {
    required String name,
    required Gender gender,
    required String origin,
  }) {
    if (s.character != null) throw ActivityError('You already set out');
    final o = data.origins[origin];
    if (o == null) throw ActivityError('No origin $origin');
    final p = data.professions[o.profession]!;
    final n = s.copy()
      ..character = Character(
        name: Game.characterName(name),
        gender: gender,
        origin: origin,
      );
    if (n.learned.add(p.id)) n.tools[p.id] ??= p.teacher.starterTool;
    n.professions[p.id] = math.max(
      n.professions[p.id] ?? 0,
      data.professionXpForLevel(data.headStartLevel),
    );
    return n;
  }

  /// Renames the character, by [characterName]'s rules (spec 0012 §4.2).
  GameState renameCharacter(GameState s, String name) {
    final c = _character(s);
    return s.copy()
      ..character = Character(
        name: Game.characterName(name),
        gender: c.gender,
        origin: c.origin,
      );
  }

  GameState setGender(GameState s, Gender gender) {
    final c = _character(s);
    return s.copy()
      ..character = Character(name: c.name, gender: gender, origin: c.origin);
  }

  Character _character(GameState s) =>
      s.character ?? (throw ActivityError('You have not set out yet'));

  /// [line] with `{name}` as [who]'s name and each `{a|b|c}` as the word
  /// for their gender (spec 0012 §2.3). Before Set out: Wanderer, neither.
  String fill(String line, Character? who) =>
      line.replaceAllMapped(RegExp(r'\{([^{}]*)\}'), (m) {
        final t = m[1]!;
        if (t == 'name') return who?.name ?? Game.defaultName;
        final words = t.split('|');
        if (words.length != 3) return m[0]!;
        return words[(who?.gender ?? Gender.neither).index];
      });

  /// Whether [profession]'s teacher shares the character's origin.
  bool isKin(GameState s, String profession) =>
      s.character != null &&
      data.origins[s.character!.origin]?.profession == profession;

  /// The line [profession]'s teacher opens with, filled: the kin line for
  /// the origin's own teacher, else the greeting (spec 0012 §3.1).
  String teacherLine(GameState s, String profession) {
    final t = data.professions[profession]!.teacher;
    return fill(isKin(s, profession) ? t.kinLine : t.greeting, s.character);
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
        if (t.level <= level && !s.tips.contains(t.id) && !tipHidden(s, t)) t,
    ];
  }

  /// The next tip [profession]'s teacher will tell at a higher level, or
  /// null. A tip about a spot not yet revealed is not named (spec 0010
  /// amendment 8 §4).
  TipDef? nextTip(GameState s, String profession) {
    final level = professionLevel(s, profession);
    return data.professions[profession]!.tips
        .where((t) => t.level > level && !tipHidden(s, t))
        .firstOrNull;
  }

  /// Whether [tip] is about a spot whose every area is hidden and not yet
  /// revealed: it waits for the reveal (spec 0010 amendment 8 §4).
  bool tipHidden(GameState s, TipDef tip) => switch (tip.node) {
    final n? =>
      data.locations.values
          .where((l) => l.nodes.contains(n))
          .every((l) => isHidden(s, l.id)),
    null => false,
  };

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

  int bankCap(GameState s) {
    var cap = data.bankCapBase + data.bankCapPerLevel * level(s);
    for (final r in _rewards(s)) {
      if (r case BankCapReward(:final amount)) cap += amount;
    }
    return cap;
  }

  /// The rewards of the earned achievements (spec 0017 §3.4).
  Iterable<Reward> _rewards(GameState s) => [
    for (final id in s.achievements)
      if (data.achievements[id] case final a?) a.reward,
  ];

  /// The character's stats: level, gear, the running meal and the bonuses
  /// of the earned feats (spec 0017 §3.4).
  Stats stats(GameState s) =>
      _gearStats(s) + mealBonus(s) + achievementBonus(s);

  /// The bonuses of the earned feats; two bonuses to one stat add up.
  Stats achievementBonus(GameState s) {
    var total = const Stats();
    for (final r in _rewards(s)) {
      if (r case BonusReward(:final bonus)) total += bonus;
    }
    return total;
  }

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
  /// Saves before version 10 need nothing: no character yet, so "Who are
  /// you?" shows once (spec 0012 §6).
  /// Saves before version 11 get the walks their queue needs (spec 0016
  /// §6).
  /// Saves before version 12 start the quality counter (spec 0017 §3.2).
  /// Any save holding a two-hander and an off-hand item puts the off-hand
  /// item in the bag.
  GameState migrate(GameState s) {
    var n = _migrateXp(s);
    if (s.loadedVersion < 4) n = _visit(n.copy(), n.location);
    if (s.loadedVersion < 5) n = _findOwnedDrops(n.copy());
    if (s.loadedVersion < 6) n = _migrateLayout(n.copy());
    if (s.loadedVersion < 7) n = _migrateBonus(n.copy());
    if (s.loadedVersion < 8) n = _migrateProfessions(n.copy());
    if (s.loadedVersion < 11) n = _migrateWalks(n.copy());
    if (s.loadedVersion < 12) n = _migrateQualityFound(n.copy());
    return _freeOffHand(n);
  }
}
