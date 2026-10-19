// Screens: locked systems are hidden, not greyed out (spec 0001 acceptance
// criterion 8), plus the permission flow, starting activities and the
// "while you were away" card. In-memory storage keeps real I/O out of the
// fake-async test zone.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/game_controller.dart';
import 'package:walkingrpg/persistence/save_data.dart';
import 'package:walkingrpg/persistence/save_store.dart';
import 'package:walkingrpg/steps/fake_step_source.dart';
import 'package:walkingrpg/sync/day_key.dart';
import 'package:walkingrpg/ui/app.dart';
import 'package:walkingrpg/ui/away_summary_card.dart';

import 'support.dart';

final game = loadTestGame();
late DateTime now;

Finder option(String kind, String target) =>
    find.byKey(ValueKey('option-$kind-$target'));

Future<(GameController, FakeStepSource)> pumpGame(
  WidgetTester tester, {
  int level = 1,
  int? xp,
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
    ..xp = xp ?? game.data.xpForLevel(level)
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
    expect(find.text('Walking to Goblin Woods: 0 / 200 steps'), findsOneWidget);
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

    await t.tap(
      find.descendant(
        of: find.byType(AwaySummaryCard),
        matching: find.text('OK'),
      ),
    );
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

  group('spec 0002 criterion 9: level-up cards', () {
    Future<GameController> walkWhileAway(
      WidgetTester t, {
      required int steps,
      int level = 1,
      int? xp,
      String location = 'goblin_woods',
      String enemy = 'goblin',
    }) async {
      final (c, source) = await pumpGame(
        t,
        level: level,
        xp: xp,
        location: location,
      );
      await c.startActivity(Activity.fight(enemy));
      source.walk(DateTime(2026, 10, 18, 10), steps);
      now = DateTime(2026, 10, 18, 11);
      await c.resume();
      await t.pump();
      return c;
    }

    testWidgets('show on open, before the report, collapsed past 3', (t) async {
      final c = await walkWhileAway(t, steps: 5000);
      final levels = c.levelCards;
      expect(levels.length, greaterThan(3));
      expect(find.text('While you were away'), findsNothing);
      expect(
        find.text('Levels ${levels.first}–${levels[levels.length - 2]}'),
        findsOneWidget,
      );
      expect(
        find.text('New monster: Goblin brute (Goblin Woods)'),
        findsOneWidget,
      );

      await t.tap(find.text('Next'));
      await t.pumpAndSettle();
      expect(find.text('Level ${levels.last}!'), findsOneWidget);

      await t.tap(find.text('Continue'));
      await t.pump();
      expect(find.text('While you were away'), findsOneWidget);
    });

    testWidgets('Skip all goes straight to the report', (t) async {
      final c = await walkWhileAway(t, steps: 5000);
      expect(c.levelCards, isNotEmpty);
      await t.tap(find.text('Skip all'));
      await t.pump();
      expect(c.levelCards, isEmpty);
      expect(find.text('While you were away'), findsOneWidget);
    });

    testWidgets('level 10 is the Adventurer ceremony', (t) async {
      await walkWhileAway(
        t,
        steps: 200,
        level: 9,
        xp: game.data.xpForLevel(10) - 1,
        location: 'old_graveyard',
        enemy: 'skeleton',
      );
      expect(find.text('Level 10!'), findsOneWidget);
      expect(find.text('Adventurer'), findsOneWidget);
      expect(find.text(game.data.ranks[1].line), findsOneWidget);
      expect(find.textContaining('+1 talent point'), findsOneWidget);
    });
  });

  group('spec 0002 criterion 10', () {
    testWidgets('a skull or red fight asks first', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      expect(find.text('💀'), findsOneWidget, reason: 'the Old Bear');

      await t.tap(option('fight', 'old_bear'));
      await t.pumpAndSettle();
      expect(find.text('You will almost certainly lose.'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(c.state.activity, isNull);

      await t.tap(option('fight', 'old_bear'));
      await t.pumpAndSettle();
      await t.tap(find.text('Fight anyway'));
      await settle(t, c);
      expect(c.state.activity!.activity, const Activity.fight('old_bear'));
    });

    testWidgets('a yellow fight starts without asking', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await t.tap(option('fight', 'goblin'));
      await settle(t, c);
      expect(find.text('Deadly'), findsNothing);
      expect(c.state.activity!.activity, const Activity.fight('goblin'));
    });

    testWidgets('"Next goal" has no Hide before level 10', (t) async {
      await pumpGame(t, location: 'goblin_woods');
      expect(find.byKey(const ValueKey('next-goal')), findsOneWidget);
      expect(
        find.text('The Goblin in Goblin Woods is your level.'),
        findsOneWidget,
      );
      expect(find.text('Hide'), findsNothing);
    });

    testWidgets('from level 10 it can be hidden and turned back on', (t) async {
      final (c, _) = await pumpGame(t, level: 10, location: 'old_graveyard');
      expect(find.byKey(const ValueKey('next-goal')), findsOneWidget);
      await t.tap(find.text('Hide'));
      await settle(t, c);
      expect(find.byKey(const ValueKey('next-goal')), findsNothing);

      await t.tap(find.text('Character'));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('show-next-goal')));
      await settle(t, c);
      await t.tap(find.text('Adventure'));
      await t.pump();
      expect(find.byKey(const ValueKey('next-goal')), findsOneWidget);
    });
  });

  testWidgets('a loss in the report carries the monster\'s hint', (t) async {
    final (c, source) = await pumpGame(t, location: 'goblin_woods');
    await c.startActivity(const Activity.fight('old_bear'));
    source.walk(DateTime(2026, 10, 18, 10), 30);
    now = DateTime(2026, 10, 18, 11);
    await c.resume();
    await t.pump();
    expect(
      find.textContaining(game.data.enemies['old_bear']!.lossHint!),
      findsOneWidget,
    );
  });

  testWidgets('flavour lines show once', (t) async {
    final (c, _) = await pumpGame(t, location: 'goblin_woods');
    final line = game.data.locations['goblin_woods']!.flavour!;
    expect(find.text(line), findsOneWidget);
    await t.tap(
      find.descendant(
        of: find.byKey(const ValueKey('discoveries')),
        matching: find.text('OK'),
      ),
    );
    await settle(t, c);
    expect(find.text(line), findsNothing);
    expect(c.seen, contains('goblin_woods'));
  });

  group('spec 0003: running your day', () {
    testWidgets('every open area is listed, nearest first, with distance', (
      t,
    ) async {
      await pumpGame(t);
      expect(find.text('Goblin Woods · 200 steps away'), findsOneWidget);
      expect(option('fight', 'goblin'), findsOneWidget);
    });

    testWidgets('below level 5 a tap starts at once', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await t.tap(option('fight', 'goblin'));
      await settle(t, c);
      expect(find.text('Stop when'), findsNothing);
      expect(c.state.activity!.activity, const Activity.fight('goblin'));
    });

    testWidgets('from level 5: pick a stop condition, start, then queue', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, level: 5, location: 'goblin_woods');
      await t.tap(option('fight', 'goblin'));
      await t.pumpAndSettle();
      expect(find.text('Stop when'), findsOneWidget);
      final grey = t.widget<ChoiceChip>(
        find.byKey(const ValueKey('stop-untilGrey')),
      );
      expect(grey.selected, isTrue, reason: 'the default for fights');
      await t.tap(find.byKey(const ValueKey('start-now')));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.activity!.stop, const StopCondition.untilGrey());

      await t.tap(option('fight', 'goblin_brute'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('stop-untilHave')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('add-to-queue')));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(
        c.state.queue.single.activity,
        const Activity.fight('goblin_brute'),
      );
      expect(c.state.queue.single.stop.kind, StopKind.untilHave);
      expect(find.byKey(const ValueKey('queued-0')), findsOneWidget);
      expect(find.text('2 of 2 actions planned'), findsOneWidget);

      await t.tap(find.byKey(const ValueKey('remove-1')));
      await settle(t, c);
      expect(c.state.queue, isEmpty);
      expect(find.byKey(const ValueKey('queued-0')), findsNothing);
    });

    testWidgets('criterion 9: the report tells each action\'s story', (
      t,
    ) async {
      final (c, source) = await pumpGame(t, level: 5);
      await c.addAction(
        const Activity.fight('goblin'),
        stop: StopCondition.untilHave('goblin_hide', 2),
      );
      await c.addAction(const Activity.craft('copper_sword'));
      source.walk(DateTime(2026, 10, 18, 10), 2000);
      now = DateTime(2026, 10, 18, 11);
      await c.resume();
      await t.pump();
      if (c.levelCards.isNotEmpty) {
        c.dismissLevelCards();
        await t.pump();
      }
      expect(
        find.textContaining(
          RegExp(r'^Fought the Goblin: \d+ wins, \+\d+ XP, .*Goblin hide'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Stopped: goal reached.'), findsOneWidget);
      expect(
        find.text(
          'Skipped the Copper sword: not enough Copper ore (needs 5 more).',
        ),
        findsOneWidget,
      );
    });

    testWidgets('criterion 9: the report says which action started next', (
      t,
    ) async {
      final (c, source) = await pumpGame(t, level: 5, location: 'goblin_woods');
      await c.addAction(
        const Activity.fight('goblin'),
        stop: StopCondition.untilHave('goblin_hide', 2),
      );
      await c.addAction(const Activity.gather('copper_vein'));
      // Enough for the hides, not enough to reach Copper Hills and mine.
      source.walk(DateTime(2026, 10, 18, 10), 400);
      now = DateTime(2026, 10, 18, 11);
      await c.resume();
      await t.pump();
      if (c.levelCards.isNotEmpty) {
        c.dismissLevelCards();
        await t.pump();
      }
      expect(c.state.activity!.leg, 'copper_hills', reason: 'still walking');
      expect(
        find.textContaining('Stopped: goal reached. Next: Copper vein.'),
        findsOneWidget,
      );
    });

    testWidgets('Stop says why it skipped a waiting action', (t) async {
      final (c, _) = await pumpGame(t, level: 5, location: 'goblin_woods');
      await c.addAction(
        const Activity.fight('goblin'),
        stop: StopCondition.untilHave('goblin_hide', 9),
      );
      await c.addAction(const Activity.craft('copper_sword'));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('stop-activity')));
      await settle(t, c);
      await t.pump();
      expect(find.text('Resting'), findsOneWidget);
      expect(
        find.text(
          'Skipped the Copper sword: not enough Copper ore (needs 5 more).',
        ),
        findsOneWidget,
      );
    });

    testWidgets('from level 5 a craft can be queued before its materials', (
      t,
    ) async {
      await pumpGame(t, level: 5);
      final tile = t.widget<ListTile>(option('craft', 'copper_sword'));
      expect(tile.enabled, isTrue);
    });
  });

  testWidgets('activity rows have no arrow: the whole row is the button', (
    t,
  ) async {
    await pumpGame(t, level: 3, location: 'goblin_woods');
    expect(option('fight', 'goblin'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  group('inventory', () {
    Future<void> openCharacter(WidgetTester t) async {
      await t.tap(find.text('Character'));
      await t.pumpAndSettle();
    }

    List<String> names(WidgetTester t) => t
        .widgetList<ListTile>(find.byKey(const ValueKey('inventory-item')))
        .map((tile) => (tile.title! as Text).data!)
        .toList();

    testWidgets('keeps its order when an item is equipped', (t) async {
      final (c, _) = await pumpGame(
        t,
        level: 3,
        inventory: {'copper_sword': 1, 'hide_vest': 2, 'goblin_hide': 3},
      );
      await openCharacter(t);
      final before = names(t);
      expect(before, ['Goblin hide', 'Copper sword', 'Hide vest']);

      await t.tap(find.byKey(const ValueKey('equip-hide_vest')));
      await settle(t, c);
      expect(names(t), before, reason: 'one Hide vest is left');

      await t.tap(find.byKey(const ValueKey('equip-copper_sword')));
      await settle(t, c);
      await t.tap(find.text('Remove').first);
      await settle(t, c);
      expect(names(t), before, reason: 'the sword is back in its place');
    });

    testWidgets('shows how many apart from the Equip button', (t) async {
      await pumpGame(t, level: 3, inventory: {'hide_vest': 2});
      await openCharacter(t);
      final equip = find.byKey(const ValueKey('equip-hide_vest'));
      expect(
        find.descendant(of: equip, matching: find.text('Equip')),
        findsOneWidget,
      );
      expect(find.text('×2'), findsOneWidget);
    });
  });
}
