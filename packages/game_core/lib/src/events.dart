import 'activity.dart';
import 'state.dart';

/// Why an action ended (spec 0003 §4). [defeated]: too many losses in a row.
/// [noRoute]: the place it happens can no longer be reached, as when an old
/// save's walk heads into the fog (spec 0008 decision 6).
enum EndReason { arrived, defeated, noMaterials, grey, enough, noRoute }

/// Why a queued action was skipped (spec 0003 §4). [notThere]: the
/// character isn't where it happens (spec 0016 §3.5).
enum SkipReason { locked, alreadyDone, noMaterials, noRoute, notThere }

/// Something that happened while steps were applied, in order. Used for the
/// "while you were away" summary.
sealed class GameEvent {
  const GameEvent();
}

class Arrived extends GameEvent {
  const Arrived(this.location);
  final String location;
}

class FightWon extends GameEvent {
  const FightWon(this.enemy, this.xp, this.drops);
  final String enemy;
  final int xp;
  final Map<String, int> drops;
}

/// A lost fight: [xp] for the [share] of the monster's health knocked off
/// (spec 0003 §5).
class FightLost extends GameEvent {
  const FightLost(this.enemy, this.xp, this.share);
  final String enemy;
  final int xp;
  final double share;
}

/// The next queued action started by itself.
class ActionStarted extends GameEvent {
  const ActionStarted(this.activity);
  final Activity activity;
}

/// A queued action couldn't start and was dropped.
class ActionSkipped extends GameEvent {
  const ActionSkipped(this.activity, this.reason, {this.missing = const {}});
  final Activity activity;
  final SkipReason reason;

  /// For a craft without materials: how many more of each input it needed.
  final Map<String, int> missing;
}

/// One item from a gathering action. A fish carries its [weight] in tenths
/// of a kg (spec 0011 §3.4).
class Gathered extends GameEvent {
  const Gathered(this.item, this.xp, {this.weight});
  final String item;
  final int xp;
  final int? weight;
}

class Crafted extends GameEvent {
  const Crafted(this.item, this.xp);
  final String item;
  final int xp;
}

class LevelUp extends GameEvent {
  const LevelUp(this.level);
  final int level;
}

/// A gathering action found its spot's rare find (spec 0010 §5.1): a
/// trophy fish carries its [weight] in tenths of a kg (spec 0011 §3.2).
class RareFound extends GameEvent {
  const RareFound(this.item, {this.weight});
  final String item;
  final int? weight;
}

/// A catch beat the record for its fish (spec 0011 §3.4); tenths of a kg.
class RecordBeaten extends GameEvent {
  const RecordBeaten(this.item, this.weight, this.was);
  final String item;
  final int weight;
  final int was;
}

/// A message in a bottle (spec 0011 §6.1): the first [revealed] an area,
/// a later one held [item].
class BottleFound extends GameEvent {
  const BottleFound({this.revealed, this.item});
  final String? revealed;
  final String? item;
}

/// A sunken chest held [key] (spec 0011 §6.3).
class ChestFound extends GameEvent {
  const ChestFound(this.key);
  final String key;
}

/// The meal [key] was eaten by auto-eat, with [left] of its kind in the
/// bag (spec 0011 §5.4).
class MealEaten extends GameEvent {
  const MealEaten(this.key, {required this.left, this.auto = true});
  final String key;
  final int left;
  final bool auto;
}

/// The running [meal] (an item id) ended with none to follow it.
class MealsOut extends GameEvent {
  const MealsOut(this.meal);
  final String meal;
}

/// A reroll ended: [before] became [after] (the same key when the quality
/// stayed; a Legendary's waiting roll, spec 0010 §7.3, is in [after]).
class Rerolled extends GameEvent {
  const Rerolled(this.before, this.after);
  final String before;
  final String after;
}

/// A profession reached [level] (spec 0010 §2.2).
class ProfessionLevelUp extends GameEvent {
  const ProfessionLevelUp(this.profession, this.level);
  final String profession;
  final int level;
}

/// A lore note was found (spec 0009 §7.2).
class LoreFound extends GameEvent {
  const LoreFound(this.note);
  final String note;
}

/// Enough kills to know [enemy]'s weakness and stats (spec 0009 §7.1).
class WeaknessLearned extends GameEvent {
  const WeaknessLearned(this.enemy);
  final String enemy;
}

/// Enough kills for the Slayer mark against [enemy] (spec 0009 §7.1).
class SlayerEarned extends GameEvent {
  const SlayerEarned(this.enemy);
  final String enemy;
}

class AchievementUnlocked extends GameEvent {
  const AchievementUnlocked(this.id);
  final String id;
}

class ActivityEnded extends GameEvent {
  const ActivityEnded(this.activity, this.reason);
  final Activity activity;
  final EndReason reason;
}

/// The result of applying walked steps.
class StepReport {
  StepReport({
    required this.state,
    required this.walked,
    required this.activitySteps,
    required this.boostUsed,
    required this.banked,
    required this.lost,
    required this.events,
  });

  final GameState state;
  final int walked;

  /// Steps paid into activities, including the bank boost.
  final int activitySteps;

  /// Banked steps spent as boost (1 per walked step while active).
  final int boostUsed;

  /// Walked steps that went into the bank.
  final int banked;

  /// Walked steps lost because the bank was full.
  final int lost;
  final List<GameEvent> events;
}
