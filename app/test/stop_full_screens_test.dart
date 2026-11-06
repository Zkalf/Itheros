// "Until the bag is full" on the screens: spec 0021 amendment 3 criteria 1-3
// and 8 (plan 0051, #224). The rule (criteria 4-7, 9) is in game_core's
// stop_full_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/ui/action_sheet.dart';

import 'now_monsters_test.dart' show inside;
import 'ui_test.dart';

void main() {
  final chip = find.byKey(const ValueKey('stop-untilFull'));

  Future<void> openSheet(WidgetTester t, Activity a, String location) async {
    await pumpGame(t, level: 5, location: location);
    if (a.kind == ActivityKind.craft) await openProfession(t, 'crafting');
    final row = option(a.kind.name, a.target);
    await t.ensureVisible(row);
    await t.pumpAndSettle();
    await t.tap(row);
    await t.pumpAndSettle();
    expect(find.byType(ActionSheet), findsOneWidget);
  }

  for (final (n, what, a, location) in [
    (1, 'a fight', const Activity.fight('goblin'), 'goblin_woods'),
    (2, 'a gather', const Activity.gather('oak_tree'), 'goblin_woods'),
  ]) {
    testWidgets('criterion $n: the action sheet of $what shows "Until the bag '
        'is full"', (t) async {
      await openSheet(t, a, location);
      expect(chip, findsOneWidget);
      expect(inside(chip, find.text('Until the bag is full')), findsOneWidget);
    });
  }

  testWidgets('criterion 3: the action sheet of a craft does not show it', (
    t,
  ) async {
    await openSheet(t, const Activity.craft('copper_sword'), 'camp');
    expect(chip, findsNothing);
  });

  testWidgets('criterion 8: the queue card shows "Until the bag is full" under '
      'the action, running and waiting', (t) async {
    final (c, _) = await pumpGame(t, level: 5, location: 'goblin_woods');
    await c.addAction(
      const Activity.gather('oak_tree'),
      stop: const StopCondition.untilFull(),
    );
    await c.addAction(
      const Activity.fight('goblin'),
      stop: const StopCondition.untilFull(),
    );
    await settle(t, c);
    await openTab(t, 'now');
    await t.pumpAndSettle();
    expect(c.state.activity?.stop, const StopCondition.untilFull());
    expect(find.text('Until the bag is full'), findsNWidgets(2));
    expect(
      inside(
        find.byKey(const ValueKey('queued-0')),
        find.text('Until the bag is full'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a tap on the chip queues the action with this stop', (t) async {
    final (c, _) = await pumpGame(t, level: 5, location: 'goblin_woods');
    await t.ensureVisible(option('gather', 'oak_tree'));
    await t.pumpAndSettle();
    await t.tap(option('gather', 'oak_tree'));
    await t.pumpAndSettle();
    await t.tap(chip);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('start-now')));
    await settle(t, c);
    await t.pumpAndSettle();
    expect(c.state.activity?.activity, const Activity.gather('oak_tree'));
    expect(c.state.activity?.stop, const StopCondition.untilFull());
  });
}
