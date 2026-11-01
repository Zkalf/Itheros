// The Journal's tabs while the player swipes between them: the lit tab
// follows the finger (spec 0014 amendment 4), and a sideways swipe changes
// the tab, never goes back (spec 0014 amendment 5, change 6).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/journal_screen.dart';
import 'package:walkingrpg/ui/theme.dart';

import 'ui_test.dart' show pumpGame;

void main() {
  final journal = find.byType(JournalScreen);

  Future<void> openJournal(WidgetTester t) async {
    await pumpGame(t);
    await t.tap(find.byKey(const ValueKey('journal-button')));
    await t.pumpAndSettle();
  }

  /// The fill of each tab box, Log first.
  List<Color> fills(WidgetTester t) => [
    for (final box in t.widgetList<ControlBox>(
      find.descendant(
        of: find.byType(TabBar),
        matching: find.byType(ControlBox),
      ),
    ))
      box.fill,
  ];

  Offset middle(WidgetTester t) => t.getCenter(find.byType(TabBarView));

  testWidgets('the lit tab follows the finger past halfway', (t) async {
    await openJournal(t);
    expect(fills(t), [Quiet.selected, Quiet.slate, Quiet.slate]);
    final width = t.getSize(find.byType(TabBarView)).width;
    // A slow swipe to the left, held past halfway: the finger is still down.
    final g = await t.startGesture(middle(t));
    for (var i = 0; i < 12; i++) {
      await g.moveBy(Offset(-width * .6 / 12, 0));
      await t.pump(const Duration(milliseconds: 50));
    }
    expect(fills(t), [Quiet.slate, Quiet.selected, Quiet.slate]);
    await g.up();
    await t.pumpAndSettle();
    expect(fills(t), [Quiet.slate, Quiet.selected, Quiet.slate]);
  });

  testWidgets('a swipe right on Log stays in the Journal', (t) async {
    await openJournal(t);
    await t.dragFrom(middle(t), const Offset(700, 0));
    await t.pumpAndSettle();
    expect(journal, findsOneWidget);
  });

  testWidgets('a swipe right on Bestiary goes to Log, not back', (t) async {
    await openJournal(t);
    await t.tap(find.text('Bestiary'));
    await t.pumpAndSettle();
    await t.dragFrom(middle(t), const Offset(700, 0));
    await t.pumpAndSettle();
    expect(journal, findsOneWidget);
    expect(fills(t), [Quiet.selected, Quiet.slate, Quiet.slate]);
  });
}
