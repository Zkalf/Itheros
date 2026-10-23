// Screens: locked systems are hidden, not greyed out (spec 0001 acceptance
// criterion 8), plus the permission flow, starting activities and the
// "while you were away" card. In-memory storage keeps real I/O out of the
// fake-async test zone.
import 'dart:convert';
import 'dart:io';

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
import 'package:walkingrpg/ui/item_square.dart';
import 'package:walkingrpg/ui/journal_screen.dart';
import 'package:walkingrpg/ui/labels.dart';
import 'package:walkingrpg/ui/world_tab.dart';
import 'package:walkingrpg/version.dart';

import 'support.dart';

final _game = loadTestGame();

/// The real game data; tests that need other items pass `withGame`.
Game get game => _game;
late DateTime now;

/// The character tests play as unless they say otherwise: a Tavern cook,
/// so no other test meets a kin line (spec 0012 §3.1).
const ada = Character(
  name: 'Ada',
  gender: Gender.neither,
  origin: 'tavern_cook',
);

Finder option(String kind, String target) =>
    find.byKey(ValueKey('option-$kind-$target'));

Future<(GameController, FakeStepSource)> pumpGame(
  WidgetTester tester, {
  int level = 1,
  int? xp,
  String location = 'camp',
  Map<String, int> inventory = const {},
  Map<String, int> counters = const {},
  Map<String, String> equipment = const {},
  bool granted = true,
  bool testWalkAllowed = true,
  bool learned = true,
  int? professionLevel,
  Game? withGame,
  Character? character = ada,
}) async {
  final game = withGame ?? _game;
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  now = DateTime(2026, 10, 18, 9);

  final source = FakeStepSource(granted: granted);
  final state = game.newGame(seed: 1)
    ..xp = xp ?? game.data.xpForLevel(level)
    ..location = location
    ..explored.add(location)
    ..inventory.addAll(inventory)
    ..counters.addAll(counters)
    ..equipment.addAll(equipment)
    ..character = character;
  // Every profession learned at the character's level (spec 0010), unless
  // the test says otherwise.
  if (learned) {
    for (final p in game.data.professions.values) {
      state
        ..learned.add(p.id)
        ..tools[p.id] = p.teacher.starterTool
        ..professions[p.id] = game.data.professionXpForLevel(
          professionLevel ?? level,
        );
    }
  }
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
    testWalkAllowed: testWalkAllowed,
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(WalkingRpgApp(controller: c));
  await c.start();
  await tester.pump();
  return (c, source);
}

/// Opens a bottom bar screen: now, world, professions, character.
Future<void> openTab(WidgetTester tester, String screen) async {
  await tester.tap(find.byKey(ValueKey('tab-$screen')));
  await tester.pumpAndSettle();
}

/// Opens the World map and taps [area] on it.
Future<void> openArea(WidgetTester tester, String area) async {
  if (find.byKey(ValueKey('area-$area')).evaluate().isEmpty) {
    await openTab(tester, 'world');
  }
  await tester.tap(find.byKey(ValueKey('area-$area')));
  await tester.pumpAndSettle();
}

/// Opens Achievements from the trophy button (spec 0006 amendment 2).
Future<void> openAchievements(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('achievements-button')));
  await tester.pumpAndSettle();
}

/// Opens Settings from the top bar (spec 0008 decision 12).
Future<void> openSettings(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('settings-button')));
  await tester.pumpAndSettle();
}

/// Closes an open bottom sheet.
Future<void> closeSheet(WidgetTester tester) async {
  await tester.tapAt(const Offset(5, 5));
  await tester.pumpAndSettle();
}

/// Taps [action], then Start now on the stop condition sheet, which opens
/// from level 1 now that the queue has 3 slots (spec 0008 decision 7).
Future<void> tapAndStart(WidgetTester tester, Finder action) async {
  await tester.tap(action);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('start-now')));
  await tester.pumpAndSettle();
}

Future<void> settle(WidgetTester tester, GameController c) async {
  await c.idle();
  await tester.pump();
}

void main() {
  professionFilters();
  playtest3();
  yourCharacter();
  lakeAndHunt();
  professionScreens();
  fightsWithDepth();
  characterScreen();
  layoutScreens();
  playtest2();
  moreScreens();
  theMap();
  mapGaps();
  // Spec 0008 replaced the level gates: areas open by exploring, recipes and
  // veins show with the level they need (amendments 1 and 2).
  group('criterion 8: what shows at a level (spec 0008)', () {
    testWidgets('level 1 at camp: neighbours open, fog beyond, recipes shown', (
      t,
    ) async {
      await pumpGame(t);
      await openArea(t, 'copper_hills');
      expect(option('travel', 'copper_hills'), findsOneWidget);
      await closeSheet(t);
      await openArea(t, 'grey_moor');
      expect(option('travel', 'grey_moor'), findsNothing);
      expect(find.textContaining('Thick fog'), findsOneWidget);
      await closeSheet(t);
      await openTab(t, 'professions');
      // Spec 0010: the first recipes need Crafting 1, the rest more.
      final sword = t.widget<ListTile>(option('craft', 'copper_sword'));
      expect(sword.enabled, isTrue);
      final iron = t.widget<ListTile>(option('craft', 'iron_sword'));
      expect(iron.enabled, isFalse, reason: 'needs Crafting 14');
      expect(
        find.textContaining('Iron sword needs Crafting 14', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('level 1 in Goblin Woods: every monster there', (t) async {
      await pumpGame(t, location: 'goblin_woods');
      await openArea(t, 'goblin_woods');
      expect(option('fight', 'goblin'), findsOneWidget);
      expect(option('fight', 'goblin_brute'), findsOneWidget);
      expect(find.text('Gather'), findsNothing);
    });

    // Spec 0010 decision 9: a profession is learned from its teacher first.
    testWidgets('at Copper Hills before learning Mining: whom to learn from', (
      t,
    ) async {
      await pumpGame(t, location: 'copper_hills', learned: false);
      await openArea(t, 'copper_hills');
      final vein = t.widget<ListTile>(option('gather', 'copper_vein'));
      expect(vein.enabled, isFalse);
      expect(find.text('Learn Mining from Hilde in Camp'), findsOneWidget);
    });

    testWidgets('level 2 shows Copper Hills and mining there', (t) async {
      await pumpGame(t, level: 2, location: 'copper_hills');
      await openArea(t, 'copper_hills');
      expect(option('gather', 'copper_vein'), findsOneWidget);
      await closeSheet(t);
      await openArea(t, 'camp');
      expect(option('travel', 'camp'), findsOneWidget);
    });

    testWidgets('level 3 can craft at camp', (t) async {
      await pumpGame(t, level: 3, inventory: {'copper_ore': 5});
      await openTab(t, 'professions');
      final sword = t.widget<ListTile>(option('craft', 'copper_sword'));
      expect(sword.enabled, isTrue);
      final vest = t.widget<ListTile>(option('craft', 'hide_vest'));
      expect(vest.enabled, isTrue, reason: 'queueable before its hides');
    });
  });

  testWidgets('tapping a destination starts walking there', (t) async {
    final (c, _) = await pumpGame(t);
    await openArea(t, 'goblin_woods');
    await tapAndStart(t, option('travel', 'goblin_woods'));
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
    await tapAndStart(t, option('travel', 'goblin_woods'));
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

    // A new game asks who you are first (spec 0012 decision 6).
    expect(find.text('Who are you?'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('origin-coast_fisher')));
    await t.pump();
    await t.tap(find.byKey(const ValueKey('set-out')));
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
    await tapAndStart(t, option('travel', 'goblin_woods'));
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
    await tapAndStart(t, option('travel', 'goblin_woods'));
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
      // Recipes are Crafting news now (spec 0010 §2.2).
      expect(find.text('The Goblin brute is now your level'), findsOneWidget);

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
      // It names the player (spec 0012 decision 5).
      expect(
        find.text(
          'The Guild names you Adventurer, Ada. The lands beyond the river '
          'know your name.',
        ),
        findsOneWidget,
      );
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
      await tapAndStart(t, find.text('Fight anyway'));
      await settle(t, c);
      expect(c.state.activity!.activity, const Activity.fight('old_bear'));
    });

    testWidgets('a yellow fight starts without asking', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await openArea(t, 'goblin_woods');
      await tapAndStart(t, option('fight', 'goblin'));
      await settle(t, c);
      expect(find.text('Deadly'), findsNothing);
      expect(c.state.activity!.activity, const Activity.fight('goblin'));
    });

    // With Crafting 1 the copper gear comes first (spec 0010 amendment 1),
    // so this player wears it already.
    testWidgets('"Next goal" shows at level 1', (t) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        equipment: {'mainHand': 'copper_sword', 'chest': 'hide_vest'},
      );
      expect(find.byKey(const ValueKey('next-goal')), findsOneWidget);
      expect(
        find.text('The Goblin in Goblin Woods is your level.'),
        findsOneWidget,
      );
    });

    testWidgets('from level 1 it can be hidden and turned back on', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      expect(find.byKey(const ValueKey('next-goal')), findsOneWidget);
      await t.tap(find.text('Hide'));
      await settle(t, c);
      expect(find.byKey(const ValueKey('next-goal')), findsNothing);

      await openSettings(t);
      await t.tap(find.byKey(const ValueKey('show-next-goal')));
      await settle(t, c);
      await t.pageBack();
      await t.pumpAndSettle();
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

    testWidgets('from level 1: pick a stop condition, start, then queue', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        location: 'goblin_woods',
        counters: {'found.goblin_brute.goblin_hide': 1},
      );
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
      // Both are real buttons, side by side: Start now left, Add to queue
      // right.
      final startNow = find.byKey(const ValueKey('start-now'));
      final addToQueue = find.byKey(const ValueKey('add-to-queue'));
      expect(t.widget(startNow), isA<FilledButton>());
      expect(t.widget(addToQueue), isA<FilledButton>());
      expect(t.getCenter(startNow).dx, lessThan(t.getCenter(addToQueue).dx));
      expect(t.getCenter(startNow).dy, t.getCenter(addToQueue).dy);
      await t.tap(addToQueue);
      await settle(t, c);
      await t.pumpAndSettle();
      expect(
        c.state.queue.single.activity,
        const Activity.fight('goblin_brute'),
      );
      expect(c.state.queue.single.stop.kind, StopKind.untilHave);
      await openTab(t, 'now');
      expect(find.byKey(const ValueKey('queued-0')), findsOneWidget);
      expect(find.text('2 of 3 actions planned'), findsOneWidget);

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
        // One hide: with misses (spec 0009 §2.1) this seed's 400 steps
        // bring only one.
        stop: StopCondition.untilHave('goblin_hide', 1),
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
      await openTab(t, 'professions');
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

    testWidgets('a friend build has no test walk (spec 0007 §4)', (t) async {
      final (c, _) = await pumpGame(t, testWalkAllowed: false);
      await openTab(t, 'character');
      await tapRank(t, 7);
      expect(c.testWalkOn, isFalse);
      expect(find.text('Test walk on'), findsNothing);

      await c.setTestWalk(true);
      await openTab(t, 'now');
      expect(card, findsNothing, reason: 'an old save with it on');
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

  testWidgets('Settings show the version from level 1 (spec 0007 §7)', (
    t,
  ) async {
    await pumpGame(t);
    await openSettings(t);
    expect(find.text('Version $appVersion'), findsOneWidget);
  });

  group('achievements tab', () {
    testWidgets('Travelling Salesman reads as a goal, not a counter name', (
      t,
    ) async {
      await pumpGame(t);
      await openAchievements(t);
      expect(find.text('Travelling Salesman'), findsOneWidget);
      // The hidden cove is a bonus (owner's choice, plan 0013 M1).
      expect(find.text('Arrive at all 11 areas'), findsOneWidget);
    });

    testWidgets('no achievement shows a raw counter name', (t) async {
      await pumpGame(t);
      await openAchievements(t);
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
        // Rings and trinkets fill their first slot (ring1, trinket1).
        final slot = game.slotsFor(key).first;
        expect(s.equipment[slot], key);
        expect(game.owned(s, item.id), 1);
        expect(game.stats(s).hp, greaterThan(0));
        final back = GameState.fromJson(s.toJson());
        expect(back.equipment[slot], key);
        expect(labels.item(key), startsWith(item.name));
        expect(labels.item(key), isNot(contains('@')));
      }
    }
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
}

void moreScreens() {
  group('more screens (spec 0006)', () {
    // Spec 0008 criterion 1 replaces spec 0006 criterion 1.
    testWidgets('spec 0008 criterion 1: four buttons, the top bar, Now first', (
      t,
    ) async {
      await pumpGame(t);
      final bar = t.widget<NavigationBar>(find.byType(NavigationBar));
      expect(
        [for (final d in bar.destinations) (d as NavigationDestination).label],
        ['Now', 'World', 'Professions', 'Character'],
      );
      expect(find.byKey(const ValueKey('walked-today')), findsOneWidget);
      for (final s in ['world', 'professions', 'character', 'now']) {
        await openTab(t, s);
        for (final b in ['journal', 'achievements', 'settings']) {
          expect(
            find.byKey(ValueKey('$b-button')),
            findsOneWidget,
            reason: '$b on $s',
          );
        }
      }
    });

    testWidgets('amendment 2: a dot marks a new achievement until opened', (
      t,
    ) async {
      final (c, source) = await pumpGame(t, location: 'goblin_woods');
      bool dot() => t
          .widget<Badge>(find.byKey(const ValueKey('achievements-dot')))
          .isLabelVisible;
      expect(dot(), isFalse);

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
      c.dismissAwaySummary();
      await t.pumpAndSettle();
      expect(c.state.achievements, contains('first_steps'));
      expect(dot(), isTrue);

      await openAchievements(t);
      await settle(t, c);
      expect(find.text('Achievements'), findsWidgets);
      await t.pageBack();
      await t.pumpAndSettle();
      expect(dot(), isFalse);
    });

    testWidgets('Professions holds crafting and the forge', (t) async {
      await pumpGame(t, level: 3);
      await openTab(t, 'professions');
      expect(find.text('At the forge (Camp)'), findsOneWidget);
    });

    testWidgets('resting: a button opens the World map', (t) async {
      await pumpGame(t);
      expect(find.textContaining('or on the World map'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('open-world')));
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
      await openTab(t, 'professions');
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
      await openTab(t, 'professions');
      expect(find.text('Nearest forge: Camp · 200 steps away'), findsOneWidget);
      // The copper sword, spear and mace (spec 0009 §4.1).
      expect(
        find.textContaining('Copper ore 2/5', findRichText: true),
        findsNWidgets(3),
      );
    });
  });
}

void theMap() {
  group('the map (spec 0006 §2.2)', () {
    Finder inArea(String area, String text) => find.descendant(
      of: find.byKey(ValueKey('area-$area')),
      matching: find.text(text),
    );

    // Spec 0008 decision 5: fog lifts by exploring, not by level.
    testWidgets('criterion 5: away from explored areas is fog, named ???', (
      t,
    ) async {
      await pumpGame(t, level: 30);
      await openTab(t, 'world');
      expect(inArea('old_graveyard', 'Old Graveyard'), findsOneWidget);
      for (final a in ['grey_moor', 'iron_ridge', 'dragons_peak']) {
        expect(inArea(a, '???'), findsOneWidget, reason: a);
      }
      expect(find.text('Grey Moor'), findsNothing);
      await openArea(t, 'grey_moor');
      expect(
        find.text(
          "Thick fog. Walk to a neighbouring area to see what's there.",
        ),
        findsOneWidget,
      );
      expect(find.text('Wolf'), findsNothing);
    });

    testWidgets('exploring lifts the fog next door', (t) async {
      await pumpGame(t, location: 'old_graveyard');
      await openTab(t, 'world');
      expect(inArea('grey_moor', 'Grey Moor'), findsOneWidget);
      expect(inArea('iron_ridge', '???'), findsOneWidget);
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
      await tapAndStart(t, option('fight', 'goblin'));
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
    await tapAndStart(t, option('gather', 'copper_vein'));
    await settle(t, c);
    expect(c.state.activity!.activity, const Activity.gather('copper_vein'));
  });

  testWidgets('spec 0006 criterion 5: paths into the fog have no count', (
    t,
  ) async {
    await pumpGame(t);
    await openTab(t, 'world');
    final painter = t
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((p) => p.painter)
        .whereType<MapPainter>()
        .single;
    final labels = [for (final p in painter.paths) p.$3];
    final fresh = game.newGame(seed: 1);
    final open = [
      for (final r in game.data.routes)
        !game.isFogged(fresh, r.from) && !game.isFogged(fresh, r.to),
    ];
    for (var i = 0; i < labels.length; i++) {
      expect(labels[i] == null, !open[i], reason: game.data.routes[i].to);
    }
    expect(labels, contains('200'), reason: 'Camp to Goblin Woods');
  });
}

/// Owner's second playtest notes (2026-10-20).
void playtest2() {
  group('playtest 2', () {
    testWidgets('pages opened from the top bar stay above the phone buttons', (
      t,
    ) async {
      await pumpGame(t);
      // The phone's own back/home/recent buttons cover the bottom 150 px.
      t.view.padding = const FakeViewPadding(bottom: 150);
      t.view.viewPadding = const FakeViewPadding(bottom: 150);
      t.view.physicalSize = const Size(1080, 1200);
      await t.pumpAndSettle();
      await openAchievements(t);
      // At the top, nothing of the list may show behind the buttons.
      expect(
        t.getRect(find.byType(ListView)).bottom,
        lessThanOrEqualTo(1200 - 150),
      );
      await t.drag(find.byType(ListView), const Offset(0, -5000));
      await t.pumpAndSettle();
      final last = game.data.achievements.values.last.name;
      expect(
        t.getBottomLeft(find.text(last)).dy,
        lessThanOrEqualTo(1200 - 150),
        reason: 'the last achievement hides behind the phone buttons',
      );
    });

    testWidgets('"until I have N" offers only drops already found', (t) async {
      await pumpGame(t, level: 8, location: 'old_graveyard');
      await openArea(t, 'old_graveyard');
      await t.tap(option('fight', 'zombie'));
      await t.pumpAndSettle();
      expect(find.text('Stop when'), findsOneWidget);
      expect(find.byKey(const ValueKey('stop-untilHave')), findsNothing);
      expect(find.text('Grave cloth'), findsNothing);
    });

    testWidgets('a found drop is offered, an unfound one is not', (t) async {
      await pumpGame(
        t,
        level: 5,
        location: 'goblin_woods',
        counters: {'kills.goblin': 3, 'found.goblin.goblin_hide': 1},
      );
      await openArea(t, 'goblin_woods');
      await t.tap(option('fight', 'goblin'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('stop-untilHave')));
      await t.pumpAndSettle();
      await t.tap(find.byType(DropdownButton<String>));
      await t.pumpAndSettle();
      expect(find.text('Goblin hide'), findsWidgets);
      expect(find.text('Rusty dagger'), findsNothing);
    });

    testWidgets('nothing can be queued behind an action that never stops', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, level: 8, location: 'copper_hills');
      await c.addAction(const Activity.gather('copper_vein'));
      await settle(t, c);
      expect(c.state.activity!.stop.kind, StopKind.never);
      await openArea(t, 'goblin_woods');
      await t.tap(option('fight', 'goblin_brute'));
      await t.pumpAndSettle();
      expect(find.text('Stop when'), findsOneWidget);
      expect(find.byKey(const ValueKey('add-to-queue')), findsNothing);
      expect(find.byKey(const ValueKey('start-now')), findsOneWidget);
    });

    testWidgets('"Next goal" only says "your level" when it is', (t) async {
      // Level 9: with misses and types counted (spec 0009 §2–§3), the
      // level 8 Zombie gives the most XP, one level below.
      await pumpGame(
        t,
        level: 9,
        location: 'old_graveyard',
        equipment: {
          'mainHand': 'kings_blade',
          'chest': 'stitched_armour',
          'offHand': 'bone_shield',
          // Spec 0011 §7's first pieces, so Next goal is a fight.
          'gloves': 'deer_hide_gloves',
          'bracer': 'deer_hide_bracers',
          'belt': 'deer_hide_belt',
          'legs': 'lake_scale_greaves',
        },
      );
      expect(find.byKey(const ValueKey('next-goal')), findsOneWidget);
      expect(find.textContaining('Old Graveyard is your level'), findsNothing);
      expect(
        find.text(
          'The Zombie in Old Graveyard gives the most XP for your steps.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('is your level'), findsNothing);
    });
  });
}

/// Spec 0008 §3 (plan 0010 M2): Now's "Here" section and Settings.
void layoutScreens() {
  group('layout screens (spec 0008 §3)', () {
    Finder here(Finder f) =>
        find.descendant(of: find.byKey(const ValueKey('here')), matching: f);

    testWidgets('Now lists what this place offers, and starts it', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      expect(find.text('Here: Goblin Woods'), findsOneWidget);
      for (final e in ['goblin', 'goblin_brute', 'old_bear']) {
        expect(here(option('fight', e)), findsOneWidget, reason: e);
      }
      expect(here(find.textContaining('Drops: ')), findsNWidgets(3));
      await tapAndStart(t, here(option('fight', 'goblin')));
      await settle(t, c);
      expect(c.state.activity!.activity, const Activity.fight('goblin'));
    });

    // Spec 0010 §2.2: the Mining level, not the character's.
    testWidgets('a vein here shows the level it needs', (t) async {
      await pumpGame(t, level: 30, professionLevel: 9, location: 'iron_ridge');
      expect(here(option('gather', 'iron_vein')), findsOneWidget);
      expect(here(find.text('Iron vein needs Mining 10')), findsOneWidget);
    });

    testWidgets('at a forge a Forge row opens Professions', (t) async {
      await pumpGame(t);
      expect(find.text('Here: Camp'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('here-forge')));
      await t.pumpAndSettle();
      expect(find.text('At the forge (Camp)'), findsOneWidget);
    });

    testWidgets('no Forge row away from a forge', (t) async {
      await pumpGame(t, location: 'goblin_woods');
      expect(find.byKey(const ValueKey('here-forge')), findsNothing);
    });

    testWidgets('Settings: Next goal, the test walk, the version', (t) async {
      final (c, _) = await pumpGame(t);
      await openSettings(t);
      expect(find.byKey(const ValueKey('show-next-goal')), findsOneWidget);
      expect(find.text('Version $appVersion'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('test-walk-switch')));
      await settle(t, c);
      expect(c.testWalkOn, isTrue);
    });

    testWidgets('a friend build has no test walk switch', (t) async {
      await pumpGame(t, testWalkAllowed: false);
      await openSettings(t);
      expect(find.byKey(const ValueKey('test-walk-switch')), findsNothing);
    });

    testWidgets('Character no longer holds settings', (t) async {
      await pumpGame(t);
      await openTab(t, 'character');
      expect(find.byKey(const ValueKey('show-next-goal')), findsNothing);
      expect(find.byKey(const ValueKey('version')), findsNothing);
    });
  });
}

/// Spec 0008 §3.5 (plan 0010 M3): the paper doll, the bag grid and the item
/// card; criteria 6-10 on screen.
void characterScreen() {
  group('character screen (spec 0008 §3.5)', () {
    Future<void> openBag(WidgetTester t) async {
      await openTab(t, 'character');
      await t.tap(find.byKey(const ValueKey('tab-bag')));
      await t.pumpAndSettle();
    }

    Future<void> openCard(WidgetTester t, String key) async {
      await t.tap(find.byKey(ValueKey(key)));
      await t.pumpAndSettle();
    }

    Finder card(Finder f) => find.descendant(
      of: find.byKey(const ValueKey('item-card')),
      matching: f,
    );

    String cardText(WidgetTester t, String key) =>
        t.widget<Text>(card(find.byKey(ValueKey(key)))).data!;

    testWidgets('the doll has 16 slots; worn gear sits in its slot', (t) async {
      await pumpGame(t, equipment: {'chest': 'hide_vest'});
      await openTab(t, 'character');
      for (final g in game.data.gearSlots) {
        expect(find.byKey(ValueKey('slot-${g.id}')), findsOneWidget);
      }
      final chest = t.widget<ItemSquare>(
        find.byKey(const ValueKey('slot-chest')),
      );
      expect(chest.item, 'hide_vest');
      final head = t.widget<ItemSquare>(
        find.byKey(const ValueKey('slot-head')),
      );
      expect(head.item, isNull, reason: 'a faint outline');
    });

    testWidgets('criterion 8: the bag stacks, gear first, icons differ', (
      t,
    ) async {
      await pumpGame(
        t,
        inventory: {'goblin_hide': 3, 'hide_vest@rare': 2, 'copper_sword': 1},
      );
      await openBag(t);
      final keys = [
        for (final w in t.widgetList<ItemSquare>(
          find.descendant(
            of: find.byKey(const ValueKey('bag')),
            matching: find.byType(ItemSquare),
          ),
        ))
          w.item,
      ];
      // Gear in doll order (Chest before Main hand), then materials.
      expect(keys, ['hide_vest@rare', 'copper_sword', 'goblin_hide']);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('bag-goblin_hide')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
      Iterable<IconData?> icons(String key) => t
          .widgetList<Icon>(
            find.descendant(
              of: find.byKey(ValueKey('bag-$key')),
              matching: find.byType(Icon),
            ),
          )
          .map((i) => i.icon);
      expect(icons('goblin_hide'), [materialIcon]);
      expect(icons('copper_sword'), isNot(contains(materialIcon)));
      Color border(String key) =>
          ((t
                          .widget<Material>(
                            find
                                .descendant(
                                  of: find.byKey(ValueKey('bag-$key')),
                                  matching: find.byType(Material),
                                )
                                .first,
                          )
                          .shape!
                      as RoundedRectangleBorder)
                  .side)
              .color;
      expect(border('hide_vest@rare'), const Color(0xff42a5f5));
      expect(border('goblin_hide'), Colors.transparent, reason: 'no border');
    });

    testWidgets('criteria 9 and 10: the card for bag gear, then Equip', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, inventory: {'hide_vest@rare': 1});
      await openBag(t);
      await openCard(t, 'bag-hide_vest@rare');
      expect(cardText(t, 'card-name'), 'Hide vest', reason: 'no bracket');
      final name = t.widget<Text>(
        card(find.byKey(const ValueKey('card-name'))),
      );
      expect(name.style?.color, const Color(0xff42a5f5));
      expect(cardText(t, 'card-kind'), 'Rare chest armour · Chest');
      // Its stats, and the same again as the change to an empty slot.
      // Light armour carries base Dodge (spec 0009 §6).
      expect(
        card(find.text('+4 Defense · +14 HP · +2% Dodge')),
        findsNWidgets(2),
      );
      expect(card(find.text('Chest is empty')), findsOneWidget);
      expect(cardText(t, 'compare-chest'), '+4 Defense · +14 HP · +2% Dodge');

      await t.tap(card(find.byKey(const ValueKey('card-equip'))));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.equipment['chest'], 'hide_vest@rare');
      expect(find.byKey(const ValueKey('item-card')), findsNothing);
    });

    testWidgets('Swap compares with what is worn; Unequip from the doll', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        inventory: {'stitched_armour': 1},
        equipment: {'chest': 'hide_vest'},
      );
      await openBag(t);
      await openCard(t, 'bag-stitched_armour');
      expect(card(find.text('Instead of your Hide vest')), findsOneWidget);
      expect(cardText(t, 'compare-chest'), '+2 Defense · +10 HP');
      await t.tap(card(find.byKey(const ValueKey('card-swap'))));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.equipment['chest'], 'stitched_armour');
      expect(c.state.inventory['hide_vest'], 1);

      await t.tap(find.byKey(const ValueKey('tab-gear')));
      await t.pumpAndSettle();
      // A doll slot opens its slot sheet (spec 0008 amendment 3).
      await openCard(t, 'slot-chest');
      await t.tap(find.byKey(const ValueKey('sheet-unequip')));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.equipment, isEmpty);
      expect(c.state.inventory['stitched_armour'], 1);
    });

    testWidgets('a material card: where it comes from, what uses it', (
      t,
    ) async {
      await pumpGame(
        t,
        inventory: {'goblin_hide': 2},
        counters: {'found.goblin.goblin_hide': 1},
      );
      await openBag(t);
      await openCard(t, 'bag-goblin_hide');
      expect(cardText(t, 'card-kind'), 'Material');
      expect(card(find.text('Drops from: Goblin')), findsOneWidget);
      expect(card(find.textContaining('Used in: Hide vest')), findsOneWidget);
      expect(card(find.byKey(const ValueKey('card-equip'))), findsNothing);
    });

    testWidgets('bag squares keep their place through equip and unequip', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        inventory: {
          'copper_sword': 1,
          'copper_sword@rare': 1,
          'hide_vest': 1,
          'goblin_hide': 2,
          'bones': 1,
        },
      );
      List<String?> order() => [
        for (final w in t.widgetList<ItemSquare>(
          find.descendant(
            of: find.byKey(const ValueKey('bag')),
            matching: find.byType(ItemSquare),
          ),
        ))
          w.item,
      ];
      await openBag(t);
      final before = order();
      await c.equip('hide_vest');
      await c.unequip('chest');
      await t.pumpAndSettle();
      expect(order(), before);
    });

    testWidgets('a material card names no vein in the fog', (t) async {
      await pumpGame(t, inventory: {'iron_ore': 1});
      await openBag(t);
      await openCard(t, 'bag-iron_ore');
      expect(card(find.textContaining('Mined at')), findsNothing);
      expect(card(find.textContaining('Used in: Iron')), findsOneWidget);
    });

    testWidgets('amendment 3: the hands alone in the bottom row', (t) async {
      await pumpGame(t);
      await openTab(t, 'character');
      Offset at(String id) => t.getTopLeft(find.byKey(ValueKey('slot-$id')));
      expect(at('mainHand').dy, at('offHand').dy);
      expect(at('mainHand').dy, greaterThan(at('trinket1').dy));
      expect(at('trinket1').dx, at('head').dx, reason: 'left column');
      expect(at('trinket2').dx, at('gloves').dx, reason: 'right column');
    });

    testWidgets('amendment 3: an empty slot lists what fits, and fills it', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        inventory: {'iron_helm': 1, 'mithril_helm': 1, 'hide_vest': 1},
      );
      await openTab(t, 'character');
      await openCard(t, 'slot-head');
      expect(find.byKey(const ValueKey('sheet-unequip')), findsNothing);
      expect(
        find.byKey(const ValueKey('sheet-equip-mithril_helm')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('sheet-equip-hide_vest')),
        findsNothing,
        reason: 'only what fits the Head slot',
      );
      await t.tap(find.byKey(const ValueKey('sheet-equip-iron_helm')));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.equipment['head'], 'iron_helm');
    });

    testWidgets('amendment 3: nothing in the bag fits', (t) async {
      await pumpGame(t, inventory: {'goblin_hide': 1});
      await openTab(t, 'character');
      await openCard(t, 'slot-neck');
      expect(
        t.widget<Text>(find.byKey(const ValueKey('sheet-title'))).data,
        'Neck',
      );
      expect(find.text('Nothing in your bag fits here yet.'), findsOneWidget);
    });

    group('test-only gear', () {
      final withGear = loadTestGame(
        items: [
          {'id': 'ring_a', 'name': 'Ring A', 'slot': 'ring', 'hp': 5},
          {'id': 'ring_b', 'name': 'Ring B', 'slot': 'ring', 'hp': 6},
          {'id': 'ring_c', 'name': 'Ring C', 'slot': 'ring', 'hp': 9},
          {
            'id': 'big_axe',
            'name': 'Big axe',
            'slot': 'mainHand',
            // Every weapon has a damage type (spec 0009 §4.1).
            'damageType': 'slash',
            'twoHanded': true,
            'attack': 10,
          },
        ],
      );

      testWidgets('an off-hand item next to a two-hander names what goes', (
        t,
      ) async {
        await pumpGame(
          t,
          withGame: withGear,
          inventory: {'bone_shield': 1},
          equipment: {'mainHand': 'big_axe'},
        );
        await openBag(t);
        await openCard(t, 'bag-bone_shield');
        expect(card(find.text('Instead of your Big axe')), findsOneWidget);
        // The comparison covers every stat (spec 0009 §8.2).
        expect(
          cardText(t, 'compare-offHand'),
          '−10 Attack · +3 Defense · +25% Block',
        );
      });

      testWidgets('amendment 3: a shield under a two-hander says Swap', (
        t,
      ) async {
        await pumpGame(
          t,
          withGame: withGear,
          inventory: {'bone_shield': 1},
          equipment: {'mainHand': 'big_axe'},
        );
        await openTab(t, 'character');
        await openCard(t, 'slot-offHand');
        expect(
          t
              .widget<Text>(find.byKey(const ValueKey('sheet-off-bone_shield')))
              .data,
          'Takes off your Big axe',
        );
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('sheet-equip-bone_shield')),
            matching: find.text('Swap'),
          ),
          findsOneWidget,
        );
      });

      testWidgets('amendment 3: Ring 2 fills Ring 2, even with Ring 1 empty', (
        t,
      ) async {
        final (c, _) = await pumpGame(
          t,
          withGame: withGear,
          inventory: {'ring_a': 1},
        );
        await openTab(t, 'character');
        await openCard(t, 'slot-ring2');
        expect(
          t.widget<Text>(find.byKey(const ValueKey('sheet-title'))).data,
          'Ring 2 · rings fit here',
        );
        expect(
          t.widget<Text>(find.byKey(const ValueKey('sheet-delta-ring_a'))).data,
          '+5 HP',
        );
        await t.tap(find.byKey(const ValueKey('sheet-equip-ring_a')));
        await settle(t, c);
        await t.pumpAndSettle();
        expect(c.state.equipment, {'ring2': 'ring_a'});
      });

      testWidgets('criterion 7: both rings worn, swap with either', (t) async {
        final (c, _) = await pumpGame(
          t,
          withGame: withGear,
          inventory: {'ring_c': 1},
          equipment: {'ring1': 'ring_a', 'ring2': 'ring_b'},
        );
        await openBag(t);
        await openCard(t, 'bag-ring_c');
        expect(card(find.text('Swap with Ring A')), findsOneWidget);
        expect(card(find.text('Swap with Ring B')), findsOneWidget);
        await t.tap(card(find.byKey(const ValueKey('card-swap-ring2'))));
        await settle(t, c);
        await t.pumpAndSettle();
        expect(c.state.equipment['ring2'], 'ring_c');
        expect(c.state.inventory['ring_b'], 1);
      });

      testWidgets('criterion 6: a two-hander says the shield goes to the bag', (
        t,
      ) async {
        final (c, _) = await pumpGame(
          t,
          withGame: withGear,
          inventory: {'big_axe': 1},
          equipment: {'mainHand': 'copper_sword', 'offHand': 'bone_shield'},
        );
        await openBag(t);
        await openCard(t, 'bag-big_axe');
        expect(cardText(t, 'card-kind'), 'Common two-hand weapon · Main hand');
        expect(
          card(
            find.text('Uses both hands: your off-hand item goes to the bag.'),
          ),
          findsOneWidget,
        );
        // The comparison covers every stat (spec 0009 §8.2).
        expect(
          cardText(t, 'compare-mainHand'),
          '+7 Attack · −3 Defense · −25% Block',
        );
        await t.tap(card(find.byKey(const ValueKey('card-swap'))));
        await settle(t, c);
        await t.pumpAndSettle();
        expect(c.state.equipment, {'mainHand': 'big_axe'});
        expect(c.state.inventory, {'copper_sword': 1, 'bone_shield': 1});

        await t.tap(find.byKey(const ValueKey('tab-gear')));
        await t.pumpAndSettle();
        final off = t.widget<ItemSquare>(
          find.byKey(const ValueKey('slot-offHand')),
        );
        expect(off.dimmed, isTrue, reason: 'greyed out under a two-hander');
      });
    });
  });
}

/// Spec 0009 §7–§8 (plan 0011 M3): the fight log, the item card, the
/// bestiary card on the monster sheet, the Journal's tabs and the stats.
void fightsWithDepth() {
  group('fights with depth (spec 0009)', () {
    Finder bestiary(Finder f) => find.descendant(
      of: find.byKey(const ValueKey('bestiary-card')),
      matching: f,
    );

    test('criterion 13: the fight log names each swing (§8.1)', () {
      final labels = Labels(game.data);
      List<String> lines(Swing? mine, Swing? theirs, {int d = 9, int t = 7}) =>
          labels.roundLines(
            RoundLog(
              round: 3,
              mine: mine,
              theirs: theirs,
              dealt: mine == null ? null : d,
              taken: theirs == null ? null : t,
            ),
            'skeleton',
          );
      expect(lines(Swing.hit, Swing.hit), [
        'Round 3: You hit for 9',
        'Skeleton hits you for 7',
      ]);
      expect(lines(Swing.crit, Swing.miss, d: 18), [
        'Round 3: Critical hit for 18',
        'Skeleton misses',
      ]);
      expect(lines(Swing.miss, Swing.dodge, d: 0, t: 0), [
        'Round 3: You miss',
        'You dodge',
      ]);
      expect(lines(Swing.dodge, Swing.block, d: 0, t: 2), [
        'Round 3: Skeleton dodges',
        'You block: 2 damage',
      ]);
      // Quick monsters swing first; a slow one may not swing at all.
      expect(
        labels.roundLines(
          const RoundLog(
            round: 1,
            mine: Swing.hit,
            dealt: 5,
            theirs: Swing.hit,
            taken: 4,
          ),
          'wolf',
        ),
        ['Round 1: Wolf hits you for 4', 'You hit for 5'],
      );
      expect(
        labels.roundLines(
          const RoundLog(
            round: 2,
            mine: Swing.hit,
            dealt: 5,
            outcome: FightOutcome.won,
          ),
          'zombie',
        ),
        ['Round 2: You hit for 5', 'Zombie is beaten'],
      );
    });

    testWidgets('criterion 13: the item card shows type, hands and bonus '
        'stats; list rows show none', (t) async {
      const spear = 'iron_spear@rare+crit3+hp12';
      await pumpGame(
        t,
        level: 14,
        inventory: {spear: 1, 'hide_vest': 1},
        equipment: {'mainHand': spear},
      );
      await openTab(t, 'character');
      await t.tap(find.byKey(const ValueKey('slot-mainHand')));
      await t.pumpAndSettle();
      final sheet = find.byKey(const ValueKey('slot-sheet'));
      expect(
        find.descendant(of: sheet, matching: find.textContaining('Crit')),
        findsNothing,
      );
      await closeSheet(t);
      await t.tap(find.byKey(const ValueKey('tab-bag')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('bag-hide_vest')));
      await t.pumpAndSettle();
      expect(find.text('Light armour · Chest'), findsOneWidget);
      // On the base line and in the comparison with the empty slot.
      expect(find.textContaining('+2% Dodge'), findsWidgets);
      await closeSheet(t);
      await t.tap(find.byKey(const ValueKey('tab-gear')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('slot-mainHand')));
      await t.pumpAndSettle();
      await t.tap(find.text('Iron spear').last);
      await t.pumpAndSettle();
      final card = find.byKey(const ValueKey('item-card'));
      Finder inCard(String text) =>
          find.descendant(of: card, matching: find.text(text));
      expect(inCard('Pierce · One hand'), findsOneWidget);
      expect(inCard('+3% Crit'), findsOneWidget);
      expect(inCard('+12 Health'), findsOneWidget);
    });

    testWidgets('criterion 11: the card fills in by fighting, never shows '
        'drop chances', (t) async {
      await pumpGame(
        t,
        location: 'old_graveyard',
        level: 8,
        counters: {'kills.skeleton': 12},
      );
      await t.tap(option('fight', 'zombie'));
      await t.pumpAndSettle();
      expect(bestiary(find.text('Zombie')), findsOneWidget);
      expect(bestiary(find.textContaining('Armour: ???')), findsOneWidget);
      expect(
        bestiary(find.textContaining('10 more kills to learn its weakness')),
        findsOneWidget,
      );
      expect(bestiary(find.textContaining('HP ')), findsNothing);
      await closeSheet(t);
      await t.tap(option('fight', 'skeleton'));
      await t.pumpAndSettle();
      expect(bestiary(find.textContaining('Heavy armour')), findsOneWidget);
      expect(bestiary(find.textContaining('Weak to crush')), findsOneWidget);
      expect(bestiary(find.textContaining('HP 48')), findsOneWidget);
      expect(bestiary(find.textContaining('12 kills')), findsOneWidget);
      expect(bestiary(find.textContaining('38 more kills')), findsOneWidget);
      expect(bestiary(find.textContaining('chance')), findsNothing);
      expect(bestiary(find.textContaining('Drops:')), findsOneWidget);
    });

    testWidgets('criterion 14: tapping a monster in Now or World opens its '
        'card with the fight choices', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await t.tap(option('fight', 'goblin'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('bestiary-card')), findsOneWidget);
      expect(find.byKey(const ValueKey('stop-untilGrey')), findsOneWidget);
      await closeSheet(t);
      await openArea(t, 'goblin_woods');
      await t.tap(option('fight', 'goblin'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('bestiary-card')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('start-now')));
      await settle(t, c);
      expect(c.state.activity?.activity, const Activity.fight('goblin'));
    });

    testWidgets('criterion 14: the Journal has Log, Bestiary and Lore tabs', (
      t,
    ) async {
      final note = game.data.enemies['goblin']!.lore!;
      final later = game.data.enemies['wolf']!.lore!;
      final (c, _) = await pumpGame(t, counters: {'kills.goblin': 60});
      // Found lore shows in the Lore tab.
      c.state.lore.addAll([note.id, later.id]);
      await t.tap(find.byKey(const ValueKey('journal-button')));
      await t.pumpAndSettle();
      expect(find.text('Log'), findsOneWidget);
      await t.tap(find.text('Bestiary'));
      await t.pumpAndSettle();
      final goblin = find.byKey(const ValueKey('bestiary-goblin'));
      expect(goblin, findsOneWidget);
      expect(
        find.descendant(of: goblin, matching: find.textContaining('Slayer')),
        findsOneWidget,
      );
      // The brute: known from the note (armour, weakness), never fought.
      expect(
        find.byKey(const ValueKey('bestiary-goblin_brute')),
        findsOneWidget,
      );
      // Beyond the fog: no card yet (decision 10).
      expect(find.byKey(const ValueKey('bestiary-young_dragon')), findsNothing);
      await t.tap(goblin);
      await t.pumpAndSettle();
      expect(bestiary(find.textContaining('Slayer')), findsOneWidget);
      await closeSheet(t);
      await t.tap(find.text('Lore'));
      await t.pumpAndSettle();
      expect(find.text('2 of 16 found'), findsOneWidget);
      // Newest first.
      expect(
        t.getTopLeft(find.text(later.title)).dy,
        lessThan(t.getTopLeft(find.text(note.title)).dy),
      );
    });

    testWidgets('repeated bonus stats are separate card lines (§8.2)', (
      t,
    ) async {
      const sword = 'iron_sword@epic+crit3+crit2+hp12';
      await pumpGame(t, level: 14, inventory: {sword: 1});
      await openTab(t, 'character');
      await t.tap(find.byKey(const ValueKey('tab-bag')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('bag-$sword')));
      await t.pumpAndSettle();
      final card = find.byKey(const ValueKey('item-card'));
      for (final line in ['+3% Crit', '+2% Crit', '+12 Health']) {
        expect(
          find.descendant(of: card, matching: find.text(line)),
          findsOneWidget,
          reason: line,
        );
      }
    });

    testWidgets('the Character stats show Crit, Hit, Dodge and Block', (
      t,
    ) async {
      await pumpGame(
        t,
        level: 7,
        equipment: {'offHand': 'bone_shield', 'chest': 'hide_vest'},
      );
      await openTab(t, 'character');
      for (final (label, value) in [
        ('Crit', '5%'),
        ('Hit', '0%'),
        ('Dodge', '2%'),
        ('Block', '25%'),
      ]) {
        expect(
          find.byKey(ValueKey('stat-$label')),
          findsOneWidget,
          reason: label,
        );
        expect(
          find.descendant(
            of: find.byKey(ValueKey('stat-$label')),
            matching: find.text(value),
          ),
          findsOneWidget,
          reason: label,
        );
      }
    });
  });
}

void professionScreens() {
  group('professions (spec 0010 §8)', () {
    Finder within(String key, Finder f) =>
        find.descendant(of: find.byKey(ValueKey(key)), matching: f);
    Finder card(Finder f) => within('item-card', f);
    Finder sheet(Finder f) => within('teacher-sheet', f);

    Future<void> openItem(WidgetTester t, String key) async {
      await openTab(t, 'character');
      await t.tap(find.byKey(const ValueKey('tab-bag')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(ValueKey('bag-$key')));
      await t.pumpAndSettle();
    }

    testWidgets('criterion 14: a card per profession, Crafting holds the '
        'recipes', (t) async {
      final (c, _) = await pumpGame(t, level: 12, professionLevel: 11);
      // The best spots lie beyond explored land.
      c.state.explored.addAll(['copper_hills', 'iron_ridge', 'grey_moor']);
      await openTab(t, 'professions');
      for (final p in ['mining', 'woodcutting', 'crafting']) {
        expect(find.byKey(ValueKey('profession-$p')), findsOneWidget);
        expect(
          within('profession-$p', find.byType(LinearProgressIndicator)),
          findsOneWidget,
        );
      }
      // In the order Mining, Woodcutting, Crafting.
      double top(String p) =>
          t.getTopLeft(find.byKey(ValueKey('profession-$p'))).dy;
      expect(top('mining'), lessThan(top('woodcutting')));
      expect(top('woodcutting'), lessThan(top('crafting')));
      // Level, tier and tool with its step cost.
      expect(within('profession-mining', find.text('Level 11')), findsOne);
      expect(within('profession-mining', find.text('Iron')), findsOneWidget);
      expect(
        within('profession-mining', find.text("Hilde's old pick · 100% steps")),
        findsOneWidget,
      );
      // Where to practise: the best spot for the level, with Go there.
      expect(
        within('profession-mining', find.text('Iron vein · Iron Ridge')),
        findsOneWidget,
      );
      expect(
        within('profession-woodcutting', find.text('Ash tree · Grey Moor')),
        findsOneWidget,
      );
      expect(
        within('profession-crafting', find.text('At the forge (Camp)')),
        findsOneWidget,
      );
      expect(
        within('profession-crafting', option('craft', 'copper_sword')),
        findsOneWidget,
      );
      // Go there walks to the spot, then works it.
      await t.tap(find.byKey(const ValueKey('go-mining')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('start-now')));
      await settle(t, c);
      expect(c.state.activity!.activity, const Activity.gather('iron_vein'));
    });

    testWidgets('criterion 14: the tool line opens its card', (t) async {
      await pumpGame(t, level: 5);
      await openTab(t, 'professions');
      await t.tap(within('profession-mining', find.textContaining('old pick')));
      await t.pumpAndSettle();
      expect(card(find.text("Hilde's old pick")), findsOneWidget);
      expect(card(find.text('Mining tool · 100% steps')), findsOneWidget);
    });

    testWidgets('criterion 14: an unlearned profession points to its '
        'teacher', (t) async {
      await pumpGame(t, learned: false);
      await openTab(t, 'professions');
      expect(
        within('profession-mining', find.text('Learn from Hilde in camp')),
        findsOneWidget,
      );
      expect(
        within('profession-crafting', find.text('Learn from Garrow in camp')),
        findsOneWidget,
      );
      expect(option('craft', 'copper_sword'), findsNothing);
      expect(find.byKey(const ValueKey('go-mining')), findsNothing);
    });

    testWidgets('criterion 4: learn from a teacher in camp, then hear a '
        'tip', (t) async {
      final (c, _) = await pumpGame(t, learned: false);
      for (final p in ['mining', 'woodcutting', 'crafting']) {
        expect(within('here', find.byKey(ValueKey('teacher-$p'))), findsOne);
      }
      expect(find.text('Hilde, the miner'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('teacher-mining')));
      await t.pumpAndSettle();
      await t.tap(sheet(find.byKey(const ValueKey('learn-mining'))));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.learned, contains('mining'));
      expect(c.state.tools['mining'], 'old_pick');
      expect(sheet(find.textContaining('Take my old pick.')), findsOneWidget);
      // Mining 1's tip is told at once and reveals the skeleton.
      expect(sheet(find.text('Bones under the hills')), findsOneWidget);
      expect(c.state.tips, contains('hilde_1'));
      expect(c.game.knowledge(c.state, 'skeleton').weakness, isTrue);
      expect(sheet(find.byKey(const ValueKey('learn-mining'))), findsNothing);
    });

    testWidgets('criterion 4: a dot marks a waiting tip until heard', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, professionLevel: 10);
      c.state.tips.addAll([
        'hilde_1',
        'bram_1',
        'bram_10',
        'garrow_1',
        'garrow_10',
      ]);
      await openTab(t, 'professions');
      await openTab(t, 'now');
      expect(find.byKey(const ValueKey('teacher-dot-mining')), findsOneWidget);
      expect(find.byKey(const ValueKey('teacher-dot-crafting')), findsNothing);
      await t.tap(find.byKey(const ValueKey('teacher-mining')));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(sheet(find.text('Troll skin')), findsOneWidget);
      expect(sheet(find.text('Bones under the hills')), findsOneWidget);
      expect(sheet(find.textContaining('Next tip at Mining 20')), findsOne);
      expect(c.state.tips, contains('hilde_10'));
      await closeSheet(t);
      expect(find.byKey(const ValueKey('teacher-dot-mining')), findsNothing);
    });

    testWidgets('no teachers away from camp', (t) async {
      await pumpGame(t, location: 'goblin_woods');
      expect(find.byKey(const ValueKey('teacher-mining')), findsNothing);
    });

    testWidgets('criterion 13: an old save opens on the levels it earned', (
      t,
    ) async {
      final json = jsonDecode(
        File('test/fixtures/saves/0.2.0.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final c = await pumpSave(t, json);
      // It sets out first (spec 0012 decision 6).
      expect(find.text('Who are you?'), findsOneWidget);
      await t.ensureVisible(find.byKey(const ValueKey('origin-tavern_cook')));
      await t.tap(find.byKey(const ValueKey('origin-tavern_cook')));
      await t.pump();
      await t.ensureVisible(find.byKey(const ValueKey('set-out')));
      await t.tap(find.byKey(const ValueKey('set-out')));
      await settle(t, c);
      final mining = c.game.professionLevel(c.state, 'mining');
      final crafting = c.game.professionLevel(c.state, 'crafting');
      expect(c.state.learned, {'mining', 'crafting', 'cooking'});
      await openTab(t, 'professions');
      expect(within('profession-mining', find.text('Level $mining')), findsOne);
      expect(
        within('profession-crafting', find.text('Level $crafting')),
        findsOneWidget,
      );
      expect(
        within('profession-woodcutting', find.text('Learn from Bram in camp')),
        findsOneWidget,
      );
      // No level-up news for the catch-up (spec 0010 §10).
      expect(find.textContaining('Reached Mining'), findsNothing);
    });

    testWidgets('Here: a spot shows its profession level colour', (t) async {
      await pumpGame(t, level: 5, location: 'copper_hills');
      expect(
        within('here', find.byKey(const ValueKey('spot-level-copper_vein'))),
        findsOneWidget,
      );
    });

    testWidgets('§8.3: a tool in the bag: profession, step cost, Swap', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, inventory: {'copper_pickaxe@rare': 1});
      await openItem(t, 'copper_pickaxe@rare');
      expect(card(find.text('Rare pickaxe · Mining')), findsOneWidget);
      // 90% less 2 points per quality step: Rare is 2 steps up.
      expect(card(find.text('Mining tool · 86% steps')), findsOneWidget);
      expect(card(find.text("Instead of Hilde's old pick")), findsOneWidget);
      await t.tap(card(find.byKey(const ValueKey('card-tool'))));
      await settle(t, c);
      expect(c.state.tools['mining'], 'copper_pickaxe@rare');
      expect(c.state.inventory['old_pick'], 1);
    });

    testWidgets('§8.3: salvage at a forge; Rare and up ask first', (t) async {
      final (c, _) = await pumpGame(
        t,
        inventory: {'bone_sword': 1, 'bone_sword@rare+crit2+hp10': 1},
      );
      await openItem(t, 'bone_sword');
      await t.tap(card(find.byKey(const ValueKey('card-salvage'))));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.inventory['common_dust'], 1);
      expect(c.state.inventory['bone_sword'], isNull);
      expect(find.textContaining('Salvaged the Bone sword'), findsOneWidget);

      await openItem(t, 'bone_sword@rare+crit2+hp10');
      await t.tap(card(find.byKey(const ValueKey('card-salvage'))));
      await t.pumpAndSettle();
      expect(c.state.inventory['rare_dust'], isNull, reason: 'asks first');
      await t.tap(find.byKey(const ValueKey('salvage-confirm')));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.inventory['rare_dust'], 1);
    });

    testWidgets('§8.3: away from a forge the card says where', (t) async {
      await pumpGame(t, location: 'goblin_woods', inventory: {'bone_sword': 1});
      await openItem(t, 'bone_sword');
      expect(card(find.text('Salvage and reroll at a forge')), findsOneWidget);
      expect(card(find.byKey(const ValueKey('card-salvage'))), findsNothing);
      expect(card(find.byKey(const ValueKey('card-reroll'))), findsNothing);
    });

    testWidgets('a starter tool has no Salvage', (t) async {
      await pumpGame(t, inventory: {'old_hatchet': 1});
      await openItem(t, 'old_hatchet');
      expect(card(find.byKey(const ValueKey('card-salvage'))), findsNothing);
    });

    testWidgets('§7.2: Reroll names the dust, starts at once, and reports', (
      t,
    ) async {
      const key = 'bone_sword@uncommon+crit2';
      final (c, source) = await pumpGame(
        t,
        level: 5,
        inventory: {key: 1, 'uncommon_dust': 3},
      );
      await openItem(t, key);
      expect(card(find.text('Reroll (3 Uncommon dust)')), findsOneWidget);
      await t.tap(card(find.byKey(const ValueKey('card-reroll'))));
      await settle(t, c);
      await t.pumpAndSettle();
      // One roll: no stop condition sheet.
      expect(find.byKey(const ValueKey('start-now')), findsNothing);
      expect(c.state.activity!.activity, const Activity.reroll(key));
      source.walk(DateTime(2026, 10, 18, 9, 5), 100);
      now = DateTime(2026, 10, 18, 9, 30);
      await c.resume();
      await t.pumpAndSettle();
      expect(find.textContaining('Bone sword reroll: '), findsOneWidget);
    });

    testWidgets('§7.3: a Legendary rerolls one chosen stat', (t) async {
      const key = 'iron_sword@legendary+crit2+crit1+hp11+hp10';
      final (c, _) = await pumpGame(
        t,
        level: 20,
        inventory: {key: 1, 'legendary_dust': 3},
      );
      await openItem(t, key);
      expect(card(find.byKey(const ValueKey('card-reroll'))), findsNothing);
      expect(
        card(find.textContaining('Reroll (3 Legendary dust)')),
        findsNWidgets(4),
      );
      await t.tap(card(find.byKey(const ValueKey('card-reroll-stat-1'))));
      await settle(t, c);
      expect(c.state.activity!.activity, Activity.rerollStat(key, 1));
    });

    testWidgets('§7.3: Keep new / Keep old, anywhere', (t) async {
      const key = 'iron_sword@legendary+crit2+crit1+hp11+hp10';
      final (c, _) = await pumpGame(
        t,
        level: 20,
        location: 'goblin_woods',
        inventory: {'$key+~1.hit4': 1},
      );
      await openItem(t, '$key+~1.hit4');
      expect(card(find.text('New roll: +4% Hit (was +1% Crit)')), findsOne);
      await t.tap(card(find.byKey(const ValueKey('card-keep-new'))));
      await settle(t, c);
      final kept = c.state.inventory.keys.single;
      expect(c.game.data.pendingRoll(kept), isNull);
      expect(c.game.data.bonusRolls(kept), contains((stat: 'hit', value: 4)));
    });

    testWidgets('Lore: tips under each teacher', (t) async {
      final (c, _) = await pumpGame(t);
      c.state.tips.addAll(['hilde_1', 'garrow_1']);
      await t.tap(find.byKey(const ValueKey('journal-button')));
      await t.pumpAndSettle();
      await t.tap(find.text('Lore'));
      await t.pumpAndSettle();
      expect(find.text('0 of 16 found'), findsOneWidget);
      expect(find.text('Hilde, the miner'), findsOneWidget);
      expect(find.text('Bones under the hills'), findsOneWidget);
      expect(find.text('Garrow, the smith'), findsOneWidget);
      expect(find.text('Bram, the woodcutter'), findsNothing);
    });

    testWidgets('§8.4: Next goal names a missing profession level', (t) async {
      await pumpGame(t, level: 30, professionLevel: 1);
      expect(
        within('next-goal', find.textContaining(RegExp('^Reach Crafting'))),
        findsOneWidget,
      );
    });
  });
}

void lakeAndHunt() {
  group('lake and hunt (spec 0011 §8)', () {
    Finder within(String key, Finder f) =>
        find.descendant(of: find.byKey(ValueKey(key)), matching: f);
    Finder card(Finder f) => within('item-card', f);

    Future<void> openItem(WidgetTester t, String key) async {
      await openTab(t, 'character');
      await t.tap(find.byKey(const ValueKey('tab-bag')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(ValueKey('bag-$key')));
      await t.pumpAndSettle();
    }

    /// Redraws the screens after a test changed the state by hand.
    Future<void> redraw(WidgetTester t, String screen) async {
      await openTab(t, screen == 'now' ? 'world' : 'now');
      await openTab(t, screen);
    }

    testWidgets('criterion 15: six cards, in the order of §8.1', (t) async {
      await pumpGame(t, level: 5);
      await openTab(t, 'professions');
      const order = [
        'mining',
        'woodcutting',
        'fishing',
        'hunting',
        'crafting',
        'cooking',
      ];
      double top(String p) =>
          t.getTopLeft(find.byKey(ValueKey('profession-$p'))).dy;
      for (var i = 0; i < order.length; i++) {
        expect(find.byKey(ValueKey('profession-${order[i]}')), findsOne);
        if (i > 0) expect(top(order[i - 1]), lessThan(top(order[i])));
      }
    });

    testWidgets('criterion 15: unlearned, the new cards name their '
        'teachers', (t) async {
      await pumpGame(t, learned: false);
      await openTab(t, 'professions');
      for (final (p, who) in [
        ('fishing', 'Wen'),
        ('hunting', 'Sigrun'),
        ('cooking', 'Marta'),
      ]) {
        expect(
          within('profession-$p', find.text('Learn from $who in camp')),
          findsOneWidget,
        );
      }
    });

    testWidgets('criterion 15: Fishing records, "???" for the uncaught', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, level: 5);
      c.state.records['pike'] = 63;
      await openTab(t, 'professions');
      expect(
        within('profession-fishing', find.text('Pike · 6.3 kg')),
        findsOneWidget,
      );
      // Lake, river and tarn hold 4 species each; the cove is hidden.
      expect(within('profession-fishing', find.text('???')), findsNWidgets(11));
      c.state.revealed.add('smugglers_cove');
      await redraw(t, 'professions');
      expect(within('profession-fishing', find.text('???')), findsNWidgets(15));
    });

    testWidgets('criterion 15: Cooking holds the meal recipes, the active '
        'meal and auto-eat', (t) async {
      final (c, _) = await pumpGame(t, level: 5);
      c.state
        ..meal = ActiveMeal('venison_skewer', 1850)
        ..autoEat = const AutoEat('venison_skewer', 0);
      await openTab(t, 'professions');
      expect(
        within('profession-cooking', option('craft', 'grilled_perch')),
        findsOneWidget,
      );
      expect(
        within('profession-crafting', option('craft', 'grilled_perch')),
        findsNothing,
      );
      expect(
        within('profession-cooking', option('craft', 'copper_sword')),
        findsNothing,
      );
      expect(
        within('profession-cooking', find.text('At the camp fire (Camp)')),
        findsOneWidget,
      );
      expect(
        within(
          'profession-cooking',
          find.textContaining('Venison skewer · +6% Attack · 1,850 steps left'),
        ),
        findsOneWidget,
      );
      expect(
        within('profession-cooking', find.textContaining('Auto-eat')),
        findsWidgets,
      );
    });

    testWidgets('criterion 15: Cooking says what its recipes need', (t) async {
      await pumpGame(t, level: 5);
      await openTab(t, 'professions');
      expect(
        within(
          'option-craft-smoked_trout',
          find.textContaining('needs Cooking 10', findRichText: true),
        ),
        findsOneWidget,
      );
    });

    testWidgets('criterion 15: Cooking away from camp walks to the fire', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, level: 5, location: 'goblin_woods');
      await openTab(t, 'professions');
      expect(
        within('profession-cooking', find.textContaining('Camp fire')),
        findsOneWidget,
      );
      await t.ensureVisible(find.byKey(const ValueKey('go-cooking')));
      await t.pumpAndSettle();
      await tapAndStart(t, find.byKey(const ValueKey('go-cooking')));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.activity!.activity, const Activity.travel('camp'));
    });

    testWidgets('criterion 15: Now shows the active meal; tap opens it', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        level: 5,
        inventory: {'venison_skewer': 3, 'venison_skewer@perfect': 1},
      );
      expect(find.byKey(const ValueKey('meal-line')), findsNothing);
      c.state
        ..meal = ActiveMeal('venison_skewer', 1850)
        ..autoEat = const AutoEat('venison_skewer', 0);
      await redraw(t, 'now');
      expect(
        find.text(
          'Venison skewer · +6% Attack · 1,850 steps left · '
          'auto-eat until out (4)',
        ),
        findsOneWidget,
      );
      await t.tap(find.byKey(const ValueKey('meal-line')));
      await t.pumpAndSettle();
      expect(card(find.text('+6% Attack for 3,000 steps')), findsOneWidget);
    });

    testWidgets('criterion 15: Camp has the three new teachers and the Camp '
        'fire, which opens Cooking', (t) async {
      await pumpGame(t, learned: false);
      for (final p in ['fishing', 'hunting', 'cooking']) {
        expect(within('here', find.byKey(ValueKey('teacher-$p'))), findsOne);
      }
      expect(find.text('Wen, the fisherman'), findsOneWidget);
      expect(find.text('Sigrun, the hunter'), findsOneWidget);
      expect(find.text('Marta, the cook'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('here-fire')));
      await t.pumpAndSettle();
      // Scrolled to the Cooking card, below Crafting's recipes.
      final top = t.getTopLeft(
        find.byKey(const ValueKey('profession-cooking')),
      );
      expect(top.dy, inInclusiveRange(0, 4000));
    });

    testWidgets('criterion 15: the new spots are in Here', (t) async {
      for (final (area, spot) in [
        ('mirror_lake', 'lake_shore'),
        ('troll_bridge', 'under_the_bridge'),
        ('goblin_woods', 'deer_trail'),
        ('grey_moor', 'moor_tracks'),
        ('mountain_pass', 'cold_tarn'),
        ('mountain_pass', 'high_crags'),
      ]) {
        await pumpGame(t, level: 5, location: area);
        expect(
          within('here', find.byKey(ValueKey('spot-level-$spot'))),
          findsOneWidget,
          reason: spot,
        );
      }
    });

    testWidgets('§8.2: a cast tallies its catches and records', (t) async {
      final (c, source) = await pumpGame(t, level: 5, location: 'mirror_lake');
      await tapAndStart(t, option('gather', 'lake_shore'));
      await settle(t, c);
      source.walk(DateTime(2026, 10, 18, 9, 5), 3000);
      now = DateTime(2026, 10, 18, 9, 30);
      await c.resume();
      await t.pumpAndSettle();
      if (find.byKey(const ValueKey('away-continue')).evaluate().isNotEmpty) {
        await t.tap(find.byKey(const ValueKey('away-continue')));
        await t.pumpAndSettle();
      }
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('tally-items')),
          matching: find.textContaining('Perch', findRichText: true),
        ),
        findsOneWidget,
      );
      expect(c.state.activity!.records, greaterThan(0));
      expect(find.byKey(const ValueKey('tally-records')), findsOneWidget);
    });

    testWidgets('§8.3: a meal card: buff, length, Eat', (t) async {
      final (c, _) = await pumpGame(t, inventory: {'grilled_perch': 2});
      await openItem(t, 'grilled_perch');
      expect(card(find.text('+6% HP for 3,000 steps')), findsOneWidget);
      await t.tap(card(find.byKey(const ValueKey('card-eat'))));
      await settle(t, c);
      expect(c.state.meal!.key, 'grilled_perch');
      expect(c.state.meal!.left, 3000);
      expect(c.state.inventory['grilled_perch'], 1);
    });

    testWidgets('§8.3: a perfect dish lasts 6,000 steps', (t) async {
      await pumpGame(t, inventory: {'grilled_perch@perfect': 1});
      await openItem(t, 'grilled_perch@perfect');
      expect(card(find.text('Grilled perch (Perfect)')), findsOneWidget);
      expect(card(find.text('+6% HP for 6,000 steps')), findsOneWidget);
    });

    testWidgets('criterion 11: Eat with a meal running asks, then replaces', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, inventory: {'grilled_perch': 1});
      c.state.meal = ActiveMeal('venison_skewer', 1240);
      await openItem(t, 'grilled_perch');
      expect(
        card(find.text('Replaces Venison skewer (1,240 steps left)')),
        findsOneWidget,
      );
      await t.tap(card(find.byKey(const ValueKey('card-eat'))));
      await t.pumpAndSettle();
      expect(c.state.meal!.key, 'venison_skewer', reason: 'asks first');
      await t.tap(find.byKey(const ValueKey('eat-confirm')));
      await settle(t, c);
      expect(c.state.meal!.key, 'grilled_perch');
      expect(c.state.inventory['grilled_perch'], isNull);
    });

    testWidgets('criterion 11: Auto-eat off, until out, only N', (t) async {
      final (c, _) = await pumpGame(t, inventory: {'venison_skewer': 5});
      await openItem(t, 'venison_skewer');
      await t.tap(card(find.byKey(const ValueKey('auto-eat-out'))));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.autoEat!.meal, 'venison_skewer');
      expect(c.state.autoEat!.keep, 0);

      await t.tap(card(find.byKey(const ValueKey('auto-eat-keep'))));
      await settle(t, c);
      await t.pumpAndSettle();
      await t.tap(card(find.byKey(const ValueKey('keep-up'))));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.autoEat!.keep, 2);
      expect(card(find.text('Keep 2')), findsOneWidget);

      await t.tap(card(find.byKey(const ValueKey('auto-eat-off'))));
      await settle(t, c);
      expect(c.state.autoEat, isNull);
    });

    testWidgets('criterion 11: picking another meal replaces the auto-eat '
        'meal', (t) async {
      final (c, _) = await pumpGame(
        t,
        inventory: {'venison_skewer': 2, 'grilled_perch': 2},
      );
      c.state.autoEat = const AutoEat('venison_skewer', 0);
      await openItem(t, 'grilled_perch');
      expect(
        card(find.textContaining('Replaces Venison skewer')),
        findsOneWidget,
      );
      await t.tap(card(find.byKey(const ValueKey('auto-eat-out'))));
      await settle(t, c);
      expect(c.state.autoEat!.meal, 'grilled_perch');
    });

    testWidgets('§8.3: fish and meat are materials with where and what', (
      t,
    ) async {
      await pumpGame(t, inventory: {'perch': 1, 'venison': 1});
      await openItem(t, 'perch');
      expect(card(find.text('Fished at: Lake shore')), findsOneWidget);
      expect(card(find.textContaining('Grilled perch')), findsWidgets);
      await closeSheet(t);
      await t.tap(find.byKey(const ValueKey('bag-venison')));
      await t.pumpAndSettle();
      expect(card(find.text('Hunted at: Deer trail')), findsOneWidget);
    });

    testWidgets('§8.3: Character marks the meal in its stats', (t) async {
      final (c, _) = await pumpGame(t, level: 5);
      c.state.meal = ActiveMeal('venison_skewer', 1850);
      await openTab(t, 'character');
      final bonus = c.game.mealBonus(c.state).attack;
      expect(bonus, greaterThan(0));
      expect(
        within('stat-Attack', find.text('(+$bonus meal)')),
        findsOneWidget,
      );
      expect(within('stat-HP', find.textContaining('meal')), findsNothing);
    });

    testWidgets('§8.4: Mirror Lake on the map; the cove once revealed', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, level: 5, location: 'mirror_lake');
      await openTab(t, 'world');
      expect(find.byKey(const ValueKey('area-mirror_lake')), findsOneWidget);
      expect(find.byKey(const ValueKey('area-smugglers_cove')), findsNothing);
      c.state.revealed.add('smugglers_cove');
      await redraw(t, 'world');
      expect(find.byKey(const ValueKey('area-smugglers_cove')), findsOne);
      expect(
        within('area-smugglers_cove', find.text("Smugglers' Cove")),
        findsOneWidget,
      );
    });

    testWidgets('§8.4: waters are drawn as water, not hills', (t) async {
      final (c, _) = await pumpGame(t, level: 5);
      c.state.revealed.add('smugglers_cove');
      c.state.explored.add('mirror_lake');
      await openTab(t, 'world');
      for (final area in ['mirror_lake', 'smugglers_cove']) {
        expect(within('area-$area', find.byIcon(Icons.water)), findsOne);
      }
      expect(
        within('area-copper_hills', find.byIcon(Icons.water)),
        findsNothing,
      );
    });
  });
}

/// Starts the app on a save from [json] (a fixture file's contents).
Future<GameController> pumpSave(
  WidgetTester tester,
  Map<String, Object?> json,
) async {
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  now = DateTime(2026, 10, 18, 9);
  final source = FakeStepSource();
  final c = GameController(
    game: game,
    source: source,
    permissions: source,
    store: MemorySaveStore(json),
    clock: () => now,
    syncInterval: null,
    newSeed: () => 1,
  );
  addTearDown(c.dispose);
  await tester.pumpWidget(WalkingRpgApp(controller: c));
  await c.start();
  await tester.pump();
  return c;
}

/// Your character: spec 0012 criteria 1, 2, 6 (screen side), 7, 8 and 9
/// (plan 0014 M2).
void yourCharacter() {
  group('your character (spec 0012)', () {
    Finder key(String k) => find.byKey(ValueKey(k));
    Finder within(String k, Finder f) =>
        find.descendant(of: key(k), matching: f);
    String textOf(WidgetTester t, String k) => t.widget<Text>(key(k)).data!;
    const oldSaveLine =
        "Your progress stays. Your origin's profession rises to level 5 if "
        'it is lower.';

    Future<void> setOut(
      WidgetTester t,
      GameController c,
      String origin, {
      String? name,
    }) async {
      if (name != null) {
        await t.enterText(key('character-name-field'), name);
      }
      await t.ensureVisible(key('origin-$origin'));
      await t.tap(key('origin-$origin'));
      await t.pump();
      await t.ensureVisible(key('set-out'));
      await t.tap(key('set-out'));
      await settle(t, c);
    }

    testWidgets('criterion 1: a save with no character opens "Who are '
        'you?", which only Set out leaves', (t) async {
      final (c, _) = await pumpGame(t, level: 6, character: null);
      expect(find.text('Who are you?'), findsOneWidget);
      expect(find.byType(HomeShell), findsNothing);
      expect(find.byType(BackButton), findsNothing);
      // An old save is told its progress stays (spec 0012 §4.1).
      expect(find.text(oldSaveLine), findsOneWidget);
      await setOut(t, c, 'hunters_apprentice', name: 'Zkalf');
      expect(find.byType(HomeShell), findsOneWidget);
      expect(c.state.character!.name, 'Zkalf');
      expect(c.state.character!.origin, 'hunters_apprentice');
      expect(c.game.level(c.state), 6, reason: 'progress stays');
      expect(c.game.professionLevel(c.state, 'hunting'), 6);
    });

    testWidgets('criterion 1: before level-up cards and the away screen', (
      t,
    ) async {
      final (c, source) = await pumpGame(
        t,
        xp: game.data.xpForLevel(2) - 1,
        location: 'goblin_woods',
        character: null,
      );
      await c.startActivity(Activity.fight('goblin'));
      source.walk(DateTime(2026, 10, 18, 10), 200);
      now = DateTime(2026, 10, 18, 11);
      await c.resume();
      await t.pump();
      expect(c.levelCards, isNotEmpty);
      expect(find.text('Who are you?'), findsOneWidget);
      expect(find.text('Level 2!'), findsNothing);
      await setOut(t, c, 'miners_child');
      expect(find.text('Level 2!'), findsOneWidget);
    });

    testWidgets('criterion 2: name, gender, six origin cards; Set out waits '
        'for an origin', (t) async {
      final (c, _) = await pumpGame(t, learned: false, character: null);
      expect(
        t.widget<TextField>(key('character-name-field')).decoration!.hintText,
        'Wanderer',
      );
      final gender = t.widget<SegmentedButton<Gender>>(
        find.byType(SegmentedButton<Gender>),
      );
      expect(gender.selected, {Gender.neither});
      for (final w in ['Male', 'Female', 'Neither']) {
        expect(find.text(w), findsOneWidget);
      }
      expect(find.text(oldSaveLine), findsNothing, reason: 'a new game');
      for (final o in game.data.origins.values) {
        expect(key('origin-${o.id}'), findsOneWidget);
      }
      expect(
        within('origin-coast_fisher', find.text('Fisher from the coast')),
        findsOneWidget,
      );
      expect(
        within(
          'origin-coast_fisher',
          find.text(
            '"You learned to read the water before you could read words."',
          ),
        ),
        findsOneWidget,
      );
      expect(
        within(
          'origin-coast_fisher',
          find.text(
            'Starts with Fishing 5 · Wen, the fisherman, greets you as kin',
            findRichText: true,
          ),
        ),
        findsOneWidget,
      );
      expect(
        t.widget<FilledButton>(key('set-out')).onPressed,
        isNull,
        reason: 'no origin yet',
      );
      await t.tap(key('origin-coast_fisher'));
      await t.pump();
      expect(t.widget<FilledButton>(key('set-out')).onPressed, isNotNull);
      expect(c.state.character, isNull, reason: 'only Set out makes it');
    });

    testWidgets('criterion 3: an empty name sets out as Wanderer; names stop '
        'at 20', (t) async {
      final (c, _) = await pumpGame(t, character: null);
      expect(t.widget<TextField>(key('character-name-field')).maxLength, 20);
      await setOut(t, c, 'tavern_cook', name: '   ');
      expect(c.state.character!.name, 'Wanderer');
    });

    testWidgets('criterion 4: Set out on a new game learns the origin at 5', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, learned: false, character: null);
      await setOut(t, c, 'smiths_apprentice');
      expect(c.state.learned, {'crafting'});
      expect(c.state.tools['crafting'], 'old_hammer');
      expect(c.game.professionLevel(c.state, 'crafting'), 5);
      expect(c.game.level(c.state), 1);
    });

    testWidgets('criterion 6: gendered titles follow the picked gender', (
      t,
    ) async {
      await pumpGame(t, character: null);
      expect(find.text("Woodcutter's child"), findsOneWidget);
      await t.tap(find.text('Male'));
      await t.pump();
      expect(find.text("Woodcutter's son"), findsOneWidget);
      await t.tap(find.text('Female'));
      await t.pump();
      expect(find.text("Woodcutter's daughter"), findsOneWidget);
    });

    testWidgets('criterion 6: changing gender in Settings changes them '
        'everywhere at once', (t) async {
      final (c, _) = await pumpGame(
        t,
        level: 12,
        character: const Character(
          name: 'Ada',
          gender: Gender.male,
          origin: 'woodcutters_child',
        ),
      );
      c.state.tips.add('bram_10');
      await openTab(t, 'character');
      expect(textOf(t, 'character-origin'), "· Woodcutter's son");
      await openSettings(t);
      await t.tap(key('settings-gender'));
      await t.pumpAndSettle();
      await t.tap(find.text('Female').last);
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.character!.gender, Gender.female);
      expect(within('settings-gender', find.text('Female')), findsOneWidget);
      await t.pageBack();
      await t.pumpAndSettle();
      expect(textOf(t, 'character-origin'), "· Woodcutter's daughter");
      // Bram's level 10 tip, in the Lore tab.
      await t.tap(key('journal-button'));
      await t.pumpAndSettle();
      await t.tap(find.text('Lore'));
      await t.pumpAndSettle();
      expect(find.textContaining('Point first, lass.'), findsOneWidget);
    });

    testWidgets('criterion 7: teachers greet by name; the kin teacher says '
        'the kin line instead of the learn line', (t) async {
      final (c, _) = await pumpGame(
        t,
        learned: false,
        character: const Character(
          name: 'Ada',
          gender: Gender.female,
          origin: 'coast_fisher',
        ),
      );
      c.state
        ..learned.add('fishing')
        ..tools['fishing'] = 'old_rod';
      await t.tap(key('teacher-mining'));
      await t.pumpAndSettle();
      expect(textOf(t, 'teacher-line'), '"Back from the hills, Ada?"');
      expect(key('learn-mining'), findsOneWidget);
      await closeSheet(t);

      await t.tap(key('teacher-fishing'));
      await t.pumpAndSettle();
      expect(
        textOf(t, 'teacher-line'),
        "\"A coast lass! Salt in your hair, Ada. Take my old rod; you'll not "
        'need telling how."',
      );
      expect(find.textContaining('Bring me back some fish'), findsNothing);
      await closeSheet(t);

      // A learned teacher of another origin: greeting, then the learn line.
      await c.learn('cooking');
      await t.pumpAndSettle();
      await t.tap(key('teacher-cooking'));
      await t.pumpAndSettle();
      expect(textOf(t, 'teacher-line'), '"Hungry, Ada?"');
      expect(find.textContaining("Here's my old pot."), findsOneWidget);
    });

    testWidgets('criterion 8: the header and the journal title name the '
        'player', (t) async {
      await pumpGame(
        t,
        character: const Character(
          name: 'Zkalf',
          gender: Gender.neither,
          origin: 'coast_fisher',
        ),
      );
      await openTab(t, 'character');
      expect(textOf(t, 'character-name'), 'Zkalf');
      expect(find.text('Recruit'), findsOneWidget);
      expect(textOf(t, 'character-origin'), '· Fisher from the coast');
      await t.tap(key('journal-button'));
      await t.pumpAndSettle();
      expect(find.text("Zkalf's journal"), findsOneWidget);
    });

    testWidgets('criterion 9: Settings change the name and show the origin', (
      t,
    ) async {
      final (c, _) = await pumpGame(t);
      await openSettings(t);
      expect(within('settings-name', find.text('Ada')), findsOneWidget);
      expect(within('settings-gender', find.text('Neither')), findsOneWidget);
      expect(
        within('settings-origin', find.text('Tavern cook')),
        findsOneWidget,
      );
      expect(
        within('settings-origin', find.text('Chosen when you set out')),
        findsOneWidget,
      );
      expect(t.widget<ListTile>(key('settings-origin')).onTap, isNull);

      await t.tap(key('settings-name'));
      await t.pumpAndSettle();
      expect(t.widget<TextField>(key('rename-field')).maxLength, 20);
      await t.enterText(key('rename-field'), '  Brann ');
      await t.tap(find.text('Save'));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.character!.name, 'Brann');
      expect(within('settings-name', find.text('Brann')), findsOneWidget);
    });
  });
}

/// The owner's playtest notes after 0.3.0's build.
void playtest3() {
  group('playtest 3', () {
    testWidgets('starting an action from World goes to Now', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await openArea(t, 'goblin_woods');
      await tapAndStart(t, option('fight', 'goblin'));
      expect(c.state.activity!.activity, const Activity.fight('goblin'));
      final bar = t.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 0, reason: 'Now');
    });

    testWidgets('starting an action from Professions goes to Now', (t) async {
      final (c, _) = await pumpGame(t, location: 'copper_hills');
      await openTab(t, 'professions');
      await t.ensureVisible(find.byKey(const ValueKey('go-mining')));
      await tapAndStart(t, find.byKey(const ValueKey('go-mining')));
      expect(c.state.activity, isNotNull);
      final bar = t.widget<NavigationBar>(find.byType(NavigationBar));
      expect(bar.selectedIndex, 0, reason: 'Now');
    });

    testWidgets('Achievements marks the ones not seen yet as new', (t) async {
      final (c, _) = await pumpGame(t);
      c.state.achievements.add('first_steps');
      await t.pump();
      Finder isNew(String id) => find.byKey(ValueKey('achievement-new-$id'));

      await openAchievements(t);
      expect(isNew('first_steps'), findsOneWidget);
      expect(isNew('marathon'), findsNothing, reason: 'not earned');
      await t.pageBack();
      await t.pumpAndSettle();

      await openAchievements(t);
      expect(isNew('first_steps'), findsNothing, reason: 'seen');
    });

    test('a learned weakness points to the Bestiary', () {
      expect(
        Labels(_game.data).weaknessLearned('goblin'),
        contains('Bestiary'),
      );
    });
  });
}

void professionFilters() {
  group('profession buttons and filters (spec 0010 amendment 3)', () {
    Finder recipe(String id) => find.byKey(ValueKey('option-craft-$id'));
    Iterable<RecipeDef> lists(Game g) => g.data.recipes.values.where(
      (r) => r.profession == 'crafting' || r.profession == 'cooking',
    );
    Future<void> chip(WidgetTester t, String id) async {
      await t.tap(find.byKey(ValueKey('filter-$id')));
      await t.pumpAndSettle();
    }

    bool selected(WidgetTester t, String id) =>
        t.widget<FilterChip>(find.byKey(ValueKey('filter-$id'))).selected;

    testWidgets('criterion 1: a button brings its card into view', (t) async {
      await pumpGame(t, level: 5);
      await openTab(t, 'professions');
      t.view.physicalSize = const Size(1080, 2400);
      await t.pumpAndSettle();
      final card = find.byKey(const ValueKey('profession-cooking'));
      expect(t.getTopLeft(card).dy, greaterThan(2400), reason: 'far down');
      await t.tap(find.byKey(const ValueKey('jump-cooking')));
      await t.pumpAndSettle();
      expect(t.getTopLeft(card).dy, inInclusiveRange(0, 2400));
    });

    testWidgets('criteria 2 and 4: each filter shows what its rule says', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        level: 5,
        inventory: {'copper_ore': 50, 'oak_log': 20},
      );
      await openTab(t, 'professions');
      final g = c.game;
      final s = c.state;
      void expectShown(bool Function(RecipeDef r) rule, String why) {
        for (final r in lists(g)) {
          expect(
            recipe(r.id),
            rule(r) ? findsOneWidget : findsNothing,
            reason: '$why: ${r.id}',
          );
        }
      }

      expectShown((_) => true, 'no filter');
      await chip(t, 'mats');
      expectShown((r) => g.hasMaterials(s, r.id), 'have mats');
      await chip(t, 'level');
      expectShown(
        (r) => g.hasMaterials(s, r.id) && g.recipeLevelMet(s, r.id),
        'have mats and level',
      );
      await chip(t, 'mats');
      expectShown((r) => g.recipeLevelMet(s, r.id), 'have level');
      await chip(t, 'ahead');
      expectShown(
        (r) => r.craftingLevel <= g.professionLevel(s, r.profession) + 5,
        'up to 5 levels ahead',
      );
      await chip(t, 'ahead');
      expectShown((_) => true, 'all off again');
    });

    testWidgets(
      'criterion 3: Have level and Up to 5 ahead exclude each other',
      (t) async {
        await pumpGame(t, level: 5);
        await openTab(t, 'professions');
        await chip(t, 'level');
        await chip(t, 'ahead');
        expect(selected(t, 'ahead'), isTrue);
        expect(selected(t, 'level'), isFalse);
        await chip(t, 'mats');
        expect(selected(t, 'mats'), isTrue);
        expect(selected(t, 'ahead'), isTrue);
        await chip(t, 'level');
        expect(selected(t, 'level'), isTrue);
        expect(selected(t, 'ahead'), isFalse);
        expect(selected(t, 'mats'), isTrue);
      },
    );

    testWidgets('an empty list says nothing matches; the running craft stays', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, level: 5, inventory: {'copper_ore': 50});
      final craft = lists(c.game).firstWhere(
        (r) => c.game.hasMaterials(c.state, r.id) && r.profession == 'crafting',
      );
      await c.startActivity(Activity.craft(craft.id));
      c.state.inventory.clear();
      await openTab(t, 'professions');
      await chip(t, 'mats');
      expect(recipe(craft.id), findsOneWidget, reason: 'running');
      expect(find.byKey(const ValueKey('no-match-cooking')), findsOneWidget);
    });
  });
}
