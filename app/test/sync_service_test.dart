// Per-day step reconciliation: spec 0001 amendment 1 and acceptance
// criterion 3 (no double counting).
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/persistence/save_data.dart';
import 'package:walkingrpg/steps/fake_step_source.dart';
import 'package:walkingrpg/steps/step_source.dart';
import 'package:walkingrpg/sync/sync_service.dart';

import 'support.dart';

void main() {
  final game = loadTestGame();
  late FakeStepSource source;
  late DateTime now;
  late SyncService sync;

  setUp(() {
    now = DateTime(2026, 10, 18, 9);
    source = FakeStepSource();
    sync = SyncService(game: game, source: source, clock: () => now);
  });

  test('steps walked before install are not credited (amendment 4)', () async {
    source.walk(DateTime(2026, 10, 18, 7), 3000);
    final save = await sync.newSave(seed: 1);

    final r = await sync.sync(save);

    expect(r.summary.walked, 0);
    expect(r.save.game.bank, 0);
  });

  test('steps after install are credited; idle steps go to the bank', () async {
    final save = await sync.newSave(seed: 1);
    source.walk(DateTime(2026, 10, 18, 9, 30), 500);
    now = DateTime(2026, 10, 18, 10);

    final r = await sync.sync(save);

    expect(r.summary.walked, 500);
    expect(r.save.game.bank, 500);
  });

  test(
    'syncing again with no new steps changes nothing (criterion 3)',
    () async {
      final save = await sync.newSave(seed: 1);
      source.walk(DateTime(2026, 10, 18, 9, 30), 500);
      now = DateTime(2026, 10, 18, 10);
      final first = await sync.sync(save);

      final second = await sync.sync(first.save);

      expect(second.summary.walked, 0);
      expect(second.save.toJson(), first.save.toJson());
    },
  );

  test(
    'a late upload into an already-synced hour is credited (amendment 1)',
    () async {
      var save = await sync.newSave(seed: 1);
      source.walk(DateTime(2026, 10, 18, 9, 30), 500);
      now = DateTime(2026, 10, 18, 10);
      save = (await sync.sync(save)).save;

      source.walk(DateTime(2026, 10, 18, 9, 15), 400); // Garmin, backdated
      now = DateTime(2026, 10, 18, 10, 5);
      final r = await sync.sync(save);

      expect(r.summary.walked, 400);
      expect(r.save.game.bank, 900);
    },
  );

  test('a late upload into yesterday is credited (amendment 2)', () async {
    now = DateTime(2026, 10, 17, 8);
    var save = await sync.newSave(seed: 1);
    now = DateTime(2026, 10, 17, 21);
    save = (await sync.sync(save)).save;

    source.walk(DateTime(2026, 10, 17, 20), 700);
    now = DateTime(2026, 10, 18, 9);
    final r = await sync.sync(save);

    expect(r.summary.walked, 700);
  });

  test('only the last 7 days are reconciled', () async {
    now = DateTime(2026, 10, 1, 8);
    final save = await sync.newSave(seed: 1);
    source.walk(DateTime(2026, 10, 11, 12), 111); // 8th day back: too old
    source.walk(DateTime(2026, 10, 12, 12), 222); // 7th day back
    now = DateTime(2026, 10, 18, 9);

    final r = await sync.sync(save);

    expect(r.summary.walked, 222);
    expect(
      r.save.credited.keys,
      everyElement(greaterThanOrEqualTo('2026-10-12')),
    );
  });

  test(
    'a dropped total credits nothing and takes nothing back (amendment 3)',
    () async {
      var save = await sync.newSave(seed: 1);
      source.walk(DateTime(2026, 10, 18, 9, 30), 1000);
      now = DateTime(2026, 10, 18, 10);
      save = (await sync.sync(save)).save;
      expect(save.game.bank, 1000);

      source
        ..clear()
        ..walk(DateTime(2026, 10, 18, 9, 30), 800); // de-dup priority changed
      final dropped = await sync.sync(save);
      expect(dropped.summary.walked, 0);
      expect(dropped.save.game.bank, 1000);

      source.walk(DateTime(2026, 10, 18, 9, 45), 400); // total now 1,200
      final risen = await sync.sync(dropped.save);
      expect(risen.summary.walked, 200);
    },
  );

  test('a source failure applies nothing', () async {
    final save = await sync.newSave(seed: 1);
    source.walk(DateTime(2026, 10, 18, 9, 30), 500);
    now = DateTime(2026, 10, 18, 10);
    source.failNext = true;

    await expectLater(sync.sync(save), throwsA(isA<StepSourceException>()));

    final retry = await sync.sync(save);
    expect(retry.summary.walked, 500);
  });

  test(
    'the clock moving backwards neither credits nor double counts',
    () async {
      var save = await sync.newSave(seed: 1);
      source.walk(DateTime(2026, 10, 18, 9, 30), 500);
      now = DateTime(2026, 10, 18, 10);
      save = (await sync.sync(save)).save;

      now = DateTime(2026, 10, 9, 10); // before install
      save = (await sync.sync(save)).save;
      now = DateTime(2026, 10, 18, 10, 30); // clock fixed
      final r = await sync.sync(save);

      expect(r.summary.walked, 0);
      expect(r.save.game.bank, 500);
    },
  );

  test(
    'a clock moved back a few days keeps later credit (no double count)',
    () async {
      now = DateTime(2026, 10, 15, 9);
      var save = await sync.newSave(seed: 1);
      source.walk(DateTime(2026, 10, 18, 9, 30), 500);
      now = DateTime(2026, 10, 18, 10);
      save = (await sync.sync(save)).save;
      expect(save.game.bank, 500);

      now = DateTime(
        2026,
        10,
        16,
        10,
      ); // after install, before the credited day
      save = (await sync.sync(save)).save;
      now = DateTime(2026, 10, 18, 10, 30); // clock fixed
      final r = await sync.sync(save);

      expect(r.summary.walked, 0);
      expect(r.save.game.bank, 500);
    },
  );

  test('steps reach the running activity, with the bank boost', () async {
    var save = await sync.newSave(seed: 1);
    final state = game.startActivity(
      save.game..bank = 100,
      const Activity.travel('goblin_woods'),
    );
    save = save.withGame(state);
    source.walk(DateTime(2026, 10, 18, 9, 30), 150);
    now = DateTime(2026, 10, 18, 10);

    final r = await sync.sync(save);

    expect(r.save.game.location, 'goblin_woods');
    expect(r.summary.boostUsed, 100);
    expect(r.save.game.bank, 50, reason: '200 steps of travel, rest banked');
  });

  test('the save survives a JSON round trip', () async {
    final save = await sync.newSave(seed: 3);
    final copy = SaveData.fromJson(save.toJson());
    expect(copy.toJson(), save.toJson());
  });
}
