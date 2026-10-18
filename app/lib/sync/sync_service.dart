import 'package:game_core/game_core.dart';

import '../persistence/save_data.dart';
import '../steps/step_source.dart';
import 'away_summary.dart';
import 'day_key.dart';

class SyncResult {
  SyncResult(this.save, this.summary);

  final SaveData save;
  final AwaySummary summary;
}

/// Per-day step reconciliation (spec 0001 amendment 1).
///
/// For each of the last [daysBack] days (never before install), the day's
/// de-duplicated total is compared with what was already credited; only the
/// increase is applied. Late, backdated uploads (Garmin) are therefore
/// counted, nothing is counted twice, and nothing is ever taken back.
class SyncService {
  SyncService({
    required this.game,
    required this.source,
    DateTime Function()? clock,
    this.daysBack = 7,
  }) : clock = clock ?? DateTime.now;

  final Game game;
  final StepSource source;
  final DateTime Function() clock;
  final int daysBack;

  /// A new game. Steps already walked today before install are marked as
  /// credited, so they don't count.
  Future<SaveData> newSave({required int seed}) async {
    final now = clock();
    final already = await source.stepsBetween(startOfDay(now), now);
    return SaveData(
      game: game.newGame(seed: seed),
      firstDay: dayKey(now),
      credited: {dayKey(now): already},
    );
  }

  /// Returns the updated save; the caller persists it. Throws
  /// [StepSourceException] without changing anything if a total can't be read.
  Future<SyncResult> sync(SaveData save) async {
    final now = clock();
    final today = startOfDay(now);
    final windowStart = addDays(today, -(daysBack - 1));
    final firstDay = parseDayKey(save.firstDay);

    final days = [
      for (var d = windowStart; !d.isAfter(today); d = addDays(d, 1))
        if (!d.isBefore(firstDay)) d,
    ];
    if (days.isEmpty) return SyncResult(save, const AwaySummary());

    // Read every total first, so a failed read applies nothing.
    final totals = <String, int>{};
    for (final d in days) {
      final end = addDays(d, 1);
      totals[dayKey(d)] = await source.stepsBetween(
        d,
        end.isBefore(now) ? end : now,
      );
    }

    var state = save.game;
    final reports = <StepReport>[];
    // Keep credit for days in or after the window. Days after it only exist if
    // the clock went backwards; dropping them would count those steps twice.
    final credited = {
      for (final e in save.credited.entries)
        if (!parseDayKey(e.key).isBefore(windowStart)) e.key: e.value,
    };
    for (final d in days) {
      final key = dayKey(d);
      final delta = totals[key]! - (credited[key] ?? 0);
      if (delta <= 0) continue;
      final report = game.applySteps(state, delta);
      reports.add(report);
      state = report.state;
      credited[key] = totals[key]!;
    }

    return SyncResult(
      SaveData(game: state, firstDay: save.firstDay, credited: credited),
      AwaySummary.fromReports(reports),
    );
  }
}
