// Test walks: spec 0004 amendment 4, criteria 15-16 (plan 0034), and
// amendment 5, criteria 1-3 (plan 0058).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

import 'images_test.dart' show loadFonts;
import 'ui_test.dart' show pumpGame, settle;

void main() {
  final card = find.byKey(const ValueKey('test-walk'));
  const words = ['+100', '+1k', '+5k', '+25k', '+100k'];
  Finder inCard(String w) => find.descendant(of: card, matching: find.text(w));

  testWidgets('amendment 5 criterion 1: five buttons, in order', (t) async {
    final (c, _) = await pumpGame(t);
    await c.setTestWalk(true);
    await t.pump();
    final x = [for (final w in words) t.getTopLeft(inCard(w)).dx];
    for (var i = 1; i < x.length; i++) {
      expect(
        x[i],
        greaterThan(x[i - 1]),
        reason: '${words[i]} after ${words[i - 1]}',
      );
    }
  });

  testWidgets('amendment 5 criterion 2: one row at 408 dp wide', (t) async {
    // The game's fonts: the square test font is much wider.
    await t.runAsync(loadFonts);
    final (c, _) = await pumpGame(t);
    // The Fairphone: 408 dp wide (pumpGame sets a wide test screen).
    t.view.physicalSize = const Size(408, 900);
    await c.setTestWalk(true);
    await t.pumpAndSettle();
    final rects = [
      t.getRect(inCard('Test walk')),
      for (final w in words) t.getRect(inCard(w)),
    ];
    final cardRect = t.getRect(card);
    for (final r in rects) {
      // Every label sits on the line of the first one, inside the card.
      expect(r.center.dy, closeTo(rects.first.center.dy, 2));
      expect(r.left, greaterThanOrEqualTo(cardRect.left));
      expect(r.right, lessThanOrEqualTo(cardRect.right));
    }
    expect(
      find.text('Adds pretend steps, as if you walked them.'),
      findsNothing,
    );
    expect(t.takeException(), isNull, reason: 'no overflow');
  });

  testWidgets('amendment 5 criterion 3: +1k walks 1,000 steps', (t) async {
    final (c, _) = await pumpGame(t, location: 'goblin_woods');
    await c.startActivity(const Activity.fight('goblin'));
    await c.setTestWalk(true);
    await t.pump();
    final before = c.state.counters['steps.walked'] ?? 0;
    await t.ensureVisible(inCard('+1k'));
    await t.tap(inCard('+1k'));
    await settle(t, c);
    expect(c.state.counters['steps.walked'], before + 1000);
  });

  testWidgets('amendment 4 criteria 15-16, amendment 5 criterion 3: +100k '
      'during an action walks 100,000 steps, in one journal entry', (t) async {
    final (c, _) = await pumpGame(t, location: 'goblin_woods');
    await c.startActivity(const Activity.fight('goblin'));
    await c.setTestWalk(true);
    await t.pump();
    final before = c.state.counters['steps.walked'] ?? 0;
    final entries = c.journal.length;
    await t.ensureVisible(inCard('+100k'));
    await t.tap(inCard('+100k'));
    await settle(t, c);
    expect(c.state.counters['steps.walked'], before + 100000);
    expect(c.journal.length, entries + 1);
    expect(c.journal.first.testWalk, isTrue);
  });
}
