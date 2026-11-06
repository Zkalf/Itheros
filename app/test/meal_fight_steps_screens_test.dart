// The words of meals that speed up fights: spec 0011 amendment 2 criteria
// 8-10 (plan 0054).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_test.dart';

void main() {
  Finder card(Finder f) =>
      find.descendant(of: find.byKey(const ValueKey('item-card')), matching: f);

  Future<void> openItem(WidgetTester t, String key) async {
    await pumpGame(t, inventory: {key: 2});
    await openTab(t, 'character');
    await t.tap(find.byKey(const ValueKey('tab-bag')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(ValueKey('bag-$key')));
    await t.pumpAndSettle();
  }

  testWidgets('criterion 8: an Attack meal card names the fight steps and '
      '6,000 steps', (t) async {
    await openItem(t, 'venison_skewer');
    expect(
      card(find.text('+6% Attack, −12% fight steps for 6,000 steps')),
      findsOneWidget,
    );
  });

  testWidgets('criterion 9: a feast card names HP, Attack and the fight '
      'steps', (t) async {
    await openItem(t, 'mossback_feast');
    expect(
      card(find.text('+6% HP, +6% Attack, −12% fight steps for 6,000 steps')),
      findsOneWidget,
    );
  });

  testWidgets('criterion 10: a Defense meal card names no fight steps', (
    t,
  ) async {
    await openItem(t, 'pike_steak');
    expect(card(find.text('+6% Defense for 6,000 steps')), findsOneWidget);
    expect(card(find.textContaining('fight steps')), findsNothing);
  });
}
