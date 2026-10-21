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
    this.missing = const {},
    this.next,
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

  /// What a skipped craft lacked (item: how many more).
  final Map<String, int> missing;

  /// The action that started after this one ended (skipped ones aside).
  final Activity? next;

  bool get isOpen => ended == null && skipped == null;

  factory ActionLog.fromJson(Map<String, Object?> j) => ActionLog(
    Activity.fromJson(j['activity']! as Map<String, Object?>),
    wins: j['wins']! as int,
    xp: j['xp']! as int,
    items: _ints(j['items']),
    losses: [
      for (final l in j['losses']! as List<Object?>)
        if (l case {
          'enemy': final String enemy,
          'xp': final int xp,
          'share': final num share,
        })
          FightLost(enemy, xp, share.toDouble()),
    ],
    ended: switch (j['ended']) {
      final String n => EndReason.values.asNameMap()[n],
      _ => null,
    },
    skipped: switch (j['skipped']) {
      final String n => SkipReason.values.asNameMap()[n],
      _ => null,
    },
    missing: _ints(j['missing']),
    next: switch (j['next']) {
      final Map<String, Object?> a => Activity.fromJson(a),
      _ => null,
    },
  );

  Map<String, Object?> toJson() => {
    'activity': activity.toJson(),
    'wins': wins,
    'xp': xp,
    'items': items,
    'losses': [
      for (final l in losses) {'enemy': l.enemy, 'xp': l.xp, 'share': l.share},
    ],
    'ended': ended?.name,
    'skipped': skipped?.name,
    'missing': missing,
    'next': next?.toJson(),
  };

  ActionLog withNext(Activity a) => ActionLog(
    activity,
    wins: wins,
    xp: xp,
    items: items,
    losses: losses,
    ended: ended,
    skipped: skipped,
    missing: missing,
    next: a,
  );

  ActionLog operator +(ActionLog o) => ActionLog(
    activity,
    wins: wins + o.wins,
    xp: xp + o.xp,
    items: AwaySummary._add(items, o.items),
    losses: [...losses, ...o.losses],
    ended: o.ended,
    skipped: o.skipped,
    missing: o.missing,
    next: o.next,
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

    // Counted by item and quality: report rows show no bonus stats (spec
    // 0009 §8.2).
    void gain(String key, int n) {
      final item = key.split(GameData.bonusMark).first;
      items[item] = (items[item] ?? 0) + n;
    }

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
          // Tell the last action that ended what came after it.
          final i = logs.lastIndexWhere((l) => l.ended != null);
          if (i >= 0 && logs[i].next == null) {
            logs[i] = logs[i].withNext(activity);
          }
        case ActionSkipped(:final activity, :final reason, :final missing):
          logs.add(ActionLog(activity, skipped: reason, missing: missing));
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

  /// Something happened beyond steps going to the bank or toward an
  /// unfinished unit: worth its own screen (spec 0004 amendment 2).
  bool get isEventful =>
      actions.isNotEmpty || levelsReached.isNotEmpty || achievements.isNotEmpty;

  factory AwaySummary.fromJson(Map<String, Object?> j) => AwaySummary(
    walked: j['walked']! as int,
    activitySteps: j['activitySteps']! as int,
    boostUsed: j['boostUsed']! as int,
    banked: j['banked']! as int,
    lost: j['lost']! as int,
    actions: [
      for (final a in j['actions']! as List<Object?>)
        ActionLog.fromJson(a! as Map<String, Object?>),
    ],
    levelsReached: (j['levelsReached']! as List<Object?>).cast<int>(),
    achievements: (j['achievements']! as List<Object?>).cast<String>(),
  );

  Map<String, Object?> toJson() => {
    'walked': walked,
    'activitySteps': activitySteps,
    'boostUsed': boostUsed,
    'banked': banked,
    'lost': lost,
    'actions': [for (final a in actions) a.toJson()],
    'levelsReached': levelsReached,
    'achievements': achievements,
  };

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

Map<String, int> _ints(Object? json) =>
    (json as Map<String, Object?>? ?? const {}).map(
      (k, v) => MapEntry(k, v! as int),
    );

/// One report kept in the journal (spec 0004 §2): when it started, and
/// whether it was a test walk.
class JournalEntry {
  const JournalEntry({
    required this.started,
    required this.summary,
    this.testWalk = false,
  });

  factory JournalEntry.fromJson(Map<String, Object?> j) => JournalEntry(
    started: DateTime.parse(j['started']! as String),
    summary: AwaySummary.fromJson(j['summary']! as Map<String, Object?>),
    testWalk: j['testWalk'] as bool? ?? false,
  );

  final DateTime started;
  final AwaySummary summary;
  final bool testWalk;

  JournalEntry withSummary(AwaySummary s) =>
      JournalEntry(started: started, summary: s, testWalk: testWalk);

  Map<String, Object?> toJson() => {
    'started': started.toIso8601String(),
    'summary': summary.toJson(),
    'testWalk': testWalk,
  };
}
