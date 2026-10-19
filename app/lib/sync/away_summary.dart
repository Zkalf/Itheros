import 'package:game_core/game_core.dart';

/// What one queued action did while steps were applied (spec 0003 §7).
class ActionLog {
  const ActionLog(
    this.activity, {
    this.wins = 0,
    this.xp = 0,
    this.items = const {},
    this.losses = const [],
    this.ended,
    this.skipped,
  });

  final Activity activity;
  final int wins;
  final int xp;
  final Map<String, int> items;
  final List<FightLost> losses;

  /// Why it ended, or null if it is still running.
  final EndReason? ended;

  /// Set when it never started.
  final SkipReason? skipped;

  bool get isOpen => ended == null && skipped == null;

  ActionLog operator +(ActionLog o) => ActionLog(
    activity,
    wins: wins + o.wins,
    xp: xp + o.xp,
    items: AwaySummary._add(items, o.items),
    losses: [...losses, ...o.losses],
    ended: o.ended,
    skipped: o.skipped,
  );
}

/// What happened while steps were applied, for the "while you were away"
/// card. Merged across days and syncs.
class AwaySummary {
  const AwaySummary({
    this.walked = 0,
    this.activitySteps = 0,
    this.boostUsed = 0,
    this.banked = 0,
    this.lost = 0,
    this.actions = const [],
    this.levelsReached = const [],
    this.achievements = const [],
  });

  factory AwaySummary.fromReports(Iterable<StepReport> reports) =>
      reports.fold(const AwaySummary(), (sum, r) => sum + AwaySummary._of(r));

  /// Splits the events into actions: each runs until it ends, and the next
  /// one starts. The last may still be running ([StepReport.state]).
  factory AwaySummary._of(StepReport r) {
    final logs = <ActionLog>[];
    final levels = <int>[];
    final achievements = <String>[];
    var wins = 0, xp = 0;
    var items = <String, int>{};
    var losses = <FightLost>[];
    Activity? started;

    void close(Activity a, EndReason? ended) {
      final empty = wins == 0 && xp == 0 && items.isEmpty && losses.isEmpty;
      if (empty && ended == null) return;
      logs.add(
        ActionLog(
          a,
          wins: wins,
          xp: xp,
          items: items,
          losses: losses,
          ended: ended,
        ),
      );
      (wins, xp, items, losses) = (0, 0, {}, []);
    }

    void gain(String item, int n) => items[item] = (items[item] ?? 0) + n;
    for (final e in r.events) {
      switch (e) {
        case FightWon(:final drops):
          wins++;
          xp += e.xp;
          drops.forEach(gain);
        case FightLost():
          xp += e.xp;
          losses = [...losses, e];
        case Gathered(:final item):
          xp += e.xp;
          gain(item, 1);
        case Crafted(:final item):
          xp += e.xp;
          gain(item, 1);
        case LevelUp(:final level):
          levels.add(level);
        case AchievementUnlocked(:final id):
          achievements.add(id);
        case ActivityEnded(:final activity, :final reason):
          close(activity, reason);
          started = null;
        case ActionStarted(:final activity):
          started = activity;
        case ActionSkipped(:final activity, :final reason):
          logs.add(ActionLog(activity, skipped: reason));
        case Arrived():
          break;
      }
    }
    final running = started ?? r.state.activity?.activity;
    if (running != null) close(running, null);
    return AwaySummary(
      walked: r.walked,
      activitySteps: r.activitySteps,
      boostUsed: r.boostUsed,
      banked: r.banked,
      lost: r.lost,
      actions: logs,
      levelsReached: levels,
      achievements: achievements,
    );
  }

  final int walked;
  final int activitySteps;
  final int boostUsed;
  final int banked;
  final int lost;

  /// Each action in order, with what it earned and why it ended.
  final List<ActionLog> actions;
  final List<int> levelsReached;
  final List<String> achievements;

  bool get isEmpty => walked == 0;

  AwaySummary operator +(AwaySummary o) {
    // An action still running at the end of one sync continues in the next.
    final merged = [...actions];
    final rest = [...o.actions];
    if (merged.isNotEmpty &&
        rest.isNotEmpty &&
        merged.last.isOpen &&
        merged.last.activity == rest.first.activity &&
        rest.first.skipped == null) {
      merged.last = merged.last + rest.removeAt(0);
    }
    return AwaySummary(
      walked: walked + o.walked,
      activitySteps: activitySteps + o.activitySteps,
      boostUsed: boostUsed + o.boostUsed,
      banked: banked + o.banked,
      lost: lost + o.lost,
      actions: [...merged, ...rest],
      levelsReached: [...levelsReached, ...o.levelsReached],
      achievements: [...achievements, ...o.achievements],
    );
  }

  static Map<String, int> _add(Map<String, int> a, Map<String, int> b) => {
    ...a,
    for (final e in b.entries) e.key: (a[e.key] ?? 0) + e.value,
  };
}
