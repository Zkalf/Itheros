// Hold an item to select several: spec 0020 amendment 8 criteria 7 to 34
// (plan 0067). The rules (criteria 1-6) are in game_core's
// move_items_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/game_controller.dart';
import 'package:walkingrpg/ui/item_card.dart';
import 'package:walkingrpg/ui/item_square.dart';
import 'package:walkingrpg/ui/theme.dart';

import 'images_test.dart' show loadFonts;
import 'ui_test.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));
  final bar = key('selection-bar');
  final cancel = key('select-cancel');
  final store = key('select-store');
  final take = key('select-take');
  final salvage = key('select-salvage');
  final card = find.byType(ItemCard);
  // Camp has a bank and a forge. Grey Moor has a forge and no bank. Goblin
  // Woods has neither.
  const bag = {
    'copper_ore': 7,
    'goblin_hide': 120,
    'copper_sword': 2,
    'hide_vest': 1,
    'grilled_perch': 2,
  };
  const banked = {'bones': 3, 'copper_mace': 1, 'copper_ore': 5};

  /// The bank screen, on its Bank tab.
  Future<void> openBank(WidgetTester t) async {
    await t.tap(key('bank-button'));
    await t.pumpAndSettle();
  }

  /// The bank screen, on its Bag tab.
  Future<void> openBankBag(WidgetTester t) async {
    await openBank(t);
    await t.tap(key('bank-tab-bag'));
    await t.pumpAndSettle();
  }

  /// Character, which opens on its Bag pane.
  Future<void> openBag(WidgetTester t) => openTab(t, 'character');

  Future<void> hold(WidgetTester t, String item) async {
    await t.ensureVisible(key(item));
    await t.longPress(key(item));
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, String item) async {
    await t.ensureVisible(key(item));
    await t.tap(key(item));
    await t.pumpAndSettle();
  }

  /// Taps a button of the bar and waits for its player action.
  Future<void> act(WidgetTester t, GameController c, Finder button) async {
    await t.tap(button);
    await settle(t, c);
    await t.pump();
  }

  /// Whether the row or square [item] shows the check mark.
  bool marked(WidgetTester t, String item) => find
      .descendant(of: key(item), matching: key('selected-mark'))
      .evaluate()
      .isNotEmpty;

  group('the start of a selection', () {
    testWidgets('criterion 7: at Camp a hold on a row of the Bag tab selects '
        'it and shows the bar', (t) async {
      await pumpGame(t, inventory: bag);
      await openBankBag(t);
      expect(bar, findsNothing);
      await hold(t, 'bank-bag-copper_ore');
      expect(bar, findsOneWidget);
      expect(find.text('1 selected'), findsOneWidget);
      expect(marked(t, 'bank-bag-copper_ore'), isTrue);
      expect(store, findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Store'), findsOneWidget);
      expect(take, findsNothing);
      expect(t.widget<IconButton>(cancel).tooltip, 'Cancel');
      expect(card, findsNothing);
    });

    testWidgets('criterion 8: at Camp a hold on a row of the Bank tab selects '
        'it and shows the bar', (t) async {
      await pumpGame(t, prepare: (s) => s.itemBank.addAll(banked));
      await openBank(t);
      await hold(t, 'bank-item-bones');
      expect(bar, findsOneWidget);
      expect(find.text('1 selected'), findsOneWidget);
      expect(marked(t, 'bank-item-bones'), isTrue);
      expect(find.widgetWithText(FilledButton, 'Take'), findsOneWidget);
      expect(store, findsNothing);
    });

    testWidgets('criterion 9: at Camp a hold on a square of the bag on '
        'Character selects it and shows the bar', (t) async {
      await pumpGame(t, inventory: bag);
      await openBag(t);
      await hold(t, 'bag-copper_ore');
      expect(bar, findsOneWidget);
      expect(find.text('1 selected'), findsOneWidget);
      expect(marked(t, 'bag-copper_ore'), isTrue);
      expect(store, findsOneWidget);
    });

    testWidgets('criterion 10: away from a bank and a forge a hold shows no '
        'bar in each of the three lists', (t) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        inventory: bag,
        prepare: (s) => s.itemBank.addAll(banked),
      );
      await openBag(t);
      await hold(t, 'bag-copper_ore');
      expect(bar, findsNothing);
      expect(key('selected-mark'), findsNothing);
      // The hold opens no card either (rule 2).
      expect(card, findsNothing);
      await openBank(t);
      await hold(t, 'bank-item-bones');
      expect(bar, findsNothing);
      expect(card, findsNothing);
      await t.tap(key('bank-tab-bag'));
      await t.pumpAndSettle();
      await hold(t, 'bank-bag-copper_ore');
      expect(bar, findsNothing);
      expect(key('selected-mark'), findsNothing);
      expect(card, findsNothing);
    });

    testWidgets('criterion 11: without a selection a tap opens the card', (
      t,
    ) async {
      await pumpGame(t, inventory: bag);
      await openBag(t);
      await tap(t, 'bag-copper_ore');
      expect(card, findsOneWidget);
      expect(bar, findsNothing);
      await closeSheet(t);
      await openBankBag(t);
      await tap(t, 'bank-bag-copper_ore');
      expect(card, findsOneWidget);
      expect(bar, findsNothing);
    });
  });

  group('select and look', () {
    testWidgets('criteria 12 to 14: a tap selects a second item and opens no '
        'card, a tap on a selected item removes it, and only selected items '
        'show the check mark', (t) async {
      await pumpGame(t, inventory: bag);
      await openBankBag(t);
      await hold(t, 'bank-bag-copper_ore');
      await tap(t, 'bank-bag-hide_vest');
      expect(find.text('2 selected'), findsOneWidget);
      expect(card, findsNothing);
      expect(marked(t, 'bank-bag-copper_ore'), isTrue);
      expect(marked(t, 'bank-bag-hide_vest'), isTrue);
      expect(marked(t, 'bank-bag-goblin_hide'), isFalse);
      expect(key('selected-mark'), findsNWidgets(2));
      // The fill of a selected chip behind a selected row (rule 6).
      ListTile row(String item) => t.widget<ListTile>(key(item));
      expect(row('bank-bag-hide_vest').tileColor, Quiet.selected);
      expect(row('bank-bag-goblin_hide').tileColor, isNull);
      await tap(t, 'bank-bag-copper_ore');
      expect(find.text('1 selected'), findsOneWidget);
      expect(marked(t, 'bank-bag-copper_ore'), isFalse);
      expect(marked(t, 'bank-bag-hide_vest'), isTrue);
    });

    testWidgets('criteria 12 to 14 in the bag on Character', (t) async {
      await pumpGame(t, inventory: bag);
      await openBag(t);
      await hold(t, 'bag-copper_ore');
      await tap(t, 'bag-hide_vest');
      expect(find.text('2 selected'), findsOneWidget);
      expect(card, findsNothing);
      expect(marked(t, 'bag-hide_vest'), isTrue);
      expect(marked(t, 'bag-grilled_perch'), isFalse);
      expect(t.widget<ItemSquare>(key('bag-hide_vest')).selected, isTrue);
      // The fill of a selected chip behind a selected square (rule 6).
      Finder fill(String item) =>
          find.descendant(of: key(item), matching: key('selected-fill'));
      expect(fill('bag-hide_vest'), findsOneWidget);
      expect(fill('bag-grilled_perch'), findsNothing);
      await tap(t, 'bag-hide_vest');
      expect(find.text('1 selected'), findsOneWidget);
      expect(marked(t, 'bag-hide_vest'), isFalse);
    });

    testWidgets('criterion 15: a hold on one square of an item with two '
        'stacks marks both squares as one selected item', (t) async {
      await pumpGame(t, inventory: bag);
      await openBag(t);
      await hold(t, 'bag-goblin_hide-2');
      expect(marked(t, 'bag-goblin_hide'), isTrue);
      expect(marked(t, 'bag-goblin_hide-2'), isTrue);
      expect(find.text('1 selected'), findsOneWidget);
    });

    testWidgets('criterion 16: a selected item stays selected after a kind '
        'chip hides it', (t) async {
      final (c, _) = await pumpGame(t, inventory: bag);
      await openBankBag(t);
      await hold(t, 'bank-bag-copper_ore');
      await t.tap(find.widgetWithText(ChoiceChip, 'Gear'));
      await t.pumpAndSettle();
      expect(key('bank-bag-copper_ore'), findsNothing);
      expect(find.text('1 selected'), findsOneWidget);
      await tap(t, 'bank-bag-hide_vest');
      expect(find.text('2 selected'), findsOneWidget);
      // The action still uses the hidden item (rule 7).
      await act(t, c, store);
      expect(c.state.itemBank, {'copper_ore': 7, 'hide_vest': 1});
    });
  });

  group('the actions', () {
    testWidgets('criteria 17, 20, 21 and 27: Store on the Bag tab moves the '
        'whole count of each selected item, asks nothing and says so', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, inventory: bag);
      await openBankBag(t);
      await hold(t, 'bank-bag-copper_ore');
      await tap(t, 'bank-bag-copper_sword');
      await tap(t, 'bank-bag-grilled_perch');
      await act(t, c, store);
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(BottomSheet), findsNothing);
      expect(c.state.itemBank, {
        'copper_ore': 7,
        'copper_sword': 2,
        'grilled_perch': 2,
      });
      expect(c.state.inventory, {'goblin_hide': 120, 'hide_vest': 1});
      expect(find.text('Stored 11 items.'), findsOneWidget);
      await t.pumpAndSettle();
      expect(bar, findsNothing);
      expect(key('selected-mark'), findsNothing);
    });

    testWidgets('criterion 21: one item reads "1 item"', (t) async {
      final (c, _) = await pumpGame(t, inventory: bag);
      await openBankBag(t);
      await hold(t, 'bank-bag-hide_vest');
      await act(t, c, store);
      expect(find.text('Stored 1 item.'), findsOneWidget);
    });

    testWidgets('criteria 18, 20, 21 and 27: Take on the Bank tab moves the '
        'whole count of each selected item, asks nothing and says so', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        inventory: {'copper_ore': 7},
        prepare: (s) => s.itemBank.addAll(banked),
      );
      await openBank(t);
      await hold(t, 'bank-item-copper_ore');
      await tap(t, 'bank-item-copper_mace');
      await act(t, c, take);
      expect(find.byType(Dialog), findsNothing);
      expect(c.state.inventory, {'copper_ore': 12, 'copper_mace': 1});
      expect(c.state.itemBank, {'bones': 3});
      expect(find.text('Took 6 items.'), findsOneWidget);
      await t.pumpAndSettle();
      expect(bar, findsNothing);
      expect(key('selected-mark'), findsNothing);
    });

    testWidgets('criterion 19: Store in the bag on Character moves the '
        'selected items to the bank', (t) async {
      final (c, _) = await pumpGame(t, inventory: bag);
      await openBag(t);
      await hold(t, 'bag-goblin_hide');
      await tap(t, 'bag-hide_vest');
      await act(t, c, store);
      expect(find.byType(Dialog), findsNothing);
      expect(c.state.itemBank, {'goblin_hide': 120, 'hide_vest': 1});
      expect(c.state.inventory, {
        'copper_ore': 7,
        'copper_sword': 2,
        'grilled_perch': 2,
      });
      expect(find.text('Stored 121 items.'), findsOneWidget);
    });

    testWidgets('rules 15 and 18: the move syncs first, and a walk that the '
        'sync ends away from Camp shows the refusal', (t) async {
      final (c, source) = await pumpGame(t, inventory: bag);
      await c.addAction(const Activity.travel('goblin_woods'));
      await settle(t, c);
      await openBankBag(t);
      await hold(t, 'bank-bag-copper_ore');
      source.walk(DateTime(2026, 10, 18, 9, 30), 5000);
      now = DateTime(2026, 10, 18, 10);
      await act(t, c, store);
      expect(c.state.location, 'goblin_woods');
      expect(t.takeException(), isNull);
      expect(find.text('Items move only at a bank.'), findsOneWidget);
      expect(c.state.itemBank, isEmpty);
      expect(c.state.inventory['copper_ore'], 7);
    });

    testWidgets('criteria 22 and 23: at a forge the bar shows Salvage with '
        'the count of the selected gear and tools, and none for materials', (
      t,
    ) async {
      await pumpGame(
        t,
        inventory: {...bag, 'copper_pickaxe': 1, 'old_pick': 1},
      );
      await openBag(t);
      await hold(t, 'bag-copper_ore');
      expect(bar, findsOneWidget);
      expect(salvage, findsNothing);
      await tap(t, 'bag-grilled_perch');
      // A starter tool is not salvaged.
      await tap(t, 'bag-old_pick');
      expect(salvage, findsNothing);
      await tap(t, 'bag-copper_sword');
      expect(find.widgetWithText(OutlinedButton, 'Salvage (2)'), findsOne);
      await tap(t, 'bag-hide_vest');
      await tap(t, 'bag-copper_pickaxe');
      expect(find.widgetWithText(OutlinedButton, 'Salvage (4)'), findsOne);
      expect(find.text('6 selected'), findsOneWidget);
    });

    testWidgets('criteria 24 and 27: Salvage asks first, and "Keep them" '
        'salvages nothing and ends the selection', (t) async {
      final (c, _) = await pumpGame(t, inventory: bag);
      await openBag(t);
      await hold(t, 'bag-copper_sword');
      await tap(t, 'bag-hide_vest');
      await t.tap(salvage);
      await t.pumpAndSettle();
      expect(find.text('Salvage 3 items?'), findsOneWidget);
      expect(find.text('They break down into dust for good.'), findsOneWidget);
      await t.tap(key('salvage-all-keep'));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.state.inventory, bag);
      expect(bar, findsNothing);
      expect(key('selected-mark'), findsNothing);
    });

    testWidgets('criteria 25 and 27: after Salvage the selected gear is '
        'gone, a selected material stays, and the message says the items and '
        'the dust', (t) async {
      final (c, _) = await pumpGame(t, inventory: bag);
      await openBag(t);
      await hold(t, 'bag-copper_sword');
      await tap(t, 'bag-hide_vest');
      await tap(t, 'bag-copper_ore');
      await t.tap(salvage);
      await t.pumpAndSettle();
      await t.tap(key('salvage-all-confirm'));
      await settle(t, c);
      await t.pump();
      expect(c.state.inventory['copper_sword'], isNull);
      expect(c.state.inventory['hide_vest'], isNull);
      expect(c.state.inventory['copper_ore'], 7);
      expect(c.state.inventory['common_dust'], 3);
      expect(c.state.itemBank, isEmpty);
      expect(
        find.textContaining('Salvaged 3 items: 3 Common dust.'),
        findsOneWidget,
      );
      await t.pumpAndSettle();
      expect(bar, findsNothing);
      expect(key('selected-mark'), findsNothing);
    });

    testWidgets('criterion 26: the bank screen shows no Salvage, and a forge '
        'without a bank shows no Store', (t) async {
      await pumpGame(t, inventory: bag);
      await openBankBag(t);
      await hold(t, 'bank-bag-copper_sword');
      expect(store, findsOneWidget);
      expect(salvage, findsNothing);
    });

    testWidgets('criterion 26: at a forge without a bank the bar shows '
        'Salvage and no Store', (t) async {
      await pumpGame(t, location: 'grey_moor', inventory: bag);
      await openBag(t);
      await hold(t, 'bag-copper_sword');
      expect(bar, findsOneWidget);
      expect(salvage, findsOneWidget);
      expect(store, findsNothing);
    });
  });

  group('the end of a selection', () {
    testWidgets('criterion 28: × ends the selection and moves nothing', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, inventory: bag);
      await openBankBag(t);
      await hold(t, 'bank-bag-copper_ore');
      await tap(t, 'bank-bag-hide_vest');
      await t.tap(cancel);
      await settle(t, c);
      await t.pumpAndSettle();
      expect(bar, findsNothing);
      expect(key('selected-mark'), findsNothing);
      expect(c.state.inventory, bag);
      expect(c.state.itemBank, isEmpty);
      // A tap opens the card again.
      await tap(t, 'bank-bag-copper_ore');
      expect(card, findsOneWidget);
    });

    testWidgets('criterion 29: back ends the selection, and the bank screen '
        'stays open', (t) async {
      await pumpGame(t, inventory: bag);
      await openBankBag(t);
      await hold(t, 'bank-bag-copper_ore');
      await t.pageBack();
      await t.pumpAndSettle();
      expect(bar, findsNothing);
      expect(key('selected-mark'), findsNothing);
      expect(key('bank-screen'), findsOneWidget);
      // With no selection, back leaves the screen.
      await t.pageBack();
      await t.pumpAndSettle();
      expect(key('bank-screen'), findsNothing);
    });

    testWidgets('criterion 29: the back gesture ends the selection of the '
        'bag on Character, and Character stays open', (t) async {
      await pumpGame(t, inventory: bag);
      await openBag(t);
      await hold(t, 'bag-copper_ore');
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(bar, findsNothing);
      expect(key('selected-mark'), findsNothing);
      expect(key('bag-copper_ore'), findsOneWidget);
    });

    testWidgets('criterion 30: the selection ends with its last item', (
      t,
    ) async {
      await pumpGame(t, inventory: bag);
      await openBag(t);
      await hold(t, 'bag-copper_ore');
      await tap(t, 'bag-copper_ore');
      expect(bar, findsNothing);
      expect(card, findsNothing);
      await tap(t, 'bag-copper_ore');
      expect(card, findsOneWidget);
    });

    testWidgets('criterion 31: the other tab of the bank screen ends the '
        'selection', (t) async {
      await pumpGame(
        t,
        inventory: bag,
        prepare: (s) => s.itemBank.addAll(banked),
      );
      await openBankBag(t);
      await hold(t, 'bank-bag-copper_ore');
      await t.tap(key('bank-tab-bank'));
      await t.pumpAndSettle();
      expect(bar, findsNothing);
      expect(key('selected-mark'), findsNothing);
      await t.tap(key('bank-tab-bag'));
      await t.pumpAndSettle();
      expect(bar, findsNothing);
      expect(key('selected-mark'), findsNothing);
    });

    testWidgets('criterion 32: another pane of Character ends the selection', (
      t,
    ) async {
      await pumpGame(t, inventory: bag);
      await openBag(t);
      await hold(t, 'bag-copper_ore');
      await t.ensureVisible(key('tab-gear'));
      await t.tap(key('tab-gear'));
      await t.pumpAndSettle();
      expect(bar, findsNothing);
      await t.tap(key('tab-bag'));
      await t.pumpAndSettle();
      expect(bar, findsNothing);
      expect(key('selected-mark'), findsNothing);
    });

    testWidgets('rule 19: a walk away from Camp ends the selection, when no '
        'action is left', (t) async {
      final (c, source) = await pumpGame(t, inventory: bag);
      await c.addAction(const Activity.travel('goblin_woods'));
      await settle(t, c);
      await openBag(t);
      await hold(t, 'bag-copper_ore');
      expect(bar, findsOneWidget);
      source.walk(DateTime(2026, 10, 18, 9, 30), 5000);
      now = DateTime(2026, 10, 18, 10);
      await c.syncNow();
      await t.pumpAndSettle();
      expect(c.state.location, 'goblin_woods');
      expect(bar, findsNothing);
      expect(key('selected-mark'), findsNothing);
    });

    testWidgets('rule 19: another tab of the game ends the selection', (
      t,
    ) async {
      await pumpGame(t, inventory: bag);
      await openBag(t);
      await hold(t, 'bag-copper_ore');
      await openTab(t, 'now');
      expect(bar, findsNothing);
      await openBag(t);
      expect(bar, findsNothing);
      expect(key('selected-mark'), findsNothing);
    });
  });

  group('what stays', () {
    testWidgets('criterion 33: Store all materials, the Salvage all buttons '
        'and the buttons of the item card stay', (t) async {
      await pumpGame(t, inventory: bag);
      await openBag(t);
      expect(key('salvage-all-common'), findsOneWidget);
      await tap(t, 'bag-copper_sword');
      expect(key('card-salvage'), findsOneWidget);
      expect(key('card-salvage-all'), findsOneWidget);
      expect(key('card-destroy'), findsOneWidget);
      await closeSheet(t);
      await openBankBag(t);
      expect(key('store-all-materials'), findsOneWidget);
      await tap(t, 'bank-bag-copper_ore');
      expect(key('bank-move-all'), findsOneWidget);
      expect(key('bank-move-some'), findsOneWidget);
    });
  });

  testWidgets('criterion 34: at 408 dp wide the bar with ×, "12 selected", '
      'Store and "Salvage (140)" stands in one row, nothing cut off', (
    t,
  ) async {
    await t.runAsync(loadFonts);
    final others = [
      for (final i in game.data.items.values)
        if (i.slot == null && i.tool == null) i.id,
    ].take(11).toList();
    await pumpGame(
      t,
      inventory: {'copper_sword': 140, for (final id in others) id: 3},
    );
    // Tall enough for the 140 squares, so each tap lands on its square.
    t.view.physicalSize = const Size(1080, 12000);
    await openBag(t);
    await hold(t, 'bag-copper_sword');
    final wide = t.getSize(key('select-count')).height;
    for (final id in others) {
      await tap(t, 'bag-$id');
    }
    t.view.physicalSize = const Size(408, 884);
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('12 selected'), findsOneWidget);
    expect(find.text('Salvage (140)'), findsOneWidget);
    const parts = [
      'select-cancel',
      'select-count',
      'select-store',
      'select-salvage',
    ];
    final rects = [for (final p in parts) t.getRect(key(p))];
    final whole = t.getRect(bar);
    for (final (i, r) in rects.indexed) {
      expect(r.left, greaterThanOrEqualTo(0), reason: parts[i]);
      expect(r.right, lessThanOrEqualTo(408), reason: parts[i]);
      expect(
        r.center.dy,
        inInclusiveRange(whole.top, whole.bottom),
        reason: parts[i],
      );
      expect(r.center.dy, closeTo(rects.first.center.dy, 1), reason: parts[i]);
      if (i > 0) {
        expect(r.left, greaterThanOrEqualTo(rects[i - 1].right - 0.01));
      }
    }
    // One line of text, as on a wide screen.
    expect(rects[1].height, wide);
    // The labels of the buttons stand on one line too.
    for (final label in ['Store', 'Salvage (140)']) {
      expect(t.getSize(find.text(label)).height, lessThan(30), reason: label);
    }
    // The bar stands above the bottom bar of the game.
    expect(whole.bottom, lessThanOrEqualTo(t.getRect(key('tab-now')).top));
  });
}
