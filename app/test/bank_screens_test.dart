// The item bank in the app: spec 0020 criteria 16-25 and 31 (plan 0040):
// the ways to the bank, the bank screen, the moves and the recipe counts at
// Camp. The rules (criteria 1-15, 26-27) are in game_core's bank_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/game_controller.dart';
import 'package:walkingrpg/ui/item_card.dart';
import 'package:walkingrpg/ui/labels.dart';

import 'ui_test.dart';

void main() {
  const gear = 'bone_sword@rare+crit2';

  void Function(GameState) banked(Map<String, int> items) =>
      (s) => s.bankItems.addAll(items);

  Future<void> openFromNow(WidgetTester t) async {
    await t.ensureVisible(find.byKey(const ValueKey('open-bank')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('open-bank')));
    await t.pumpAndSettle();
  }

  Future<void> openFromCharacter(WidgetTester t) async {
    await openTab(t, 'character');
    await t.tap(find.byKey(const ValueKey('tab-bag')));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const ValueKey('bag-bank')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('bag-bank')));
    await t.pumpAndSettle();
  }

  Future<void> bankTab(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('bank-tab-bank')));
    await t.pumpAndSettle();
  }

  Future<void> tapAndSettle(WidgetTester t, GameController c, Finder f) async {
    await t.tap(f);
    await settle(t, c);
    await t.pumpAndSettle();
  }

  group('the ways to the bank', () {
    testWidgets('criterion 16: at Camp, Now shows the Bank card', (t) async {
      await pumpGame(t);
      expect(find.byKey(const ValueKey('bank-card')), findsOneWidget);
      expect(find.text('Open bank'), findsOneWidget);
      await openFromNow(t);
      expect(find.byKey(const ValueKey('bank-screen')), findsOneWidget);
    });

    testWidgets('criterion 16: away from Camp, Now shows no Bank card', (
      t,
    ) async {
      await pumpGame(t, location: 'goblin_woods');
      expect(find.byKey(const ValueKey('bank-card')), findsNothing);
    });

    testWidgets('criterion 17: the Character tab shows Bank everywhere', (
      t,
    ) async {
      await pumpGame(t, location: 'goblin_woods');
      await openFromCharacter(t);
      expect(find.byKey(const ValueKey('bank-screen')), findsOneWidget);
    });
  });

  group('the bank screen', () {
    testWidgets('criterion 18: the tabs Bag and Bank with items and counts', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        inventory: {'iron_ore': 4},
        prepare: banked({'oak_log': 9}),
      );
      await openFromNow(t);
      final labels = Labels(c.game.data);
      expect(find.text('Bank'), findsWidgets);
      expect(find.byKey(const ValueKey('bank-tab-bag')), findsOneWidget);
      expect(find.text('${labels.item('iron_ore')} ×4'), findsOneWidget);
      await bankTab(t);
      expect(find.text('${labels.item('oak_log')} ×9'), findsOneWidget);
    });

    testWidgets('criterion 19: away from Camp, items do not move', (t) async {
      await pumpGame(t, location: 'goblin_woods', inventory: {'iron_ore': 4});
      await openFromCharacter(t);
      expect(find.text('Items move only at Camp.'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('bank-bag-iron_ore')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('bank-move-all')), findsNothing);
      expect(find.byKey(const ValueKey('bank-move-some')), findsNothing);
    });

    testWidgets('criterion 20: Store all and Store some… move to the bank', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, inventory: {'iron_ore': 10});
      await openFromNow(t);
      await t.tap(find.byKey(const ValueKey('bank-bag-iron_ore')));
      await t.pumpAndSettle();
      expect(find.text('Store some…'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('bank-move-some')));
      await t.pumpAndSettle();
      expect(find.text('How many?'), findsOneWidget);
      await t.enterText(find.byKey(const ValueKey('count-field')), '3');
      await t.pumpAndSettle();
      await tapAndSettle(t, c, find.text('Set'));
      expect(c.state.inventory['iron_ore'], 7);
      expect(c.state.bankItems['iron_ore'], 3);

      await t.tap(find.byKey(const ValueKey('bank-bag-iron_ore')));
      await t.pumpAndSettle();
      expect(find.text('Store all'), findsOneWidget);
      await tapAndSettle(t, c, find.byKey(const ValueKey('bank-move-all')));
      expect(c.state.inventory['iron_ore'], isNull);
      expect(c.state.bankItems['iron_ore'], 10);
    });

    testWidgets('criterion 21: Take all and Take some… move to the bag', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, prepare: banked({'iron_ore': 10}));
      await openFromNow(t);
      await bankTab(t);
      await t.tap(find.byKey(const ValueKey('bank-item-iron_ore')));
      await t.pumpAndSettle();
      expect(find.text('Take some…'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('bank-move-some')));
      await t.pumpAndSettle();
      await t.enterText(find.byKey(const ValueKey('count-field')), '4');
      await t.pumpAndSettle();
      await tapAndSettle(t, c, find.text('Set'));
      expect(c.state.bankItems['iron_ore'], 6);
      expect(c.state.inventory['iron_ore'], 4);

      await t.tap(find.byKey(const ValueKey('bank-item-iron_ore')));
      await t.pumpAndSettle();
      expect(find.text('Take all'), findsOneWidget);
      await tapAndSettle(t, c, find.byKey(const ValueKey('bank-move-all')));
      expect(c.state.bankItems['iron_ore'], isNull);
      expect(c.state.inventory['iron_ore'], 10);
    });

    testWidgets('criterion 22: gear shows in its quality colour', (t) async {
      final (c, _) = await pumpGame(
        t,
        inventory: {gear: 1},
        prepare: banked({gear: 1}),
      );
      await openFromNow(t);
      final line = find.text('${Labels(c.game.data).item(gear)} ×1');
      expect(t.widget<Text>(line).style?.color, itemColour(c.game.data, gear));
      await bankTab(t);
      expect(t.widget<Text>(line).style?.color, itemColour(c.game.data, gear));
    });

    testWidgets('criterion 23: an empty bank reads "The bank is empty."', (
      t,
    ) async {
      await pumpGame(t);
      await openFromNow(t);
      await bankTab(t);
      expect(find.text('The bank is empty.'), findsOneWidget);
    });
  });

  group('crafting at Camp', () {
    testWidgets("criterion 24: at Camp, a recipe's have counts the bank", (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        level: 3,
        inventory: {'copper_ore': 3},
        prepare: banked({'copper_ore': 2}),
      );
      await openProfession(t, 'crafting');
      final name = Labels(c.game.data).item('copper_ore');
      expect(
        find.textContaining('$name 5/5', findRichText: true),
        findsWidgets,
      );
    });

    testWidgets('criterion 25: at Camp, "Have the materials" counts the bank', (
      t,
    ) async {
      await pumpGame(t, level: 3, prepare: banked({'copper_ore': 5}));
      await openProfession(t, 'crafting');
      await t.tap(find.byKey(const ValueKey('filter-mats')));
      await t.pumpAndSettle();
      expect(option('craft', 'copper_sword'), findsOneWidget);
    });
  });

  group('the one queue', () {
    testWidgets('criterion 31: a move syncs first', (t) async {
      final (c, source) = await pumpGame(t, inventory: {'iron_ore': 2});
      source.walk(DateTime(2026, 10, 18, 9, 30), 300);
      now = DateTime(2026, 10, 18, 10);
      expect(c.stepsToday, 0);
      await c.storeInBank('iron_ore', 1);
      expect(c.stepsToday, 300);
      expect(c.state.bankItems['iron_ore'], 1);
      await c.takeFromBank('iron_ore', 1);
      expect(c.state.inventory['iron_ore'], 2);
    });
  });
}
