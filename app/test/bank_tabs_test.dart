// The bank screen's tabs as buttons, Bank first: spec 0020 amendment 3
// criteria 1-4 (plan 0050, #220).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/ui/labels.dart';
import 'package:walkingrpg/ui/theme.dart' show ControlBox, Quiet;

import 'now_monsters_test.dart' show inside;
import 'ui_test.dart';

void main() {
  void Function(GameState) banked(Map<String, int> items) =>
      (s) => s.itemBank.addAll(items);

  Future<void> openBank(WidgetTester t) async {
    await t.ensureVisible(find.byKey(const ValueKey('bank-card')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('bank-card')));
    await t.pumpAndSettle();
  }

  final bankTab = find.byKey(const ValueKey('bank-tab-bank'));
  final bagTab = find.byKey(const ValueKey('bank-tab-bag'));

  Color fillOf(WidgetTester t, Finder tab) =>
      t.widget<ControlBox>(inside(tab, find.byType(ControlBox))).fill;

  testWidgets('criterion 1: Bank stands on the left and Bag on the right, each '
      'in a button box', (t) async {
    await pumpGame(t);
    await openBank(t);
    expect(t.getRect(bankTab).left, lessThan(t.getRect(bagTab).left));
    expect(inside(bankTab, find.text('Bank')), findsOneWidget);
    expect(inside(bagTab, find.text('Bag')), findsOneWidget);
    for (final tab in [bankTab, bagTab]) {
      expect(inside(tab, find.byType(ControlBox)), findsOneWidget);
    }
  });

  testWidgets('criterion 2: the selected tab has the selected look; the other '
      'does not', (t) async {
    await pumpGame(t);
    await openBank(t);
    expect(fillOf(t, bankTab), Quiet.selected);
    expect(fillOf(t, bagTab), Quiet.slate);
    await t.tap(bagTab);
    await t.pumpAndSettle();
    expect(fillOf(t, bagTab), Quiet.selected);
    expect(fillOf(t, bankTab), Quiet.slate);
  });

  testWidgets('criterion 3: the bank screen opens on the Bank tab', (t) async {
    final (c, _) = await pumpGame(
      t,
      inventory: {'iron_ore': 4},
      prepare: banked({'oak_log': 9}),
    );
    await openBank(t);
    final labels = Labels(c.game.data);
    expect(find.text('${labels.item('oak_log')} ×9'), findsOneWidget);
    expect(find.text('${labels.item('iron_ore')} ×4'), findsNothing);
  });

  testWidgets("criterion 4: a tap on Bag shows the bag's items; a tap on Bank "
      "shows the bank's", (t) async {
    final (c, _) = await pumpGame(
      t,
      inventory: {'iron_ore': 4},
      prepare: banked({'oak_log': 9}),
    );
    await openBank(t);
    final labels = Labels(c.game.data);
    await t.tap(bagTab);
    await t.pumpAndSettle();
    expect(find.text('${labels.item('iron_ore')} ×4'), findsOneWidget);
    expect(find.text('${labels.item('oak_log')} ×9'), findsNothing);
    await t.tap(bankTab);
    await t.pumpAndSettle();
    expect(find.text('${labels.item('oak_log')} ×9'), findsOneWidget);
  });
}
