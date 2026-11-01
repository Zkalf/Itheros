// The talent screens and the trainer: spec 0015 criteria 31-32 (on screen),
// 39-40 (on screen), 48-49 and 52-54 (plan 0031 M2), and the tree of
// amendment 3, criteria 77-97 (plan 0032).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

import 'package:walkingrpg/ui/labels.dart';
import 'package:walkingrpg/ui/level_up_screen.dart';

import 'support.dart';
import 'ui_test.dart' show closeSheet, openTab, pumpGame, settle;

void main() {
  Finder within(String key, Finder f) =>
      find.descendant(of: find.byKey(ValueKey(key)), matching: f);

  Future<void> openTalents(WidgetTester t) async {
    await openTab(t, 'character');
    await t.tap(find.byKey(const ValueKey('tab-talents')));
    await t.pumpAndSettle();
  }

  group('the Talents tab', () {
    testWidgets('criteria 48-49: a tab after Gear and Bag, with the points', (
      t,
    ) async {
      await pumpGame(t, level: 12);
      await openTalents(t);
      final x = [
        for (final k in ['tab-gear', 'tab-bag', 'tab-talents'])
          t.getTopLeft(find.byKey(ValueKey(k))).dx,
      ];
      expect(x[0] < x[1] && x[1] < x[2], isTrue);
      expect(find.text('3 points left'), findsOneWidget);
      expect(find.textContaining('Combat · 0'), findsOneWidget);
      expect(find.textContaining('Utility · 0'), findsOneWidget);
    });

    testWidgets('before level 10: talents open at level 10', (t) async {
      await pumpGame(t, level: 9);
      await openTalents(t);
      expect(find.text('Talents open at level 10.'), findsOneWidget);
    });

    testWidgets('criteria 52, 88: Learn takes a rank and raises the badge', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, level: 12);
      await openTalents(t);
      await t.tap(find.byKey(const ValueKey('talent-might')));
      await t.pumpAndSettle();
      expect(within('talent-sheet', find.text('Rank 0 of 5')), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('learn-talent')));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.talents['might'], 1);
      expect(within('talent-sheet', find.text('Rank 1 of 5')), findsOneWidget);
      await closeSheet(t);
      expect(within('badge-might', find.text('1/5')), findsOneWidget);
      expect(find.text('2 points left'), findsOneWidget);
    });

    testWidgets('a talent with no points left says why', (t) async {
      await pumpGame(t, level: 9);
      await openTalents(t);
      await t.tap(find.byKey(const ValueKey('talent-might')));
      await t.pumpAndSettle();
      expect(
        within('talent-sheet', find.text('No points left')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('learn-talent')), findsNothing);
    });
  });

  group('the tree (amendment 3)', () {
    /// Every widget whose key starts with [prefix].
    Finder keyed(String prefix) => find.byWidgetPredicate(
      (w) =>
          w.key is ValueKey<String> &&
          (w.key! as ValueKey<String>).value.startsWith(prefix),
    );

    Offset at(WidgetTester t, String id) =>
        t.getCenter(find.byKey(ValueKey('talent-$id')));

    /// The talent's icon in [state]: closed, open, learn or full.
    Finder node(String state, String id) =>
        find.byKey(ValueKey('node-$state-$id'));

    double opacityOf(WidgetTester t, String id) => t
        .widget<Opacity>(within('talent-$id', find.byType(Opacity)).first)
        .opacity;

    testWidgets('criteria 77-78: icons at their rows and columns', (t) async {
      await pumpGame(t, level: 12);
      await openTalents(t);
      expect(find.byKey(const ValueKey('talent-grid')), findsOneWidget);
      final might = at(t, 'might'); // row 1, column 1
      final toughness = at(t, 'toughness'); // row 1, column 3
      final guard = at(t, 'guard'); // row 2, column 1
      final swift = at(t, 'swift_strikes'); // row 3, column 2
      expect(toughness.dy, might.dy);
      expect(toughness.dx, greaterThan(might.dx));
      expect(guard.dx, might.dx);
      expect(guard.dy, greaterThan(might.dy));
      expect(swift.dy, greaterThan(guard.dy));
      expect(swift.dx, closeTo((might.dx + toughness.dx) / 2, 1));
      // One tree at a time: no Utility talent shows.
      expect(find.byKey(const ValueKey('talent-deep_pockets')), findsNothing);
    });

    testWidgets('criteria 79-80: the name and the ranks of each icon', (
      t,
    ) async {
      await pumpGame(t, level: 12, prepare: (s) => s.talents['might'] = 2);
      await openTalents(t);
      expect(within('talent-might', find.text('Might')), findsOneWidget);
      expect(within('badge-might', find.text('2/5')), findsOneWidget);
      expect(within('badge-guard', find.text('0/3')), findsOneWidget);
    });

    testWidgets('criteria 81-82: the line only on the sheet; a tap opens it', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, level: 12);
      await openTalents(t);
      final line = c.game.data.talents['might']!.line;
      expect(find.text(line), findsNothing);
      await t.tap(find.byKey(const ValueKey('talent-might')));
      await t.pumpAndSettle();
      expect(within('talent-sheet', find.text(line)), findsOneWidget);
      expect(within('talent-sheet', find.text('Might')), findsOneWidget);
    });

    testWidgets('criteria 83, 85: a closed row; an icon that can learn', (
      t,
    ) async {
      await pumpGame(t, level: 12);
      await openTalents(t);
      expect(node('learn', 'might'), findsOneWidget);
      expect(node('closed', 'guard'), findsOneWidget);
      expect(opacityOf(t, 'guard'), .4);
      expect(opacityOf(t, 'might'), 1);
    });

    testWidgets('criterion 87: no points left, an open icon has no ring', (
      t,
    ) async {
      await pumpGame(t, level: 10, prepare: (s) => s.talents['might'] = 1);
      await openTalents(t);
      expect(node('open', 'might'), findsOneWidget);
      expect(node('open', 'toughness'), findsOneWidget);
    });

    testWidgets('criteria 84, 86: a needed talent not full; a full one', (
      t,
    ) async {
      await pumpGame(
        t,
        level: 40,
        prepare: (s) => s.talents.addAll({
          'might': 5,
          'toughness': 5,
          'guard': 3,
          'keen_eye': 2,
          'swift_strikes': 5,
          'precision': 3,
          'evasion': 2,
        }),
      );
      await openTalents(t);
      expect(node('full', 'might'), findsOneWidget);
      expect(node('learn', 'keen_eye'), findsOneWidget);
      // Row 6 opens at 25 ranks, but Keen eye has 2 of 3.
      expect(node('closed', 'impale'), findsOneWidget);
      expect(opacityOf(t, 'impale'), .4);
    });

    testWidgets('criteria 89, 92, 94: one faint line in Combat', (t) async {
      await pumpGame(t, level: 12);
      await openTalents(t);
      expect(keyed('line-'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('line-keen_eye-impale-faint')),
        findsOneWidget,
      );
    });

    testWidgets('criterion 93: a line is teal when its talent is full', (
      t,
    ) async {
      await pumpGame(t, level: 20, prepare: (s) => s.talents['keen_eye'] = 3);
      await openTalents(t);
      expect(
        find.byKey(const ValueKey('line-keen_eye-impale-teal')),
        findsOneWidget,
      );
    });

    testWidgets('criteria 90-91, 94: two lines in Utility', (t) async {
      await pumpGame(t, level: 12);
      await openTalents(t);
      await t.tap(find.byKey(const ValueKey('tree-utility')));
      await t.pumpAndSettle();
      expect(keyed('line-'), findsNWidgets(2));
      expect(
        find.byKey(const ValueKey('line-master_crafter-lucky_hammer-faint')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('line-light_pack-wayfarer-faint')),
        findsOneWidget,
      );
    });

    testWidgets('criteria 51, 95-96: one "Opens at" line, above row 2', (
      t,
    ) async {
      await pumpGame(t, level: 20);
      await openTalents(t);
      expect(find.textContaining('Opens at'), findsOneWidget);
      final opens = find.byKey(const ValueKey('opens-at'));
      expect(
        find.descendant(
          of: opens,
          matching: find.text('Opens at 5 points in Combat'),
        ),
        findsOneWidget,
      );
      final y = t.getCenter(opens).dy;
      expect(y, greaterThan(at(t, 'might').dy));
      expect(y, lessThan(at(t, 'guard').dy));
    });

    testWidgets('criterion 95: the number follows the ranks', (t) async {
      await pumpGame(
        t,
        level: 20,
        prepare: (s) => s.talents.addAll({'might': 5, 'toughness': 2}),
      );
      await openTalents(t);
      expect(find.text('Opens at 10 points in Combat'), findsOneWidget);
    });

    testWidgets('criterion 97: all rows open, no "Opens at" line', (t) async {
      await pumpGame(
        t,
        level: 40,
        prepare: (s) => s.talents.addAll({
          'might': 5,
          'toughness': 5,
          'guard': 3,
          'keen_eye': 3,
          'swift_strikes': 5,
          'precision': 3,
          'evasion': 1,
        }),
      );
      await openTalents(t);
      expect(find.textContaining('Opens at'), findsNothing);
    });
  });

  group('review of PR 152', () {
    testWidgets('a double tap on Learn takes one rank', (t) async {
      final (c, source) = await pumpGame(t, level: 12);
      await openTalents(t);
      await t.tap(find.byKey(const ValueKey('talent-might')));
      await t.pumpAndSettle();
      // The sync before the rank waits, as on a phone: the second tap
      // comes while the first one is on its way.
      final sync = Completer<void>();
      source.gate = sync.future;
      await t.tap(find.byKey(const ValueKey('learn-talent')));
      await t.pump();
      await t.tap(
        find.byKey(const ValueKey('learn-talent')),
        warnIfMissed: false,
      );
      source.gate = null;
      sync.complete();
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.talents['might'], 1);
    });

    testWidgets('too few steps in the bank: the price shows, no button', (
      t,
    ) async {
      await pumpGame(
        t,
        level: 12,
        prepare: (s) => s
          ..talents['might'] = 1
          ..talentResets = 1
          ..bank = 1500,
      );
      await t.tap(find.byKey(const ValueKey('trainer')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('reset-talents')), findsNothing);
      expect(
        within('trainer-sheet', find.text('You need 2,000 steps in the bank.')),
        findsOneWidget,
      );
    });
  });

  group('Ysolde, the trainer', () {
    testWidgets('criterion 53: in Camp, with a dot when points are left', (
      t,
    ) async {
      await pumpGame(t, level: 12);
      expect(find.byKey(const ValueKey('trainer')), findsOneWidget);
      expect(find.byKey(const ValueKey('trainer-dot')), findsOneWidget);
    });

    testWidgets('no dot when no points are left', (t) async {
      await pumpGame(t, level: 10, prepare: (s) => s.talents['might'] = 1);
      expect(find.byKey(const ValueKey('trainer-dot')), findsNothing);
    });

    testWidgets('criteria 39-40 on screen: free, then a price; confirmed', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        level: 12,
        prepare: (s) => s
          ..talents['might'] = 2
          ..bank = 5000,
      );
      await t.tap(find.byKey(const ValueKey('trainer')));
      await t.pumpAndSettle();
      expect(
        within('trainer-sheet', find.text('Forget my talents')),
        findsOneWidget,
      );
      await t.tap(find.byKey(const ValueKey('reset-talents')));
      await t.pumpAndSettle();
      expect(
        find.text('Forget every talent? Your points come back to spend again.'),
        findsOneWidget,
      );
      await t.tap(find.text('Forget'));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.talents, isEmpty);
      // In quotes, like the teachers' lines.
      expect(find.text('"There. Walk a new road."'), findsOneWidget);
      c.state.talents['might'] = 1;
      await closeSheet(t);
      await t.tap(find.byKey(const ValueKey('trainer')));
      await t.pumpAndSettle();
      expect(
        within('trainer-sheet', find.text('Forget my talents · 2,000 steps')),
        findsOneWidget,
      );
    });

    testWidgets('Keep changes nothing', (t) async {
      final (c, _) = await pumpGame(
        t,
        level: 12,
        prepare: (s) => s.talents['might'] = 2,
      );
      await t.tap(find.byKey(const ValueKey('trainer')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('reset-talents')));
      await t.pumpAndSettle();
      await t.tap(find.text('Keep'));
      await t.pumpAndSettle();
      expect(c.state.talents, {'might': 2});
    });
  });

  group('the deadly-fight warning', () {
    // A level 1 player meets the level 4 Goblin brute: orange.
    Future<void> tapBrute(WidgetTester t) async {
      await t.tap(find.byKey(const ValueKey('option-fight-goblin_brute')));
      await t.pumpAndSettle();
    }

    testWidgets('criterion 31 on screen: Wary warns before an orange fight', (
      t,
    ) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        prepare: (s) => s.talents['wary'] = 1,
      );
      await tapBrute(t);
      expect(find.text('Deadly'), findsOneWidget);
    });

    testWidgets('criterion 32 on screen: no warning without Wary', (t) async {
      await pumpGame(t, location: 'goblin_woods');
      await tapBrute(t);
      expect(find.text('Deadly'), findsNothing);
    });
  });

  testWidgets('criterion 54: no screen says talents arrive later', (t) async {
    await pumpGame(t, level: 12);
    await openTab(t, 'character');
    expect(find.textContaining('arrive in a later update'), findsNothing);
    expect(find.text('3 talent points to spend'), findsOneWidget);
  });

  test('the words of a talent point (spec 0015 §3.2)', () {
    final labels = Labels(loadTestGame().data);
    expect(
      labels.news(const LevelNews(NewsKind.talentPoint, '')),
      '+1 talent point.',
    );
    expect(
      talentPointLine(1),
      '+1 talent point. Spend it on Character → Talents.',
    );
    expect(
      talentPointLine(3),
      '+3 talent points. Spend them on Character → Talents.',
    );
  });
}
