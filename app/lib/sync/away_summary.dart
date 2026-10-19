import 'package:game_core/game_core.dart';

/// What happened while steps were applied, for the "while you were away"
/// card. Merged across days and syncs.
class AwaySummary {
  const AwaySummary({
    this.walked = 0,
    this.activitySteps = 0,
    this.boostUsed = 0,
    this.banked = 0,
    this.lost = 0,
    this.fightsWon = const {},
    this.lossesTo = const {},
    this.itemsGained = const {},
    this.levelsReached = const [],
    this.achievements = const [],
    this.activitiesEnded = const [],
  });

  factory AwaySummary.fromReports(Iterable<StepReport> reports) =>
      reports.fold(const AwaySummary(), (sum, r) => sum + AwaySummary._of(r));

  factory AwaySummary._of(StepReport r) {
    final won = <String, int>{};
    final items = <String, int>{};
    final lost = <String, int>{};
    final levels = <int>[];
    final achievements = <String>[];
    final ended = <ActivityEnded>[];
    void gain(String item, int n) => items[item] = (items[item] ?? 0) + n;
    for (final e in r.events) {
      switch (e) {
        case FightWon(:final enemy, :final drops):
          won[enemy] = (won[enemy] ?? 0) + 1;
          drops.forEach(gain);
        case FightLost(:final enemy):
          lost[enemy] = (lost[enemy] ?? 0) + 1;
        case Gathered(:final item):
          gain(item, 1);
        case Crafted(:final item):
          gain(item, 1);
        case LevelUp(:final level):
          levels.add(level);
        case AchievementUnlocked(:final id):
          achievements.add(id);
        case ActivityEnded():
          ended.add(e);
        case Arrived() || ActionStarted() || ActionSkipped():
          break;
      }
    }
    return AwaySummary(
      walked: r.walked,
      activitySteps: r.activitySteps,
      boostUsed: r.boostUsed,
      banked: r.banked,
      lost: r.lost,
      fightsWon: won,
      lossesTo: lost,
      itemsGained: items,
      levelsReached: levels,
      achievements: achievements,
      activitiesEnded: ended,
    );
  }

  final int walked;
  final int activitySteps;
  final int boostUsed;
  final int banked;
  final int lost;
  final Map<String, int> fightsWon;

  /// Fights lost, by monster (spec 0002 §9.4: each gets its hint).
  final Map<String, int> lossesTo;
  final Map<String, int> itemsGained;
  final List<int> levelsReached;
  final List<String> achievements;
  final List<ActivityEnded> activitiesEnded;

  bool get isEmpty => walked == 0;

  AwaySummary operator +(AwaySummary o) => AwaySummary(
    walked: walked + o.walked,
    activitySteps: activitySteps + o.activitySteps,
    boostUsed: boostUsed + o.boostUsed,
    banked: banked + o.banked,
    lost: lost + o.lost,
    fightsWon: _add(fightsWon, o.fightsWon),
    lossesTo: _add(lossesTo, o.lossesTo),
    itemsGained: _add(itemsGained, o.itemsGained),
    levelsReached: [...levelsReached, ...o.levelsReached],
    achievements: [...achievements, ...o.achievements],
    activitiesEnded: [...activitiesEnded, ...o.activitiesEnded],
  );

  static Map<String, int> _add(Map<String, int> a, Map<String, int> b) => {
    ...a,
    for (final e in b.entries) e.key: (a[e.key] ?? 0) + e.value,
  };
}
