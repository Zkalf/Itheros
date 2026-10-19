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
import 'package:walkingrpg/ui/journal_screen.dart';
import 'package:walkingrpg/ui/labels.dart';

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

    await t.tap(find.byKey(const ValueKey('journal-button')));
    await t.pumpAndSettle();
    expect(find.text('Today 11:00'), findsOneWidget);
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
      expect(before, [
        'Goblin hide',
        'Copper sword (Common)',
        'Hide vest (Common)',
      ]);

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
      await t.tap(find.text('Character'));
      await t.pumpAndSettle();
      await tapRank(t, 6);
      expect(c.testWalkOn, isFalse, reason: 'six is not enough');
      await tapRank(t, 1);
      expect(c.testWalkOn, isTrue);
      expect(find.text('Test walk on'), findsOneWidget);

      await t.tap(find.text('Adventure'));
      await t.pumpAndSettle();
      expect(card, findsOneWidget);

      await t.tap(find.text('Character'));
      await t.pumpAndSettle();
      await tapRank(t, 7);
      expect(c.testWalkOn, isFalse);
      await t.tap(find.text('Adventure'));
      await t.pumpAndSettle();
      expect(card, findsNothing);
    });

    testWidgets(
      'criterion 5: +1,000 walks 1,000 steps, marked in the journal',
      (t) async {
        final (c, _) = await pumpGame(t);
        await c.setTestWalk(true);
        await t.pump();
        await t.tap(find.descendant(of: card, matching: find.text('+1,000')));
        await settle(t, c);
        await t.pump();
        expect(c.state.bank, 1000, reason: 'resting: the steps are banked');
        expect(find.text('You walked 1,000 steps.'), findsOneWidget);

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
      await t.tap(find.text('Achievements'));
      await t.pumpAndSettle();
      expect(find.text('Travelling Salesman'), findsOneWidget);
      expect(find.text('Arrive at all 10 areas'), findsOneWidget);
    });

    testWidgets('no achievement shows a raw counter name', (t) async {
      await pumpGame(t);
      await t.tap(find.text('Achievements'));
      await t.pumpAndSettle();
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
      await t.tap(find.text('Character'));
      await t.pumpAndSettle();
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
    await t.tap(find.text('Character'));
    await t.pumpAndSettle();
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
}
