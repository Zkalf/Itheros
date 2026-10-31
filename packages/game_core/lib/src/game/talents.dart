part of '../game.dart';

/// Which quality roll a talent boosts (spec 0015 §2.2).
enum QualityRoll { drop, craft, reroll }

/// Talent trees: points, ranks, effects and the reset (spec 0015).
extension GameTalents on Game {
  /// Points earned by level and not yet spent (spec 0015 §2.1).
  int talentPointsLeft(GameState s) =>
      talentPoints(level(s)) - s.talents.values.fold(0, (a, b) => a + b);

  /// Ranks taken in [tree].
  int ranksIn(GameState s, String tree) => [
    for (final MapEntry(:key, :value) in s.talents.entries)
      if (data.talents[key]?.tree == tree) value,
  ].fold(0, (a, b) => a + b);

  /// Ranks [tree] needs before [row] opens.
  int rowOpensAt(int row) => data.talentRowEvery * (row - 1);

  /// Why the player cannot take a rank of [talent] now, in the words of
  /// spec 0015 §3.1, or null when they can.
  String? whyNotRank(GameState s, String talent) {
    final t = data.talents[talent]!;
    final taken = s.talents[talent] ?? 0;
    if (taken >= t.ranks) return 'All ranks taken';
    if (ranksIn(s, t.tree) < rowOpensAt(t.row)) {
      return 'Opens at ${rowOpensAt(t.row)} points in '
          '${data.talentTrees[t.tree]!.name}';
    }
    if (t.needs case final n?) {
      final need = data.talents[n]!;
      if ((s.talents[n] ?? 0) < need.ranks) {
        return 'Needs ${need.name} ${need.ranks}/${need.ranks}';
      }
    }
    if (talentPointsLeft(s) <= 0) return 'No points left';
    return null;
  }

  /// Takes one rank of [talent]: instant, anywhere, 1 point. Throws
  /// [ActivityError] with the reason when it can't.
  GameState takeRank(GameState s, String talent) {
    if (whyNotRank(s, talent) case final why?) throw ActivityError(why);
    final n = s.copy();
    n.talents[talent] = (n.talents[talent] ?? 0) + 1;
    return n;
  }

  /// Rank × value, summed over the talents with [effect].
  double talentSum(GameState s, TalentEffect effect) {
    var sum = 0.0;
    for (final MapEntry(:key, :value) in s.talents.entries) {
      final t = data.talents[key];
      if (t != null && t.effect == effect) sum += t.value * value;
    }
    return sum;
  }

  /// The share of steps the talents with [effect] leave: each talent takes
  /// its own share off, and the shares multiply (spec 0015 §2.4: Light
  /// pack and Wayfarer leave 0.8 × 0.5).
  double _stepShare(GameState s, TalentEffect effect) {
    var share = 1.0;
    for (final MapEntry(:key, :value) in s.talents.entries) {
      final t = data.talents[key];
      if (t != null && t.effect == effect) share *= 1 - t.value * value;
    }
    return share;
  }

  /// The factor on the Uncommon-or-better chances of [roll] (spec 0015
  /// §2.2). A reroll multiplies the craft and reroll talents.
  double qualityBoost(GameState s, QualityRoll roll) {
    double f(TalentEffect e) => 1 + talentSum(s, e);
    return switch (roll) {
      QualityRoll.drop => f(TalentEffect.dropQuality),
      QualityRoll.craft => f(TalentEffect.craftQuality),
      QualityRoll.reroll =>
        f(TalentEffect.craftQuality) * f(TalentEffect.rerollQuality),
    };
  }

  /// What the talents add to the stats from level and gear [gear] (spec
  /// 0015 §2.2): percents rounded down, points as they are.
  Stats talentBonus(GameState s, Stats gear) {
    int pct(int v, TalentEffect e) => (v * talentSum(s, e) + 1e-9).floor();
    return Stats(
      hp: pct(gear.hp, TalentEffect.hpPercent),
      attack: pct(gear.attack, TalentEffect.attackPercent),
      defense: pct(gear.defense, TalentEffect.defensePercent),
      crit: talentSum(s, TalentEffect.crit).round(),
      hit: talentSum(s, TalentEffect.hit).round(),
      dodge: talentSum(s, TalentEffect.dodge).round(),
    );
  }

  /// The player's critical damage (spec 0015 §2.3, Impale). Monsters keep
  /// [CombatRules.critDamage].
  double critDamage(GameState s) =>
      data.combat.critDamage + talentSum(s, TalentEffect.critDamage);

  /// Steps a road of [steps] costs, rounded up (spec 0015 §2.4).
  int travelCost(GameState s, int steps) =>
      (steps * _stepShare(s, TalentEffect.travelSteps) - 1e-9).ceil();

  /// The share of gathering and crafting steps Nimble hands leaves.
  double professionStepShare(GameState s) =>
      _stepShare(s, TalentEffect.professionSteps);

  /// Steps a fight of [rounds] gives back to its action (spec 0015 §2.3,
  /// Swift strikes), rounded down.
  int fightStepsBack(GameState s, int rounds) =>
      (rounds * data.combatRoundSteps * talentSum(s, TalentEffect.fightSteps) +
              1e-9)
          .floor();

  /// Whether a fight against [enemy] shows the deadly-fight warning: red
  /// and skull, and orange with Wary (spec 0015 §2.4).
  bool deadlyWarning(GameState s, String enemy) =>
      switch (enemyBand(s, enemy).colour) {
        LevelColour.red || LevelColour.skull => true,
        LevelColour.orange => talentSum(s, TalentEffect.lossXpShare) > 0,
        _ => false,
      };

  /// The price of the next reset now, in steps from the bank: free the
  /// first time, then the saved price less what walking took off (spec
  /// 0015 §2.6).
  int resetPriceNow(GameState s) {
    if (s.talentResets == 0) return 0;
    final r = data.talentReset;
    final off = r.step * (s.walkedSinceReset ~/ r.cooldownSteps);
    return math.max(r.base, s.resetPrice - off);
  }

  /// Resets both trees at the trainer: every point comes back. Throws
  /// [ActivityError] away from the trainer, with no ranks, or with too few
  /// steps in the bank.
  GameState resetTalents(GameState s) {
    final trainer = data.trainer;
    if (s.location != trainer.location) {
      throw ActivityError(
        '${trainer.name} is in ${data.locations[trainer.location]?.name}',
      );
    }
    if (s.talents.values.every((r) => r == 0)) {
      throw ActivityError('No talents to forget');
    }
    final price = resetPriceNow(s);
    if (s.bank < price) {
      throw ActivityError('You need ${_grouped(price)} steps in the bank.');
    }
    final n = s.copy()
      ..talents.clear()
      ..bank = s.bank - price
      ..walkedSinceReset = 0
      ..talentResets = s.talentResets + 1;
    if (price > 0) {
      n.resetPrice = math.min(
        data.talentReset.cap,
        price + data.talentReset.step,
      );
    }
    return n;
  }

  /// Ranks of talents the data no longer holds go, and their points come
  /// back (spec 0015 §4).
  GameState _migrateTalents(GameState s) {
    s.talents.removeWhere((id, _) => !data.talents.containsKey(id));
    return s;
  }
}

/// [n] with a comma between thousands: 4000 → "4,000".
String _grouped(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
