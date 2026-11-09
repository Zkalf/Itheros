// The bag limit on screen: spec 0021 criteria 30-36 (plan 0041 M2). The
// rules are in game_core's bag_limit_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/ui/theme.dart';

import 'ui_test.dart';

void main() {
  /// Fills the bag to [kinds] kinds of item, one of each.
  void Function(GameState) filled(int kinds) => (s) {
    for (final id in game.data.items.keys) {
      if (game.spacesUsed(s) >= kinds) break;
      s.inventory.putIfAbsent(id, () => 1);
    }
  };

  Future<void> openBag(WidgetTester t) async {
    await openTab(t, 'character');
    await t.tap(find.byKey(const ValueKey('tab-bag')));
    await t.pumpAndSettle();
  }

  Color? colourOf(WidgetTester t, String key) =>
      t.widget<Text>(find.byKey(ValueKey(key))).style?.color;

  testWidgets('criterion 30: the Bag pane shows "Spaces N / 40"', (t) async {
    final (c, _) = await pumpGame(t, prepare: filled(32));
    await openBag(t);
    expect(game.spacesUsed(c.state), 32);
    expect(find.text('Spaces 32 / 40'), findsOneWidget);
    expect(colourOf(t, 'bag-spaces'), isNot(Quiet.risky));
  });

  testWidgets('criterion 31: overloaded, the line shows the overload in '
      'Quiet.risky', (t) async {
    await pumpGame(t, prepare: filled(43));
    await openBag(t);
    expect(find.text('Spaces 43 / 40 · Overloaded +15% steps'), findsOneWidget);
    expect(colourOf(t, 'bag-spaces'), Quiet.risky);
  });

  testWidgets('criterion 32: overloaded, Now shows the Overloaded line', (
    t,
  ) async {
    await pumpGame(t, prepare: filled(43));
    expect(find.text('Overloaded: +15% steps'), findsOneWidget);
    expect(colourOf(t, 'overloaded-text'), Quiet.risky);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('overloaded-line')),
        matching: find.byIcon(Icons.backpack),
      ),
      findsOneWidget,
    );
  });

  testWidgets('criterion 33: not overloaded, Now shows no Overloaded line', (
    t,
  ) async {
    await pumpGame(t, prepare: filled(40));
    expect(find.byKey(const ValueKey('overloaded-line')), findsNothing);
  });

  testWidgets('criterion 34: a tap on the line opens its sheet', (t) async {
    await pumpGame(t, prepare: filled(43));
    await t.tap(find.byKey(const ValueKey('overloaded-line')));
    await t.pumpAndSettle();
    final sheet = find.byKey(const ValueKey('overloaded-sheet'));
    expect(sheet, findsOneWidget);
    for (final line in [
      'Overloaded',
      // The words of spec 0021 amendment 4, rule 10.
      'Your bag uses 43 spaces. It has 40.',
      'Each space over adds 5% to the steps of your actions, up to 50%.',
      'At Camp, crafts and rerolls cost no more.',
      'Store items in the bank at Camp, or salvage, eat or use them.',
    ]) {
      expect(
        find.descendant(of: sheet, matching: find.text(line)),
        findsOneWidget,
        reason: line,
      );
    }
  });

  testWidgets('criterion 35: the bank screen\'s Bag tab shows the line', (
    t,
  ) async {
    await pumpGame(t, prepare: filled(43));
    await openBag(t);
    await t.ensureVisible(find.byKey(const ValueKey('bag-bank')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('bag-bank')));
    await t.pumpAndSettle();
    // The bank screen opens on Bank (spec 0020 amendment 3); these tests
    // start on the Bag tab.
    await t.tap(find.byKey(const ValueKey('bank-tab-bag')));
    await t.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('bank-screen')),
        matching: find.text('Spaces 43 / 40 · Overloaded +15% steps'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('criterion 36: Bigger bag shows with the bag icon', (t) async {
    await pumpGame(t, level: 12);
    await openTab(t, 'character');
    await t.tap(find.byKey(const ValueKey('tab-talents')));
    await t.pumpAndSettle();
    final talent = find.byKey(const ValueKey('talent-bigger_bag'));
    expect(
      find.descendant(of: talent, matching: find.byIcon(Icons.backpack)),
      findsOneWidget,
    );
    final data = game.data.talents['bigger_bag']!;
    expect((data.row, data.column, data.tree), (1, 2, 'utility'));
  });
}
