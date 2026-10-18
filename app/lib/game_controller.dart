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
    int Function()? newSeed,
  }) : _sync = SyncService(game: game, source: source, clock: clock),
       _newSeed = newSeed ?? (() => Random.secure().nextInt(1 << 32));

  final Game game;
  final StepPermissions permissions;
  final SaveStorage store;

  /// Foreground sync period; null disables the timer (tests).
  final Duration? syncInterval;

  final SyncService _sync;
  final int Function() _newSeed;

  ControllerStatus status = ControllerStatus.loading;
  SaveData? _save;
  AwaySummary? awaySummary;

  /// Last step-sync failure, cleared by the next successful sync.
  Object? syncError;

  Timer? _timer;
  Future<void> _tail = Future.value();

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
  Future<void> resume() => _serial(() async {
    if (status != ControllerStatus.ready) return;
    await _syncNow(away: true);
    _startTimer();
  });

  /// App went to the background.
  void pause() => _stopTimer();

  Future<void> syncNow() => _serial(() async {
    if (status == ControllerStatus.ready) await _syncNow(away: false);
  });

  void dismissAwaySummary() {
    awaySummary = null;
    notifyListeners();
  }

  /// Throws [ActivityError] if the rules don't allow [a].
  Future<void> startActivity(Activity a) =>
      _act((s) => game.startActivity(s, a));

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
    if (!result.summary.isEmpty) {
      _save = result.save;
      await store.save(_save!);
      if (away) {
        awaySummary = (awaySummary ?? const AwaySummary()) + result.summary;
      }
    } else if (result.save.credited.length != _save!.credited.length) {
      _save = result.save; // pruned old days
      await store.save(_save!);
    }
    notifyListeners();
  }

  void _setStatus(ControllerStatus s) {
    status = s;
    notifyListeners();
  }

  void _startTimer() {
    _stopTimer();
    final interval = syncInterval;
    if (interval != null) _timer = Timer.periodic(interval, (_) => syncNow());
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
