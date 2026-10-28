// Issue #115: a tap on the number of "Until I have N" or "Until N crafted"
// lets the player type it; − and + stay.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_test.dart' show option, pumpGame;

void main() {
  Future<void> openUntilHave(WidgetTester t) async {
    await pumpGame(t, location: 'goblin_woods');
    await t.tap(option('gather', 'deer_trail'));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('stop-untilHave')));
    await t.pumpAndSettle();
  }

  testWidgets('typing 400 sets the number; + still counts on', (t) async {
    await openUntilHave(t);
    await t.tap(find.byKey(const ValueKey('count')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('count-field')), '400');
    await t.tap(find.text('Set'));
    await t.pumpAndSettle();
    expect(find.text('400'), findsOneWidget);

    await t.tap(find.byKey(const ValueKey('count-up')));
    await t.pump();
    expect(find.text('401'), findsOneWidget);
  });

  testWidgets('Cancel keeps the number', (t) async {
    await openUntilHave(t);
    // Deer hide: 0 owned + 5.
    expect(find.text('5'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('count')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const ValueKey('count-field')), '400');
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(find.text('5'), findsOneWidget);
    expect(find.text('400'), findsNothing);
  });

  testWidgets('0, empty or letters can not be set', (t) async {
    await openUntilHave(t);
    await t.tap(find.byKey(const ValueKey('count')));
    await t.pumpAndSettle();
    final set = find.widgetWithText(FilledButton, 'Set');
    for (final typed in ['0', '', 'abc']) {
      await t.enterText(find.byKey(const ValueKey('count-field')), typed);
      await t.pump();
      expect(t.widget<FilledButton>(set).onPressed, isNull, reason: typed);
    }
  });
}
