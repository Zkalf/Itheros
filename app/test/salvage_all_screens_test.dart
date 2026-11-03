// Salvage all in the app: spec 0010 amendment 9 criteria 8-15 (plan 0043).
// The rules (criteria 1-7) are in game_core's salvage_all_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_test.dart';

void main() {
  Finder within(String key, Finder f) =>
      find.descendant(of: find.byKey(ValueKey(key)), matching: f);
  Finder card(Finder f) => within('item-card', f);

  Future<void> openBag(WidgetTester t) async {
    await openTab(t, 'character');
    await t.tap(find.byKey(const ValueKey('tab-bag')));
    await t.pumpAndSettle();
  }

  Future<void> openItem(WidgetTester t, String key) async {
    await openBag(t);
    await t.tap(find.byKey(ValueKey('bag-$key')));
    await t.pumpAndSettle();
  }

  Future<void> tapVisible(WidgetTester t, String key) async {
    await t.ensureVisible(find.byKey(ValueKey(key)));
    await t.pumpAndSettle();
    await t.tap(find.byKey(ValueKey(key)));
    await t.pumpAndSettle();
  }

  const bag = {
    'bone_sword': 2,
    'copper_sword': 1,
    'bone_sword@rare+crit2+hp10': 1,
    'old_pick': 1,
    'copper_ore': 4,
  };

  testWidgets('criteria 8, 9: at a forge, one button per quality with items', (
    t,
  ) async {
    await pumpGame(t, inventory: bag);
    await openBag(t);
    expect(find.text('Salvage all Common (3)'), findsOneWidget);
    expect(find.text('Salvage all Rare (1)'), findsOneWidget);
    expect(find.byKey(const ValueKey('salvage-all-uncommon')), findsNothing);
    expect(find.byKey(const ValueKey('salvage-all-epic')), findsNothing);
    expect(find.byKey(const ValueKey('salvage-all-legendary')), findsNothing);
  });

  testWidgets('criterion 10: away from a forge, no Salvage all button', (
    t,
  ) async {
    await pumpGame(t, location: 'goblin_woods', inventory: bag);
    await openBag(t);
    expect(find.textContaining('Salvage all'), findsNothing);
  });

  testWidgets('criterion 11: a stack of 2 or more shows Salvage all (N)', (
    t,
  ) async {
    await pumpGame(t, inventory: bag);
    await openItem(t, 'bone_sword');
    expect(card(find.text('Salvage all (2)')), findsOneWidget);
  });

  testWidgets('criterion 12: a single item shows no Salvage all', (t) async {
    await pumpGame(t, inventory: bag);
    await openItem(t, 'copper_sword');
    expect(card(find.byKey(const ValueKey('card-salvage'))), findsOneWidget);
    expect(card(find.byKey(const ValueKey('card-salvage-all'))), findsNothing);
  });

  testWidgets('criterion 13: a Common batch asks; Keep them salvages nothing', (
    t,
  ) async {
    final (c, _) = await pumpGame(t, inventory: bag);
    await openBag(t);
    await tapVisible(t, 'salvage-all-common');
    expect(find.text('Salvage 3 Common items?'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('salvage-all-keep')));
    await settle(t, c);
    await t.pumpAndSettle();
    expect(c.state.inventory['bone_sword'], 2);
    expect(c.state.inventory['copper_sword'], 1);
    expect(c.state.inventory['common_dust'], isNull);
  });

  testWidgets('criterion 14: the message says the items and the dust', (
    t,
  ) async {
    final (c, _) = await pumpGame(t, inventory: bag);
    await openBag(t);
    await tapVisible(t, 'salvage-all-common');
    await t.tap(find.byKey(const ValueKey('salvage-all-confirm')));
    await settle(t, c);
    await t.pumpAndSettle();
    expect(c.state.inventory['bone_sword'], isNull);
    expect(c.state.inventory['copper_sword'], isNull);
    expect(c.state.inventory['bone_sword@rare+crit2+hp10'], 1);
    expect(c.state.inventory['old_pick'], 1);
    expect(c.state.inventory['common_dust'], 3);
    expect(find.text('Salvaged 3 items: 3 Common dust.'), findsOneWidget);
  });

  testWidgets('the item card salvages its whole stack after one question', (
    t,
  ) async {
    final (c, _) = await pumpGame(t, inventory: bag);
    await openItem(t, 'bone_sword');
    await t.tap(card(find.byKey(const ValueKey('card-salvage-all'))));
    await t.pumpAndSettle();
    expect(find.text('Salvage 2 Bone swords?'), findsOneWidget);
    await t.tap(find.byKey(const ValueKey('salvage-all-confirm')));
    await settle(t, c);
    await t.pumpAndSettle();
    expect(c.state.inventory['bone_sword'], isNull);
    expect(c.state.inventory['copper_sword'], 1);
    expect(find.text('Salvaged 2 items: 2 Common dust.'), findsOneWidget);
  });

  testWidgets('criterion 15: a shard found shows with its count', (t) async {
    // 2% a sword: 300 swords find shards with this seed.
    final (c, _) = await pumpGame(t, inventory: {'bone_sword': 300});
    await openItem(t, 'bone_sword');
    await t.tap(card(find.byKey(const ValueKey('card-salvage-all'))));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('salvage-all-confirm')));
    await settle(t, c);
    await t.pumpAndSettle();
    final shards = c.state.inventory['kings_shard'] ?? 0;
    expect(shards, greaterThan(1));
    expect(
      find.text(
        'Salvaged 300 items: 300 Common dust. Found $shards Shards of the '
        'Graveyard King ($shards of 10)!',
      ),
      findsOneWidget,
    );
  });
}
