// Spec 0010 amendment 7 (issues #99, #100): a tool line says the saving of
// the tool, and a weapon recipe row says the damage type and the hands of the
// weapon.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/profession_screen.dart';

import 'quiet_teal_test.dart' show openItem;
import 'ui_test.dart' show openProfession, option, pumpGame;

Finder _in(Finder of, String text) => find.descendant(
  of: of,
  matching: find.textContaining(text, findRichText: true),
);

final _mining = find.byKey(const ValueKey('profession-mining'));

/// A share of the steps without the minus sign of a saving, as the old
/// words "100% steps" (spec 0010 amendment 7, criterion 5).
final _shareWithoutMinus = find.textContaining(
  RegExp(r'(^|[^−+\d])\d+% steps'),
  findRichText: true,
);

/// Scrolls the profession screen until [row] shows.
Future<void> _show(WidgetTester t, Finder row) => t.scrollUntilVisible(
  row,
  300,
  scrollable: find
      .descendant(
        of: find.byType(ProfessionScreen),
        matching: find.byType(Scrollable),
      )
      .first,
);

void main() {
  group('tool lines', () {
    testWidgets('criterion 1: a starter tool says "Full step cost" on its '
        'screen and on its item card', (t) async {
      await pumpGame(t, level: 5);
      await openProfession(t, 'mining');
      expect(_in(_mining, "Hilde's old pick · Full step cost"), findsOneWidget);
      await t.tap(_in(_mining, 'old pick'));
      await t.pumpAndSettle();
      expect(find.text('Mining tool · Full step cost'), findsOneWidget);
    });

    testWidgets('criterion 2: a Common copper tool says "−10% steps" on its '
        'screen and on its item card', (t) async {
      final (c, _) = await pumpGame(t, level: 5);
      c.state.tools['mining'] = 'copper_pickaxe';
      await openProfession(t, 'mining');
      expect(_in(_mining, 'Copper pickaxe · −10% steps'), findsOneWidget);
      await t.tap(_in(_mining, 'Copper pickaxe'));
      await t.pumpAndSettle();
      expect(find.text('Mining tool · −10% steps'), findsOneWidget);
    });

    testWidgets('criterion 3: an Uncommon copper tool says "−12% steps"', (
      t,
    ) async {
      await pumpGame(t, inventory: {'copper_pickaxe@uncommon': 1});
      await openItem(t, 'copper_pickaxe@uncommon');
      expect(find.text('Mining tool · −12% steps'), findsOneWidget);
    });

    testWidgets('criteria 4 and 5: the copper pickaxe recipe row says '
        '"−10% steps", and no line shows a share without the minus', (t) async {
      await pumpGame(t, level: 5);
      await openProfession(t, 'crafting');
      final row = option('craft', 'copper_pickaxe');
      await _show(t, row);
      expect(_in(row, 'Mining tool · −10% steps'), findsOneWidget);
      expect(_shareWithoutMinus, findsNothing, reason: 'Crafting');
    });

    testWidgets('criterion 5: each gathering screen and a tool card show no '
        'share without the minus', (t) async {
      final (c, _) = await pumpGame(t, level: 5);
      c.state.tools['mining'] = 'copper_pickaxe';
      for (final p in ['mining', 'woodcutting', 'fishing', 'hunting']) {
        await openProfession(t, p);
        expect(_shareWithoutMinus, findsNothing, reason: p);
      }
      await openProfession(t, 'mining');
      await t.tap(_in(_mining, 'Copper pickaxe'));
      await t.pumpAndSettle();
      expect(find.text('Mining tool · −10% steps'), findsOneWidget);
      expect(_shareWithoutMinus, findsNothing, reason: 'the item card');
    });
  });

  group('weapon recipe rows', () {
    testWidgets('criterion 6: the copper sword row shows "Slash · One hand · '
        '+3 Attack"', (t) async {
      await pumpGame(t, level: 5);
      await openProfession(t, 'crafting');
      final row = option('craft', 'copper_sword');
      await _show(t, row);
      expect(_in(row, 'Slash · One hand · +3 Attack'), findsOneWidget);
      expect(_in(row, 'Main hand'), findsNothing);
    });

    testWidgets('criterion 7: a two-handed weapon row shows "Two hands"', (
      t,
    ) async {
      await pumpGame(t, level: 5);
      await openProfession(t, 'crafting');
      final row = option('craft', 'bone_greataxe');
      await _show(t, row);
      expect(_in(row, 'Slash · Two hands · +'), findsOneWidget);
    });

    testWidgets('criterion 8: an armour row keeps its slot and shows no armour '
        'type', (t) async {
      await pumpGame(t, level: 5);
      await openProfession(t, 'crafting');
      final row = option('craft', 'hide_vest');
      await _show(t, row);
      expect(_in(row, 'Chest'), findsOneWidget);
      expect(_in(row, 'armour'), findsNothing);
    });
  });
}
