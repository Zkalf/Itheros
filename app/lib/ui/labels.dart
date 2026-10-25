import 'package:game_core/game_core.dart';

import '../sync/away_summary.dart';

/// 12345 -> "12,345".
String fmt(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// (1, 'step') -> "1 step"; (1200, 'step') -> "1,200 steps".
String plural(int n, String noun) => '${fmt(n)} $noun${n == 1 ? '' : 's'}';

/// Male, Female, Neither (spec 0012 §4.1).
String genderName(Gender g) => switch (g) {
  Gender.male => 'Male',
  Gender.female => 'Female',
  Gender.neither => 'Neither',
};

/// The line between two fights in the fight log.
const newFight = '── New fight ──';

/// Display names from the game data.
class Labels {
  Labels(this.data, [this.who]);

  final GameData data;

  /// Whose name and gendered words data lines are filled with (spec 0012
  /// §2.3).
  final Character? who;

  /// [line] filled for [who].
  String fill(String line) => Game(data).fill(line, who);

  String location(String id) => data.locations[id]?.name ?? id;
  String enemy(String id) => data.enemies[id]?.name ?? id;
  String node(String id) => data.nodes[id]?.name ?? id;

  /// An item's name; gear better than common adds its quality: "Bone sword
  /// (Rare)" (spec 0005 decision 3).
  String item(String key) {
    final item = data.itemOf(key);
    if (item == null) return key;
    if (data.isPerfect(key)) return '${item.name} (Perfect)';
    final q = data.qualityOf(key);
    return q == data.qualities.first ? item.name : '${item.name} (${q.name})';
  }

  /// A piece of gear you own, always with its quality: "Hide vest (Common)",
  /// "Bone sword (Rare)". Materials keep their plain name.
  String owned(String key) {
    final item = data.itemOf(key);
    if (item == null) return key;
    if (item.slot == null) return this.item(key);
    return '${item.name} (${data.qualityOf(key).name})';
  }

  String qualityName(String id) =>
      data.qualities.where((q) => q.id == id).firstOrNull?.name ?? id;

  /// A round of the fight log, one line per swing (spec 0009 §8.1):
  /// "Round 3: You hit for 9", "Skeleton misses", in the order they swung,
  /// then who was beaten.
  List<String> roundLines(RoundLog r, String enemyId) {
    final name = enemy(enemyId);
    final mine = switch (r.mine) {
      Swing.hit => 'You hit for ${r.dealt}',
      Swing.crit => 'Critical hit for ${r.dealt}',
      Swing.miss => 'You miss',
      Swing.dodge => '$name dodges',
      Swing.block || null => null,
    };
    final theirs = switch (r.theirs) {
      Swing.hit || Swing.crit => '$name hits you for ${r.taken}',
      Swing.miss => '$name misses',
      Swing.dodge => 'You dodge',
      Swing.block => 'You block: ${r.taken} damage',
      null => null,
    };
    final quick = data.enemies[enemyId]?.has(Trait.quick) ?? false;
    final lines = [
      ...quick ? [?theirs, ?mine] : [?mine, ?theirs],
      if (r.outcome == FightOutcome.won) '$name is beaten',
      if (r.outcome == FightOutcome.lost) 'You are beaten',
    ];
    if (lines.isEmpty) return ['Round ${r.round}'];
    return ['Round ${r.round}: ${lines.first}', ...lines.skip(1)];
  }

  /// The fight log, newest round first, with [newFight] between fights
  /// (playtest 3): a fight ends on a round with an outcome, or the next
  /// round's number starts over.
  List<String> fightLog(List<RoundLog> log, String enemyId) => [
    for (var i = log.length - 1; i >= 0; i--) ...[
      ...roundLines(log[i], enemyId),
      if (i > 0 &&
          (log[i - 1].outcome != null || log[i].round <= log[i - 1].round))
        newFight,
    ],
  ];

  /// "+4 Defense", "+14 HP", "+25% Block": the stats a piece of gear adds.
  List<String> bonus(Stats b) => [
    if (b.attack != 0) '+${b.attack} Attack',
    if (b.defense != 0) '+${b.defense} Defense',
    if (b.hp != 0) '+${b.hp} HP',
    if (b.block != 0) '+${b.block}% Block',
    if (b.dodge != 0) '+${b.dodge}% Dodge',
    if (b.crit != 0) '+${b.crit}% Crit',
    if (b.hit != 0) '+${b.hit}% Hit',
  ];

  /// One bonus stat roll: "+3% Crit", "+12 Health" (spec 0009 §8.2).
  String bonusRoll(BonusRoll r) => switch (r.stat) {
    'hp' => '+${r.value} Health',
    final stat => '+${r.value}% ${stat[0].toUpperCase()}${stat.substring(1)}',
  };

  /// A change in stats, signed: "+2 Attack · −10 HP"; "No change" if none.
  String delta(Stats d) {
    String part(int v, String name) => '${v > 0 ? '+' : '−'}${v.abs()} $name';
    String pct(int v, String name) => '${v > 0 ? '+' : '−'}${v.abs()}% $name';
    final parts = [
      if (d.attack != 0) part(d.attack, 'Attack'),
      if (d.defense != 0) part(d.defense, 'Defense'),
      if (d.hp != 0) part(d.hp, 'HP'),
      if (d.block != 0) pct(d.block, 'Block'),
      if (d.dodge != 0) pct(d.dodge, 'Dodge'),
      if (d.crit != 0) pct(d.crit, 'Crit'),
      if (d.hit != 0) pct(d.hit, 'Hit'),
    ];
    return parts.isEmpty ? 'No change' : parts.join(' · ');
  }

  /// A weapon's damage type and hands, "Pierce · One hand", or an armour
  /// piece's type and slot, "Light armour · Chest"; null otherwise (spec
  /// 0009 §8.2).
  String? typeLine(String key) {
    if (weaponLine(key) case final weapon?) return weapon;
    final item = data.itemOf(key);
    if (item?.armourType case final type?) {
      return '${armour(type)} · ${slot(item!.slot!)}';
    }
    return null;
  }

  /// A weapon's damage type and hands, "Pierce · One hand"; null for
  /// anything else (spec 0009 §8.2).
  String? weaponLine(String key) {
    final item = data.itemOf(key);
    if (item?.damageType case final type?) {
      return '${capital(type)} · ${item!.twoHanded ? 'Two hands' : 'One hand'}';
    }
    return null;
  }

  /// `heavy` -> "Heavy armour".
  String armour(String type) => '${capital(type)} armour';

  String capital(String word) => word[0].toUpperCase() + word.substring(1);

  /// A monster twist in words: "Quick: strikes first" (spec 0009 §7.1).
  String trait(Trait t) => switch (t) {
    Trait.quick => 'Quick: strikes first',
    Trait.slow => 'Slow: strikes every second round',
    Trait.ghostly => 'Ghostly: ignores your defence',
    Trait.regenerates => 'Regenerates: heals every round',
  };

  /// The bestiary and lore news of a report (spec 0009 §7).
  String loreFound(String note) =>
      'Found a lore note: ${data.loreNotes.where((n) => n.id == note).firstOrNull?.title ?? note}';
  String weaknessLearned(String id) =>
      '${enemy(id)}: weakness learned, see the Bestiary in the Journal';
  String slayerEarned(String id) => 'Slayer: ${enemy(id)}';

  /// How working [node] reads: "Mining" / "Mined" / "mine", and so on for
  /// chopping, fishing and hunting.
  (String, String, String) _verbs(String node) =>
      switch (data.nodes[node]?.profession) {
        'woodcutting' => ('Chopping', 'Chopped', 'chop'),
        'fishing' => ('Fishing', 'Fished', 'fish'),
        'hunting' => ('Hunting', 'Hunted', 'hunt'),
        _ => ('Mining', 'Mined', 'mine'),
      };

  /// A spot as a sentence names it: "the Iron vein", or a water or trail
  /// with its area, "Under the bridge (Troll Bridge)".
  String _spot(String node) => (data.nodes[node]?.catches.isEmpty ?? true)
      ? 'the ${this.node(node)}'
      : '${this.node(node)} (${homeOf(node)})';

  /// Whether [recipe] is a meal, cooked at the camp fire (spec 0011 §5.1).
  bool _cooks(String recipe) => data.recipes[recipe]?.profession == 'cooking';

  String profession(String id) => data.professions[id]?.name ?? id;

  /// A profession level reached, with what it opens (spec 0010 §2.2):
  /// "Mining 10: the Iron vein is yours to work", "Crafting 14: new
  /// recipes", or "Reached Mining 2!".
  String professionLevel(String id, int level) {
    final news = Game(data).professionNews(id, level);
    final name = '${profession(id)} $level';
    for (final n in news) {
      if (n.kind == NewsKind.gatheringSpot) {
        final verb = switch (data.nodes[n.id]?.profession) {
          'fishing' || 'hunting' => _verbs(n.id).$3,
          _ => 'work',
        };
        return '$name: ${_spot(n.id)} is yours to $verb';
      }
    }
    return news.isEmpty ? 'Reached $name!' : '$name: new recipes';
  }

  /// "Found a Garnet!" (spec 0010 §5.1); a trophy fish with its weight,
  /// "Caught Old Mossback, 14.2 kg!", and a rare animal's trophy, "Tracked
  /// the Golden stag: a golden antler!" (spec 0011 §3.2, §4).
  String rareFound(String item, {int? weight}) {
    if (weight != null) return 'Caught ${plain(item)}, ${kg(weight)}!';
    final animal = data.nodes.values
        .where((n) => n.rareFind == item && n.rareAnimal != null)
        .firstOrNull
        ?.rareAnimal;
    if (animal == null) return 'Found a ${plain(item)}!';
    final name = plain(item);
    // "Old Tusk's tusk" keeps its capital and takes no article.
    final what = name.contains("'s ")
        ? name
        : 'a ${name[0].toLowerCase()}${name.substring(1)}';
    return 'Tracked the $animal: $what!';
  }

  /// Tenths of a kg in words: 63 -> "6.3 kg".
  String kg(int tenths) => '${tenths ~/ 10}.${tenths % 10} kg';

  /// "New record: Pike, 6.3 kg (was 4.8)" (spec 0011 §3.4).
  String record(String item, int weight, int was) =>
      'New record: ${plain(item)}, ${kg(weight)} '
      '(was ${was ~/ 10}.${was % 10})';

  /// What a message in a bottle held (spec 0011 §6.1).
  String bottle({String? revealed, String? item}) => revealed != null
      ? 'A message in a bottle! An old sea chart, an X beside the lake: '
            '${location(revealed)}.'
      : 'Another bottle: a few grains of ${plain(item ?? '')} inside.';

  /// "A sunken chest! The Drowned Captain's ring (Rare)" (spec 0011 §6.3).
  String chest(String key) => 'A sunken chest! The ${owned(key)}';

  /// "Ate Venison skewer (auto, 4 left)" (spec 0011 §5.4).
  String mealEaten(String key, int left) =>
      'Ate ${item(key)} (auto, ${fmt(left)} left)';

  /// "Out of Venison skewer: no meal running".
  String mealsOut(String meal) => 'Out of ${item(meal)}: no meal running';

  /// A meal's buffs (spec 0011 §5.3): "+6% Attack", "+2% Crit", "6% fewer
  /// steps"; a feast's two joined, "+6% HP, +6% Attack".
  String mealBuff(String key) {
    final meal = data.itemOf(key)?.meal;
    if (meal == null) return '';
    final pct = data.mealPercent[meal.tier - 1];
    return [
      for (final b in meal.buffs)
        switch (b) {
          'hp' => '+$pct% HP',
          'attack' => '+$pct% Attack',
          'defense' => '+$pct% Defense',
          'crit' => '+${data.mealCrit[meal.tier - 1]}% Crit',
          _ => '$pct% fewer steps',
        },
    ].join(', ');
  }

  /// "+6% Attack for 3,000 steps"; a perfect dish lasts twice as long.
  String mealLength(String key) =>
      '${mealBuff(key)} for ${fmt(data.mealStepsOf(key))} steps';

  /// A reroll's end (spec 0010 §7.2-7.3): "Bone sword reroll: Rare → Epic",
  /// "Bone sword reroll: stays Rare", or a Legendary's waiting roll.
  String rerollNews(String before, String after) {
    final name = plain(before);
    if (data.pendingRoll(after) != null) {
      return '$name: new roll ready at the forge';
    }
    final (from, to) = (data.qualityOf(before), data.qualityOf(after));
    return from == to
        ? '$name reroll: stays ${from.name}'
        : '$name reroll: ${from.name} → ${to.name}';
  }

  /// What salvaging [item] gave (spec 0010 §7.1), with a shard's count
  /// toward its unique: "… Found a Shard of the Graveyard King (3 of 10)!".
  String salvaged(String item, SalvageResult r) {
    final line = 'Salvaged the ${plain(item)}: ${plain(r.dust)}.';
    final shard = r.shard;
    if (shard == null) return line;
    final need = data.recipes.values
        .where((x) => x.inputs.containsKey(shard))
        .firstOrNull
        ?.inputs[shard];
    final count = need == null
        ? ''
        : ' (${r.state.inventory[shard] ?? 0} of $need)';
    return '$line Found a ${plain(shard)}$count!';
  }

  /// A tool's profession and step saving: "Mining tool · −14% steps" (spec
  /// 0010 §3.2, amendment 7).
  String toolLine(String key) {
    final p = data.toolProfession(key);
    return '${profession(p!)} tool · ${stepSaving(key)}';
  }

  /// The saving of the tool with [key]: "Full step cost" with none, else
  /// "−10% steps" (spec 0010 amendment 7). A tool that costs more steps
  /// says so: "+10% steps".
  String stepSaving(String? key) {
    final saving = 100 - _stepShare(key);
    return switch (saving) {
      0 => 'Full step cost',
      > 0 => '−$saving% steps',
      _ => '+${-saving}% steps',
    };
  }

  /// The share of an action's steps the tool with [key] costs, in percent.
  int _stepShare(String? key) => (Game(data).toolFactor(key) * 100).round();

  /// An item drawn as an object (bag, doll, card title): its name only, the
  /// quality shows as colour and on the card's kind line (spec 0008
  /// decision 10).
  /// A perfect dish says so (spec 0011 §5.3).
  String plain(String key) =>
      data.isPerfect(key) ? item(key) : data.itemOf(key)?.name ?? key;

  /// The card's kind line: "Rare one-hand weapon · Main hand", "Material".
  String kind(String key) {
    final item = data.itemOf(key);
    final slot = item?.slot;
    if (item?.tool case final tool?) {
      final p = data.professions[tool.profession]!;
      return '${data.qualityOf(key).name} ${p.toolName.toLowerCase()} · '
          '${p.name}';
    }
    if (item?.meal != null) {
      return data.isPerfect(key) ? 'Perfect meal' : 'Meal';
    }
    if (item == null || slot == null) return 'Material';
    final word = switch (slot) {
      'mainHand' => item.twoHanded ? 'two-hand weapon' : 'one-hand weapon',
      'offHand' => 'off-hand item',
      'head' => 'helm',
      'neck' => 'amulet',
      'chest' => 'chest armour',
      'legs' => 'leggings',
      _ => this.slot(slot).toLowerCase(),
    };
    return '${data.qualityOf(key).name} $word · ${this.slot(slot)}';
  }

  String recipe(String id) => item(data.recipes[id]?.output ?? id);
  String achievement(String id) => data.achievements[id]?.name ?? id;

  /// What [r] gives: "+250 step bank cap", "Iron shield (Uncommon)",
  /// "+4 Attack", "+1 queue slot" (spec 0017 §6).
  String reward(Reward r) => switch (r) {
    BankCapReward(:final amount) => '+${fmt(amount)} step bank cap',
    ItemReward(:final item, :final quality) => this.item(
      data.keyFor(item, quality),
    ),
    BonusReward(:final bonus) => this.bonus(bonus).join(', '),
    QueueSlotReward() => '+1 queue slot',
  };

  /// The banner of an earned achievement names its reward (spec 0017 §6).
  String achievementUnlocked(String id) {
    final a = data.achievements[id];
    final name = 'Achievement unlocked: ${achievement(id)}';
    return a == null ? name : '$name. Reward: ${reward(a.reward)}';
  }

  /// A lost achievement and what the player lost with it (spec 0017 §5).
  String achievementLost(AchievementLost e) {
    final a = data.achievements[e.id];
    final name = 'Achievement lost: ${achievement(e.id)}';
    if (a == null) return '$name.';
    final lost = switch (a.reward) {
      BankCapReward() when e.bankSteps > 0 =>
        '${reward(a.reward)} and ${plural(e.bankSteps, 'step')} from your '
            'step bank',
      ItemReward() when e.item == null =>
        'nothing more, the ${reward(a.reward)} was gone already',
      QueueSlotReward() when e.actions > 0 =>
        '${reward(a.reward)} and ${plural(e.actions, 'waiting action')}',
      final r => reward(r),
    };
    return '$name. Lost: $lost.';
  }

  String activity(Activity a) => switch (a.kind) {
    ActivityKind.travel => 'Walking to ${location(a.target)}',
    ActivityKind.fight => 'Fighting ${enemy(a.target)}s',
    ActivityKind.gather => '${_verbs(a.target).$1} ${node(a.target)}',
    ActivityKind.craft =>
      '${_cooks(a.target) ? 'Cooking' : 'Crafting'} ${recipe(a.target)}',
    ActivityKind.reroll => 'Rerolling ${rerolled(a)}',
  };

  /// The item a reroll works on (spec 0010 §7.2).
  String rerolled(Activity a) => data.itemOf(a.rerollKey)?.name ?? a.rerollKey;

  /// Why an action ended, as a sentence without the full stop.
  String endReason(Activity a, EndReason r) => switch (r) {
    EndReason.arrived => 'Arrived at ${location(a.target)}',
    EndReason.defeated => 'Gave up after 3 losses in a row',
    EndReason.grey => 'Stopped: the ${enemy(a.target)} turned grey',
    EndReason.enough => 'Stopped: goal reached',
    EndReason.noMaterials => 'Stopped: out of materials',
    EndReason.noRoute => 'Stopped: the way on is in the fog',
  };

  /// A stop condition, with progress toward it (spec 0003 §3).
  String stop(
    StopCondition c,
    Activity a, {
    required int owned,
    int crafted = 0,
  }) => switch (c.kind) {
    StopKind.untilGrey => 'Until it turns grey',
    StopKind.untilHave =>
      'Until you have ${fmt(c.count)} ${item(c.item!)} '
          '(${fmt(owned)} / ${fmt(c.count)})',
    StopKind.untilCrafted =>
      'Until ${fmt(c.count)} crafted (${fmt(crafted)} / ${fmt(c.count)})',
    StopKind.untilQuality => 'Until ${qualityName(c.item!)} or better',
    StopKind.never => switch (a.kind) {
      ActivityKind.travel => 'Until you arrive',
      ActivityKind.craft => 'Until materials run out',
      _ => 'Keeps going',
    },
  };

  /// Why a queued action never started. [missing]: what a craft lacked.
  String skipReason(
    Activity a,
    SkipReason r, {
    Map<String, int> missing = const {},
  }) => switch (r) {
    SkipReason.locked => 'not unlocked yet',
    SkipReason.noRoute => 'no open route there',
    SkipReason.notThere => 'you were not there',
    SkipReason.noMaterials when missing.isNotEmpty =>
      'not enough ${missing.entries.map((e) => '${item(e.key)} (needs ${fmt(e.value)} more)').join(', ')}',
    SkipReason.noMaterials => 'not enough materials',
    SkipReason.alreadyDone => switch (a.kind) {
      ActivityKind.travel => 'you were already there',
      ActivityKind.fight => 'it was already grey or the goal was reached',
      _ => 'the goal was already reached',
    },
  };

  /// "Skipped the Bone shield: not enough Bones (needs 2 more)." An action
  /// at the wrong place: "Copper vein: you are not at Copper Hills." (spec
  /// 0016 §3.5).
  String skipLine(Activity a, SkipReason r, Map<String, int> missing) {
    if (r != SkipReason.notThere) {
      return 'Skipped the ${short(a)}: ${skipReason(a, r, missing: missing)}.';
    }
    final name = short(a);
    final where = switch (a.kind) {
      ActivityKind.fight || ActivityKind.gather => homeOf(a.target),
      ActivityKind.craft when _cooks(a.target) => 'a fire',
      ActivityKind.craft || ActivityKind.reroll => 'a forge',
      ActivityKind.travel => location(a.target),
    };
    return '${name[0].toUpperCase()}${name.substring(1)}: '
        'you are not at $where.';
  }

  /// A short name for an action: "Skeleton", "Copper vein", "Bone sword".
  String short(Activity a) => switch (a.kind) {
    ActivityKind.travel => 'walk to ${location(a.target)}',
    ActivityKind.fight => enemy(a.target),
    ActivityKind.gather => node(a.target),
    ActivityKind.craft => recipe(a.target),
    ActivityKind.reroll => 'reroll of the ${rerolled(a)}',
  };

  /// The report lines for one action (spec 0003 §7), ending with the action
  /// that started after it.
  List<String> actionLines(ActionLog log) {
    final a = log.activity;
    if (log.skipped case final why?) {
      return [skipLine(a, why, log.missing)];
    }
    final gains = [
      if (log.wins > 0) plural(log.wins, 'win'),
      if (log.xp > 0) '+${fmt(log.xp)} XP',
      if (log.items.isNotEmpty) counts(log.items, owned),
    ];
    final ended = log.ended;
    final then = log.next != null ? ' Next: ${short(log.next!)}.' : '';
    final lines = <String>[
      if (a.kind != ActivityKind.travel)
        '${switch (a.kind) {
              ActivityKind.fight => 'Fought the ${enemy(a.target)}',
              ActivityKind.gather => '${_verbs(a.target).$2} ${_spot(a.target)}',
              ActivityKind.reroll => 'Rerolled the ${rerolled(a)}',
              _ => '${_cooks(a.target) ? 'Cooked' : 'Crafted'} the ${recipe(a.target)}',
            }}${gains.isEmpty ? '' : ': ${gains.join(', ')}'}.'
            '${ended == null ? '' : ' ${endReason(a, ended)}.'}$then'
      else if (ended == EndReason.arrived && log.walkSteps > 0)
        'Walked to ${location(a.target)} (${fmt(log.walkSteps)} steps).$then'
      else if (ended == EndReason.arrived)
        'Arrived at ${location(a.target)}.$then',
      for (final l in log.losses.take(3))
        'Lost to the ${enemy(l.enemy)} (knocked off '
            '${(l.share * 100).round()}% of its health), +${fmt(l.xp)} XP.',
      if (log.losses.length > 3)
        '…and ${log.losses.length - 3} more '
            '${log.losses.length == 4 ? 'loss' : 'losses'}.',
      for (final enemy in {for (final l in log.losses) l.enemy})
        ?data.enemies[enemy]?.lossHint,
    ];
    return lines;
  }

  String counts(Map<String, int> m, String Function(String) name) =>
      m.entries.map((e) => '${name(e.key)} ×${e.value}').join(', ');

  /// Where [enemy] or [node] lives.
  String homeOf(String id) => location(
    data.locations.values
        .firstWhere((l) => l.enemies.contains(id) || l.nodes.contains(id))
        .id,
  );

  /// A slot id or kind in words: `mainHand` → "Main hand", `ring1` → "Ring".
  String slot(String id) {
    final words = id
        .replaceAll(RegExp(r'\d+$'), '')
        .replaceAllMapped(RegExp('[A-Z]'), (m) => ' ${m[0]!.toLowerCase()}');
    return words[0].toUpperCase() + words.substring(1);
  }

  /// One "What's new" line of a level-up card (spec 0002 §9.1).
  String news(LevelNews n) => switch (n.kind) {
    NewsKind.rank => fill(data.ranks.firstWhere((r) => r.name == n.id).line),
    NewsKind.gatheringSpot => 'You can now ${_verbs(n.id).$3} ${_spot(n.id)}',
    NewsKind.recipe => 'New recipe: ${recipe(n.id)}',
    NewsKind.talentPoint =>
      '+1 talent point. Talents arrive in a later update; your points wait '
          'for you.',
    NewsKind.yourLevel => 'The ${enemy(n.id)} is now your level',
    NewsKind.turnedGrey =>
      'The ${enemy(n.id)} turned grey: little XP, but it still drops its loot',
  };

  /// The "Next goal" line (spec 0002 §9.3). [grey] marks a grey source;
  /// [yourLevel] a fight goal whose monster is exactly the player's level.
  String goal(
    Goal g, {
    required bool canCraftHere,
    bool grey = false,
    bool yourLevel = false,
  }) => switch (g) {
    EquipGoal(:final item) => 'Equip the ${owned(item)} (Character tab).',
    CraftGoal(:final recipe) when _cooks(recipe) =>
      'Cook the ${this.recipe(recipe)} at the camp fire.',
    CraftGoal(:final recipe) =>
      'Craft the ${this.recipe(recipe)}'
          '${canCraftHere ? ' here' : ' at Camp or an outpost'}.',
    CollectGoal(:final item, :final count, :final source) =>
      switch (source.kind) {
            ActivityKind.gather =>
              '${capital(_verbs(source.target).$3)} ${fmt(count)} more ${this.item(item)} at '
                  '${homeOf(source.target)}.',
            _ =>
              'Get ${fmt(count)} more ${this.item(item)} from the '
                  '${enemy(source.target)} in ${homeOf(source.target)}.',
          } +
          (grey ? ' Grey monsters still drop their loot.' : ''),
    ProfessionGoal(:final profession, :final level, :final current) =>
      'Reach ${this.profession(profession)} $level to '
          '${switch (g.target) {
            Activity(kind: ActivityKind.craft, :final target) => '${_cooks(target) ? 'cook' : 'craft'} the ${recipe(target)}',
            Activity(:final target) => '${_verbs(target).$3} ${_spot(target)}',
          }} (${level - current} to go).',
    FightGoal(:final enemy) =>
      'The ${this.enemy(enemy)} in ${homeOf(enemy)} '
          '${yourLevel ? 'is your level' : 'gives the most XP for your steps'}.',
  };
}
