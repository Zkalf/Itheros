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
import 'package:walkingrpg/sync/away_summary.dart';
import 'package:walkingrpg/sync/day_key.dart';
import 'package:walkingrpg/ui/app.dart';
import 'package:walkingrpg/ui/away_summary_card.dart';
import 'package:walkingrpg/ui/home_shell.dart';
import 'package:walkingrpg/ui/journal_screen.dart';
import 'package:walkingrpg/ui/labels.dart';
import 'package:walkingrpg/ui/map_tab.dart';

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
  Map<String, int> counters = const {},
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
    ..inventory.addAll(inventory)
    ..counters.addAll(counters);
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

/// Opens a bottom bar screen: now, map, craft, character, achievements.
Future<void> openTab(WidgetTester tester, String screen) async {
  await tester.tap(find.byKey(ValueKey('tab-$screen')));
  await tester.pumpAndSettle();
}

/// Opens the Map and taps [area] on it.
Future<void> openArea(WidgetTester tester, String area) async {
  if (find.byKey(ValueKey('area-$area')).evaluate().isEmpty) {
    await openTab(tester, 'map');
  }
  await tester.tap(find.byKey(ValueKey('area-$area')));
  await tester.pumpAndSettle();
}

/// Closes an open bottom sheet.
Future<void> closeSheet(WidgetTester tester) async {
  await tester.tapAt(const Offset(5, 5));
  await tester.pumpAndSettle();
}

Future<void> settle(WidgetTester tester, GameController c) async {
  await c.idle();
  await tester.pump();
}

void main() {
  moreScreens();
  theMap();
  mapGaps();
  group('criterion 8: locked systems are hidden', () {
    testWidgets('level 1 at camp: no crafting, no Copper Hills', (t) async {
      await pumpGame(t);
      await openArea(t, 'goblin_woods');
      expect(option('travel', 'goblin_woods'), findsOneWidget);
      await closeSheet(t);
      await openArea(t, 'copper_hills');
      expect(option('travel', 'copper_hills'), findsNothing);
      expect(find.textContaining('Thick fog'), findsOneWidget);
      await closeSheet(t);
      expect(find.byKey(const ValueKey('tab-craft')), findsNothing);
      expect(option('craft', 'copper_sword'), findsNothing);
    });

    testWidgets('level 1 in Goblin Woods: goblins, no brute, no mining', (
      t,
    ) async {
      await pumpGame(t, location: 'goblin_woods');
      await openArea(t, 'goblin_woods');
      expect(option('fight', 'goblin'), findsOneWidget);
      expect(option('fight', 'goblin_brute'), findsNothing);
      expect(find.text('Gather'), findsNothing);
    });

    testWidgets('level 2 shows Copper Hills and mining there', (t) async {
      await pumpGame(t, level: 2, location: 'copper_hills');
      await openArea(t, 'copper_hills');
      expect(option('gather', 'copper_vein'), findsOneWidget);
      await closeSheet(t);
      await openArea(t, 'camp');
      expect(option('travel', 'camp'), findsOneWidget);
    });

    testWidgets('level 3 shows crafting at camp', (t) async {
      await pumpGame(t, level: 3, inventory: {'copper_ore': 5});
      await openTab(t, 'craft');
      expect(option('craft', 'copper_sword'), findsOneWidget);
      expect(option('craft', 'hide_vest'), findsOneWidget);
      final vest = t.widget<ListTile>(option('craft', 'hide_vest'));
      expect(vest.enabled, isFalse, reason: 'no hides yet');
    });

    testWidgets('level 4 shows the goblin brute', (t) async {
      await pumpGame(t, level: 4, location: 'goblin_woods');
      await openArea(t, 'goblin_woods');
      expect(option('fight', 'goblin_brute'), findsOneWidget);
    });
  });

  testWidgets('tapping a destination starts walking there', (t) async {
    final (c, _) = await pumpGame(t);
    await openArea(t, 'goblin_woods');
    await t.tap(option('travel', 'goblin_woods'));
    await settle(t, c);
    await openTab(t, 'now');
    expect(find.text('Walking to Goblin Woods'), findsOneWidget);
    expect(find.text('Walking to Goblin Woods: 0 / 200 steps'), findsOneWidget);
  });

  testWidgets('Stop is shown only while active, and banks unspent steps', (
    t,
  ) async {
    final (c, source) = await pumpGame(t);
    final stop = find.byKey(const ValueKey('stop-activity'));
    expect(stop, findsNothing, reason: 'resting');

    await openArea(t, 'goblin_woods');
    await t.tap(option('travel', 'goblin_woods'));
    await settle(t, c);
    await openTab(t, 'now');
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
    await openArea(t, 'goblin_woods');
    expect(option('travel', 'goblin_woods'), findsOneWidget);
  });

  testWidgets('criterion 10: the "While you were away" screen, then the game', (
    t,
  ) async {
    final (c, source) = await pumpGame(t);
    await openArea(t, 'goblin_woods');
    await t.tap(option('travel', 'goblin_woods'));
    await settle(t, c);

    source.walk(DateTime(2026, 10, 18, 10), 300);
    now = DateTime(2026, 10, 18, 11);
    await c.resume();
    await t.pump();

    expect(find.text('While you were away'), findsOneWidget);
    expect(find.text('Today 11:00'), findsOneWidget);
    expect(find.text('You walked 300 steps.'), findsOneWidget);
    expect(find.text('Arrived at Goblin Woods.'), findsOneWidget);
    expect(find.text('Saved 100 steps in your step bank.'), findsOneWidget);
    expect(find.byType(HomeShell), findsNothing, reason: 'own screen');

    await t.tap(find.byKey(const ValueKey('away-continue')));
    await t.pump();
    expect(find.text('While you were away'), findsNothing);
    expect(find.byType(HomeShell), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('journal-button')));
    await t.pumpAndSettle();
    expect(find.text('Today 11:00'), findsOneWidget);
    expect(find.text('You walked 300 steps.'), findsOneWidget);
  });

  testWidgets('criterion 11: only banked steps show a short note', (t) async {
    final (c, source) = await pumpGame(t);
    // First Steps (an achievement) out of the way first.
    c.pause();
    source.walk(DateTime(2026, 10, 18, 9, 10), 150);
    now = DateTime(2026, 10, 18, 9, 20);
    await c.resume();
    c
      ..dismissAwaySummary()
      ..pause();
    source.walk(DateTime(2026, 10, 18, 10), 300);
    now = DateTime(2026, 10, 18, 11);
    await c.resume();
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('While you were away'), findsNothing);
    expect(find.byType(HomeShell), findsOneWidget);
    expect(
      find.text('You walked 300 steps. Saved 300 steps in your step bank.'),
      findsOneWidget,
    );
  });

  testWidgets('a single step reads as "1 step"', (t) async {
    final (c, source) = await pumpGame(t);
    await openArea(t, 'goblin_woods');
    await t.tap(option('travel', 'goblin_woods'));
    await settle(t, c);

    source.walk(DateTime(2026, 10, 18, 10), 1);
    now = DateTime(2026, 10, 18, 11);
    await c.resume();
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));

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
      await openArea(t, 'goblin_woods');
      expect(find.text('💀'), findsOneWidget, reason: 'the Old Bear');

      await t.tap(option('fight', 'old_bear'));
      await t.pumpAndSettle();
      expect(find.text('You will almost certainly lose.'), findsOneWidget);
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      expect(c.state.activity, isNull);

      await openArea(t, 'goblin_woods');
      await t.tap(option('fight', 'old_bear'));
      await t.pumpAndSettle();
      await t.tap(find.text('Fight anyway'));
      await settle(t, c);
      expect(c.state.activity!.activity, const Activity.fight('old_bear'));
    });

    testWidgets('a yellow fight starts without asking', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await openArea(t, 'goblin_woods');
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

      await openTab(t, 'character');
      await t.tap(find.byKey(const ValueKey('show-next-goal')));
      await settle(t, c);
      await openTab(t, 'now');
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
      await openArea(t, 'goblin_woods');
      expect(find.text('200 steps away'), findsOneWidget);
      expect(option('fight', 'goblin'), findsOneWidget);
    });

    testWidgets('below level 5 a tap starts at once', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await openArea(t, 'goblin_woods');
      await t.tap(option('fight', 'goblin'));
      await settle(t, c);
      expect(find.text('Stop when'), findsNothing);
      expect(c.state.activity!.activity, const Activity.fight('goblin'));
    });

    testWidgets('from level 5: pick a stop condition, start, then queue', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, level: 5, location: 'goblin_woods');
      await openArea(t, 'goblin_woods');
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

      await openArea(t, 'goblin_woods');
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
      await openTab(t, 'now');
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
      await openTab(t, 'craft');
      final tile = t.widget<ListTile>(option('craft', 'copper_sword'));
      expect(tile.enabled, isTrue);
    });
  });

  testWidgets('activity rows have no arrow: the whole row is the button', (
    t,
  ) async {
    await pumpGame(t, level: 3, location: 'goblin_woods');
    await openArea(t, 'goblin_woods');
    expect(option('fight', 'goblin'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  group('inventory', () {
    Future<void> openCharacter(WidgetTester t) => openTab(t, 'character');

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
      expect(before, [
        'Copper sword (Common)',
        'Hide vest (Common)',
        'Goblin hide',
      ], reason: 'gear first, then materials');

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
    testWidgets('counts and buttons line up in columns', (t) async {
      final (c, _) = await pumpGame(
        t,
        level: 3,
        inventory: {'goblin_hide': 3, 'copper_sword': 1, 'hide_vest': 2},
      );
      await c.equip('copper_sword');
      await openCharacter(t);
      await t.pumpAndSettle();
      expect(
        t.getTopRight(find.text('×3')).dx,
        t.getTopRight(find.text('×2')).dx,
        reason: 'a material count sits in the same column as a gear count',
      );
      Finder button(Finder label) => find
          .ancestor(of: label, matching: find.bySubtype<ButtonStyleButton>())
          .first;
      expect(
        t.getTopRight(button(find.text('Remove'))).dx,
        t.getTopRight(find.byKey(const ValueKey('equip-hide_vest'))).dx,
        reason: 'Remove and Equip end at the same edge',
      );
      expect(
        t.getSize(button(find.text('Remove'))).width,
        t.getSize(find.byKey(const ValueKey('equip-hide_vest'))).width,
        reason: 'Remove and Equip are the same size',
      );
    });
  });

  group('journal (spec 0004)', () {
    test('times read as today, yesterday, or a date', () {
      final now = DateTime(2026, 10, 18, 20);
      expect(journalTime(DateTime(2026, 10, 18, 14, 5), now), 'Today 14:05');
      expect(
        journalTime(DateTime(2026, 10, 17, 18, 30), now),
        'Yesterday 18:30',
      );
      expect(
        journalTime(DateTime(2026, 10, 16, 9, 12), now),
        'Fri 16 Oct 09:12',
      );
    });

    testWidgets('with nothing walked yet it says so', (t) async {
      await pumpGame(t);
      await t.tap(find.byKey(const ValueKey('journal-button')));
      await t.pumpAndSettle();
      expect(find.textContaining('No reports yet'), findsOneWidget);
    });

    testWidgets('lists entries newest first', (t) async {
      final (c, source) = await pumpGame(t);
      for (final (hour, steps) in [(10, 120), (12, 340)]) {
        c
          ..dismissAwaySummary()
          ..pause();
        source.walk(DateTime(2026, 10, 18, hour - 1), steps);
        now = DateTime(2026, 10, 18, hour);
        await c.resume();
      }
      await t.pump();
      await t.tap(find.byKey(const ValueKey('journal-button')));
      await t.pumpAndSettle();
      final first = t.getTopLeft(find.text('Today 12:00')).dy;
      final second = t.getTopLeft(find.text('Today 10:00')).dy;
      expect(first, lessThan(second));
      expect(find.text('You walked 340 steps.'), findsOneWidget);
      expect(find.text('You walked 120 steps.'), findsOneWidget);
    });
  });

  group('test walk (spec 0004 §3)', () {
    final rank = find.text('Recruit');
    final card = find.byKey(const ValueKey('test-walk'));

    Future<void> tapRank(WidgetTester t, int times) async {
      for (var i = 0; i < times; i++) {
        await t.tap(rank);
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.pumpAndSettle();
    }

    testWidgets('criterion 4: seven taps on the rank switch it on and off', (
      t,
    ) async {
      final (c, _) = await pumpGame(t);
      await openTab(t, 'character');
      await tapRank(t, 6);
      expect(c.testWalkOn, isFalse, reason: 'six is not enough');
      await tapRank(t, 1);
      expect(c.testWalkOn, isTrue);
      expect(find.text('Test walk on'), findsOneWidget);

      await openTab(t, 'now');
      expect(card, findsOneWidget);

      await openTab(t, 'character');
      await tapRank(t, 7);
      expect(c.testWalkOn, isFalse);
      await openTab(t, 'now');
      expect(card, findsNothing);
    });

    testWidgets(
      'criterion 5: +1,000 walks 1,000 steps, marked in the journal',
      (t) async {
        final (c, source) = await pumpGame(t);
        // First Steps (an achievement) out of the way first.
        c.pause();
        source.walk(DateTime(2026, 10, 18, 8, 50), 150);
        await c.resume();
        c.dismissAwaySummary();
        await c.setTestWalk(true);
        await t.pump();
        await t.tap(find.descendant(of: card, matching: find.text('+1,000')));
        await settle(t, c);
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
        expect(c.state.bank, 1150, reason: 'resting: 150 + 1,000 banked');
        expect(
          find.textContaining('You walked 1,000 steps.'),
          findsOneWidget,
          reason: 'only banked: a note',
        );

        await t.tap(find.byKey(const ValueKey('journal-button')));
        await t.pumpAndSettle();
        expect(find.text('Today 09:00 (test walk)'), findsOneWidget);
      },
    );
  });

  group('achievements tab', () {
    testWidgets('Travelling Salesman reads as a goal, not a counter name', (
      t,
    ) async {
      await pumpGame(t);
      await openTab(t, 'achievements');
      expect(find.text('Travelling Salesman'), findsOneWidget);
      expect(find.text('Arrive at all 10 areas'), findsOneWidget);
    });

    testWidgets('no achievement shows a raw counter name', (t) async {
      await pumpGame(t);
      await openTab(t, 'achievements');
      for (final a in game.data.achievements.values) {
        expect(
          find.textContaining(a.counter),
          findsNothing,
          reason: '${a.id} shows "${a.counter}"',
        );
      }
    });
  });

  group('item qualities (spec 0005 criterion 9)', () {
    final labels = Labels(game.data);

    test('names read "Bone sword (Rare)"; common and materials stay plain', () {
      expect(labels.item('bone_sword@rare'), 'Bone sword (Rare)');
      expect(labels.item('bone_sword@legendary'), 'Bone sword (Legendary)');
      expect(labels.item('bone_sword'), 'Bone sword');
      expect(labels.item('bones'), 'Bones');
    });

    test('the report names the quality', () {
      final lines = labels.actionLines(
        const ActionLog(
          Activity.craft('hide_vest'),
          xp: 30,
          items: {'hide_vest': 1, 'hide_vest@rare': 1},
        ),
      );
      expect(
        lines.single,
        contains('Hide vest (Common) ×1, Hide vest (Rare) ×1'),
      );
    });

    testWidgets('each quality is its own row, in colour, with its stats', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        level: 3,
        inventory: {'hide_vest@rare': 2, 'hide_vest': 1},
      );
      await openTab(t, 'character');
      final rows = t
          .widgetList<ListTile>(find.byKey(const ValueKey('inventory-item')))
          .map((tile) => (tile.title! as Text).data!)
          .toList();
      expect(rows, ['Hide vest (Common)', 'Hide vest (Rare)']);

      final rare = t.widget<Text>(find.text('Hide vest (Rare)'));
      expect(rare.style?.color, const Color(0xff42a5f5));
      expect(find.text('+4 Defense · +14 HP'), findsOneWidget);
      expect(find.text('+2 Defense · +10 HP'), findsOneWidget);

      await t.tap(find.byKey(const ValueKey('equip-hide_vest@rare')));
      await settle(t, c);
      expect(c.state.equipment['body'], 'hide_vest@rare');
      expect(
        find.text('Hide vest (Rare)'),
        findsNWidgets(2),
        reason: 'equipped, and one left in the inventory',
      );
    });
  });

  test('every gear item in every quality equips, saves and has a name', () {
    final labels = Labels(game.data);
    for (final item in game.data.items.values.where((i) => i.slot != null)) {
      for (final q in game.data.qualities) {
        final key = game.data.keyFor(item.id, q.id);
        var s = game.newGame(seed: 1)
          ..xp = game.data.xpForLevel(30)
          ..inventory[key] = 1;
        s = game.equip(s, key);
        expect(s.equipment[item.slot], key);
        expect(game.owned(s, item.id), 1);
        expect(game.stats(s).hp, greaterThan(0));
        final back = GameState.fromJson(s.toJson());
        expect(back.equipment[item.slot], key);
        expect(labels.item(key), startsWith(item.name));
        expect(labels.item(key), isNot(contains('@')));
      }
    }
  });

  testWidgets('common gear and materials have different colours', (t) async {
    await pumpGame(t, level: 3, inventory: {'hide_vest': 1, 'goblin_hide': 3});
    await openTab(t, 'character');
    final scheme = Theme.of(t.element(find.text('Hide vest (Common)')))
        .colorScheme;
    Color? colour(String text) => t.widget<Text>(find.text(text)).style?.color;
    expect(
      colour('Hide vest (Common)'),
      scheme.onSurface,
      reason: 'common gear',
    );
    expect(colour('Goblin hide'), scheme.onSurfaceVariant, reason: 'material');
    expect(colour('Hide vest (Common)'), isNot(colour('Goblin hide')));
  });

  group('quality colour in reports', () {
    const line =
        'Crafted the Hide vest: +30 XP, Hide vest (Common) ×1, '
        'Hide vest (Rare) ×1, Bear-pelt cloak (Legendary) ×1.';

    test('better-than-common gear is coloured; the rest stays plain', () {
      final spans = reportSpans(line, game.data);
      expect(spans.map((s) => s.text).join(), line, reason: 'nothing lost');
      Color? colourOf(String text) =>
          spans.firstWhere((s) => s.text == text).style?.color;
      expect(colourOf('Hide vest (Rare)'), const Color(0xff42a5f5));
      expect(colourOf('Bear-pelt cloak (Legendary)'), const Color(0xffff9800));
      expect(spans.where((s) => s.style?.color != null).map((s) => s.text), [
        'Hide vest (Rare)',
        'Bear-pelt cloak (Legendary)',
      ]);
    });

    testWidgets('the report card and the journal draw it', (t) async {
      final (c, source) = await pumpGame(
        t,
        level: 3,
        inventory: {'goblin_hide': 4 * 30},
      );
      await c.startActivity(const Activity.craft('hide_vest'));
      c.pause();
      source.walk(DateTime(2026, 10, 18, 10), 150 * 30);
      now = DateTime(2026, 10, 18, 11);
      await c.resume();
      await t.pump();
      if (c.levelCards.isNotEmpty) {
        c.dismissLevelCards();
        await t.pump();
      }
      bool coloured(Widget w) {
        if (w is! RichText) return false;
        if (!w.text.toPlainText().contains('Hide vest (')) return false;
        var found = false;
        w.text.visitChildren((span) {
          if (span is TextSpan &&
              span.style?.color != null &&
              (span.text ?? '').contains('Hide vest (')) {
            found = true;
          }
          return !found;
        });
        return found;
      }

      expect(find.byWidgetPredicate(coloured), findsWidgets);

      await t.tap(find.byKey(const ValueKey('away-continue')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('journal-button')));
      await t.pumpAndSettle();
      expect(find.byWidgetPredicate(coloured), findsWidgets);
    });
  });

  group('banners for achievements and levels (spec 0004 amendment 3)', () {
    testWidgets('on the screen and in the journal, not as plain lines', (
      t,
    ) async {
      final (c, source) = await pumpGame(t, location: 'goblin_woods');
      await c.startActivity(const Activity.fight('goblin'));
      c.pause();
      source.walk(DateTime(2026, 10, 18, 10), 300);
      now = DateTime(2026, 10, 18, 11);
      await c.resume();
      await t.pump();
      if (c.levelCards.isNotEmpty) {
        c.dismissLevelCards();
        await t.pump();
      }
      expect(c.awaySummary!.achievements, contains('first_steps'));
      expect(c.awaySummary!.levelsReached, contains(2));

      final banners = find.byKey(const ValueKey('report-banner'));
      Finder banner(String text) =>
          find.descendant(of: banners, matching: find.text(text));
      expect(banner('Achievement unlocked: First Steps'), findsOneWidget);
      expect(banner('Reached level 2!'), findsOneWidget);
      expect(
        find.descendant(of: banners, matching: find.byIcon(Icons.emoji_events)),
        findsWidgets,
      );
      expect(find.textContaining('Achievement:'), findsNothing);

      final first = t.getTopLeft(banner('Reached level 2!')).dy;
      final line = t.getTopLeft(find.text('You walked 300 steps.')).dy;
      expect(first, lessThan(line), reason: 'banners come first');

      await t.tap(find.byKey(const ValueKey('away-continue')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('journal-button')));
      await t.pumpAndSettle();
      expect(banner('Achievement unlocked: First Steps'), findsOneWidget);
      expect(banner('Reached level 2!'), findsOneWidget);
    });
  });

  testWidgets('equipped gear shows its stats, like the inventory', (t) async {
    final (c, _) = await pumpGame(
      t,
      level: 3,
      inventory: {'hide_vest@rare': 1, 'copper_sword': 1},
    );
    await c.equip('hide_vest@rare');
    await c.equip('copper_sword');
    await openTab(t, 'character');
    expect(find.text('Body · +4 Defense · +14 HP'), findsOneWidget);
    expect(find.text('Weapon · +3 Attack'), findsOneWidget);
  });
}

void moreScreens() {
  group('more screens (spec 0006)', () {
    testWidgets('criterion 1: the bottom bar; it opens on Now', (t) async {
      await pumpGame(t);
      for (final s in ['now', 'map', 'character', 'achievements']) {
        expect(find.byKey(ValueKey('tab-$s')), findsOneWidget, reason: s);
      }
      expect(
        find.byKey(const ValueKey('tab-craft')),
        findsNothing,
        reason: 'no recipe before level 3',
      );
      expect(find.byKey(const ValueKey('walked-today')), findsOneWidget);
      for (final s in ['map', 'character', 'achievements', 'now']) {
        await openTab(t, s);
        expect(find.byKey(const ValueKey('journal-button')), findsOneWidget);
      }
    });

    testWidgets('craft opens with the first recipe', (t) async {
      await pumpGame(t, level: 3);
      await openTab(t, 'craft');
      expect(find.text('At the forge (Camp)'), findsOneWidget);
    });

    testWidgets('resting: a button opens the map', (t) async {
      await pumpGame(t);
      await t.tap(find.byKey(const ValueKey('open-map')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('area-goblin_woods')), findsOneWidget);
    });

    testWidgets('criteria 3 and 4: the fight log and the tally', (t) async {
      final (c, source) = await pumpGame(t, level: 3, location: 'goblin_woods');
      await c.startActivity(
        const Activity.fight('goblin'),
        stop: const StopCondition.never(),
      );
      source.walk(DateTime(2026, 10, 18, 9, 5), 400);
      now = DateTime(2026, 10, 18, 9, 30);
      await c.syncNow();
      await t.pump();
      final log = find.byKey(const ValueKey('fight-log'));
      expect(
        find.descendant(of: log, matching: find.textContaining('Round ')),
        findsNWidgets(game.data.fightLogRounds),
      );
      final run = c.state.activity!;
      expect(run.won, greaterThan(0));
      expect(find.text('${run.won} won · ${run.lost} lost'), findsOneWidget);
      expect(find.byKey(const ValueKey('tally-items')), findsOneWidget);
    });

    testWidgets('criterion 8: craft until a quality from the sheet', (t) async {
      final (c, _) = await pumpGame(t, level: 5, inventory: {'copper_ore': 50});
      await openTab(t, 'craft');
      await t.tap(option('craft', 'copper_sword'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('stop-untilQuality')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('quality-epic')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('start-now')));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.activity!.stop, const StopCondition.untilQuality('epic'));
      await openTab(t, 'now');
      expect(find.text('Until Epic or better'), findsOneWidget);
    });

    testWidgets('criterion 9: owned/needed and the nearest forge', (t) async {
      await pumpGame(
        t,
        level: 3,
        location: 'goblin_woods',
        inventory: {'copper_ore': 2},
      );
      await openTab(t, 'craft');
      expect(find.text('Nearest forge: Camp · 200 steps away'), findsOneWidget);
      expect(
        find.textContaining('Copper ore 2/5', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('criterion 10: Gear, then Materials', (t) async {
      await pumpGame(
        t,
        level: 3,
        inventory: {'goblin_hide': 3, 'hide_vest': 1},
      );
      await openTab(t, 'character');
      final gear = find.byKey(const ValueKey('heading-gear'));
      final materials = find.byKey(const ValueKey('heading-materials'));
      expect(t.getTopLeft(gear).dy, lessThan(t.getTopLeft(materials).dy));
    });

    testWidgets('no Gear heading without gear', (t) async {
      await pumpGame(t, inventory: {'goblin_hide': 3});
      await openTab(t, 'character');
      expect(find.byKey(const ValueKey('heading-gear')), findsNothing);
      expect(find.byKey(const ValueKey('heading-materials')), findsOneWidget);
    });
  });
}

void theMap() {
  group('the map (spec 0006 §2.2)', () {
    Finder inArea(String area, String text) => find.descendant(
      of: find.byKey(ValueKey('area-$area')),
      matching: find.text(text),
    );

    testWidgets('criterion 5: above your level is fog, named ???', (t) async {
      await pumpGame(t);
      await openTab(t, 'map');
      expect(inArea('goblin_woods', 'Goblin Woods'), findsOneWidget);
      for (final a in ['copper_hills', 'old_graveyard', 'dragons_peak']) {
        expect(inArea(a, '???'), findsOneWidget, reason: a);
      }
      expect(find.text('Old Graveyard'), findsNothing);
      await openArea(t, 'old_graveyard');
      expect(
        find.text('Thick fog. The Guild opens this road at level 6.'),
        findsOneWidget,
      );
      expect(find.text('Skeleton'), findsNothing);
    });

    testWidgets('at level 10 the fog has lifted', (t) async {
      await pumpGame(t, level: 10);
      await openTab(t, 'map');
      expect(find.text('???'), findsNothing);
      expect(inArea('dragons_peak', "Dragon's Peak"), findsOneWidget);
    });

    testWidgets('criterion 6: only found drops, no chances', (t) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        counters: {'found.goblin.goblin_hide': 1},
      );
      await openArea(t, 'goblin_woods');
      expect(
        find.textContaining('Drops: Goblin hide, ??? · 1 of 2 found'),
        findsOneWidget,
      );
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('a fight starts from the sheet, which closes', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await openArea(t, 'goblin_woods');
      await t.tap(option('fight', 'goblin'));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(c.state.activity!.activity, const Activity.fight('goblin'));
    });

    testWidgets('travel to a far place from its sheet', (t) async {
      final (c, _) = await pumpGame(t, level: 6);
      await openArea(t, 'old_graveyard');
      expect(find.text('500 steps away'), findsOneWidget);
      await t.tap(option('travel', 'old_graveyard'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('start-now')));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(
        c.state.activity!.activity,
        const Activity.travel('old_graveyard'),
      );
    });
  });
}

void mapGaps() {
  testWidgets('spec 0006 criterion 2: mining starts from the map', (t) async {
    final (c, _) = await pumpGame(t, level: 2, location: 'copper_hills');
    await openArea(t, 'copper_hills');
    await t.tap(option('gather', 'copper_vein'));
    await settle(t, c);
    expect(c.state.activity!.activity, const Activity.gather('copper_vein'));
  });

  testWidgets('spec 0006 criterion 5: paths into the fog have no count', (
    t,
  ) async {
    await pumpGame(t);
    await openTab(t, 'map');
    final painter = t
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<MapPainter>()
        .single;
    final labels = [for (final p in painter.paths) p.$3];
    final open = [
      for (final r in game.data.routes)
        game.data.locations[r.from]!.unlockLevel <= 1 &&
            game.data.locations[r.to]!.unlockLevel <= 1,
    ];
    for (var i = 0; i < labels.length; i++) {
      expect(labels[i] == null, !open[i], reason: game.data.routes[i].to);
    }
    expect(labels, contains('200'), reason: 'Camp to Goblin Woods');
  });
}
