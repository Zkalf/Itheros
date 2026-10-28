// Spec 0016 amendment 2: the change sheet. Criteria 1-10, 17 and 18.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/game_controller.dart';

import 'ui_test.dart';

void main() {
  const goblins = Activity.fight('goblin');
  const brutes = Activity.fight('goblin_brute');
  const hides = StopCondition.untilHave('goblin_hide', 50);

  Finder button(String key) => find.byKey(ValueKey(key));

  ChoiceChip chip(WidgetTester t, StopKind k) =>
      t.widget<ChoiceChip>(button('stop-${k.name}'));

  /// Goblins until 50 hides, then brutes until 50 hides, on Now.
  Future<GameController> twoFights(
    WidgetTester t, {
    Map<String, int> inventory = const {},
  }) async {
    final (c, _) = await pumpGame(
      t,
      location: 'goblin_woods',
      inventory: inventory,
    );
    await c.addAction(goblins, stop: hides);
    await c.addAction(brutes, stop: hides);
    await settle(t, c);
    return c;
  }

  group('opening the sheet (criteria 1-4)', () {
    testWidgets('criterion 1: a tap on the current action on Now', (t) async {
      await twoFights(t);
      await t.tap(button('change-0'));
      await t.pumpAndSettle();
      expect(button('change-stop'), findsOneWidget);
    });

    testWidgets('criterion 2: a tap on the "Active" row', (t) async {
      await twoFights(t);
      await t.tap(option('fight', 'goblin'));
      await t.pumpAndSettle();
      expect(button('change-stop'), findsOneWidget);
    });

    testWidgets('criterion 3: a tap on a waiting action on Now', (t) async {
      await twoFights(t);
      await t.tap(button('queued-0'));
      await t.pumpAndSettle();
      expect(button('change-stop'), findsOneWidget);
    });

    testWidgets('criterion 4: a tap on a walk opens nothing', (t) async {
      final (c, _) = await pumpGame(t);
      await c.addAction(goblins, stop: hides);
      await c.addAction(const Activity.travel('copper_hills'));
      await settle(t, c);
      expect(c.state.activity!.activity.kind, ActivityKind.travel);
      expect(button('change-0'), findsNothing);
      await t.tap(button('queued-1'));
      await t.pumpAndSettle();
      expect(button('change-stop'), findsNothing);
    });
  });

  group('the sheet (criteria 5-7)', () {
    testWidgets('criteria 5 and 6: it opens with the stop condition, the item '
        'and the number of the action', (t) async {
      await twoFights(t, inventory: {'goblin_hide': 3});
      await t.tap(button('change-0'));
      await t.pumpAndSettle();
      expect(chip(t, StopKind.untilHave).selected, isTrue);
      expect(chip(t, StopKind.untilGrey).selected, isFalse);
      expect(find.text('Goblin hide'), findsOneWidget);
      expect(find.text('50'), findsOneWidget, reason: 'not 3 + 5');
    });

    testWidgets('criterion 7: one button, "Change"', (t) async {
      await twoFights(t);
      await t.tap(button('change-0'));
      await t.pumpAndSettle();
      expect(
        find.descendant(
          of: button('change-stop'),
          matching: find.text('Change'),
        ),
        findsOneWidget,
      );
      expect(button('start-now'), findsNothing);
      expect(button('add-to-queue'), findsNothing);
    });

    testWidgets('a tap on "Change" changes the stop condition and keeps the '
        'queue', (t) async {
      final c = await twoFights(t);
      await t.tap(button('queued-0'));
      await t.pumpAndSettle();
      await t.tap(button('count-up'));
      await t.pumpAndSettle();
      await t.tap(button('change-stop'));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.activity!.stop, hides);
      expect(
        c.state.queue.single.stop,
        const StopCondition.untilHave('goblin_hide', 51),
      );
    });
  });

  group('picker rules (criteria 8-10)', () {
    testWidgets('criterion 8: "Never" shows for the last action', (t) async {
      await twoFights(t);
      await t.tap(button('queued-0'));
      await t.pumpAndSettle();
      expect(button('stop-never'), findsOneWidget);
    });

    testWidgets('criterion 9: "Never" hides for an action with another '
        'action after it', (t) async {
      await twoFights(t);
      await t.tap(button('change-0'));
      await t.pumpAndSettle();
      expect(button('stop-never'), findsNothing);
      expect(button('stop-untilHave'), findsOneWidget);
    });

    testWidgets('criterion 10: "Until grey" hides for a grey monster', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, level: 20, location: 'goblin_woods');
      expect(c.game.enemyBand(c.state, 'goblin').colour, LevelColour.grey);
      await c.addAction(goblins, stop: hides);
      await settle(t, c);
      await t.tap(button('change-0'));
      await t.pumpAndSettle();
      expect(button('stop-untilGrey'), findsNothing);
    });
  });

  group('a goal that is already reached (criterion 18)', () {
    testWidgets('the sheet warns before the tap on the current action', (
      t,
    ) async {
      await twoFights(t, inventory: {'goblin_hide': 3});
      await t.tap(button('change-0'));
      await t.pumpAndSettle();
      expect(find.textContaining('You have this already'), findsNothing);
      for (var i = 0; i < 50; i++) {
        await t.tap(find.byIcon(Icons.remove).last);
      }
      await t.pumpAndSettle();
      expect(
        find.text('You have this already. The action stops now.'),
        findsOneWidget,
      );
    });

    testWidgets('the sheet warns before the tap on a waiting action', (
      t,
    ) async {
      await twoFights(t, inventory: {'goblin_hide': 3});
      await t.tap(button('queued-0'));
      await t.pumpAndSettle();
      for (var i = 0; i < 50; i++) {
        await t.tap(find.byIcon(Icons.remove).last);
      }
      await t.pumpAndSettle();
      expect(
        find.text('You have this already. The action will be skipped.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('criterion 17: the game syncs steps before the change', (
    t,
  ) async {
    final (c, source) = await pumpGame(t, location: 'goblin_woods');
    await c.addAction(goblins, stop: hides);
    await c.addAction(brutes, stop: hides);
    await settle(t, c);
    source.walk(DateTime(2026, 10, 18, 9, 30), 2000);
    now = DateTime(2026, 10, 18, 10);

    await c.changeStop(0, const StopCondition.untilHave('goblin_hide', 1));
    await settle(t, c);

    // The 2,000 steps went to the goblins under the old stop condition.
    // Then the new goal was reached, so the brutes start with no fight yet.
    expect(c.state.counters['kills.goblin'], greaterThan(0));
    expect(c.state.inventory['goblin_hide'], greaterThan(1));
    expect(c.state.activity!.activity, brutes);
    expect(c.state.counters['kills.goblin_brute'], isNull);
  });

  // Review of PR #131: the queue can change while the sheet is open.
  group('the queue changes while the sheet is open', () {
    testWidgets('the sheet does not break when its action is gone', (t) async {
      final c = await twoFights(t);
      await c.addAction(goblins, stop: hides);
      await settle(t, c);
      await t.tap(button('queued-1'));
      await t.pumpAndSettle();

      await c.removeAction(1);
      await settle(t, c);
      await t.tap(button('count-up'));
      await t.pumpAndSettle();

      expect(t.takeException(), isNull);
      expect(button('change-stop'), findsOneWidget);
    });

    testWidgets('"Change" refuses when another action took the place', (
      t,
    ) async {
      final c = await twoFights(t);
      await t.tap(button('change-0'));
      await t.pumpAndSettle();
      await t.tap(button('count-up'));
      await t.pumpAndSettle();

      // The goblins end (as a sync can end them); the brutes take place 0.
      await c.removeAction(0);
      await settle(t, c);
      expect(c.state.activity!.activity, brutes);
      await t.tap(button('change-stop'));
      await settle(t, c);
      await t.pumpAndSettle();

      expect(c.state.activity!.stop, hides, reason: 'the brutes keep 50');
      expect(
        find.text('The queue changed. Open the action again.'),
        findsOneWidget,
      );
    });
  });

  testWidgets('a tap on the selected chip keeps the number of the action', (
    t,
  ) async {
    await twoFights(t, inventory: {'goblin_hide': 3});
    await t.tap(button('change-0'));
    await t.pumpAndSettle();
    await t.tap(button('stop-untilHave'));
    await t.pumpAndSettle();
    expect(find.text('50'), findsOneWidget, reason: 'not 3 + 5');
  });
}
