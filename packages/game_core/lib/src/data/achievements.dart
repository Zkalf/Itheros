part of '../data.dart';

/// A title the player earns at [level], with its ceremony line
/// (spec 0002 decision 10).
class RankDef {
  RankDef._(Map<String, Object?> j)
    : level = _int(j, 'level'),
      name = _str(j, 'name'),
      line = _str(j, 'line');

  final int level;
  final String name;
  final String line;
}

/// A milestone comes on the way; a feat costs a grind (spec 0017 §1).
enum AchievementKind { milestone, feat }

/// The part of the game an achievement belongs to (spec 0017 §2).
enum AchievementStage { early, mid, late }

/// What an achievement asks for (spec 0017 §3.1).
sealed class Criterion {
  const Criterion();

  factory Criterion._(Map<String, Object?> j) => switch (j) {
    {'counter': final String c} => CounterCriterion(c, _int(j, 'atLeast')),
    {'profession': final String p} => ProfessionCriterion(p, _int(j, 'level')),
    {'professions': final List<Object?> list} => EachProfessionCriterion(
      list.cast<String>(),
      _int(j, 'level'),
    ),
    {'level': final int level} => LevelCriterion(level),
    {'quality': final String q} => QualityCriterion(q),
    _ => throw FormatException('Invalid game data: unknown criterion $j'),
  };
}

/// A [GameState.counters] entry, such as `kills.goblin`, at [atLeast].
final class CounterCriterion extends Criterion {
  const CounterCriterion(this.counter, this.atLeast);
  final String counter;
  final int atLeast;

  @override
  bool operator ==(Object other) =>
      other is CounterCriterion &&
      other.counter == counter &&
      other.atLeast == atLeast;

  @override
  int get hashCode => Object.hash(counter, atLeast);

  @override
  String toString() => 'CounterCriterion($counter, $atLeast)';
}

/// The level of the character.
final class LevelCriterion extends Criterion {
  const LevelCriterion(this.level);
  final int level;

  @override
  bool operator ==(Object other) =>
      other is LevelCriterion && other.level == level;

  @override
  int get hashCode => level.hashCode;

  @override
  String toString() => 'LevelCriterion($level)';
}

/// The level of [profession].
final class ProfessionCriterion extends Criterion {
  const ProfessionCriterion(this.profession, this.level);
  final String profession;
  final int level;

  @override
  bool operator ==(Object other) =>
      other is ProfessionCriterion &&
      other.profession == profession &&
      other.level == level;

  @override
  int get hashCode => Object.hash(profession, level);

  @override
  String toString() => 'ProfessionCriterion($profession, $level)';
}

/// Each of [professions] at [level] (spec 0017 amendment 1).
final class EachProfessionCriterion extends Criterion {
  const EachProfessionCriterion(this.professions, this.level);
  final List<String> professions;
  final int level;

  @override
  bool operator ==(Object other) =>
      other is EachProfessionCriterion &&
      other.level == level &&
      other.professions.length == professions.length &&
      [
        for (var i = 0; i < professions.length; i++)
          other.professions[i] == professions[i],
      ].every((same) => same);

  @override
  int get hashCode => Object.hash(Object.hashAll(professions), level);

  @override
  String toString() => 'EachProfessionCriterion($professions, $level)';
}

/// An item of [quality] (a quality id) or better found (spec 0017 §3.2).
final class QualityCriterion extends Criterion {
  const QualityCriterion(this.quality);
  final String quality;

  @override
  bool operator ==(Object other) =>
      other is QualityCriterion && other.quality == quality;

  @override
  int get hashCode => quality.hashCode;

  @override
  String toString() => 'QualityCriterion($quality)';
}

/// What an achievement gives (spec 0017 §3.4).
sealed class Reward {
  const Reward();

  factory Reward._(Map<String, Object?> j) => switch (j) {
    {'bankCap': final int n} => BankCapReward(n),
    {'item': final String item} => ItemReward(item, _str(j, 'quality')),
    {'queueSlot': 1} => const QueueSlotReward(),
    // A bonus names only stats, and at least one: a misspelt reward must
    // not load as a bonus of nothing.
    _
        when j.isNotEmpty &&
            j.keys.every(_statNames.contains) &&
            Stats.fromJson(j) != const Stats() =>
      BonusReward(Stats.fromJson(j)),
    _ => throw FormatException('Invalid game data: unknown reward $j'),
  };

  static const _statNames = {
    'hp',
    'attack',
    'defense',
    'crit',
    'hit',
    'dodge',
    'block',
  };
}

final class BankCapReward extends Reward {
  const BankCapReward(this.amount);
  final int amount;

  @override
  bool operator ==(Object other) =>
      other is BankCapReward && other.amount == amount;

  @override
  int get hashCode => amount.hashCode;

  @override
  String toString() => 'BankCapReward($amount)';
}

/// [item] at a fixed [quality] (a quality id), with no bonus rolls.
final class ItemReward extends Reward {
  const ItemReward(this.item, this.quality);
  final String item;
  final String quality;

  @override
  bool operator ==(Object other) =>
      other is ItemReward && other.item == item && other.quality == quality;

  @override
  int get hashCode => Object.hash(item, quality);

  @override
  String toString() => 'ItemReward($item, $quality)';
}

final class BonusReward extends Reward {
  const BonusReward(this.bonus);
  final Stats bonus;

  @override
  bool operator ==(Object other) =>
      other is BonusReward && other.bonus == bonus;

  @override
  int get hashCode => bonus.hashCode;

  @override
  String toString() => 'BonusReward($bonus)';
}

/// One more action in the queue.
final class QueueSlotReward extends Reward {
  const QueueSlotReward();

  @override
  bool operator ==(Object other) => other is QueueSlotReward;

  @override
  int get hashCode => 0;

  @override
  String toString() => 'QueueSlotReward()';
}

class AchievementDef {
  AchievementDef._(Map<String, Object?> j)
    : id = _str(j, 'id'),
      name = _str(j, 'name'),
      kind = AchievementKind.values.byName(_str(j, 'kind')),
      stage = AchievementStage.values.byName(_str(j, 'stage')),
      criterion = Criterion._(j['criterion']! as Map<String, Object?>),
      reward = Reward._(j['reward']! as Map<String, Object?>);

  final String id;
  final String name;
  final AchievementKind kind;
  final AchievementStage stage;
  final Criterion criterion;
  final Reward reward;
}
