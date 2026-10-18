// Screens: locked systems are hidden, not greyed out (spec 0001 acceptance
// criterion 8), plus the permission flow, starting activities and the
// "while you were away" card. In-memory storage keeps real I/O out of the
// fake-async test zone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/game_controller.dart';
import 'package:walkingrpg/persistence/save_data.dart';
import 'package:walkingrpg/persistence/save_store.dart';
import 'package:walkingrpg/steps/fake_step_source.dart';
import 'package:walkingrpg/sync/day_key.dart';
import 'package:walkingrpg/ui/app.dart';

import 'support.dart';

final game = loadTestGame();
late DateTime now;

Finder option(String kind, String target) =>
    find.byKey(ValueKey('option-$kind-$target'));

Future<(GameController, FakeStepSource)> pumpGame(
  WidgetTester tester, {
  int level = 1,
  String location = 'camp',
  Map<String, int> inventory = const {},
  bool granted = true,
}) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  now = DateTime(2026, 10, 18, 9);

  final source = FakeStepSource(granted: granted);
  final state = game.newGame(seed: 1)
    ..xp = game.data.xpForLevel(level)
    ..location = location
    ..inventory.addAll(inventory);
  final store = MemorySaveStore(
    granted
        ? SaveData(
            game: state,
            firstDay: dayKey(now),
            credited: const {},
          ).toJson()
        : null,
  );

  final c = GameController(
    game: game,
    source: source,
    permissions: source,
    store: store,
    clock: () => now,
    syncInterval: null,
    newSeed: () => 1,
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(WalkingRpgApp(controller: c));
  await c.start();
  await tester.pump();
  return (c, source);
}

Future<void> settle(WidgetTester tester, GameController c) async {
  await c.idle();
  await tester.pump();
}

void main() {
  group('criterion 8: locked systems are hidden', () {
    testWidgets('level 1 at camp: no crafting, no Copper Hills', (t) async {
      await pumpGame(t);
      expect(option('travel', 'goblin_woods'), findsOneWidget);
      expect(option('travel', 'copper_hills'), findsNothing);
      expect(find.text('Craft'), findsNothing);
      expect(option('craft', 'copper_sword'), findsNothing);
    });

    testWidgets('level 1 in Goblin Woods: goblins, no brute, no mining', (
      t,
    ) async {
      await pumpGame(t, location: 'goblin_woods');
      expect(option('fight', 'goblin'), findsOneWidget);
      expect(option('fight', 'goblin_brute'), findsNothing);
      expect(find.text('Gather'), findsNothing);
    });

    testWidgets('level 2 shows Copper Hills and mining there', (t) async {
      await pumpGame(t, level: 2, location: 'copper_hills');
      expect(option('gather', 'copper_vein'), findsOneWidget);
      expect(option('travel', 'camp'), findsOneWidget);
    });

    testWidgets('level 3 shows crafting at camp', (t) async {
      await pumpGame(t, level: 3, inventory: {'copper_ore': 5});
      expect(option('craft', 'copper_sword'), findsOneWidget);
      expect(option('craft', 'hide_vest'), findsOneWidget);
      final vest = t.widget<ListTile>(option('craft', 'hide_vest'));
      expect(vest.enabled, isFalse, reason: 'no hides yet');
    });

    testWidgets('level 4 shows the goblin brute', (t) async {
      await pumpGame(t, level: 4, location: 'goblin_woods');
      expect(option('fight', 'goblin_brute'), findsOneWidget);
    });
  });

  testWidgets('tapping a destination starts walking there', (t) async {
    final (c, _) = await pumpGame(t);
    await t.tap(option('travel', 'goblin_woods'));
    await settle(t, c);
    expect(find.text('Walking to Goblin Woods'), findsOneWidget);
    expect(find.text('0 / 200 steps'), findsOneWidget);
  });

  testWidgets('Stop is shown only while active, and banks unspent steps', (
    t,
  ) async {
    final (c, source) = await pumpGame(t);
    final stop = find.byKey(const ValueKey('stop-activity'));
    expect(stop, findsNothing, reason: 'resting');

    await t.tap(option('travel', 'goblin_woods'));
    await settle(t, c);
    expect(stop, findsOneWidget);

    source.walk(DateTime(2026, 10, 18, 9, 30), 120);
    now = DateTime(2026, 10, 18, 10);
    await t.tap(stop);
    await settle(t, c);

    expect(stop, findsNothing);
    expect(find.text('Resting'), findsOneWidget);
    expect(c.state.bank, 120, reason: '120 travel steps refunded');
  });

  testWidgets('without permission the permission screen is shown', (t) async {
    final (c, _) = await pumpGame(t, granted: false);
    expect(find.text('Allow step access'), findsOneWidget);

    await t.tap(find.text('Allow step access'));
    await settle(t, c);

    expect(find.text('Camp'), findsOneWidget);
    expect(option('travel', 'goblin_woods'), findsOneWidget);
  });

  testWidgets('the away card shows what happened and can be dismissed', (
    t,
  ) async {
    final (c, source) = await pumpGame(t);
    await t.tap(option('travel', 'goblin_woods'));
    await settle(t, c);

    source.walk(DateTime(2026, 10, 18, 10), 300);
    now = DateTime(2026, 10, 18, 11);
    await c.resume();
    await t.pump();

    expect(find.text('While you were away'), findsOneWidget);
    expect(find.text('You walked 300 steps.'), findsOneWidget);
    expect(find.text('Arrived at Goblin Woods.'), findsOneWidget);
    expect(find.text('Saved 100 steps in your step bank.'), findsOneWidget);

    await t.tap(find.text('OK'));
    await t.pump();
    expect(find.text('While you were away'), findsNothing);

    await t.tap(find.byIcon(Icons.history));
    await t.pump();
    expect(find.text('You walked 300 steps.'), findsOneWidget);
  });

  testWidgets('a single step reads as "1 step"', (t) async {
    final (c, source) = await pumpGame(t);
    await t.tap(option('travel', 'goblin_woods'));
    await settle(t, c);

    source.walk(DateTime(2026, 10, 18, 10), 1);
    now = DateTime(2026, 10, 18, 11);
    await c.resume();
    await t.pump();

    expect(find.text('You walked 1 step.'), findsOneWidget);
  });
}
