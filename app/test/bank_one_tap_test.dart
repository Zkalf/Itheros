// The bank in one tap, and Store all materials: spec 0020 amendment 5
// criteria 1-6, 9-14 and 17 (plan 0059). The rule (criteria 7, 8, 15, 16) is
// in game_core's store_all_materials_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/game_controller.dart';
import 'package:walkingrpg/ui/home_shell.dart';

import 'ui_test.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));
  final bankButton = key('bank-button');
  final bankScreen = key('bank-screen');
  final storeAll = key('store-all-materials');
  const topBar = [
    'bank-button',
    'supply-chest-button',
    'achievements-button',
    'journal-button',
    'settings-button',
  ];
  const bag = {
    'copper_ore': 7,
    'goblin_hide': 120,
    'copper_sword': 1,
    'copper_pickaxe': 1,
    'grilled_perch': 2,
  };

  /// Opens the bank from the top bar, on its Bag tab.
  Future<void> openBag(WidgetTester t) async {
    await t.tap(bankButton);
    await t.pumpAndSettle();
    await t.tap(key('bank-tab-bag'));
    await t.pumpAndSettle();
  }

  Future<void> tapStoreAll(WidgetTester t, GameController c) async {
    await t.tap(storeAll);
    await settle(t, c);
    await t.pump();
  }

  group('the Bank button in the top bar', () {
    testWidgets('criterion 1: five buttons, Bank first', (t) async {
      await pumpGame(t);
      final xs = [for (final b in topBar) t.getCenter(key(b)).dx];
      expect(xs, [...xs]..sort(), reason: '$topBar from left to right');
      expect(xs.toSet(), hasLength(5));
      expect(t.widget<IconButton>(bankButton).tooltip, 'Bank');
    });

    testWidgets('criterion 2: a tap opens the bank from each tab', (t) async {
      await pumpGame(t);
      for (final tab in ['now', 'world', 'professions', 'character']) {
        await openTab(t, tab);
        await t.pumpAndSettle();
        await t.tap(bankButton);
        await t.pumpAndSettle();
        expect(bankScreen, findsOneWidget, reason: tab);
        await t.pageBack();
        await t.pumpAndSettle();
        expect(bankScreen, findsNothing, reason: tab);
      }
    });

    testWidgets('criterion 3: away from Camp it opens the bank, which says '
        'that items move only at Camp', (t) async {
      await pumpGame(t, location: 'goblin_woods', inventory: bag);
      await t.tap(bankButton);
      await t.pumpAndSettle();
      expect(bankScreen, findsOneWidget);
      expect(find.text('Items move only at Camp.'), findsOneWidget);
    });

    testWidgets('criterion 4: during the camp tour a tap does nothing', (
      t,
    ) async {
      // A new game: "Who are you?", then Set out starts the tour.
      final (c, _) = await pumpGame(t, character: null);
      await t.enterText(key('character-name-field'), 'Ada');
      await t.ensureVisible(key('origin-tavern_cook'));
      await t.tap(key('origin-tavern_cook'));
      await t.pump();
      await t.ensureVisible(key('set-out'));
      await t.tap(key('set-out'));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(key('tour-card'), findsOneWidget);
      await t.tap(bankButton, warnIfMissed: false);
      await t.pumpAndSettle();
      expect(bankScreen, findsNothing);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(key('tour-card'), findsOneWidget);
    });

    testWidgets('criterion 5: at 408 dp wide the five buttons stand in one '
        'row, none cut off', (t) async {
      await pumpGame(t);
      t.view.physicalSize = const Size(408, 900);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final rects = [for (final b in topBar) t.getRect(key(b))];
      for (final (i, r) in rects.indexed) {
        expect(r.left, greaterThanOrEqualTo(0), reason: topBar[i]);
        expect(r.right, lessThanOrEqualTo(408), reason: topBar[i]);
        expect(r.center.dy, rects.first.center.dy, reason: topBar[i]);
        // A whole touch target, and no button under the one before it.
        expect(r.width, greaterThanOrEqualTo(40), reason: topBar[i]);
        if (i > 0) {
          expect(r.left, greaterThanOrEqualTo(rects[i - 1].right - 0.01));
        }
      }
    });
  });

  group('Store all materials', () {
    testWidgets('criteria 6 to 9: at Camp the button moves every material in '
        'one tap, and gear, a tool and a meal stay', (t) async {
      final (c, _) = await pumpGame(t, inventory: bag);
      await openBag(t);
      expect(storeAll, findsOneWidget);
      expect(find.text('Store all materials'), findsOneWidget);
      await tapStoreAll(t, c);
      // No question: no dialog and no sheet.
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(c.state.itemBank, {'copper_ore': 7, 'goblin_hide': 120});
      expect(c.state.inventory, {
        'copper_sword': 1,
        'copper_pickaxe': 1,
        'grilled_perch': 2,
      });
      expect(find.text('Stored 2 kinds of material.'), findsOneWidget);
      // Nothing left to store: the button goes (criterion 13).
      await t.pumpAndSettle();
      expect(storeAll, findsNothing);
    });

    testWidgets('criterion 10: one kind reads "1 kind"', (t) async {
      final (c, _) = await pumpGame(
        t,
        inventory: {'copper_ore': 7, 'copper_sword': 1},
      );
      await openBag(t);
      await tapStoreAll(t, c);
      expect(find.text('Stored 1 kind of material.'), findsOneWidget);
    });

    testWidgets('criterion 11: with the kind button Gear picked, it still '
        'stores every material', (t) async {
      final (c, _) = await pumpGame(t, inventory: bag);
      await openBag(t);
      await t.tap(find.widgetWithText(ChoiceChip, 'Gear'));
      await t.pumpAndSettle();
      expect(key('bank-bag-copper_ore'), findsNothing);
      await tapStoreAll(t, c);
      expect(c.state.itemBank, {'copper_ore': 7, 'goblin_hide': 120});
    });

    testWidgets('rule 8: the move syncs first, and a walk that the sync '
        'ends away from Camp shows the refusal', (t) async {
      final (c, source) = await pumpGame(t, inventory: bag);
      await c.addAction(const Activity.travel('goblin_woods'));
      await settle(t, c);
      await openBag(t);
      expect(storeAll, findsOneWidget);
      // Steps walked before the tap: the sync credits them to the walk.
      source.walk(DateTime(2026, 10, 18, 9, 30), 5000);
      now = DateTime(2026, 10, 18, 10);
      await tapStoreAll(t, c);
      expect(c.state.location, 'goblin_woods');
      expect(t.takeException(), isNull);
      expect(find.text('Items move only at a bank.'), findsOneWidget);
      expect(c.state.itemBank, isEmpty);
      expect(c.state.inventory['copper_ore'], 7);
    });

    testWidgets('criterion 12: away from Camp the Bag tab shows no button', (
      t,
    ) async {
      await pumpGame(t, location: 'goblin_woods', inventory: bag);
      await openBag(t);
      expect(key('bank-bag-copper_ore'), findsOneWidget);
      expect(storeAll, findsNothing);
    });

    testWidgets('criterion 13: with no material in the bag the Bag tab shows '
        'no button', (t) async {
      await pumpGame(t, inventory: {'copper_sword': 1, 'grilled_perch': 2});
      await openBag(t);
      expect(key('bank-bag-copper_sword'), findsOneWidget);
      expect(storeAll, findsNothing);
    });

    testWidgets('criterion 14: the Bank tab shows no button', (t) async {
      await pumpGame(
        t,
        inventory: bag,
        prepare: (s) => s.itemBank['bones'] = 3,
      );
      await t.tap(bankButton);
      await t.pumpAndSettle();
      expect(key('bank-item-bones'), findsOneWidget);
      expect(storeAll, findsNothing);
    });
  });

  group('what stays', () {
    testWidgets('criterion 17: the Bank row on Now and the Bank button under '
        'the bag stay', (t) async {
      await pumpGame(t);
      expect(key('bank-card'), findsOneWidget);
      // A plain row since amendment 6: no button.
      expect(find.text('Open bank'), findsNothing);
      await openTab(t, 'character');
      await t.tap(key('tab-bag'));
      await t.pumpAndSettle();
      expect(key('bag-bank'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Bank'), findsOneWidget);
    });
  });
}
