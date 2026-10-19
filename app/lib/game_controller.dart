import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:game_core/game_core.dart';

import 'persistence/save_data.dart';
import 'persistence/save_store.dart';
import 'steps/step_source.dart';
import 'sync/away_summary.dart';
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
  }) : _clock = clock ?? DateTime.now,
       _sync = SyncService(game: game, source: source, clock: clock),
       _newSeed = newSeed ?? (() => Random.secure().nextInt(1 << 32));

  final Game game;
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

  /// The report on screen, or null once dismissed.
  AwaySummary? awaySummary;

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
  bool get testWalkOn => _save!.testWalk;

  Future<void> setTestWalk(bool on) => _update((s) => s.copyWith(testWalk: on));

  /// Applies [steps] pretend steps exactly as walked ones, after a normal
  /// sync, as a journal entry of its own. Health Connect crediting is left
  /// alone, so later real syncs are unchanged (spec 0004 §3).
  Future<void> testWalk(int steps) => _serial(() async {
    await _syncNow(away: false);
    final report = game.applySteps(state, steps);
    final summary = AwaySummary.fromReports([report]);
    _levelCards.addAll(summary.levelsReached);
    _save = _addEntry(
      _save!.withGame(report.state),
      JournalEntry(started: _clock(), summary: summary, testWalk: true),
    );
    awaySummary = summary;
    // Real steps arriving next start their own entry.
    _freshReturn = true;
    await store.save(_save!);
    notifyListeners();
  });

  /// Areas and monsters whose flavour line was shown (spec 0002 §9.5).
  Set<String> get seen => _save!.seen;

  Future<void> markSeen(Iterable<String> ids) =>
      _update((s) => s.copyWith(seen: {...s.seen, ...ids}));

  /// Saves a change to screen settings. Costs no steps, so no sync first.
  Future<void> _update(SaveData Function(SaveData) change) => _serial(() async {
    _save = change(_save!);
    await store.save(_save!);
    notifyListeners();
  });

  void dismissAwaySummary() {
    awaySummary = null;
    notifyListeners();
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

  Future<void> equip(String item) => _act((s) => game.equip(s, item));

  Future<void> unequip(String slot) => _act((s) => game.unequip(s, slot));

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
    if (loaded != null && loaded.loadedVersion != GameState.schemaVersion) {
      _save = _save!.withGame(game.migrate(loaded));
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
    final SyncResult result;
    try {
      result = await _sync.sync(_save!);
    } on StepSourceException catch (e) {
      syncError = e;
      notifyListeners();
      return;
    }
    syncError = null;
    _levelCards.addAll(result.summary.levelsReached);
    // Also saves when old days were pruned from the credit.
    var changed =
        !result.summary.isEmpty ||
        result.save.credited.length != _save!.credited.length;
    if (changed) _save = result.save;
    if (_report(result.summary, away: away)) changed = true;
    if (changed) await store.save(_save!);
    notifyListeners();
  }

  SaveData _addEntry(SaveData save, JournalEntry entry) => save.copyWith(
    journal: [entry, ...save.journal].take(game.data.journalEntries).toList(),
  );

  /// Adds a sync's results to the away report and the journal. A return
  /// (open or resume) starts a new entry unless the previous report is still
  /// on screen; syncs within [awayGrace] after it are added too, and re-show
  /// the report. Returns whether the journal changed.
  bool _report(AwaySummary summary, {required bool away}) {
    final now = _clock();
    if (away) {
      _awayUntil = now.add(awayGrace);
      _freshReturn = awaySummary == null;
    }
    final inGrace = _awayUntil != null && now.isBefore(_awayUntil!);
    if (summary.isEmpty || !(away || inGrace)) return false;
    final journal = _save!.journal;
    if (_freshReturn || journal.isEmpty) {
      _save = _addEntry(_save!, JournalEntry(started: now, summary: summary));
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
    awaySummary = lastAwaySummary;
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
