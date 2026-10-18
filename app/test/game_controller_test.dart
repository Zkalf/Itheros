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

  test('a refused action throws and changes nothing', () async {
    final c = controller();
    await c.start();
    await expectLater(
      c.startActivity(const Activity.fight('goblin')),
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
    expect(s.activitiesEnded.single.reason, EndReason.arrived);
    expect(s.banked, 100);

    c.dismissAwaySummary();
    expect(c.awaySummary, isNull);
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
}
