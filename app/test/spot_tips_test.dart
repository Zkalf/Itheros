// Spot tips in the teacher sheet and the Lore tab: spec 0010 amendment 8,
// criteria 3, 7 and 12-14 (plan 0030 M1).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_test.dart' show closeSheet, openTab, pumpGame, settle;

void main() {
  Finder sheet(Finder f) => find.descendant(
    of: find.byKey(const ValueKey('teacher-sheet')),
    matching: f,
  );

  Future<void> openTeacher(WidgetTester t, String profession) async {
    await openTab(t, 'professions');
    await openTab(t, 'now');
    await t.tap(find.byKey(ValueKey('teacher-$profession')));
    await t.pumpAndSettle();
  }

  testWidgets('criterion 12: a spot tip says which spot it is about', (
    t,
  ) async {
    final (c, _) = await pumpGame(t, professionLevel: 1);
    await openTeacher(t, 'hunting');
    await settle(t, c);
    await t.pumpAndSettle();
    expect(sheet(find.text('The deer trail')), findsOneWidget);
    expect(sheet(find.text('About Deer trail')), findsOneWidget);
    // A monster tip keeps its words.
    expect(sheet(find.text('About the Goblin brute')), findsOneWidget);
  });

  testWidgets('criterion 3: a dot on Sigrun at Hunting 10', (t) async {
    final (c, _) = await pumpGame(t, professionLevel: 10);
    c.state.tips.addAll(['sigrun_1', 'sigrun_10', 'sigrun_deer_trail']);
    await openTab(t, 'professions');
    await openTab(t, 'now');
    expect(find.byKey(const ValueKey('teacher-dot-hunting')), findsOneWidget);
    await openTeacher(t, 'hunting');
    await settle(t, c);
    await t.pumpAndSettle();
    expect(c.state.tips, contains('sigrun_moor_tracks'));
    await closeSheet(t);
    expect(find.byKey(const ValueKey('teacher-dot-hunting')), findsNothing);
  });

  testWidgets('criterion 7: the hidden cove is not the next tip', (t) async {
    final (c, _) = await pumpGame(t, professionLevel: 10);
    await openTeacher(t, 'fishing');
    await settle(t, c);
    await t.pumpAndSettle();
    expect(sheet(find.textContaining('Next tip at Fishing 20.')), findsOne);
    expect(sheet(find.textContaining('Fishing 15')), findsNothing);
  });

  testWidgets('criteria 13-14: Lore shows spot tips under the teacher, '
      'not in the count', (t) async {
    final (c, _) = await pumpGame(t);
    c.state.tips.addAll(['sigrun_deer_trail', 'wen_lake_shore']);
    await t.tap(find.byKey(const ValueKey('journal-button')));
    await t.pumpAndSettle();
    await t.tap(find.text('Lore'));
    await t.pumpAndSettle();
    expect(find.text('0 of 16 found'), findsOneWidget);
    expect(find.text('Sigrun, the hunter'), findsOneWidget);
    expect(find.text('The deer trail'), findsOneWidget);
    expect(find.text('Wen, the fisherman'), findsOneWidget);
    expect(find.text('Mirror Lake'), findsOneWidget);
  });
}
