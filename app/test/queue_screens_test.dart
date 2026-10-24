// Spec 0016 §7 (plan 0018 M2): the queue card, the action sheet and the
// report with walks in the queue. Criteria 19 and 26-28.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/sync/away_summary.dart';
import 'package:walkingrpg/ui/labels.dart';

import 'support.dart';
import 'ui_test.dart';

void main() {
  const goblins = Activity.fight('goblin');
  const brutes = Activity.fight('goblin_brute');
  const mining = Activity.gather('copper_vein');
  final someHides = StopCondition.untilHave('goblin_hide', 50);
  final someOre = StopCondition.untilHave('copper_ore', 3);

  Finder startNowText(String label) => find.descendant(
    of: find.byKey(const ValueKey('start-now')),
    matching: find.text(label),
  );

  group('criterion 19: the Start now button', () {
    testWidgets('reads "Start" with nothing running', (t) async {
      await pumpGame(t, location: 'goblin_woods');
      await openArea(t, 'goblin_woods');
      await t.tap(option('fight', 'goblin'));
      await t.pumpAndSettle();
      expect(startNowText('Start'), findsOneWidget);
    });

    testWidgets('reads "Start now" with an empty queue', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await c.addAction(goblins, stop: someHides);
      await settle(t, c);
      await openArea(t, 'goblin_woods');
      await t.tap(option('fight', 'goblin_brute'));
      await t.pumpAndSettle();
      expect(startNowText('Start now'), findsOneWidget);
    });

    testWidgets('reads "Start now, clear queue" with actions waiting', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await c.addAction(goblins, stop: someHides);
      await c.addAction(brutes, stop: someHides);
      await settle(t, c);
      await openArea(t, 'copper_hills');
      await t.tap(option('gather', 'copper_vein'));
      await t.pumpAndSettle();
      expect(startNowText('Start now, clear queue'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('start-now')));
      await settle(t, c);
      expect(c.state.activity!.activity, const Activity.travel('copper_hills'));
      expect(c.state.queue.single.activity, mining);
    });
  });

  group('the queue card', () {
    testWidgets('criteria 26 and 27: a walk has its own line and a slot', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await c.addAction(goblins, stop: someHides);
      await c.addAction(mining, stop: someOre);
      await settle(t, c);
      await openTab(t, 'now');
      expect(find.text('Travel to Copper Hills · 300 steps'), findsOneWidget);
      expect(find.text('3 of 5 actions planned'), findsOneWidget);
    });

    testWidgets('the remove button of a needed walk says why it stays', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await c.addAction(goblins, stop: someHides);
      await c.addAction(mining, stop: someOre);
      await settle(t, c);
      await openTab(t, 'now');
      await t.tap(find.byKey(const ValueKey('remove-1')));
      await settle(t, c);
      await t.pump();
      expect(
        find.text('Copper vein needs this walk. Remove Copper vein first.'),
        findsOneWidget,
      );
      expect(c.state.queue, hasLength(2));
    });
  });

  group('the action sheet', () {
    testWidgets('criterion 28: it names the walk first, with its steps', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await c.addAction(goblins, stop: someHides);
      await settle(t, c);
      await openArea(t, 'copper_hills');
      await t.tap(option('gather', 'copper_vein'));
      await t.pumpAndSettle();
      expect(
        find.text('Walk to Copper Hills first: 300 steps, one more slot.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('add-to-queue')), findsOneWidget);
    });

    testWidgets('a full queue shows "The queue is full."', (t) async {
      final (c, _) = await pumpGame(t, level: 10, location: 'goblin_woods');
      await c.addAction(goblins, stop: someHides);
      await c.addAction(mining, stop: someOre);
      await c.addAction(const Activity.travel('camp'));
      await c.addAction(const Activity.travel('mirror_lake'));
      await settle(t, c);
      await openArea(t, 'goblin_woods');
      await t.tap(option('fight', 'goblin_brute'));
      await t.pumpAndSettle();
      expect(find.text('The queue is full.'), findsOneWidget);
      expect(find.byKey(const ValueKey('add-to-queue')), findsNothing);
    });

    testWidgets('a walk to where the queue ends shows why it is refused', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await c.addAction(goblins, stop: someHides);
      await c.addAction(const Activity.travel('camp'));
      await settle(t, c);
      await openArea(t, 'camp');
      await t.tap(option('travel', 'camp'));
      await t.pumpAndSettle();
      expect(find.text('The queue already ends at Camp.'), findsOneWidget);
      expect(find.byKey(const ValueKey('add-to-queue')), findsNothing);
    });

    testWidgets('with no room for the walk, it shows the refusal', (t) async {
      // Level 10: the skeleton is not deadly, so its sheet opens at once.
      final (c, _) = await pumpGame(t, level: 10, location: 'goblin_woods');
      await c.addAction(goblins, stop: someHides);
      await c.addAction(mining, stop: someOre);
      await c.addAction(const Activity.travel('camp'));
      await settle(t, c);
      await openArea(t, 'old_graveyard');
      await t.tap(option('fight', 'skeleton'));
      await t.pumpAndSettle();
      expect(
        find.text(
          'The queue is full. The walk to Old Graveyard needs a slot too.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('add-to-queue')), findsNothing);
    });
  });

  group('the report', () {
    testWidgets('a walk reads "Walked to", with its steps', (t) async {
      final (c, source) = await pumpGame(t);
      await c.addAction(goblins, stop: someHides);
      source.walk(DateTime(2026, 10, 18, 10), 250);
      now = DateTime(2026, 10, 18, 11);
      await c.resume();
      await t.pump();
      if (c.levelCards.isNotEmpty) {
        c.dismissLevelCards();
        await t.pump();
      }
      expect(
        find.textContaining('Walked to Goblin Woods (200 steps).'),
        findsOneWidget,
      );
    });

    test('a leg in the middle of a walk is not news; its steps add up', () {
      StepReport report(List<GameEvent> events, {required bool walking}) =>
          StepReport(
            state: GameState(location: 'old_graveyard', rngState: 1)
              ..activity = walking
                  ? RunningActivity(const Activity.travel('grey_moor'))
                  : null,
            walked: 500,
            activitySteps: 500,
            boostUsed: 0,
            banked: 0,
            lost: 0,
            events: events,
          );
      // Camp -> Old Graveyard (500), then Old Graveyard -> Grey Moor (800).
      final middle = AwaySummary.fromReports([
        report(const [Arrived('old_graveyard', steps: 500)], walking: true),
      ]);
      expect(middle.isEventful, isFalse);
      final both =
          middle +
          AwaySummary.fromReports([
            report(const [
              Arrived('grey_moor', steps: 800),
              ActivityEnded(Activity.travel('grey_moor'), EndReason.arrived),
            ], walking: false),
          ]);
      expect(both.isEventful, isTrue);
      expect(Labels(loadTestGame().data).actionLines(both.actions.single), [
        'Walked to Grey Moor (1,300 steps).',
      ]);
    });

    test('an action at the wrong place says where the player is not', () {
      final labels = Labels(loadTestGame().data);
      expect(
        labels.skipLine(mining, SkipReason.notThere, const {}),
        'Copper vein: you are not at Copper Hills.',
      );
      expect(
        labels.skipLine(
          const Activity.craft('copper_sword'),
          SkipReason.notThere,
          const {},
        ),
        'Copper sword: you are not at a forge.',
      );
    });
  });
}
