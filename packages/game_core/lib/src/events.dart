import 'activity.dart';
import 'state.dart';

enum EndReason { arrived, defeated, noMaterials }

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

class FightLost extends GameEvent {
  const FightLost(this.enemy);
  final String enemy;
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
