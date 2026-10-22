import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/game_controller.dart';
import 'package:walkingrpg/persistence/save_store.dart';
import 'package:walkingrpg/steps/fake_step_source.dart';

import 'support.dart';

void main() {
  final game = loadTestGame();
  late Directory dir;
  late FakeStepSource source;
  late DateTime now;

  GameController controller() => GameController(
    game: game,
    source: source,
    permissions: source,
    store: SaveStore(dir),
    clock: () => now,
    syncInterval: null,
    newSeed: () => 1,
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('controller_test');
    source = FakeStepSource();
    now = DateTime(2026, 10, 18, 9);
  });

  tearDown(() => dir.delete(recursive: true));

  test('without Health Connect the status is unavailable', () async {
    source.available = false;
    final c = controller();
    await c.start();
    expect(c.status, ControllerStatus.unavailable);
  });

  test(
    'without permission it asks; granting creates and saves a game',
    () async {
      source.granted = false;
      final c = controller();
      await c.start();
      expect(c.status, ControllerStatus.needsPermission);

      await c.requestPermission();

      expect(c.status, ControllerStatus.ready);
      expect(await SaveStore(dir).load(), isNotNull);
    },
  );

  test('a refused permission keeps asking', () async {
    source
      ..granted = false
      ..grantOnRequest = false;
    final c = controller();
    await c.start();
    await c.requestPermission();
    expect(c.status, ControllerStatus.needsPermission);
  });

  test('an action syncs first, so earlier steps are not given to it', () async {
    final c = controller();
    await c.start();
    source.walk(DateTime(2026, 10, 18, 9, 30), 1000);
    now = DateTime(2026, 10, 18, 10);

    await c.startActivity(const Activity.travel('goblin_woods'));

    expect(c.state.bank, 1000, reason: 'walked while idle');
    expect(c.state.activity!.progress, 0);
  });

  test('actions are saved', () async {
    final c = controller();
    await c.start();
    await c.startActivity(const Activity.travel('goblin_woods'));

    final reopened = controller();
    await reopened.start();
    expect(
      reopened.state.activity!.activity,
      const Activity.travel('goblin_woods'),
    );
  });

  test('a version 1 save is migrated and saved on open', () async {
    final c = controller();
    await c.start();
    final file = File('${dir.path}${Platform.pathSeparator}save.json');
    final json = jsonDecode(await file.readAsString()) as Map<String, Object?>;
    (json['game'] as Map<String, Object?>)
      ..['version'] = 1
      ..['xp'] = 28000; // level 10 in spec 0001's table
    await file.writeAsString(jsonEncode(json));

    final reopened = controller();
    await reopened.start();
    expect(game.level(reopened.state), 10);
    expect(reopened.state.xp, game.data.xpForLevel(10));
    final saved = (await SaveStore(dir).load())!.game;
    expect(saved.loadedVersion, GameState.schemaVersion);
  });

  test('a refused action throws and changes nothing', () async {
    final c = controller();
    await c.start();
    await expectLater(
      c.startActivity(const Activity.fight('wolf')), // in the fog at first
      throwsA(isA<ActivityError>()),
    );
    expect(c.state.activity, isNull);
  });

  test('resuming after a walk shows a summary until dismissed', () async {
    final c = controller();
    await c.start();
    await c.startActivity(const Activity.travel('goblin_woods'));
    c.pause();

    source.walk(DateTime(2026, 10, 18, 11), 300);
    now = DateTime(2026, 10, 18, 12);
    await c.resume();

    final s = c.awaySummary!;
    expect(s.walked, 300);
    expect(s.actions.single.ended, EndReason.arrived);
    expect(s.banked, 100);

    c.dismissAwaySummary();
    expect(c.awaySummary, isNull);
  });

  group('late steps after opening (Health Connect batches)', () {
    Future<GameController> returned({required int stepsOnOpen}) async {
      final c = controller();
      await c.start();
      await c.startActivity(const Activity.travel('goblin_woods'));
      c.pause();
      if (stepsOnOpen > 0) {
        source.walk(DateTime(2026, 10, 18, 9, 30), stepsOnOpen);
      }
      now = DateTime(2026, 10, 18, 10);
      await c.resume();
      return c;
    }

    test('steps arriving just after opening join the report', () async {
      // The 00:06 case on the Fairphone: 1 step on open, 261 thirty seconds later.
      final c = await returned(stepsOnOpen: 1);
      expect(c.journal.first.summary.walked, 1);

      source.walk(DateTime(2026, 10, 18, 9, 45), 261);
      now = DateTime(2026, 10, 18, 10, 0, 30);
      await c.syncNow();

      expect(c.journal.first.summary.walked, 262);
      expect(c.awaySummary!.walked, 262, reason: 'arrived: the screen opens');
    });

    test('a return with no steps yet still collects late ones', () async {
      final c = await returned(stepsOnOpen: 0);
      expect(c.awaySummary, isNull);

      source.walk(DateTime(2026, 10, 18, 9, 45), 300);
      now = DateTime(2026, 10, 18, 10, 1);
      await c.syncNow();

      expect(c.awaySummary!.walked, 300);
    });

    test(
      'once closed, late steps join the entry without reopening it',
      () async {
        final c = await returned(stepsOnOpen: 1);
        c.dismissAwaySummary();

        source.walk(DateTime(2026, 10, 18, 9, 45), 261);
        now = DateTime(2026, 10, 18, 10, 0, 30);
        await c.syncNow();

        expect(c.awaySummary, isNull);
        expect(c.journal.first.summary.walked, 262);
      },
    );

    test(
      'after the grace period, steps are applied without a report',
      () async {
        final c = await returned(stepsOnOpen: 100);
        c.dismissAwaySummary();

        source.walk(DateTime(2026, 10, 18, 10, 2), 50);
        now = DateTime(2026, 10, 18, 10, 3);
        await c.syncNow();

        expect(c.awaySummary, isNull);
        expect(c.lastAwaySummary!.walked, 100);
        expect(c.state.counters['steps.walked'], 150);
      },
    );

    test('the last report can be shown again after dismissing it', () async {
      final c = await returned(stepsOnOpen: 120);
      c.dismissAwaySummary();
      expect(c.awaySummary, isNull);

      c.showLastAwaySummary();

      expect(c.awaySummary!.walked, 120);
    });

    test('the next return starts a new report', () async {
      final c = await returned(stepsOnOpen: 120);
      c
        ..dismissAwaySummary()
        ..pause();
      source.walk(DateTime(2026, 10, 18, 11), 40);
      now = DateTime(2026, 10, 18, 12);
      await c.resume();

      expect(c.journal.first.summary.walked, 40);
    });
  });

  group('the foreground sync timer (spec 0001 §2.1)', () {
    // A short real interval keeps these tests fast.
    GameController timed() => GameController(
      game: game,
      source: source,
      permissions: source,
      store: SaveStore(dir),
      clock: () => now,
      syncInterval: const Duration(milliseconds: 20),
      newSeed: () => 1,
    );

    // Stops the timer and waits for a sync still writing the save, so
    // tearDown can delete the folder (Windows refuses while a file is open).
    Future<void> stop(GameController c) async {
      c.pause();
      await c.idle();
      c.dispose();
    }

    test('syncs while the app is in the foreground', () async {
      final c = timed();
      await c.start();
      source.walk(DateTime(2026, 10, 18, 9, 30), 500);
      now = DateTime(2026, 10, 18, 10);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(c.state.bank, 500);
      await stop(c);
    });

    test('does not sync when the app opened while in the background', () async {
      // Started with the screen off: Android never reports "hidden", so the
      // app is told it is in the background before the save opens.
      final c = timed()..pause();
      await c.start();
      source.walk(DateTime(2026, 10, 18, 9, 30), 500);
      now = DateTime(2026, 10, 18, 10);

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(
        c.state.bank,
        0,
        reason: 'Health Connect refuses background reads',
      );
      await stop(c);
    });
  });

  test('a step source failure is reported and applies nothing', () async {
    final c = controller();
    await c.start();
    source
      ..walk(DateTime(2026, 10, 18, 9, 30), 500)
      ..failNext = true;
    now = DateTime(2026, 10, 18, 10);

    await c.syncNow();
    expect(c.syncError, isNotNull);
    expect(c.state.bank, 0);

    await c.syncNow();
    expect(c.syncError, isNull);
    expect(c.state.bank, 500);
  });

  group('the journal (spec 0004 §2)', () {
    test(
      'criterion 1: a report is kept with its time, across restarts',
      () async {
        final c = controller();
        await c.start();
        c.pause();
        source.walk(DateTime(2026, 10, 18, 11), 300);
        now = DateTime(2026, 10, 18, 12);
        await c.resume();
        expect(c.journal.single.started, DateTime(2026, 10, 18, 12));
        expect(c.journal.single.summary.walked, 300);
        expect(c.journal.single.testWalk, isFalse);
        c.dispose();

        // Android closed the app: a fresh controller on the same save.
        final again = controller();
        await again.start();
        expect(again.journal.single.summary.walked, 300);
        expect(again.journal.single.started, DateTime(2026, 10, 18, 12));
      },
    );

    test('dismissing the card keeps the entry', () async {
      final c = controller();
      await c.start();
      c.pause();
      source.walk(DateTime(2026, 10, 18, 11), 300);
      now = DateTime(2026, 10, 18, 12);
      await c.resume();
      c.dismissAwaySummary();
      expect(c.journal, hasLength(1));
    });

    test('criterion 2: late steps join the same entry', () async {
      final c = controller();
      await c.start();
      c.pause();
      source.walk(DateTime(2026, 10, 18, 9, 30), 1);
      now = DateTime(2026, 10, 18, 10);
      await c.resume();
      source.walk(DateTime(2026, 10, 18, 9, 45), 261);
      now = DateTime(2026, 10, 18, 10, 0, 30);
      await c.syncNow();
      expect(c.journal.single.summary.walked, 262);
      expect(c.journal.single.started, DateTime(2026, 10, 18, 10));
    });

    test('a return with no steps makes no entry', () async {
      final c = controller();
      await c.start();
      c.pause();
      now = DateTime(2026, 10, 18, 12);
      await c.resume();
      expect(c.journal, isEmpty);
    });

    test('criterion 3: it keeps the newest 20, newest first', () async {
      final c = controller();
      await c.start();
      for (var i = 1; i <= 22; i++) {
        c
          ..dismissAwaySummary()
          ..pause();
        source.walk(DateTime(2026, 10, 18, 9, i * 2), i);
        now = DateTime(2026, 10, 18, 9, i * 2 + 1);
        await c.resume();
      }
      expect(c.journal, hasLength(20));
      expect(c.journal.first.summary.walked, 22);
      expect(c.journal.last.summary.walked, 3);
    });
  });

  group('test walk (spec 0004 §3)', () {
    test('criterion 5: pretend steps play exactly like walked ones', () async {
      final c = controller();
      await c.start();
      final before = c.state;
      source.walk(DateTime(2026, 10, 18, 9, 30), 500);
      now = DateTime(2026, 10, 18, 10);

      await c.testWalk(1000);

      final expected = game.applySteps(
        game.applySteps(before, 500).state,
        1000,
      );
      expect(c.state.toJson(), expected.state.toJson());
      expect(c.state.counters['steps.walked'], 1500);
      expect(c.journal.first.testWalk, isTrue);
      expect(c.journal.first.summary.walked, 1000);
      expect(c.awaySummary, isNull, reason: 'resting: only banked');
      expect(c.quietReport!.walked, 1000);
    });

    test('criterion 5: the next real sync credits only real steps', () async {
      final c = controller();
      await c.start();
      await c.testWalk(1000);
      source.walk(DateTime(2026, 10, 18, 9, 30), 200);
      now = DateTime(2026, 10, 18, 10);
      await c.syncNow();
      await c.syncNow();
      expect(c.state.counters['steps.walked'], 1200);
      c.dispose();

      final again = controller();
      await again.start();
      expect(again.state.counters['steps.walked'], 1200);
    });

    test('criterion 4: the switch is saved', () async {
      final c = controller();
      await c.start();
      expect(c.testWalkOn, isFalse);
      await c.setTestWalk(true);
      c.dispose();

      final again = controller();
      await again.start();
      expect(again.testWalkOn, isTrue);
    });
  });

  test('real steps never join a test walk entry (spec 0004 §3)', () async {
    final c = controller();
    await c.start();
    now = DateTime(2026, 10, 18, 10);
    await c.testWalk(1000);
    // The test walk's card is left on screen; the player walks off.
    c.pause();
    source.walk(DateTime(2026, 10, 18, 11), 300);
    now = DateTime(2026, 10, 18, 12);
    await c.resume();

    expect(c.journal, hasLength(2));
    expect(c.journal.first.testWalk, isFalse);
    expect(c.journal.first.summary.walked, 300);
    expect(c.journal.first.started, DateTime(2026, 10, 18, 12));
    expect(c.journal[1].testWalk, isTrue);
    expect(c.journal[1].summary.walked, 1000);
  });

  test('every return is its own entry, read or not (amendment 1)', () async {
    final c = controller();
    await c.start();
    c.pause();
    source.walk(DateTime(2026, 10, 18, 10), 300);
    now = DateTime(2026, 10, 18, 11);
    await c.resume();
    // The card is never dismissed.
    c.pause();
    source.walk(DateTime(2026, 10, 18, 12), 40);
    now = DateTime(2026, 10, 18, 13);
    await c.resume();

    expect(c.journal, hasLength(2));
    expect(c.journal.first.started, DateTime(2026, 10, 18, 13));
    expect(c.journal.first.summary.walked, 40);
    expect(c.journal[1].started, DateTime(2026, 10, 18, 11));
    expect(c.journal[1].summary.walked, 300);
    expect(c.quietReport!.walked, 40, reason: 'the note shows the newest');
  });

  group('the "While you were away" screen (spec 0004 amendment 2)', () {
    test(
      'criterion 11: steps that only went to the bank make a note',
      () async {
        final c = controller();
        await c.start();
        // First Steps (an achievement) out of the way first.
        c.pause();
        source.walk(DateTime(2026, 10, 18, 9, 10), 150);
        now = DateTime(2026, 10, 18, 9, 20);
        await c.resume();
        expect(c.awaySummary!.achievements, ['first_steps']);
        c
          ..dismissAwaySummary()
          ..pause();
        source.walk(DateTime(2026, 10, 18, 10), 300);
        now = DateTime(2026, 10, 18, 11);
        await c.resume();
        expect(c.awaySummary, isNull);
        expect(c.quietReport!.banked, 300);
        expect(c.journal.first.summary.walked, 300, reason: 'still kept');
        c.clearQuietReport();
        expect(c.quietReport, isNull);
      },
    );

    test('criterion 10: something happened, so the screen opens', () async {
      final c = controller();
      await c.start();
      await c.startActivity(const Activity.travel('goblin_woods'));
      c.pause();
      source.walk(DateTime(2026, 10, 18, 10), 300);
      now = DateTime(2026, 10, 18, 11);
      await c.resume();
      expect(c.awaySummary!.walked, 300);
      expect(c.quietReport, isNull);
    });

    test('late steps that finish something open it within the grace', () async {
      final c = controller();
      await c.start();
      await c.startActivity(const Activity.travel('goblin_woods'));
      c.pause();
      source.walk(DateTime(2026, 10, 18, 9, 30), 50);
      now = DateTime(2026, 10, 18, 10);
      await c.resume();
      expect(c.awaySummary, isNull, reason: 'only on the way');
      source.walk(DateTime(2026, 10, 18, 9, 45), 200);
      now = DateTime(2026, 10, 18, 10, 0, 30);
      await c.syncNow();
      expect(c.awaySummary!.walked, 250, reason: 'arrived');
    });
  });
}
