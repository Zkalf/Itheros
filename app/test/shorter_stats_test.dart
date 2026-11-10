// A shorter stats block on Character: spec 0008 amendment 7 criteria 1-8
// (plan 0064).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

import 'images_test.dart' show loadFonts;
import 'ui_test.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));
  const stats = ['HP', 'Attack', 'Defense', 'Crit', 'Hit', 'Dodge', 'Block'];
  final row = key('stats-row');

  /// The Fairphone: 408 by 884 dp, with the game's fonts.
  Future<void> phone(WidgetTester t, {double textSize = 1}) async {
    await t.runAsync(loadFonts);
    t.platformDispatcher.textScaleFactorTestValue = textSize;
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> open(WidgetTester t) async {
    t.view.physicalSize = const Size(408, 884);
    await openGear(t);
    await t.pumpAndSettle();
  }

  testWidgets('criterion 1: the level stands on the line of the name, and '
      'the stats row has no Level', (t) async {
    await phone(t);
    await pumpGame(t, level: 12);
    await open(t);
    final level = key('stat-Level');
    expect(
      find.descendant(
        of: level,
        matching: find.text('Level 12', findRichText: true),
      ),
      findsOneWidget,
    );
    final name = t.getRect(key('character-name'));
    final at = t.getRect(level);
    expect(at.center.dy, inInclusiveRange(name.top, name.bottom));
    expect(at.left, greaterThan(name.right));
    expect(find.descendant(of: row, matching: level), findsNothing);
    expect(
      find.descendant(of: row, matching: find.text('Level')),
      findsNothing,
    );
  });

  testWidgets('criteria 2 and 8: at 408 dp the seven stats stand in one row, '
      'in their order, each at least 44 dp wide', (t) async {
    await phone(t);
    // Wide numbers: HP in the hundreds and a shield's Block.
    await pumpGame(
      t,
      level: 30,
      equipment: {'offHand': 'bone_shield', 'chest': 'hide_vest'},
      // The meal line under HP is the widest thing a stat shows.
      prepare: (s) => s
        ..talents['toughness'] = 5
        ..meal = ActiveMeal('grilled_perch', 6000),
    );
    await open(t);
    expect(find.textContaining(' meal'), findsOneWidget);
    final rects = [for (final s in stats) t.getRect(key('stat-$s'))];
    for (final (i, r) in rects.indexed) {
      expect(r.top, rects.first.top, reason: '${stats[i]} on the first row');
      expect(r.width, greaterThanOrEqualTo(44), reason: stats[i]);
      if (i > 0) {
        expect(
          r.left,
          greaterThanOrEqualTo(rects[i - 1].right),
          reason: '${stats[i]} after ${stats[i - 1]}',
        );
      }
    }
    expect(
      find.descendant(
        of: row,
        matching: find.byWidgetPredicate(
          (w) => switch (w.key) {
            ValueKey<String>(:final value) => value.startsWith('stat-'),
            _ => false,
          },
        ),
      ),
      findsNWidgets(7),
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('criterion 3: each stat opens its sheet; the level opens '
      'nothing', (t) async {
    await pumpGame(t, level: 12);
    await openGear(t);
    for (final s in stats) {
      await t.tap(key('stat-$s'));
      await t.pumpAndSettle();
      expect(t.widget<Text>(key('stat-sheet-title')).data, s, reason: s);
      await closeSheet(t);
    }
    await t.tap(key('stat-Level'));
    await t.pumpAndSettle();
    expect(key('stat-sheet'), findsNothing);
  });

  testWidgets('criterion 4: with a meal that adds HP, the line under HP reads '
      '"+N meal"', (t) async {
    final (c, _) = await pumpGame(
      t,
      level: 12,
      prepare: (s) => s.meal = ActiveMeal('grilled_perch', 6000),
    );
    await openGear(t);
    final bonus = c.game.mealBonus(c.state).hp;
    expect(bonus, greaterThan(0));
    expect(
      find.descendant(of: key('stat-HP'), matching: find.text('+$bonus meal')),
      findsOneWidget,
    );
    expect(find.textContaining('(+'), findsNothing);
  });

  testWidgets('criteria 5 and 6: the portrait is 48 dp, and the three tabs '
      'start in the top third of the screen', (t) async {
    await phone(t);
    // The tallest block: a meal line and the talent line.
    await pumpGame(
      t,
      level: 12,
      prepare: (s) => s.meal = ActiveMeal('grilled_perch', 6000),
    );
    await open(t);
    expect(t.getSize(key('character-portrait')), const Size(48, 48));
    expect(key('talent-line'), findsOneWidget);
    expect(t.getTopLeft(key('tab-gear')).dy, lessThan(295));
  });

  // Erratum 1: a name too long for the line pushes the level under it.
  testWidgets('a name of 20 letters: the level stands under the name, and '
      'nothing is cut off', (t) async {
    await phone(t);
    await pumpGame(
      t,
      level: 12,
      character: const Character(
        name: 'Wilhelmina Blackwood',
        gender: Gender.female,
        origin: 'woodcutters_child',
      ),
      prepare: (s) => s.meal = ActiveMeal('grilled_perch', 6000),
    );
    await open(t);
    expect(t.takeException(), isNull);
    final name = t.getRect(key('character-name'));
    final level = t.getRect(key('stat-Level'));
    expect(level.top, greaterThanOrEqualTo(name.bottom));
    expect(level.left, name.left);
    expect(name.right, lessThanOrEqualTo(408));
    // The stats keep their one row.
    final tops = {for (final s in stats) t.getRect(key('stat-$s')).top};
    expect(tops, hasLength(1));
  });

  testWidgets('criterion 7: at text size 2.0 on a 408 dp phone the block '
      'does not overflow', (t) async {
    await phone(t, textSize: 2);
    await pumpGame(
      t,
      level: 30,
      equipment: {'offHand': 'bone_shield', 'chest': 'hide_vest'},
      prepare: (s) => s
        ..talents['toughness'] = 5
        ..meal = ActiveMeal('grilled_perch', 6000),
    );
    await open(t);
    expect(t.takeException(), isNull);
    // The row wraps, and each stat is still on the screen.
    for (final s in stats) {
      final r = t.getRect(key('stat-$s'));
      expect(r.left, greaterThanOrEqualTo(0), reason: s);
      expect(r.right, lessThanOrEqualTo(408), reason: s);
    }
  });
}
