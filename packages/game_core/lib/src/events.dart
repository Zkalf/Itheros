import 'activity.dart';
import 'state.dart';

/// Why an action ended (spec 0003 §4). [defeated]: too many losses in a row.
enum EndReason { arrived, defeated, noMaterials, grey, enough }

/// Why a queued action was skipped (spec 0003 §4).
enum SkipReason { locked, alreadyDone, noMaterials, noRoute }

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
  const ActionSkipped(this.activity, this.reason);
  final Activity activity;
  final SkipReason reason;
}

class Gathered extends GameEvent {
  const Gathered(this.item, this.xp);
  final String item;
  final int xp;
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
