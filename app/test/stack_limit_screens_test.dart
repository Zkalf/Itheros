// A stack limit for each kind of item, on screen: spec 0021 amendment 4
// criteria 9-14 (plan 0056). The rules are in game_core's
// stack_limit_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/item_square.dart';

import 'ui_test.dart';

void main() {
  const ore = 'copper_ore';
  const hide = 'goblin_hide';
  const meal = 'grilled_perch';
  const sword = 'bone_sword';

  Future<void> openBag(WidgetTester t) async {
    await openTab(t, 'character');
    await t.tap(find.byKey(const ValueKey('tab-bag')));
    await t.pumpAndSettle();
  }

  Future<void> tapKey(WidgetTester t, String key) async {
    await t.ensureVisible(find.byKey(ValueKey(key)));
    await t.pumpAndSettle();
    await t.tap(find.byKey(ValueKey(key)));
    await t.pumpAndSettle();
  }

  Future<void> closeCard(WidgetTester t) async {
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();
  }

  ItemSquare square(WidgetTester t, String key) =>
      t.widget<ItemSquare>(find.byKey(ValueKey(key)));

  /// The keys of the bag's squares, in screen order.
  List<String> squares(WidgetTester t) => [
    for (final w in t.widgetList<ItemSquare>(find.byType(ItemSquare)))
      (w.key! as ValueKey<String>).value,
  ];

  testWidgets('criterion 9: 237 copper ore show as three squares: 100, 100 '
      'and 37, side by side', (t) async {
    await pumpGame(t, inventory: {ore: 237});
    await openBag(t);
    final keys = ['bag-$ore', 'bag-$ore-2', 'bag-$ore-3'];
    expect([for (final k in keys) square(t, k).count], [100, 100, 37]);
    expect(squares(t), keys);
    final rects = [for (final k in keys) t.getRect(find.byKey(ValueKey(k)))];
    expect(rects[1].top, rects[0].top, reason: 'one row');
    expect(rects[2].top, rects[0].top, reason: 'one row');
    expect(rects[1].left, greaterThan(rects[0].left));
    expect(rects[2].left, greaterThan(rects[1].left));
  });

  testWidgets('criterion 10: any square opens the card of copper ore with the '
      'whole count', (t) async {
    await pumpGame(t, inventory: {ore: 237});
    await openBag(t);
    for (final key in ['bag-$ore', 'bag-$ore-3']) {
      await tapKey(t, key);
      expect(
        t.widget<Text>(find.byKey(const ValueKey('card-name'))).data,
        'Copper ore',
        reason: key,
      );
      // Destroy asks "How many?" with the whole count filled in.
      final destroy = find.byKey(const ValueKey('card-destroy'));
      await t.ensureVisible(destroy);
      await t.pumpAndSettle();
      await t.tap(destroy);
      await t.pumpAndSettle();
      expect(find.text('How many?'), findsOneWidget);
      expect(
        t
            .widget<TextField>(find.byKey(const ValueKey('count-field')))
            .controller!
            .text,
        '237',
        reason: key,
      );
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();
      await closeCard(t);
    }
  });

  testWidgets('criterion 11: sorted by Count, the biggest whole count comes '
      'first, with all its squares together', (t) async {
    // 101 ore (100 and 1) beat 100 hides (100): the whole count decides.
    await pumpGame(t, inventory: {hide: 100, ore: 101});
    await openBag(t);
    final sort = find.byKey(const ValueKey('sort-bag'));
    await t.ensureVisible(sort);
    await t.pumpAndSettle();
    await t.tap(sort);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('sort-bag-count')).last);
    await t.pumpAndSettle();
    expect(squares(t), ['bag-$ore', 'bag-$ore-2', 'bag-$hide']);
  });

  testWidgets('criterion 12: the card says how much a bag space holds, for '
      'materials and meals only', (t) async {
    await pumpGame(t, inventory: {ore: 5, meal: 3, sword: 1});
    await openBag(t);
    for (final (key, line) in [
      (ore, 'Up to 100 in a bag space.'),
      (meal, 'Up to 20 in a bag space.'),
      (sword, null),
    ]) {
      await tapKey(t, 'bag-$key');
      final stack = find.byKey(const ValueKey('card-stack'));
      if (line == null) {
        expect(stack, findsNothing, reason: key);
      } else {
        expect(t.widget<Text>(stack).data, line, reason: key);
      }
      await closeCard(t);
    }
  });

  testWidgets('criterion 13: the Overloaded sheet counts spaces', (t) async {
    // One kind in 43 stacks.
    await pumpGame(t, inventory: {ore: 4300});
    await t.tap(find.byKey(const ValueKey('overloaded-line')));
    await t.pumpAndSettle();
    final sheet = find.byKey(const ValueKey('overloaded-sheet'));
    for (final line in [
      'Your bag uses 43 spaces. It has 40.',
      'Each space over adds 5% to the steps of your actions, up to 50%.',
    ]) {
      expect(
        find.descendant(of: sheet, matching: find.text(line)),
        findsOneWidget,
        reason: line,
      );
    }
  });

  testWidgets('criterion 14: the bank screen shows one row for copper ore with '
      'the whole count, in both tabs', (t) async {
    await pumpGame(
      t,
      inventory: {ore: 237},
      prepare: (s) => s.itemBank[ore] = 237,
    );
    await openBag(t);
    await tapKey(t, 'bag-bank');
    for (final (tab, row) in [
      ('bank-tab-bag', 'bank-bag-$ore'),
      ('bank-tab-bank', 'bank-item-$ore'),
    ]) {
      await t.tap(find.byKey(ValueKey(tab)));
      await t.pumpAndSettle();
      expect(find.byKey(ValueKey(row)), findsOneWidget, reason: tab);
      expect(find.byKey(ValueKey('$row-2')), findsNothing, reason: tab);
      expect(
        find.descendant(
          of: find.byKey(ValueKey(row)),
          matching: find.text('Copper ore ×237'),
        ),
        findsOneWidget,
        reason: tab,
      );
    }
  });
}
