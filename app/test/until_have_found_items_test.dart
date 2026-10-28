// Issue #114: at a spot, "Until I have N" lists only the items the player has
// found there, as for a monster's drops. The spot's own item is always there.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_test.dart' show option, pumpGame;

void main() {
  Future<void> openItems(WidgetTester t) async {
    await t.tap(option('gather', 'deer_trail'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('stop-untilHave')));
    await t.pumpAndSettle();
    await t.tap(find.byType(DropdownButton<String>));
    await t.pumpAndSettle();
  }

  testWidgets('nothing caught yet: only the spot item', (t) async {
    await pumpGame(t, location: 'goblin_woods');
    await openItems(t);
    expect(find.text('Deer hide'), findsWidgets);
    expect(find.text('Venison'), findsNothing);
    expect(find.text('Boar meat'), findsNothing);
    expect(find.text('Golden antler'), findsNothing);
  });

  testWidgets('a caught item and an owned one join the list', (t) async {
    await pumpGame(
      t,
      location: 'goblin_woods',
      counters: {'gathered.venison': 3},
      inventory: {'golden_antler': 1},
    );
    await openItems(t);
    expect(find.text('Deer hide'), findsWidgets);
    expect(find.text('Venison'), findsWidgets);
    expect(find.text('Golden antler'), findsWidgets);
    expect(find.text('Boar meat'), findsNothing);
  });
}
