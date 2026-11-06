// Pictures for the actions in the queue: spec 0014 amendment 8 criteria
// 1-12 (plan 0047).
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/game_controller.dart';
import 'package:walkingrpg/ui/action_sheet.dart';
import 'package:walkingrpg/ui/bestiary_card.dart';
import 'package:walkingrpg/ui/images.dart';

import 'images_test.dart'
    show diskImages, expectRing, expectShows, qualityRgb, socketIn;
import 'now_monsters_test.dart' show inside;
import 'ui_test.dart';

/// The game with [slots] queue slots in `economy.json`.
Game gameWithSlots(int slots) {
  final files = {
    for (final f in Directory(
      '../packages/game_core/data',
    ).listSync().whereType<File>())
      if (f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
  };
  final economy = jsonDecode(files['economy']!) as Map<String, Object?>;
  economy['queueSlots'] = slots;
  files['economy'] = jsonEncode(economy);
  return Game(GameData.fromJsonStrings(files));
}

void main() {
  final data = game.data;
  final reroll = data.keyFor('bone_sword', 'uncommon');
  const craft = Activity.craft('copper_sword');
  const fight = Activity.fight('goblin');
  const gather = Activity.gather('oak_tree');
  const walk = Activity.travel('goblin_woods');

  /// At Camp: a craft runs; a reroll, the walk to Goblin Woods, a fight and
  /// a gather wait.
  Future<GameController> fullQueue(WidgetTester t) async {
    final (c, _) = await pumpGame(
      t,
      images: diskImages,
      level: 5,
      inventory: {'copper_ore': 5, reroll: 1, 'uncommon_dust': 3},
    );
    await c.addAction(craft, stop: StopCondition.untilCrafted(1));
    await c.addAction(Activity.reroll(reroll));
    await c.addAction(fight, stop: StopCondition.untilHave('goblin_hide', 2));
    await c.addAction(gather, stop: StopCondition.untilHave('oak_log', 5));
    await settle(t, c);
    await openTab(t, 'now');
    await t.pumpAndSettle();
    expect(
      [for (final q in c.state.queue) q.activity],
      [Activity.reroll(reroll), walk, fight, gather],
      reason: 'the queue of the test',
    );
    return c;
  }

  Finder queued(int i) => find.byKey(ValueKey('queued-$i'));
  Finder current() => find.byKey(const ValueKey('queue-picture-0'));

  group('the queue card', () {
    for (final (where, activity, location) in [
      ('a fight', fight, 'goblin_woods'),
      ('a gather', gather, 'goblin_woods'),
      ('a craft', craft, 'camp'),
      ('a walk', walk, 'camp'),
    ]) {
      testWidgets("criterion 1: the current action's row starts with its "
          'picture in a 48 dp socket, for $where', (t) async {
        final (c, _) = await pumpGame(
          t,
          images: diskImages,
          level: 5,
          location: location,
          inventory: {'copper_ore': 5},
        );
        await c.addAction(activity);
        await settle(t, c);
        await openTab(t, 'now');
        await t.pumpAndSettle();
        expect(c.state.activity?.activity, activity);
        final socket = socketIn(current());
        expect(t.getSize(socket), const Size(48, 48), reason: where);
        expectShows(t, socket, thingOf(data, activity), where);
        // Before the action's name, on its line.
        final stop = find.byKey(const ValueKey('stop-activity'));
        expect(
          t.getRect(socket).right,
          lessThan(t.getRect(stop).left),
          reason: where,
        );
        expect(
          t.getRect(socket).left,
          lessThan(32),
          reason: '$where: the picture starts the row',
        );
      });
    }

    testWidgets("criterion 2: each waiting action's row starts with its "
        'picture in a 48 dp socket', (t) async {
      final c = await fullQueue(t);
      for (final (i, q) in c.state.queue.indexed) {
        final what = '${q.activity}';
        final socket = socketIn(queued(i));
        expect(t.getSize(socket), const Size(48, 48), reason: what);
        expectShows(t, socket, thingOf(data, q.activity), what);
        // The picture starts the row: the number badge sits on it, and every
        // word of the row stands to its right.
        final p = t.getRect(socket);
        expect(p.left, lessThan(32), reason: what);
        final badge = find.byKey(const ValueKey('action-number'));
        for (final e in inside(queued(i), find.byType(Text)).evaluate()) {
          if (find
              .ancestor(of: find.byWidget(e.widget), matching: badge)
              .evaluate()
              .isNotEmpty) {
            continue;
          }
          final r = t.getRect(find.byWidget(e.widget));
          expect(r.left, greaterThan(p.right), reason: '$what: ${e.widget}');
        }
      }
    });

    testWidgets('criterion 3: a craft of gear shows the ring of the quality '
        'of its item', (t) async {
      await fullQueue(t);
      expectRing(t, current(), qualityRgb('common'), 'the craft');
    });

    testWidgets('criterion 4: a reroll shows the ring of the quality of its '
        'item', (t) async {
      await fullQueue(t);
      expectRing(t, queued(0), qualityRgb('uncommon'), 'the reroll');
    });

    testWidgets('criterion 5: each waiting row shows its number as a badge on '
        'its picture', (t) async {
      final c = await fullQueue(t);
      for (var i = 0; i < c.state.queue.length; i++) {
        final badge = inside(
          queued(i),
          find.byKey(const ValueKey('action-number')),
        );
        expect(
          inside(badge, find.text('${i + 2}')),
          findsOneWidget,
          reason: 'row ${i + 2}',
        );
        // On the top-left corner of the picture.
        final b = t.getRect(badge);
        final p = t.getRect(socketIn(queued(i)));
        expect(b.overlaps(p), isTrue, reason: 'row ${i + 2}');
        expect(b.left, lessThan(p.left + 4), reason: 'row ${i + 2}');
        expect(b.top, lessThan(p.top + 4), reason: 'row ${i + 2}');
        expect(b.center.dx, lessThan(p.left + 12), reason: 'row ${i + 2}');
        expect(b.center.dy, lessThan(p.top + 12), reason: 'row ${i + 2}');
      }
    });

    testWidgets('criterion 6: with two or more slots, the current action shows '
        'the badge 1', (t) async {
      await fullQueue(t);
      expect(
        inside(current(), find.byKey(const ValueKey('action-number'))),
        findsOneWidget,
      );
      expect(inside(current(), find.text('1')), findsOneWidget);
    });

    // Criterion 7 (one slot, no number) has no test: the game data refuses
    // fewer than two queue slots ("queueSlots must be >= 2"), and talents
    // only add slots. The queue card keeps the guard `slots > 1`.
    test('criterion 7: the data never gives one slot', () {
      expect(
        () => gameWithSlots(1),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('queueSlots must be >= 2'),
          ),
        ),
      );
    });

    testWidgets('criterion 8: no waiting row shows the old number circle', (
      t,
    ) async {
      final c = await fullQueue(t);
      for (var i = 0; i < c.state.queue.length; i++) {
        expect(
          inside(queued(i), find.byType(CircleAvatar)),
          findsNothing,
          reason: 'row ${i + 2}',
        );
      }
      expect(inside(current(), find.byType(CircleAvatar)), findsNothing);
    });

    testWidgets('criterion 9: a tap on a waiting row opens its change sheet, '
        'and Remove removes it', (t) async {
      final c = await fullQueue(t);
      // The fight: its stop condition can change.
      await t.ensureVisible(queued(2));
      await t.pumpAndSettle();
      await t.tap(queued(2));
      await t.pumpAndSettle();
      expect(find.byType(ActionSheet), findsOneWidget);
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();
      await t.ensureVisible(find.byKey(const ValueKey('remove-4')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('remove-4')));
      await settle(t, c);
      expect(
        [for (final q in c.state.queue) q.activity],
        [Activity.reroll(reroll), walk, fight],
      );
    });
  });

  group('the action sheet', () {
    /// Opens the sheet of [a] as the player does: a tap on its row, on Now
    /// at [location] or on the Crafting screen.
    Future<void> openSheet(WidgetTester t, Activity a, String location) async {
      await pumpGame(t, images: diskImages, level: 5, location: location);
      if (a.kind == ActivityKind.craft) await openProfession(t, 'crafting');
      final row = option(a.kind.name, a.target);
      await t.ensureVisible(row);
      await t.pumpAndSettle();
      await t.tap(row);
      await t.pumpAndSettle();
      expect(find.byType(ActionSheet), findsOneWidget);
    }

    for (final (n, what, activity, location, title) in [
      (10, 'a gather', gather, 'goblin_woods', 'Oak tree'),
      (11, 'a craft', craft, 'camp', 'Copper sword'),
    ]) {
      testWidgets('criterion $n: the sheet of $what starts with its picture in '
          'a 72 dp socket, beside the title', (t) async {
        await openSheet(t, activity, location);
        final sheet = find.byType(ActionSheet);
        final socket = socketIn(
          inside(sheet, find.byKey(const ValueKey('sheet-picture'))),
        );
        expect(t.getSize(socket), const Size(72, 72), reason: what);
        expectShows(t, socket, thingOf(data, activity), what);
        // Beside the title, and before "Stop when".
        final name = t.getRect(inside(sheet, find.text(title)));
        final p = t.getRect(socket);
        expect(name.left, greaterThan(p.right), reason: what);
        expect(
          p.top < name.center.dy && name.center.dy < p.bottom,
          isTrue,
          reason: '$what: the title on the line of the picture',
        );
        expect(
          p.bottom,
          lessThanOrEqualTo(
            t.getRect(inside(sheet, find.text('Stop when'))).top,
          ),
          reason: '$what: the picture comes first',
        );
      });
    }

    testWidgets('criterion 12: the sheet of a fight still starts with the '
        "monster's card", (t) async {
      await openSheet(t, fight, 'goblin_woods');
      expect(find.byType(BestiaryCard), findsOneWidget);
      expect(find.byKey(const ValueKey('sheet-picture')), findsNothing);
    });
  });
}
