// The talent screens and the trainer: spec 0015 criteria 13, 31-32 (on
// screen), 39-40 (on screen) and 48-54 (plan 0031 M2).
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

    testWidgets('criterion 50: one pip per rank, the taken ones filled', (
      t,
    ) async {
      await pumpGame(t, level: 20, prepare: (s) => s.talents['might'] = 2);
      await openTalents(t);
      expect(
        within('talent-might', find.byKey(const ValueKey('pip-on'))),
        findsNWidgets(2),
      );
      expect(
        within('talent-might', find.byKey(const ValueKey('pip-off'))),
        findsNWidgets(3),
      );
    });

    testWidgets('criterion 51: a closed row says when it opens', (t) async {
      await pumpGame(t, level: 20);
      await openTalents(t);
      expect(
        within('row-combat-2', find.text('Opens at 5 points in Combat')),
        findsOneWidget,
      );
      expect(
        within('row-combat-1', find.textContaining('Opens at')),
        findsNothing,
      );
    });

    testWidgets('criterion 13: a plate says what it needs', (t) async {
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
      await t.scrollUntilVisible(
        find.byKey(const ValueKey('talent-impale')),
        200,
      );
      expect(
        within('talent-impale', find.text('Needs Keen eye 3/3')),
        findsOneWidget,
      );
    });

    testWidgets('criterion 52: Learn takes a rank and fills a pip', (t) async {
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
      expect(
        within('talent-might', find.byKey(const ValueKey('pip-on'))),
        findsOneWidget,
      );
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

  group('review of PR 152', () {
    testWidgets('a double tap on Learn takes one rank', (t) async {
      final (c, _) = await pumpGame(t, level: 12);
      await openTalents(t);
      await t.tap(find.byKey(const ValueKey('talent-might')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('learn-talent')));
      await t.pump();
      await t.tap(
        find.byKey(const ValueKey('learn-talent')),
        warnIfMissed: false,
      );
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
