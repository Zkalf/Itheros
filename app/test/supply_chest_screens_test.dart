// The supply chest in the app: spec 0013 criteria 11 and 36-51 (plan 0037
// M2) and amendment 4 (plan 0038): the top bar button and its dot, the
// supply chest screen, the chest sheet, the away summary, the journal, the
// sync and the test walk.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/game_controller.dart';
import 'package:walkingrpg/steps/fake_step_source.dart';
import 'package:walkingrpg/sync/away_summary.dart';
import 'package:walkingrpg/sync/day_key.dart';
import 'package:walkingrpg/sync/sync_service.dart';
import 'package:walkingrpg/ui/away_summary_card.dart';
import 'package:walkingrpg/ui/labels.dart';

import 'support.dart';
import 'ui_test.dart';

void main() {
  const gear = 'bone_sword@rare+crit2';

  /// Chests waiting, one per entry, for [prepare].
  void Function(GameState) chests(List<Map<String, int>> contents) =>
      (s) => s.supplyChests.addAll([
        for (final (i, items) in contents.indexed)
          SupplyChest('2026-10-${'${10 + i}'}', items),
      ]);

  Future<void> openScreen(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('supply-chest-button')));
    await t.pumpAndSettle();
  }

  group('the top bar button', () {
    testWidgets('criterion 36: the button stands left of Achievements', (
      t,
    ) async {
      await pumpGame(t);
      final chest = t.getCenter(
        find.byKey(const ValueKey('supply-chest-button')),
      );
      final trophy = t.getCenter(
        find.byKey(const ValueKey('achievements-button')),
      );
      expect(chest.dx, lessThan(trophy.dx));
      expect(chest.dy, trophy.dy);
    });

    testWidgets('criterion 37: a dot while a chest waits', (t) async {
      await pumpGame(
        t,
        prepare: chests([
          {'iron_ore': 5},
        ]),
      );
      final dot = t.widget<Badge>(
        find.byKey(const ValueKey('supply-chest-dot')),
      );
      expect(dot.isLabelVisible, isTrue);
    });

    testWidgets('criterion 38: no dot while no chest waits', (t) async {
      await pumpGame(t);
      final dot = t.widget<Badge>(
        find.byKey(const ValueKey('supply-chest-dot')),
      );
      expect(dot.isLabelVisible, isFalse);
    });

    testWidgets('criterion 39: Now shows no chest card and no progress', (
      t,
    ) async {
      await pumpGame(t, prepare: (s) => s.supplySteps[dayKey(now)] = 3200);
      await openTab(t, 'now');
      expect(find.textContaining('Supply chest'), findsNothing);
      expect(find.textContaining('supply chest'), findsNothing);
      expect(find.textContaining('Today:'), findsNothing);
    });
  });

  group('the supply chest screen', () {
    testWidgets('criteria 40 and 41: the button opens the screen with '
        "today's count", (t) async {
      await pumpGame(t, prepare: (s) => s.supplySteps[dayKey(now)] = 3200);
      await openScreen(t);
      expect(find.text('Today: 3,200 / 5,000 steps'), findsOneWidget);
    });

    testWidgets("criterion 42: after today's chest it reads Today: earned", (
      t,
    ) async {
      await pumpGame(
        t,
        prepare: (s) => s
          ..supplySteps[dayKey(now)] = 5600
          ..supplyPaid.add(dayKey(now)),
      );
      await openScreen(t);
      expect(find.text('Today: earned'), findsOneWidget);
    });

    testWidgets('criterion 43: no chest waiting', (t) async {
      await pumpGame(t);
      await openScreen(t);
      expect(find.text('No chest waiting'), findsOneWidget);
      expect(find.byKey(const ValueKey('supply-open')), findsNothing);
      expect(find.byKey(const ValueKey('supply-open-all')), findsNothing);
    });

    testWidgets('criterion 44: one chest shows Open', (t) async {
      await pumpGame(
        t,
        prepare: chests([
          {'iron_ore': 5},
        ]),
      );
      await openScreen(t);
      expect(find.text('1 supply chest'), findsOneWidget);
      expect(find.byKey(const ValueKey('supply-open')), findsOneWidget);
      expect(find.byKey(const ValueKey('supply-open-all')), findsNothing);
    });

    testWidgets('criterion 45: two chests show Open and Open all', (t) async {
      await pumpGame(
        t,
        prepare: chests([
          {'iron_ore': 5},
          {'oak_log': 5},
        ]),
      );
      await openScreen(t);
      expect(find.text('2 supply chests'), findsOneWidget);
      expect(find.byKey(const ValueKey('supply-open')), findsOneWidget);
      expect(find.byKey(const ValueKey('supply-open-all')), findsOneWidget);
    });
  });

  group('the chest sheet', () {
    testWidgets('criteria 46 and 47: each item with its count, gear in its '
        'quality colour; the items go into the bag', (t) async {
      final (c, _) = await pumpGame(
        t,
        prepare: chests([
          {'iron_ore': 5, gear: 1},
        ]),
      );
      await openScreen(t);
      await t.tap(find.byKey(const ValueKey('supply-open')));
      await settle(t, c);
      await t.pumpAndSettle();
      final labels = Labels(c.game.data);
      expect(find.text('Supply chest'), findsOneWidget);
      expect(find.text('${labels.item('iron_ore')} ×5'), findsOneWidget);
      final line = find.text('${labels.item(gear)} ×1');
      expect(line, findsOneWidget);
      final rare = c.game.data.qualities.firstWhere((q) => q.id == 'rare');
      expect(t.widget<Text>(line).style?.color, qualityColour(rare));
      expect(c.state.inventory['iron_ore'], 5);
      expect(c.state.inventory[gear], 1);
      expect(c.state.supplyChests, isEmpty);
    });

    testWidgets('Open all lists every chest under "2 supply chests"', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        prepare: chests([
          {'iron_ore': 5},
          {'iron_ore': 5, 'oak_log': 5},
        ]),
      );
      await openScreen(t);
      await t.tap(find.byKey(const ValueKey('supply-open-all')));
      await settle(t, c);
      await t.pumpAndSettle();
      final labels = Labels(c.game.data);
      expect(find.text('2 supply chests'), findsWidgets);
      expect(find.text('${labels.item('iron_ore')} ×10'), findsOneWidget);
      expect(find.text('${labels.item('oak_log')} ×5'), findsOneWidget);
      expect(c.state.supplyChests, isEmpty);
    });

    testWidgets('Common gear is drawn as on its item card: in the normal '
        'text colour', (t) async {
      final (c, _) = await pumpGame(
        t,
        prepare: chests([
          {'bone_sword': 1},
        ]),
      );
      await openScreen(t);
      await t.tap(find.byKey(const ValueKey('supply-open')));
      await settle(t, c);
      await t.pumpAndSettle();
      final line = find.text('${Labels(c.game.data).item('bone_sword')} ×1');
      expect(t.widget<Text>(line).style?.color, isNull);
    });

    testWidgets('a double tap on Open opens one chest and throws nothing', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        prepare: chests([
          {'iron_ore': 5},
        ]),
      );
      await openScreen(t);
      // Two presses before the first open is done: on the phone the sync
      // inside Open leaves time for a second tap.
      final open = t.widget<FilledButton>(
        find.byKey(const ValueKey('supply-open')),
      );
      open.onPressed!();
      open.onPressed!();
      await settle(t, c);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(c.state.inventory['iron_ore'], 5);
      expect(find.text('Supply chest'), findsOneWidget);
    });

    testWidgets('criterion 48: a tap on gear opens its item card', (t) async {
      final (c, _) = await pumpGame(
        t,
        prepare: chests([
          {gear: 1},
        ]),
      );
      await openScreen(t);
      await t.tap(find.byKey(const ValueKey('supply-open')));
      await settle(t, c);
      await t.pumpAndSettle();
      await t.tap(find.text('${Labels(c.game.data).item(gear)} ×1'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('item-card')), findsOneWidget);
    });
  });

  group('the away summary and the journal', () {
    final game = loadTestGame();
    StepReport earn(List<String> days) {
      var s = game.startActivity(
        game.newGame(seed: 1)
          ..location = 'copper_hills'
          ..learned.add('mining')
          ..tools['mining'] = 'old_pick',
        const Activity.gather('copper_vein'),
      );
      late StepReport r;
      final events = <GameEvent>[];
      for (final d in days) {
        r = game.applySteps(s, 5000, day: d);
        events.addAll(r.events);
        s = r.state;
      }
      return StepReport(
        state: s,
        walked: 5000 * days.length,
        activitySteps: 5000 * days.length,
        boostUsed: 0,
        banked: 0,
        lost: 0,
        events: events,
      );
    }

    test('criterion 49: one chest reads "Supply chest earned"', () {
      final s = AwaySummary.fromReports([
        earn(['2026-10-17']),
      ]);
      expect(s.supplyChests, 1);
      expect(
        reportNews(s, Labels(game.data)).map((n) => n.$2),
        contains('Supply chest earned'),
      );
    });

    test('criterion 50: two chests read "2 supply chests earned"', () {
      final s = AwaySummary.fromReports([
        earn(['2026-10-17', '2026-10-18']),
      ]);
      expect(s.supplyChests, 2);
      expect(
        reportNews(s, Labels(game.data)).map((n) => n.$2),
        contains('2 supply chests earned'),
      );
    });

    test('criterion 51: the journal keeps the chest line', () {
      final entry = JournalEntry(
        started: DateTime(2026, 10, 18, 9),
        summary: AwaySummary.fromReports([
          earn(['2026-10-17']),
        ]),
      );
      final back = JournalEntry.fromJson(entry.toJson());
      expect(back.summary.supplyChests, 1);
      // An entry from before the supply chest has none.
      final old = entry.toJson();
      (old['summary']! as Map<String, Object?>).remove('supplyChests');
      expect(JournalEntry.fromJson(old).summary.supplyChests, 0);
    });
  });

  group('the sync and the test walk', () {
    test(
      'criterion 11: a sync of 3 days that reach the goal earns 3 chests',
      () async {
        final game = loadTestGame();
        var now = DateTime(2026, 10, 16, 8);
        final source = FakeStepSource();
        final sync = SyncService(game: game, source: source, clock: () => now);
        final base = await sync.newSave(seed: 1);
        final mining = game.startActivity(
          base.game
            ..location = 'copper_hills'
            ..learned.add('mining')
            ..tools['mining'] = 'old_pick',
          const Activity.gather('copper_vein'),
        );
        source.walk(DateTime(2026, 10, 16, 12), 6000);
        source.walk(DateTime(2026, 10, 17, 12), 6000);
        source.walk(DateTime(2026, 10, 18, 12), 6000);
        now = DateTime(2026, 10, 18, 20);
        final r = await sync.sync(base.withGame(mining));
        expect(
          [for (final c in r.save.game.supplyChests) c.day],
          ['2026-10-16', '2026-10-17', '2026-10-18'],
        );
        expect(r.summary.supplyChests, 3);
      },
    );

    testWidgets('amendment 4 criterion 1: a test walk counts toward '
        "today's chest", (t) async {
      final (c, _) = await pumpGame(t, location: 'copper_hills');
      await c.startActivity(const Activity.gather('copper_vein'));
      await settle(t, c);
      await c.testWalk(3000);
      await settle(t, c);
      expect(c.supplyToday.steps, 3000);
      expect(c.state.supplyChests, isEmpty);
    });

    testWidgets('amendment 4 criterion 2: a test walk of the goal earns '
        "today's chest", (t) async {
      final (c, _) = await pumpGame(t, location: 'copper_hills');
      await c.startActivity(const Activity.gather('copper_vein'));
      await settle(t, c);
      await c.testWalk(6000);
      await settle(t, c);
      expect([for (final s in c.state.supplyChests) s.day], [dayKey(now)]);
      expect(c.supplyToday.paid, isTrue);
    });
  });

  group('spec 0013 amendment 4', () {
    testWidgets('criterion 3: the screen syncs when it opens', (t) async {
      final (c, source) = await pumpGame(t, location: 'copper_hills');
      await c.startActivity(const Activity.gather('copper_vein'));
      await settle(t, c);
      expect(c.supplyToday.steps, 0);
      source.walk(DateTime(2026, 10, 18, 9, 30), 1200);
      now = DateTime(2026, 10, 18, 10);
      await openScreen(t);
      await settle(t, c);
      await t.pumpAndSettle();
      expect(find.text('Today: 1,200 / 5,000 steps'), findsOneWidget);
    });

    Future<GameController> openGear(WidgetTester t) async {
      final (c, _) = await pumpGame(
        t,
        prepare: chests([
          {gear: 1, 'iron_ore': 5},
        ]),
      );
      await openScreen(t);
      await t.tap(find.byKey(const ValueKey('supply-open')));
      await settle(t, c);
      await t.pumpAndSettle();
      return c;
    }

    ListTile row(WidgetTester t, GameController c) => t.widget<ListTile>(
      find.ancestor(
        of: find.text('${Labels(c.game.data).item(gear)} ×1'),
        matching: find.byType(ListTile),
      ),
    );

    testWidgets('criterion 4: worn gear stays in the sheet, grey', (t) async {
      final c = await openGear(t);
      await c.equip(gear);
      await settle(t, c);
      await t.pumpAndSettle();
      expect(find.text('${Labels(c.game.data).item(gear)} ×1'), findsOneWidget);
      expect(row(t, c).enabled, isFalse);
    });

    testWidgets('criterion 5: salvaged gear stays in the sheet, grey', (
      t,
    ) async {
      final c = await openGear(t);
      await c.salvage(gear);
      await settle(t, c);
      await t.pumpAndSettle();
      expect(find.text('${Labels(c.game.data).item(gear)} ×1'), findsOneWidget);
      expect(row(t, c).enabled, isFalse);
    });

    testWidgets('criterion 6: a tap on a grey row opens nothing', (t) async {
      final c = await openGear(t);
      await c.equip(gear);
      await settle(t, c);
      await t.pumpAndSettle();
      await t.tap(find.text('${Labels(c.game.data).item(gear)} ×1'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('item-card')), findsNothing);
    });

    testWidgets('criterion 7: gear still in the bag keeps its colour and '
        'opens its card', (t) async {
      final c = await openGear(t);
      final line = find.text('${Labels(c.game.data).item(gear)} ×1');
      final rare = c.game.data.qualities.firstWhere((q) => q.id == 'rare');
      expect(t.widget<Text>(line).style?.color, qualityColour(rare));
      expect(row(t, c).enabled, isNot(isFalse));
      await t.tap(line);
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('item-card')), findsOneWidget);
    });
  });
}
