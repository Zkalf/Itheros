// Issue #113: in "Until I have N", the number follows the picked item:
// what the player has of it, plus 5, as for the first item of the list.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_test.dart' show option, pumpGame;

void main() {
  testWidgets('picking another item sets the number from that item', (t) async {
    await pumpGame(
      t,
      location: 'goblin_woods',
      inventory: {'deer_hide': 398, 'venison': 12},
    );
    await t.tap(option('gather', 'deer_trail'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('stop-untilHave')));
    await t.pumpAndSettle();
    // The first item, Deer hide: 398 + 5.
    expect(find.text('403'), findsOneWidget);

    await t.tap(find.byType(DropdownButton<String>));
    await t.pumpAndSettle();
    await t.tap(find.text('Venison').last);
    await t.pumpAndSettle();
    expect(find.text('you have 12'), findsOneWidget);
    expect(find.text('17'), findsOneWidget, reason: '12 venison + 5');
    expect(find.text('403'), findsNothing);
  });
}
