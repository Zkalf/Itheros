// Swipe right to go back: spec 0014 amendment 5, criteria 29-34 (plan 0034).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/profession_screen.dart';

import 'ui_test.dart' show openProfession, openTab, option, pumpGame;

void main() {
  final screen = find.byType(ProfessionScreen);

  /// A point in the middle of the screen, far from the left edge.
  Offset middle(WidgetTester t) => t.getCenter(screen);

  testWidgets('criterion 29: a swipe right from the middle goes back', (
    t,
  ) async {
    await pumpGame(t);
    await openProfession(t, 'crafting');
    expect(screen, findsOneWidget);
    await t.dragFrom(middle(t), const Offset(700, 0));
    await t.pumpAndSettle();
    expect(screen, findsNothing);
    expect(
      find.byKey(const ValueKey('profession-button-crafting')),
      findsOneWidget,
    );
  });

  testWidgets('criterion 30: a tap on a recipe opens it, and stays', (t) async {
    await pumpGame(t);
    await openProfession(t, 'crafting');
    await t.ensureVisible(option('craft', 'copper_sword'));
    await t.pumpAndSettle();
    await t.tap(option('craft', 'copper_sword'));
    await t.pumpAndSettle();
    expect(screen, findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('criterion 31: a short slow swipe leaves the screen open', (
    t,
  ) async {
    await pumpGame(t);
    await openProfession(t, 'crafting');
    final width = t.getSize(screen).width;
    await t.timedDragFrom(
      middle(t),
      Offset(width / 4, 0),
      const Duration(seconds: 1),
    );
    await t.pumpAndSettle();
    expect(screen, findsOneWidget);
    expect(t.getTopLeft(screen).dx, 0, reason: 'slid back in');
  });

  testWidgets('criterion 32: a vertical scroll does not go back', (t) async {
    await pumpGame(t);
    await openProfession(t, 'crafting');
    await t.dragFrom(middle(t), const Offset(40, -400));
    await t.pumpAndSettle();
    expect(screen, findsOneWidget);
  });

  testWidgets('criterion 33: a swipe left does not go back', (t) async {
    await pumpGame(t);
    await openProfession(t, 'crafting');
    await t.dragFrom(middle(t), const Offset(-700, 0));
    await t.pumpAndSettle();
    expect(screen, findsOneWidget);
  });

  testWidgets('criterion 34: a swipe right on Now changes nothing', (t) async {
    await pumpGame(t);
    await openTab(t, 'now');
    final now = find.byKey(const ValueKey('test-walk')).evaluate().isEmpty
        ? find.text('Here')
        : find.byKey(const ValueKey('test-walk'));
    await t.dragFrom(const Offset(540, 600), const Offset(700, 0));
    await t.pumpAndSettle();
    expect(now, findsWidgets);
    expect(t.takeException(), isNull);
  });
}
