// Destroy an item, in the app: spec 0021 amendment 2 criteria 7-15 (plan
// 0049). The rules (criteria 1-6) are in game_core's destroy_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/game_controller.dart';

import 'ui_test.dart';

void main() {
  const hide = 'goblin_hide';
  const sword = 'bone_sword';

  void Function(GameState) banked(Map<String, int> items) =>
      (s) => s.itemBank.addAll(items);

  Future<void> openBag(WidgetTester t) async {
    await openTab(t, 'character');
    await t.tap(find.byKey(const ValueKey('tab-bag')));
    await t.pumpAndSettle();
  }

  Future<void> openBank(WidgetTester t, {bool bankTab = false}) async {
    await openBag(t);
    await t.ensureVisible(find.byKey(const ValueKey('bag-bank')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('bag-bank')));
    await t.pumpAndSettle();
    // The bank screen opens on Bank (spec 0020 amendment 3); these tests
    // start on the Bag tab.
    await t.tap(find.byKey(const ValueKey('bank-tab-bag')));
    await t.pumpAndSettle();
    if (bankTab) {
      await t.tap(find.byKey(const ValueKey('bank-tab-bank')));
      await t.pumpAndSettle();
    }
  }

  Future<void> tapKey(WidgetTester t, String key) async {
    await t.ensureVisible(find.byKey(ValueKey(key)));
    await t.pumpAndSettle();
    await t.tap(find.byKey(ValueKey(key)));
    await t.pumpAndSettle();
  }

  final destroy = find.byKey(const ValueKey('card-destroy'));

  /// Destroy on the open card, [count] typed in "How many?" when asked, then
  /// the confirm dialog's button [confirm].
  Future<void> destroyOnCard(
    WidgetTester t,
    GameController c, {
    int? count,
    bool confirm = true,
  }) async {
    await t.ensureVisible(destroy);
    await t.pumpAndSettle();
    await t.tap(destroy);
    await t.pumpAndSettle();
    if (count != null) {
      expect(find.text('How many?'), findsOneWidget);
      await t.enterText(find.byKey(const ValueKey('count-field')), '$count');
      await t.pumpAndSettle();
      await t.tap(find.text('Set'));
      await t.pumpAndSettle();
    }
    await t.tap(
      find.byKey(ValueKey(confirm ? 'destroy-confirm' : 'destroy-keep')),
    );
    await settle(t, c);
    await t.pumpAndSettle();
  }

  testWidgets('criterion 7: a destroy syncs first', (t) async {
    final (c, source) = await pumpGame(t, inventory: {hide: 2});
    source.walk(DateTime(2026, 10, 18, 9, 30), 300);
    now = DateTime(2026, 10, 18, 10);
    expect(c.stepsToday, 0);
    await c.destroy(hide, 1);
    expect(c.stepsToday, 300);
    expect(c.state.inventory[hide], 1);
  });

  testWidgets('criterion 8: the item card from the bag shows Destroy', (
    t,
  ) async {
    await pumpGame(t, inventory: {hide: 2, sword: 1});
    await openBag(t);
    for (final key in [hide, sword]) {
      await tapKey(t, 'bag-$key');
      expect(destroy, findsOneWidget, reason: key);
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();
    }
  });

  testWidgets('criterion 9: the card of a worn item shows no Destroy', (
    t,
  ) async {
    await pumpGame(t, equipment: {'mainHand': sword}, inventory: {sword: 1});
    await openTab(t, 'character');
    await t.tap(find.byKey(const ValueKey('tab-gear')));
    await t.pumpAndSettle();
    await tapKey(t, 'slot-mainHand');
    expect(find.byKey(const ValueKey('item-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('card-unequip')), findsOneWidget);
    expect(destroy, findsNothing);
  });

  testWidgets('the card of the tool in use shows no Destroy, even with the '
      'same tool in the bag', (t) async {
    final (c, _) = await pumpGame(t);
    final tool = c.state.tools['mining']!;
    c.state.addItem(tool);
    await openProfession(t, 'mining');
    await tapKey(t, 'tool-mining');
    expect(find.byKey(const ValueKey('item-card')), findsOneWidget);
    expect(find.text('In use'), findsOneWidget);
    expect(destroy, findsNothing);
  });

  testWidgets('one item: the message says "Destroyed the Bone sword."', (
    t,
  ) async {
    final (c, _) = await pumpGame(t, inventory: {sword: 1});
    await openBag(t);
    await tapKey(t, 'bag-$sword');
    await destroyOnCard(t, c);
    expect(c.state.inventory[sword], isNull);
    expect(find.text('Destroyed the Bone sword.'), findsOneWidget);
  });

  testWidgets('criterion 10: a Bag tab card on the bank screen destroys from '
      'the bag', (t) async {
    final (c, _) = await pumpGame(
      t,
      inventory: {hide: 4},
      prepare: banked({hide: 6}),
    );
    await openBank(t);
    await tapKey(t, 'bank-bag-$hide');
    await destroyOnCard(t, c, count: 4);
    expect(c.state.inventory[hide], isNull);
    expect(c.state.itemBank[hide], 6);
  });

  testWidgets('criterion 11: a Bank tab card on the bank screen destroys from '
      'the bank', (t) async {
    final (c, _) = await pumpGame(
      t,
      inventory: {hide: 4},
      prepare: banked({hide: 6}),
    );
    await openBank(t, bankTab: true);
    await tapKey(t, 'bank-item-$hide');
    await destroyOnCard(t, c, count: 2);
    expect(c.state.itemBank[hide], 4);
    expect(c.state.inventory[hide], 4);
  });

  testWidgets('criterion 12: away from Camp, a bank screen card shows Destroy '
      'and no Store or Take', (t) async {
    await pumpGame(
      t,
      location: 'goblin_woods',
      inventory: {hide: 2},
      prepare: banked({sword: 1}),
    );
    await openBank(t);
    await tapKey(t, 'bank-bag-$hide');
    expect(destroy, findsOneWidget);
    expect(find.byKey(const ValueKey('bank-move-all')), findsNothing);
    await t.tapAt(const Offset(10, 10));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('bank-tab-bank')));
    await t.pumpAndSettle();
    await tapKey(t, 'bank-item-$sword');
    expect(destroy, findsOneWidget);
    expect(find.byKey(const ValueKey('bank-move-all')), findsNothing);
  });

  testWidgets('criterion 13: for a stack, Destroy asks "How many?" with the '
      'whole stack filled in', (t) async {
    await pumpGame(t, inventory: {hide: 12});
    await openBag(t);
    await tapKey(t, 'bag-$hide');
    await t.tap(destroy);
    await t.pumpAndSettle();
    expect(find.text('How many?'), findsOneWidget);
    expect(
      t
          .widget<TextField>(find.byKey(const ValueKey('count-field')))
          .controller!
          .text,
      '12',
    );
  });

  testWidgets('criterion 14: the confirm dialog names the count and the item, '
      'and Keep them leaves the items', (t) async {
    final (c, _) = await pumpGame(t, inventory: {hide: 12});
    await openBag(t);
    await tapKey(t, 'bag-$hide');
    await t.tap(destroy);
    await t.pumpAndSettle();
    await t.tap(find.text('Set'));
    await t.pumpAndSettle();
    expect(find.text('Destroy 12 Goblin hides?'), findsOneWidget);
    expect(find.text('They are gone for good.'), findsOneWidget);
    expect(find.text('Keep them'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('destroy-keep')));
    await settle(t, c);
    await t.pumpAndSettle();
    expect(c.state.inventory[hide], 12);
  });

  testWidgets('criterion 14: one item asks "Destroy the Bone sword?" with '
      'Keep it, and no "How many?"', (t) async {
    final (c, _) = await pumpGame(t, inventory: {sword: 1});
    await openBag(t);
    await tapKey(t, 'bag-$sword');
    await t.tap(destroy);
    await t.pumpAndSettle();
    expect(find.text('How many?'), findsNothing);
    expect(find.text('Destroy the Bone sword?'), findsOneWidget);
    expect(find.text('It is gone for good.'), findsOneWidget);
    await t.tap(find.text('Keep it'));
    await settle(t, c);
    expect(c.state.inventory[sword], 1);
  });

  testWidgets('criterion 15: Destroy in the confirm dialog removes the items '
      'and says "Destroyed N <items>."', (t) async {
    final (c, _) = await pumpGame(t, inventory: {hide: 12});
    await openBag(t);
    await tapKey(t, 'bag-$hide');
    await destroyOnCard(t, c, count: 5);
    expect(c.state.inventory[hide], 7);
    expect(find.text('Destroyed 5 Goblin hides.'), findsOneWidget);
  });
}
