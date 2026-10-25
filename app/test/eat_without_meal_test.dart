// Spec 0011 §5.4: a meal's card has Eat, and eating takes one meal from the
// bag. With none in the bag, the card offers no Eat that fails (owner's
// playtest, 2026-10-25: "No grilled_perch to eat").

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

import 'ui_test.dart' show openTab, pumpGame;

void main() {
  testWidgets('the card of the running meal, with none in the bag, cannot '
      'eat and says why; Auto-eat stays', (t) async {
    final (c, _) = await pumpGame(t, level: 5);
    c.state.meal = ActiveMeal('grilled_perch', 1200);
    await openTab(t, 'world');
    await openTab(t, 'now');
    await t.tap(find.byKey(const ValueKey('meal-line')));
    await t.pumpAndSettle();

    final eat = find.byKey(const ValueKey('card-eat'));
    expect(eat, findsOneWidget);
    expect(t.widget<ButtonStyleButton>(eat).onPressed, isNull);
    expect(find.text('None in the bag'), findsOneWidget);
    expect(find.byKey(const ValueKey('auto-eat-out')), findsOneWidget);

    await t.tap(eat, warnIfMissed: false);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(c.state.meal!.key, 'grilled_perch');
    expect(c.state.meal!.left, 1200);
  });

  testWidgets('with one in the bag, the card of the running meal can eat it', (
    t,
  ) async {
    final (c, _) = await pumpGame(t, level: 5, inventory: {'grilled_perch': 1});
    c.state.meal = ActiveMeal('grilled_perch', 1200);
    await openTab(t, 'world');
    await openTab(t, 'now');
    await t.tap(find.byKey(const ValueKey('meal-line')));
    await t.pumpAndSettle();

    final eat = find.byKey(const ValueKey('card-eat'));
    expect(t.widget<ButtonStyleButton>(eat).onPressed, isNotNull);
    expect(find.text('None in the bag'), findsNothing);
  });
}
