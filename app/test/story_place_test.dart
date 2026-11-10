// The story of the place stands under the current action: spec 0008
// amendment 6 criteria 1-4 (plan 0063).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

import 'ui_test.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));
  final story = key('discoveries');
  final action = key('queue-card');
  final here = key('here');

  testWidgets('criteria 1 and 2: with a fight, the story stands under the '
      'current action and above "Here"', (t) async {
    final (c, _) = await pumpGame(t, location: 'goblin_woods');
    await c.startActivity(const Activity.fight('goblin'));
    await settle(t, c);
    expect(
      find.descendant(of: action, matching: find.textContaining('Goblin')),
      findsWidgets,
    );
    expect(story, findsOneWidget);
    expect(
      t.getTopLeft(story).dy,
      greaterThanOrEqualTo(t.getRect(action).bottom),
    );
    expect(t.getRect(story).bottom, lessThanOrEqualTo(t.getTopLeft(here).dy));
  });

  testWidgets('criterion 3: with no current action, the story stands under '
      '"Resting"', (t) async {
    await pumpGame(t, location: 'goblin_woods');
    expect(
      find.descendant(of: action, matching: find.text('Resting')),
      findsOneWidget,
    );
    expect(
      t.getTopLeft(story).dy,
      greaterThanOrEqualTo(t.getRect(action).bottom),
    );
    expect(t.getRect(story).bottom, lessThanOrEqualTo(t.getTopLeft(here).dy));
  });

  testWidgets('criterion 4: a tap on OK takes the story away', (t) async {
    final (c, _) = await pumpGame(t, location: 'goblin_woods');
    await t.tap(find.descendant(of: story, matching: find.text('OK')));
    await settle(t, c);
    expect(story, findsNothing);
    expect(action, findsOneWidget);
  });
}
