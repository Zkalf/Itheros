// Bigger test walks: spec 0004 amendment 4, criteria 14-16 (plan 0034).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

import 'ui_test.dart' show pumpGame, settle;

void main() {
  final card = find.byKey(const ValueKey('test-walk'));

  testWidgets('criterion 14: five buttons, in order', (t) async {
    final (c, _) = await pumpGame(t);
    await c.setTestWalk(true);
    await t.pump();
    const words = ['+100', '+1,000', '+5,000', '+25,000', '+100,000'];
    final x = [
      for (final w in words)
        t.getTopLeft(find.descendant(of: card, matching: find.text(w))),
    ];
    // In order: left to right, then on the next line when they wrap.
    for (var i = 1; i < x.length; i++) {
      expect(
        x[i].dy > x[i - 1].dy || x[i].dx > x[i - 1].dx,
        isTrue,
        reason: '${words[i]} after ${words[i - 1]}',
      );
    }
  });

  testWidgets('criteria 15-16: +100,000 during an action walks 100,000 '
      'steps, in one journal entry', (t) async {
    final (c, _) = await pumpGame(t, location: 'goblin_woods');
    await c.startActivity(const Activity.fight('goblin'));
    await c.setTestWalk(true);
    await t.pump();
    final before = c.state.counters['steps.walked'] ?? 0;
    final entries = c.journal.length;
    await t.ensureVisible(
      find.descendant(of: card, matching: find.text('+100,000')),
    );
    await t.tap(find.descendant(of: card, matching: find.text('+100,000')));
    await settle(t, c);
    expect(c.state.counters['steps.walked'], before + 100000);
    expect(c.journal.length, entries + 1);
    expect(c.journal.first.testWalk, isTrue);
  });
}
