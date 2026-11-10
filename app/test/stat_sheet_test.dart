// Hit as a chance, and a tap on a stat explains it: spec 0009 amendment 4
// criteria 1, 2 and 5-15 (plan 0060). The rule (criteria 1-4, 16) is in
// game_core's hit_at_level_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

import 'images_test.dart' show loadFonts;
import 'ui_test.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));
  final sheet = key('stat-sheet');
  final combat = game.data.combat;
  const hitSword = 'bone_sword@rare+hit4';
  const labels = ['HP', 'Attack', 'Defense', 'Crit', 'Hit', 'Dodge', 'Block'];

  String textOf(WidgetTester t, String k) => t.widget<Text>(key(k)).data!;

  /// The number that the stats block shows under [label].
  String shown(WidgetTester t, String label) => t
      .widget<Text>(
        find
            .descendant(of: key('stat-$label'), matching: find.byType(Text))
            .first,
      )
      .data!;

  Future<void> open(WidgetTester t, String label) async {
    await t.tap(key('stat-$label'));
    await t.pumpAndSettle();
  }

  /// Gear, a talent and an HP meal.
  void geared(GameState s) => s
    ..talents['toughness'] = 5
    ..meal = ActiveMeal('grilled_perch', 6000);

  group('Hit shows a chance', () {
    testWidgets('criterion 1: with no Hit the block shows the base chance', (
      t,
    ) async {
      await pumpGame(t, level: 12);
      await openGear(t);
      expect(shown(t, 'Hit'), '75%');
    });

    testWidgets('criterion 2: with +4% Hit from gear it shows 79%', (t) async {
      await pumpGame(t, level: 12, equipment: {'mainHand': hitSword});
      await openGear(t);
      expect(shown(t, 'Hit'), '79%');
    });
  });

  group('the sheets', () {
    testWidgets('criteria 5, 7 and 8: each stat opens its sheet, with its '
        'number and what it does', (t) async {
      final (c, _) = await pumpGame(
        t,
        level: 12,
        equipment: {'mainHand': hitSword, 'offHand': 'bone_shield'},
      );
      await openGear(t);
      final stats = c.game.stats(c.state);
      final block = (combat.blockShare * 100).round();
      final expected = {
        'HP': (
          '${stats.hp} HP',
          'You lose a fight when your HP reaches 0. Each fight starts at full '
              'HP.',
        ),
        'Attack': (
          '${stats.attack} Attack',
          "A hit deals about your Attack minus half of the monster's Defense.",
        ),
        'Defense': (
          '${stats.defense} Defense',
          "A monster's hit loses half of your Defense.",
        ),
        'Crit': (
          '${c.game.critChance(c.state)}% chance of a critical hit',
          'A critical hit deals 2 times the damage.',
        ),
        'Hit': (
          '79% against a monster of your level',
          'Each level a monster is above you takes ${combat.hitPerLevel}% '
              'off. Each level below adds ${combat.hitPerLevel}%.',
        ),
        'Dodge': (
          '${c.game.dodgeChance(c.state)}% chance to dodge a hit',
          'A dodged hit deals no damage.',
        ),
        'Block': (
          '${c.game.blockChance(c.state)}% chance to block a hit',
          'A blocked hit deals $block% of its damage.',
        ),
      };
      expect(expected.keys, labels);
      for (final MapEntry(key: label, value: (number, does))
          in expected.entries) {
        await open(t, label);
        expect(sheet, findsOneWidget, reason: label);
        expect(textOf(t, 'stat-sheet-title'), label);
        expect(textOf(t, 'stat-sheet-number'), number);
        // The sheet starts with the number of the stats block.
        expect(number, startsWith(shown(t, label)), reason: label);
        expect(textOf(t, 'stat-sheet-does'), does);
        await closeSheet(t);
        expect(sheet, findsNothing, reason: label);
      }
    });

    testWidgets('criterion 6: a tap on Level opens nothing', (t) async {
      await pumpGame(t, level: 12);
      await openGear(t);
      await t.tap(key('stat-Level'));
      await t.pumpAndSettle();
      expect(sheet, findsNothing);
    });

    testWidgets('criterion 9: the HP sheet names the level, gear, talents '
        'and the meal, and they add up', (t) async {
      final (c, _) = await pumpGame(
        t,
        level: 12,
        equipment: {'chest': 'hide_vest'},
        prepare: geared,
      );
      await openGear(t);
      await open(t, 'HP');
      final lines = [
        for (final id in ['level', 'gear', 'talents', 'meal'])
          textOf(t, 'stat-source-$id'),
      ];
      expect(lines[0], startsWith('From your level: '));
      expect(lines[1], startsWith('From gear: +'));
      expect(lines[2], startsWith('From talents: +'));
      expect(lines[3], startsWith('From your meal: +'));
      expect(key('stat-source-achievements'), findsNothing);
      final sum = lines
          .map((l) => int.parse(l.split(': ').last.replaceAll('+', '')))
          .reduce((a, b) => a + b);
      expect(sum, c.game.stats(c.state).hp);
      expect(textOf(t, 'stat-sheet-number'), '$sum HP');
    });

    testWidgets('criterion 10: a source that adds nothing has no line', (
      t,
    ) async {
      await pumpGame(t, level: 12, equipment: {'chest': 'hide_vest'});
      await openGear(t);
      for (final label in labels) {
        await open(t, label);
        expect(find.textContaining('From your meal'), findsNothing);
        expect(find.textContaining('From talents'), findsNothing);
        expect(find.textContaining('From achievements'), findsNothing);
        await closeSheet(t);
      }
      // No gear adds Attack here: the level alone.
      await open(t, 'Attack');
      expect(key('stat-source-level'), findsOneWidget);
      expect(key('stat-source-gear'), findsNothing);
    });

    testWidgets('criterion 11: the Hit sheet with +4% Hit from gear', (
      t,
    ) async {
      await pumpGame(t, level: 12, equipment: {'mainHand': hitSword});
      await openGear(t);
      await open(t, 'Hit');
      expect(
        textOf(t, 'stat-sheet-number'),
        '79% against a monster of your level',
      );
      expect(textOf(t, 'stat-source-base'), 'Base: 75%');
      expect(textOf(t, 'stat-source-gear'), 'From gear: +4%');
    });

    testWidgets('criterion 12: Dodge and Block with neither show "From gear: '
        '+0%"', (t) async {
      await pumpGame(t, level: 12);
      await openGear(t);
      for (final label in ['Dodge', 'Block']) {
        await open(t, label);
        expect(textOf(t, 'stat-source-gear'), 'From gear: +0%', reason: label);
        await closeSheet(t);
      }
    });

    testWidgets('criterion 13: Crit, Hit, Dodge and Block show their limits; '
        'HP, Attack and Defense show none', (t) async {
      await pumpGame(t, level: 12);
      await openGear(t);
      final limits = {
        'Crit': 'At most ${combat.critCap}%.',
        'Hit': 'Never under ${combat.hitMin}% or over ${combat.hitMax}%.',
        'Dodge': 'At most ${combat.dodgeCap}%.',
        'Block':
            'At most ${combat.blockCap}%. Gear gives Block only on a shield.',
      };
      for (final label in labels) {
        await open(t, label);
        if (limits[label] case final limit?) {
          expect(textOf(t, 'stat-sheet-limit'), limit);
        } else {
          expect(key('stat-sheet-limit'), findsNothing, reason: label);
        }
        await closeSheet(t);
      }
      // The numbers of today, word for word (rule 8, erratum 1).
      expect(limits, {
        'Crit': 'At most 50%.',
        'Hit': 'Never under 50% or over 90%.',
        'Dodge': 'At most 30%.',
        'Block': 'At most 50%. Gear gives Block only on a shield.',
      });
    });

    testWidgets('rules 6 and 9: the Crit sheet names the base, a talent, the '
        'meal and an achievement, and they add up', (t) async {
      final (c, _) = await pumpGame(
        t,
        level: 12,
        counters: {'kills.old_bear': 100000},
        prepare: (s) => s
          ..talents['keen_eye'] = 2
          ..achievements.add('bear_hunter')
          ..meal = ActiveMeal('golden_carp_curry', 6000),
      );
      await openGear(t);
      await open(t, 'Crit');
      final lines = [
        for (final id in ['base', 'talents', 'meal', 'achievements'])
          textOf(t, 'stat-source-$id'),
      ];
      expect(lines[0], 'Base: ${combat.critBase}%');
      expect(lines[1], 'From talents: +2%');
      expect(lines[2], startsWith('From your meal: +'));
      expect(lines[3], startsWith('From achievements: +'));
      expect(key('stat-source-gear'), findsNothing);
      final sum = lines
          .map(
            (l) => int.parse(l.split(': ').last.replaceAll(RegExp('[+%]'), '')),
          )
          .reduce((a, b) => a + b);
      expect(textOf(t, 'stat-sheet-number'), startsWith('$sum% chance'));
      expect(c.game.critChance(c.state), sum);
    });

    testWidgets('at text size 2.0 on a 408 dp phone the stats block does not '
        'overflow', (t) async {
      await t.runAsync(loadFonts);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpGame(t, level: 12, equipment: {'offHand': 'bone_shield'});
      t.view.physicalSize = const Size(408, 900);
      await openGear(t);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });

    testWidgets('criterion 14: with Impale the Crit sheet shows the '
        "player's own critical damage", (t) async {
      final (c, _) = await pumpGame(
        t,
        level: 30,
        prepare: (s) => s.talents['impale'] = 1,
      );
      final damage = c.game.critDamage(c.state);
      expect(damage, greaterThan(combat.critDamage));
      await openGear(t);
      await open(t, 'Crit');
      expect(
        textOf(t, 'stat-sheet-does'),
        'A critical hit deals $damage times the damage.',
      );
    });
  });

  group('what stays', () {
    testWidgets('criterion 15: an item card with Hit still reads "+4% Hit"', (
      t,
    ) async {
      await pumpGame(t, level: 12, inventory: {hitSword: 1});
      await t.tap(key('bank-button'));
      await t.pumpAndSettle();
      await t.tap(key('bank-tab-bag'));
      await t.pumpAndSettle();
      await t.tap(key('bank-bag-$hitSword'));
      await t.pumpAndSettle();
      expect(key('item-card'), findsOneWidget);
      expect(find.textContaining('+4% Hit'), findsWidgets);
    });
  });
}
