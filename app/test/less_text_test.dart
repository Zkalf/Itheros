// Fewer words on Now and World: spec 0014 amendment 6, criteria 37-40
// (plan 0035).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_test.dart' show openTab, pumpGame;

void main() {
  const banked =
      'Steps walked while resting are saved here. During an '
      'activity, each step you walk uses one banked step and counts double.';
  const arrive =
      'Steps arrive from Health Connect about once a minute. '
      'Pull down to check now.';

  testWidgets('criteria 37-38: Now shows neither line', (t) async {
    await pumpGame(t);
    expect(find.textContaining('saved here'), findsNothing);
    expect(find.textContaining('about once a minute'), findsNothing);
  });

  testWidgets('criterion 39: a tap on the step bank opens its sheet', (
    t,
  ) async {
    await pumpGame(t);
    await t.tap(find.byKey(const ValueKey('step-bank')));
    await t.pumpAndSettle();
    final sheet = find.byKey(const ValueKey('step-bank-sheet'));
    expect(sheet, findsOneWidget);
    for (final words in ['Step bank', banked, arrive]) {
      expect(
        find.descendant(of: sheet, matching: find.text(words)),
        findsOneWidget,
        reason: words,
      );
    }
  });

  testWidgets('criterion 40: World shows no hint under the map', (t) async {
    await pumpGame(t);
    await openTab(t, 'world');
    expect(find.text('Tap a place to see what lives there.'), findsNothing);
  });
}
