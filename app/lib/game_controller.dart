import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:game_core/game_core.dart';

import 'persistence/save_data.dart';
import 'persistence/save_store.dart';
import 'steps/step_source.dart';
import 'sync/away_summary.dart';
import 'sync/day_key.dart';
import 'sync/sync_service.dart';

enum ControllerStatus { loading, unavailable, needsPermission, ready }

/// Owns the save. Syncs steps on start, on resume and on a timer while in the
/// foreground, and applies player actions. All changes run one at a time, and
/// every action syncs first so steps walked before it are credited to the
/// previous activity (or the bank), not the new one.
class GameController extends ChangeNotifier {
  GameController({
    required this.game,
    required StepSource source,
    required this.permissions,
    required this.store,
    DateTime Function()? clock,
    this.syncInterval = const Duration(seconds: 30),
    this.awayGrace = const Duration(minutes: 2),
    int Function()? newSeed,
    this.testWalkAllowed = true,
  }) : _clock = clock ?? DateTime.now,
       _sync = SyncService(game: game, source: source, clock: clock),
       _newSeed = newSeed ?? (() => Random.secure().nextInt(1 << 32));

  final Game game;

  /// Test walk exists in this build: owner builds only (spec 0007 §4).
  final bool testWalkAllowed;
  final StepPermissions permissions;
  final SaveStorage store;

  /// Foreground sync period; null disables the timer (tests).
  final Duration? syncInterval;

  /// After the app opens, steps that arrive within this time still belong to
  /// the "while you were away" report. Health Connect delivers steps in
  /// batches about once a minute, so some arrive just after opening.
  final Duration awayGrace;

  final DateTime Function() _clock;
  final SyncService _sync;
  final int Function() _newSeed;

  ControllerStatus status = ControllerStatus.loading;
  SaveData? _save;

  /// The "While you were away" screen's report, or null when it isn't shown
  /// (spec 0004 amendment 2).
  AwaySummary? awaySummary;

  /// A report where nothing happened but steps, for a short note instead of
  /// the screen; cleared once shown.
  AwaySummary? quietReport;

  /// What the load of the save earned and lost (spec 0017 §4, §5), for the
  /// report of the next sync.
  AwaySummary _loaded = const AwaySummary();

  /// The player closed this return's screen: late steps don't reopen it.
  bool _closed = false;

  /// Recent reports, newest first, kept in the save (spec 0004 §2).
  List<JournalEntry> get journal => _save?.journal ?? const [];

  /// The most recent report, so it can be shown again after dismissal.
  AwaySummary? get lastAwaySummary =>
      journal.isEmpty ? null : journal.first.summary;
  DateTime? _awayUntil;
  bool _freshReturn = false;

  /// Last step-sync failure, cleared by the next successful sync.
  Object? syncError;

  Timer? _timer;
  Future<void> _tail = Future.value();

  /// Health Connect only answers apps in the foreground, so the sync timer
  /// runs only while this is true (spec 0001 §2.1).
  bool _foreground = true;

  GameState get state => _save!.game;

  /// The controller's clock, for screens that show times.
  DateTime get now => _clock();

  /// Today's Health Connect total as last read; test walks don't count
  /// (spec 0006 decision 10).
  int get stepsToday => _save!.credited[dayKey(now)] ?? 0;

  Future<void> start() => _serial(() async {
    if (!await permissions.isAvailable()) {
      return _setStatus(ControllerStatus.unavailable);
    }
    if (!await permissions.hasPermission()) {
      return _setStatus(ControllerStatus.needsPermission);
    }
    await _openSave(away: true);
  });

  Future<void> requestPermission() => _serial(() async {
    if (await permissions.requestPermission()) {
      await _openSave(away: true);
    } else {
      _setStatus(ControllerStatus.needsPermission);
    }
  });

  /// App came to the foreground.
  Future<void> resume() {
    _foreground = true;
    return _serial(() async {
      if (status != ControllerStatus.ready) return;
      await _syncNow(away: true);
      _startTimer();
    });
  }

  /// App went to the background. Can arrive before [start] finishes (an app
  /// launched with the screen off), so opening the save must not restart the
  /// timer afterwards.
  void pause() {
    _foreground = false;
    _stopTimer();
  }

  Future<void> syncNow() => _serial(() async {
    if (status == ControllerStatus.ready) await _syncNow(away: false);
  });

  /// Levels reached and not yet celebrated, oldest first (spec 0002 §9.1).
  /// Shown before the away report.
  List<int> get levelCards => List.unmodifiable(_levelCards);
  final _levelCards = <int>[];

  void dismissLevelCards() {
    _levelCards.clear();
    notifyListeners();
  }

  /// The player hid "Next goal" (spec 0002 §9.3).
  bool get nextGoalHidden => _save!.nextGoalHidden;

  Future<void> setNextGoalHidden(bool hidden) =>
      _update((s) => s.copyWith(nextGoalHidden: hidden));

  /// The hidden test walk switch (spec 0004 §3).
  bool get testWalkOn => testWalkAllowed && _save!.testWalk;

  Future<void> setTestWalk(bool on) => _update((s) => s.copyWith(testWalk: on));

  /// Applies [steps] pretend steps exactly as walked ones, after a normal
  /// sync, as a journal entry of its own. Health Connect crediting is left
  /// alone, so later real syncs are unchanged (spec 0004 §3).
  Future<void> testWalk(int steps) => _serial(() async {
    await _syncNow(away: false);
    final start = state.location;
    final report = game.applySteps(state, steps);
    final summary = _from(start, AwaySummary.fromReports([report]));
    _levelCards.addAll(summary.levelsReached);
    _save = _addEntry(
      _save!.withGame(report.state),
      JournalEntry(started: _clock(), summary: summary, testWalk: true),
    );
    _closed = false;
    awaySummary = null;
    _show(summary);
    await store.save(_save!);
    notifyListeners();
  });

  /// Areas and monsters whose flavour line was shown (spec 0002 §9.5).
  Set<String> get seen => _save!.seen;

  Future<void> markSeen(Iterable<String> ids) =>
      _update((s) => s.copyWith(seen: {...s.seen, ...ids}));

  /// Earned achievements not yet looked at, as [seen] ids: they put a dot
  /// on the trophy button (spec 0006 amendment 2).
  List<String> get unseenAchievements => [
    for (final id in state.achievements)
      if (!seen.contains('achievement.$id')) 'achievement.$id',
  ];

  /// Saves a change to screen settings. Costs no steps, so no sync first.
  Future<void> _update(SaveData Function(SaveData) change) => _serial(() async {
    _save = change(_save!);
    await store.save(_save!);
    notifyListeners();
  });

  void dismissAwaySummary() {
    awaySummary = null;
    _closed = true;
    notifyListeners();
  }

  void clearQuietReport() {
    quietReport = null;
    notifyListeners();
  }

  /// The screen when something happened, otherwise the short note.
  void _show(AwaySummary report) {
    if (_closed) return;
    if (report.isEventful) {
      awaySummary = report;
      quietReport = null;
    } else if (awaySummary == null) {
      quietReport = report;
    }
  }

  void showLastAwaySummary() {
    awaySummary = lastAwaySummary;
    notifyListeners();
  }

  /// Throws [ActivityError] if the rules don't allow [a].
  Future<void> startActivity(
    Activity a, {
    StopCondition stop = const StopCondition.never(),
  }) => _act((s) => game.startActivity(s, a, stop: stop));

  /// Adds [a] to the queue, or starts it with nothing running or a 1-slot
  /// queue (spec 0003 §2). Throws [ActivityError] if the rules don't allow
  /// it.
  Future<void> addAction(Activity a, {StopCondition? stop}) =>
      _act((s) => game.addAction(s, a, stop: stop));

  /// Removes the action at [index]; 0 is the running one (spec 0003 §2).
  /// Returns the waiting actions that couldn't start next, and why.
  Future<List<ActionSkipped>> removeAction(int index) =>
      _actSkipping((s, events) => game.removeAction(s, index, events: events));

  /// Starts the next action, or rests; unspent steps go to the bank (spec
  /// 0001 amendment 2). Returns the waiting actions that couldn't start.
  Future<List<ActionSkipped>> stopActivity() =>
      _actSkipping((s, events) => game.stopActivity(s, events: events));

  Future<List<ActionSkipped>> _actSkipping(
    GameState Function(GameState, List<GameEvent>) action,
  ) async {
    final events = <GameEvent>[];
    await _act((s) => action(s, events));
    return events.whereType<ActionSkipped>().toList();
  }

  /// Wears [item] in [slot], or in the first free slot it fits (spec 0008
  /// decision 11).
  Future<void> equip(String item, {String? slot}) =>
      _act((s) => game.equip(s, item, slot: slot));

  Future<void> unequip(String slot) => _act((s) => game.unequip(s, slot));

  /// Learns [profession] from its teacher here, who then tells the tips
  /// waiting (spec 0010 §6).
  Future<void> learn(String profession) =>
      _act((s) => game.talk(game.learn(s, profession), profession));

  /// Makes the character on "Who are you?" (spec 0012 §2.2).
  Future<void> setOut({
    required String name,
    required Gender gender,
    required String origin,
  }) => _act(
    (s) => game.makeCharacter(s, name: name, gender: gender, origin: origin),
  );

  /// Settings' Name and Gender (spec 0012 §4.2).
  Future<void> renameCharacter(String name) =>
      _act((s) => game.renameCharacter(s, name));

  Future<void> setGender(Gender gender) =>
      _act((s) => game.setGender(s, gender));

  /// Talks to [profession]'s teacher here: every waiting tip is told.
  Future<void> talk(String profession) => _act((s) => game.talk(s, profession));

  /// Wears the tool [key] from the bag; the one worn goes to the bag.
  Future<void> useTool(String key) => _act((s) => game.equipTool(s, key));

  /// Eats the meal [key] from the bag, replacing one running (spec 0011
  /// §5.4).
  Future<void> eat(String key) => _act((s) => game.eat(s, key));

  /// Sets the auto-eat meal and how many to keep; null turns it off.
  Future<void> setAutoEat(String? meal, {int keep = 0}) =>
      _act((s) => game.setAutoEat(s, meal, keep: keep));

  /// Salvages the bag item [key] at a forge (spec 0010 §7.1).
  Future<SalvageResult> salvage(String key) async {
    late SalvageResult result;
    await _act((s) => (result = game.salvage(s, key)).state);
    return result;
  }

  /// Settles a Legendary's waiting stat roll (spec 0010 §7.3).
  Future<void> keepRoll(String key, {required bool keepNew}) =>
      _act((s) => game.keepRoll(s, key, keepNew: keepNew));

  Future<void> _act(GameState Function(GameState) action) => _serial(() async {
    await _syncNow(away: false);
    final next = action(state);
    _save = _save!.withGame(next);
    await store.save(_save!);
    notifyListeners();
  });

  Future<void> _openSave({required bool away}) async {
    _save = await store.load();
    final loaded = _save?.game;
    // Each load checks the achievements again (spec 0017 §4); the report
    // of the next sync names the ones lost (§5).
    if (loaded != null) {
      final (:state, :events) = game.load(loaded);
      _save = _save!.withGame(state);
      _loaded = AwaySummary.fromReports([
        StepReport(
          state: state,
          walked: 0,
          activitySteps: 0,
          boostUsed: 0,
          banked: 0,
          lost: 0,
          // Only the lost ones (spec 0017 §5): an achievement that the load
          // earns makes no report.
          events: events.whereType<AchievementLost>().toList(),
        ),
      ]);
      await store.save(_save!);
    }
    if (_save == null) {
      _save = await _sync.newSave(seed: _newSeed());
      await store.save(_save!);
    }
    status = ControllerStatus.ready;
    await _syncNow(away: away);
    _startTimer();
    notifyListeners();
  }

  Future<void> _syncNow({required bool away}) async {
    final start = state.location;
    final SyncResult result;
    try {
      result = await _sync.sync(_save!);
    } on StepSourceException catch (e) {
      syncError = e;
      notifyListeners();
      return;
    }
    syncError = null;
    final summary = _from(start, _loaded + result.summary);
    // The losses of the load open a report of their own, also after a
    // failed sync at the open (spec 0017 §5).
    final lostOnLoad = !_loaded.isEmpty;
    _loaded = const AwaySummary();
    _levelCards.addAll(summary.levelsReached);
    // Also saves when old days were pruned from the credit.
    var changed =
        !summary.isEmpty ||
        result.save.credited.length != _save!.credited.length;
    if (changed) _save = result.save;
    if (_report(summary, away: away || lostOnLoad)) changed = true;
    if (changed) await store.save(_save!);
    notifyListeners();
  }

  /// [summary] with its route from [start], the place where the player was
  /// before its steps (spec 0014 §5).
  static AwaySummary _from(String start, AwaySummary summary) =>
      AwaySummary(route: [start]) + summary;

  SaveData _addEntry(SaveData save, JournalEntry entry) => save.copyWith(
    journal: [entry, ...save.journal].take(game.data.journalEntries).toList(),
  );

  /// Adds a sync's results to the away report and the journal. Every return
  /// (open or resume) starts a new entry, read or not (spec 0004 amendment
  /// 1); syncs within [awayGrace] after it are added to it, and re-show the
  /// report. Returns whether the journal changed.
  bool _report(AwaySummary summary, {required bool away}) {
    final now = _clock();
    if (away) {
      _awayUntil = now.add(awayGrace);
      _freshReturn = true;
    }
    final inGrace = _awayUntil != null && now.isBefore(_awayUntil!);
    if (summary.isEmpty || !(away || inGrace)) return false;
    final journal = _save!.journal;
    // Real steps never join a test walk's entry (spec 0004 §3).
    if (_freshReturn || journal.isEmpty || journal.first.testWalk) {
      _save = _addEntry(_save!, JournalEntry(started: now, summary: summary));
      _closed = false;
      awaySummary = null;
    } else {
      final first = journal.first;
      _save = _save!.copyWith(
        journal: [
          first.withSummary(first.summary + summary),
          ...journal.skip(1),
        ],
      );
    }
    _freshReturn = false;
    _show(lastAwaySummary!);
    return true;
  }

  void _setStatus(ControllerStatus s) {
    status = s;
    notifyListeners();
  }

  void _startTimer() {
    _stopTimer();
    final interval = syncInterval;
    if (interval == null || !_foreground) return;
    _timer = Timer.periodic(interval, (_) {
      if (_foreground) syncNow();
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Completes when every queued change has finished.
  @visibleForTesting
  Future<void> idle() => _tail;

  /// Runs [task] after every earlier task, even if one of them failed.
  Future<void> _serial(Future<void> Function() task) {
    final run = _tail.then((_) => task());
    _tail = run.catchError((Object _) {});
    return run;
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}
