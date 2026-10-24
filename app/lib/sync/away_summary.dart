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
    this.walkSteps = 0,
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

  /// The steps of the legs a walk finished (spec 0016 §7.3).
  final int walkSteps;

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
    // Journal entries before spec 0016 have none.
    walkSteps: j['walkSteps'] as int? ?? 0,
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
    if (walkSteps > 0) 'walkSteps': walkSteps,
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
    walkSteps: walkSteps,
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
    walkSteps: walkSteps + o.walkSteps,
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
    this.lore = const [],
    this.learned = const [],
    this.slayers = const [],
    this.professionLevels = const [],
    this.finds = const [],
    this.rerolls = const [],
    this.trophyFish = const [],
    this.records = const [],
    this.charts = const [],
    this.bottleItems = const [],
    this.chests = const [],
    this.mealsEaten = const [],
    this.mealsOut = const [],
    this.route = const [],
  });

  factory AwaySummary.fromReports(Iterable<StepReport> reports) =>
      reports.fold(const AwaySummary(), (sum, r) => sum + AwaySummary._of(r));

  /// Splits the events into actions: each runs until it ends, and the next
  /// one starts. The last may still be running ([StepReport.state]).
  factory AwaySummary._of(StepReport r) {
    final logs = <ActionLog>[];
    final levels = <int>[];
    final achievements = <String>[];
    final lore = <String>[], learned = <String>[], slayers = <String>[];
    final professionLevels = <(String, int)>[];
    final finds = <String>[];
    final trophyFish = <(String, int)>[];
    final rerolls = <(String, String)>[];
    final records = <(String, int, int)>[];
    final charts = <String>[], bottleItems = <String>[], chests = <String>[];
    final mealsEaten = <(String, int)>[];
    final mealsOut = <String>[];
    final route = <String>[];
    var wins = 0, xp = 0, walkSteps = 0;
    var items = <String, int>{};
    var losses = <FightLost>[];
    Activity? started;

    void close(Activity a, EndReason? ended) {
      final empty =
          wins == 0 &&
          xp == 0 &&
          items.isEmpty &&
          losses.isEmpty &&
          walkSteps == 0;
      if (empty && ended == null) return;
      logs.add(
        ActionLog(
          a,
          wins: wins,
          xp: xp,
          items: items,
          losses: losses,
          ended: ended,
          walkSteps: walkSteps,
        ),
      );
      (wins, xp, items, losses, walkSteps) = (0, 0, {}, [], 0);
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
        // Gems and heartwood join the action's items, and are news (spec
        // 0010 §5.1).
        case RareFound(:final item, :final weight?):
          gain(item, 1);
          trophyFish.add((item, weight));
        case RareFound(:final item):
          gain(item, 1);
          finds.add(item);
        case ProfessionLevelUp(:final profession, :final level):
          professionLevels.add((profession, level));
        case Rerolled(:final before, :final after):
          rerolls.add((before, after));
        case AchievementUnlocked(:final id):
          achievements.add(id);
        // Only a load loses an achievement; plan 0021 M3 reports it.
        case AchievementLost():
          break;
        case LoreFound(:final note):
          lore.add(note);
        case WeaknessLearned(:final enemy):
          learned.add(enemy);
        case SlayerEarned(:final enemy):
          slayers.add(enemy);
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
        // Each leg of a walk ends with an arrival (spec 0014 §5).
        case Arrived(:final location, :final steps):
          route.add(location);
          walkSteps += steps;
        // Spec 0011's news: records, bottles, the chest, meals.
        case RecordBeaten(:final item, :final weight, :final was):
          records.add((item, weight, was));
        case BottleFound(:final revealed?):
          charts.add(revealed);
        case BottleFound(:final item):
          if (item != null) bottleItems.add(item);
        case ChestFound(:final key):
          chests.add(key);
        case MealEaten(:final key, :final left):
          mealsEaten.add((key, left));
        case MealsOut(:final meal):
          mealsOut.add(meal);
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
      lore: lore,
      learned: learned,
      slayers: slayers,
      professionLevels: professionLevels,
      finds: finds,
      rerolls: rerolls,
      trophyFish: trophyFish,
      records: records,
      charts: charts,
      bottleItems: bottleItems,
      chests: chests,
      mealsEaten: mealsEaten,
      mealsOut: mealsOut,
      route: route,
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

  /// Lore notes found, monsters whose weakness was learned, Slayer marks
  /// earned (spec 0009 §7).
  final List<String> lore;
  final List<String> learned;
  final List<String> slayers;

  /// Profession levels reached, rare finds, and rerolls as the item's key
  /// before and after (spec 0010 §2.2, §5.1, §7.2-7.3).
  final List<(String, int)> professionLevels;
  final List<String> finds;
  final List<(String, String)> rerolls;

  /// Spec 0011's news: trophy fish caught (fish, weight in tenths of a kg),
  /// records beaten (fish, weight, was), areas a sea chart
  /// revealed, what later bottles held, sunken chests' rings, meals eaten by
  /// auto-eat (key, left) and meals that ran out (§3.4, §5.4, §6).
  final List<(String, int)> trophyFish;
  final List<(String, int, int)> records;
  final List<String> charts;
  final List<String> bottleItems;
  final List<String> chests;
  final List<(String, int)> mealsEaten;
  final List<String> mealsOut;

  /// The route as place ids: the place where the player was, then each
  /// place where the player arrived (spec 0014 §5). The controller puts the
  /// start place first. A report alone holds only its arrivals.
  final List<String> route;

  bool get isEmpty => walked == 0;

  /// Something happened beyond steps going to the bank or toward an
  /// unfinished unit: worth its own screen (spec 0004 amendment 2). A route
  /// alone is not news (plan 0017, M3), nor a walk that has not arrived: it
  /// is open only to add up its steps (spec 0016 §7.3).
  bool get isEventful =>
      actions.any(
        (a) => !(a.isOpen && a.activity.kind == ActivityKind.travel),
      ) ||
      levelsReached.isNotEmpty ||
      achievements.isNotEmpty ||
      lore.isNotEmpty ||
      learned.isNotEmpty ||
      slayers.isNotEmpty ||
      professionLevels.isNotEmpty ||
      finds.isNotEmpty ||
      rerolls.isNotEmpty ||
      trophyFish.isNotEmpty ||
      records.isNotEmpty ||
      charts.isNotEmpty ||
      bottleItems.isNotEmpty ||
      chests.isNotEmpty ||
      mealsEaten.isNotEmpty ||
      mealsOut.isNotEmpty;

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
    // Entries from before spec 0009 have none.
    lore: _strings(j['lore']),
    learned: _strings(j['learned']),
    slayers: _strings(j['slayers']),
    // Entries from before spec 0010 have none.
    professionLevels: [
      for (final p in j['professionLevels'] as List<Object?>? ?? const [])
        if (p case [final String id, final int level]) (id, level),
    ],
    finds: _strings(j['finds']),
    rerolls: [
      for (final r in j['rerolls'] as List<Object?>? ?? const [])
        if (r case [final String before, final String after]) (before, after),
    ],
    // Entries from before spec 0011 have none.
    trophyFish: [
      for (final f in j['trophyFish'] as List<Object?>? ?? const [])
        if (f case [final String item, final int weight]) (item, weight),
    ],
    records: [
      for (final r in j['records'] as List<Object?>? ?? const [])
        if (r case [final String item, final int weight, final int was])
          (item, weight, was),
    ],
    charts: _strings(j['charts']),
    bottleItems: _strings(j['bottleItems']),
    chests: _strings(j['chests']),
    mealsEaten: [
      for (final m in j['mealsEaten'] as List<Object?>? ?? const [])
        if (m case [final String key, final int left]) (key, left),
    ],
    mealsOut: _strings(j['mealsOut']),
    // Entries from before spec 0014 have none, and show no route map.
    route: _strings(j['route']),
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
    'lore': lore,
    'learned': learned,
    'slayers': slayers,
    'professionLevels': [
      for (final (id, level) in professionLevels) [id, level],
    ],
    'finds': finds,
    'rerolls': [
      for (final (a, b) in rerolls) [a, b],
    ],
    'trophyFish': [
      for (final (item, weight) in trophyFish) [item, weight],
    ],
    'records': [
      for (final (item, weight, was) in records) [item, weight, was],
    ],
    'charts': charts,
    'bottleItems': bottleItems,
    'chests': chests,
    'mealsEaten': [
      for (final (key, left) in mealsEaten) [key, left],
    ],
    'mealsOut': mealsOut,
    'route': route,
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
      lore: [...lore, ...o.lore],
      learned: [...learned, ...o.learned],
      slayers: [...slayers, ...o.slayers],
      professionLevels: [...professionLevels, ...o.professionLevels],
      finds: [...finds, ...o.finds],
      rerolls: [...rerolls, ...o.rerolls],
      trophyFish: [...trophyFish, ...o.trophyFish],
      records: [...records, ...o.records],
      charts: [...charts, ...o.charts],
      bottleItems: [...bottleItems, ...o.bottleItems],
      chests: [...chests, ...o.chests],
      mealsEaten: [...mealsEaten, ...o.mealsEaten],
      mealsOut: [...mealsOut, ...o.mealsOut],
      // The place where one route ends and the next starts shows once.
      route: [
        ...route,
        ...(route.isNotEmpty && o.route.firstOrNull == route.last
            ? o.route.skip(1)
            : o.route),
      ],
    );
  }

  static Map<String, int> _add(Map<String, int> a, Map<String, int> b) => {
    ...a,
    for (final e in b.entries) e.key: (a[e.key] ?? 0) + e.value,
  };
}

List<String> _strings(Object? json) =>
    (json as List<Object?>? ?? const []).cast<String>();

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
