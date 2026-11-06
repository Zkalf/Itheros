// Pictures, item cards and kinds on the bank screen and in the bag: spec 0020
// amendment 2 criteria 2-29 (plan 0046). Criterion 1 is in game_core's
// item_kinds_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/game_controller.dart';
import 'package:walkingrpg/ui/images.dart';
import 'package:walkingrpg/ui/item_card.dart';
import 'package:walkingrpg/ui/item_square.dart';
import 'package:walkingrpg/ui/labels.dart';
import 'package:walkingrpg/ui/theme.dart' show BackPlate;

import 'images_test.dart' show diskImages, expectRing, qualityRgb, ringIn;
import 'now_monsters_test.dart' show expectSocketFirst, inside;
import 'ui_test.dart';

void main() {
  const sword = 'bone_sword';
  const rareSword = 'bone_sword@rare+crit2';
  const pick = 'copper_pickaxe';
  const meal = 'venison_skewer';
  const ore = 'copper_ore';
  const mixed = {sword: 2, pick: 1, meal: 3, ore: 5};
  final data = game.data;

  void Function(GameState) banked(Map<String, int> items) =>
      (s) => s.itemBank.addAll(items);

  Future<void> openBag(WidgetTester t) async {
    await openTab(t, 'character');
    await t.tap(find.byKey(const ValueKey('tab-bag')));
    await t.pumpAndSettle();
  }

  Future<void> openBank(WidgetTester t) async {
    await openBag(t);
    await t.ensureVisible(find.byKey(const ValueKey('bag-bank')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('bag-bank')));
    await t.pumpAndSettle();
  }

  Future<void> bankTab(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('bank-tab-bank')));
    await t.pumpAndSettle();
  }

  Finder chip(String list, String id) => find.byKey(ValueKey('kind-$list-$id'));

  Future<void> pickKind(WidgetTester t, String list, String id) async {
    await t.ensureVisible(chip(list, id));
    await t.pumpAndSettle();
    await t.tap(chip(list, id));
    await t.pumpAndSettle();
  }

  bool selected(WidgetTester t, String list, String id) =>
      t.widget<ChoiceChip>(chip(list, id)).selected;

  /// The item keys of the bag grid, in screen order.
  List<String> bagSquares(WidgetTester t) => [
    for (final w in t.widgetList<ItemSquare>(find.byType(ItemSquare)))
      (w.key! as ValueKey<String>).value.substring('bag-'.length),
  ];

  /// The item keys of the rows of a bank tab, in screen order.
  List<String> bankRows(WidgetTester t, String prefix) => [
    for (final w in t.widgetList<ListTile>(
      find.byWidgetPredicate(
        (w) =>
            w is ListTile &&
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('$prefix-'),
      ),
    ))
      (w.key! as ValueKey<String>).value.substring(prefix.length + 1),
  ];

  List<String> ofKind(Map<String, int> items, ItemKind? k) => [
    for (final key in bagOrder(data, items.keys))
      if (k == null || data.kindOf(key) == k) key,
  ];

  Future<void> tapAndSettle(WidgetTester t, GameController c, Finder f) async {
    await t.tap(f);
    await settle(t, c);
    await t.pumpAndSettle();
  }

  group('the filter buttons', () {
    const lists = ['bag', 'bank-bag', 'bank-bank'];
    const words = {
      'all': 'All',
      'gear': 'Gear',
      'tool': 'Tools',
      'meal': 'Meals',
      'material': 'Materials',
    };

    Future<void> openList(WidgetTester t, String list) async {
      if (list == 'bag') return openBag(t);
      await openBank(t);
      if (list == 'bank-bank') await bankTab(t);
    }

    for (final (n, list) in [(2, 'bag'), (3, 'bank-bag'), (4, 'bank-bank')]) {
      testWidgets('criteria $n and 5: $list shows the five chips, with no '
          'counts', (t) async {
        await pumpGame(t, inventory: mixed, prepare: banked(mixed));
        await openList(t, list);
        for (final MapEntry(key: id, value: word) in words.entries) {
          expect(
            inside(chip(list, id), find.text(word)),
            findsOneWidget,
            reason: '$list: the chip $id reads "$word" only',
          );
        }
      });
    }

    for (final list in lists) {
      testWidgets('criteria 6-10: in $list, All shows every item and each '
          'kind only its items, in the order of the bag', (t) async {
        await pumpGame(t, inventory: mixed, prepare: banked(mixed));
        await openList(t, list);
        List<String> shown() => list == 'bag'
            ? bagSquares(t)
            : bankRows(t, list == 'bank-bag' ? 'bank-bag' : 'bank-item');
        expect(shown(), ofKind(mixed, null), reason: '$list: All');
        expect(shown(), hasLength(4), reason: '$list: All');
        for (final k in ItemKind.values) {
          await pickKind(t, list, k.name);
          expect(shown(), ofKind(mixed, k), reason: '$list: ${k.name}');
          expect(shown(), isNotEmpty, reason: '$list: ${k.name}');
        }
        await pickKind(t, list, 'all');
        expect(shown(), ofKind(mixed, null), reason: '$list: All again');
      });
    }

    testWidgets('criterion 11: the picked chip has the selected look, the '
        'others do not', (t) async {
      await pumpGame(t, inventory: mixed);
      await openBag(t);
      expect(selected(t, 'bag', 'all'), isTrue);
      await pickKind(t, 'bag', 'meal');
      for (final id in words.keys) {
        expect(selected(t, 'bag', id), id == 'meal', reason: id);
      }
    });

    testWidgets('criterion 12: a kind with no items reads "Nothing of this '
        'kind here."', (t) async {
      await pumpGame(t, inventory: {ore: 2}, prepare: banked({ore: 1}));
      await openBag(t);
      await pickKind(t, 'bag', 'meal');
      expect(find.text('Nothing of this kind here.'), findsOneWidget);
      expect(find.byType(ItemSquare), findsNothing);
    });

    testWidgets('criterion 13: a pick in the bag leaves both bank tabs on '
        'their own picks', (t) async {
      await pumpGame(t, inventory: mixed, prepare: banked(mixed));
      // The Bank tab gets its own pick first, so a bag pick that wrote over
      // it would show.
      await openBank(t);
      await bankTab(t);
      await pickKind(t, 'bank-bank', 'gear');
      await t.tap(find.byType(BackPlate));
      await t.pumpAndSettle();
      await openBag(t);
      await pickKind(t, 'bag', 'meal');
      await openBank(t);
      expect(selected(t, 'bank-bag', 'all'), isTrue);
      await bankTab(t);
      expect(selected(t, 'bank-bank', 'gear'), isTrue);
    });

    testWidgets('criterion 14: a pick in the Bag tab leaves the Bank tab on '
        'its own pick', (t) async {
      await pumpGame(t, inventory: mixed, prepare: banked(mixed));
      await openBank(t);
      await pickKind(t, 'bank-bag', 'tool');
      await bankTab(t);
      expect(selected(t, 'bank-bank', 'all'), isTrue);
      await pickKind(t, 'bank-bank', 'gear');
      await t.tap(find.byKey(const ValueKey('bank-tab-bag')));
      await t.pumpAndSettle();
      expect(selected(t, 'bank-bag', 'tool'), isTrue);
    });

    testWidgets('criterion 15: a list keeps its pick after the bank screen '
        'closes and opens again', (t) async {
      await pumpGame(t, inventory: mixed, prepare: banked(mixed));
      await openBank(t);
      await pickKind(t, 'bank-bag', 'tool');
      await bankTab(t);
      await pickKind(t, 'bank-bank', 'material');
      await t.tap(find.byType(BackPlate));
      await t.pumpAndSettle();
      await openTab(t, 'now');
      await openBank(t);
      expect(selected(t, 'bank-bag', 'tool'), isTrue);
      expect(bankRows(t, 'bank-bag'), [pick]);
      await bankTab(t);
      expect(selected(t, 'bank-bank', 'material'), isTrue);
    });

    testWidgets('criterion 16: after a restart, each list shows All', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        inventory: mixed,
        prepare: banked(mixed),
      );
      await openBank(t);
      await pickKind(t, 'bank-bag', 'tool');
      await bankTab(t);
      await pickKind(t, 'bank-bank', 'gear');
      c.kindPicks['bag'] = ItemKind.meal;
      // A new controller is a new start of the app.
      await t.pumpWidget(const SizedBox());
      await pumpGame(t, inventory: mixed, prepare: banked(mixed));
      await openBag(t);
      expect(selected(t, 'bag', 'all'), isTrue);
      await openBank(t);
      expect(selected(t, 'bank-bag', 'all'), isTrue);
      await bankTab(t);
      expect(selected(t, 'bank-bank', 'all'), isTrue);
    });
  });

  group('the rows of the bank screen', () {
    final rarePick = data.keyFor(pick, 'rare');

    testWidgets('criteria 17-18: each row starts with its picture in a 48 dp '
        'socket', (t) async {
      final items = {rareSword: 1, rarePick: 1, meal: 2, ore: 4};
      await pumpGame(
        t,
        images: diskImages,
        inventory: items,
        prepare: banked(items),
      );
      await openBank(t);
      for (final (prefix, n) in [('bank-bag', 17), ('bank-item', 18)]) {
        if (prefix == 'bank-item') await bankTab(t);
        for (final key in items.keys) {
          final row = find.byKey(ValueKey('$prefix-$key'));
          expectSocketFirst(
            t,
            row,
            ItemThing(key),
            48,
            'criterion $n: $key in $prefix',
          );
        }
      }
    });

    testWidgets('criterion 19: gear and tools show the ring of their quality', (
      t,
    ) async {
      final items = {rareSword: 1, rarePick: 1, meal: 2};
      await pumpGame(t, images: diskImages, prepare: banked(items));
      await openBank(t);
      await bankTab(t);
      for (final key in [rareSword, rarePick]) {
        expectRing(
          t,
          find.byKey(ValueKey('bank-item-$key')),
          qualityRgb('rare'),
          key,
        );
      }
      expect(
        ringIn(t, find.byKey(const ValueKey('bank-item-$meal'))),
        isNull,
        reason: 'a meal has no ring',
      );
    });

    testWidgets('criterion 20: the row shows the name in its quality colour '
        'and the count', (t) async {
      await pumpGame(t, inventory: {rareSword: 1, ore: 4});
      await openBank(t);
      final labels = Labels(data);
      for (final (key, n) in [(rareSword, 1), (ore, 4)]) {
        final line = inside(
          find.byKey(ValueKey('bank-bag-$key')),
          find.text('${labels.item(key)} ×$n'),
        );
        expect(line, findsOneWidget, reason: key);
        expect(t.widget<Text>(line).style?.color, itemColour(data, key));
      }
    });
  });

  group('the item card on the bank screen', () {
    const rolled = 'bone_sword@rare+crit2+hp10';
    final noActions = [
      'card-equip',
      'card-swap',
      'card-eat',
      'card-tool',
      'card-salvage',
      'card-salvage-all',
      'card-reroll',
    ];

    Future<void> openCard(WidgetTester t, String prefix, String key) async {
      await t.tap(find.byKey(ValueKey('$prefix-$key')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('item-card')), findsOneWidget);
    }

    testWidgets('criterion 21: a tap on a row opens the item card with its '
        'stats and bonus stats', (t) async {
      await pumpGame(t, prepare: banked({rolled: 1}));
      await openBank(t);
      await bankTab(t);
      await openCard(t, 'bank-item', rolled);
      final labels = Labels(data);
      final card = find.byKey(const ValueKey('item-card'));
      expect(inside(card, find.text(labels.plain(rolled))), findsOneWidget);
      expect(
        inside(
          card,
          find.text(labels.bonus(data.baseStatsOf(rolled)).join(' · ')),
        ),
        findsOneWidget,
        reason: 'the stats',
      );
      for (final r in data.bonusRolls(rolled)) {
        expect(
          inside(card, find.text(labels.bonusRoll(r))),
          findsOneWidget,
          reason: 'the bonus stat ${labels.bonusRoll(r)}',
        );
      }
    });

    testWidgets('criterion 22: at Camp, a Bag tab card shows Store all and '
        'Store some…', (t) async {
      await pumpGame(t, inventory: {ore: 5});
      await openBank(t);
      await openCard(t, 'bank-bag', ore);
      expect(find.text('Store all'), findsOneWidget);
      expect(find.text('Store some…'), findsOneWidget);
      expect(find.textContaining('Take'), findsNothing);
    });

    testWidgets('criterion 23: at Camp, a Bank tab card shows Take all and '
        'Take some…', (t) async {
      await pumpGame(t, prepare: banked({ore: 5}));
      await openBank(t);
      await bankTab(t);
      await openCard(t, 'bank-item', ore);
      expect(find.text('Take all'), findsOneWidget);
      expect(find.text('Take some…'), findsOneWidget);
      expect(find.textContaining('Store'), findsNothing);
    });

    testWidgets('criterion 24: Store all on the card moves the whole stack to '
        'the bank', (t) async {
      final (c, _) = await pumpGame(t, inventory: {sword: 2});
      await openBank(t);
      await openCard(t, 'bank-bag', sword);
      await tapAndSettle(t, c, find.byKey(const ValueKey('bank-move-all')));
      expect(c.state.inventory[sword], isNull);
      expect(c.state.itemBank[sword], 2);
      expect(find.byKey(const ValueKey('item-card')), findsNothing);
    });

    testWidgets('criterion 25: Take some… on the card moves the typed count to '
        'the bag', (t) async {
      final (c, _) = await pumpGame(t, prepare: banked({ore: 10}));
      await openBank(t);
      await bankTab(t);
      await openCard(t, 'bank-item', ore);
      await t.tap(find.byKey(const ValueKey('bank-move-some')));
      await t.pumpAndSettle();
      expect(find.text('How many?'), findsOneWidget);
      await t.enterText(find.byKey(const ValueKey('count-field')), '4');
      await t.pumpAndSettle();
      await tapAndSettle(t, c, find.text('Set'));
      expect(c.state.itemBank[ore], 6);
      expect(c.state.inventory[ore], 4);
    });

    testWidgets('criterion 26: away from Camp, a tap opens the card with no '
        'Store or Take', (t) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        inventory: {ore: 2},
        prepare: banked({sword: 1}),
      );
      await openBank(t);
      expect(find.text('Items move only at Camp.'), findsOneWidget);
      await openCard(t, 'bank-bag', ore);
      expect(find.byKey(const ValueKey('bank-move-all')), findsNothing);
      expect(find.byKey(const ValueKey('bank-move-some')), findsNothing);
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();
      await bankTab(t);
      await openCard(t, 'bank-item', sword);
      expect(find.byKey(const ValueKey('bank-move-all')), findsNothing);
      expect(find.byKey(const ValueKey('bank-move-some')), findsNothing);
    });

    testWidgets('criterion 27: the card on the bank screen shows no Equip, '
        'Eat, Auto-eat, Salvage or Reroll', (t) async {
      // At Camp, a forge: from the bag, these cards would show them.
      final items = {sword: 2, pick: 2, meal: 2};
      await pumpGame(t, inventory: items, prepare: banked(items));
      await openBank(t);
      for (final prefix in ['bank-bag', 'bank-item']) {
        if (prefix == 'bank-item') await bankTab(t);
        for (final key in items.keys) {
          await openCard(t, prefix, key);
          for (final k in noActions) {
            expect(
              find.byKey(ValueKey(k)),
              findsNothing,
              reason: '$key in $prefix shows $k',
            );
          }
          expect(find.text('Auto-eat'), findsNothing, reason: key);
          expect(find.byKey(const ValueKey('bank-move-all')), findsOneWidget);
          await t.tapAt(const Offset(10, 10));
          await t.pumpAndSettle();
        }
      }
    });

    testWidgets('the card that the bag opens keeps its buttons', (t) async {
      await pumpGame(t, inventory: {sword: 2});
      await openBag(t);
      await t.tap(find.byKey(const ValueKey('bag-$sword')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('card-equip')), findsOneWidget);
      expect(find.byKey(const ValueKey('card-salvage')), findsOneWidget);
      expect(find.byKey(const ValueKey('bank-move-all')), findsNothing);
    });

    testWidgets('the card of a meal that the bag opens keeps Eat and '
        'Auto-eat', (t) async {
      await pumpGame(t, inventory: {meal: 2});
      await openBag(t);
      await t.tap(find.byKey(const ValueKey('bag-$meal')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('card-eat')), findsOneWidget);
      expect(find.text('Auto-eat'), findsOneWidget);
      expect(find.byKey(const ValueKey('bank-move-all')), findsNothing);
    });
  });

  group('what stays', () {
    testWidgets('criterion 28: the bag spaces line counts every item with '
        'another chip picked', (t) async {
      await pumpGame(t, inventory: mixed);
      await openBag(t);
      String spaces() =>
          t.widget<Text>(find.byKey(const ValueKey('bag-spaces'))).data!;
      final all = spaces();
      expect(all, startsWith('Spaces 4 / '));
      await pickKind(t, 'bag', 'meal');
      expect(spaces(), all);
    });

    testWidgets('criterion 29: at a forge, Salvage all counts every item with '
        'another chip picked', (t) async {
      await pumpGame(t, inventory: mixed);
      await openBag(t);
      final button = find.byKey(const ValueKey('salvage-all-common'));
      String label() =>
          t.widget<Text>(inside(button, find.byType(Text)).first).data!;
      final all = label();
      expect(all, 'Salvage all Common (3)');
      await pickKind(t, 'bag', 'meal');
      expect(label(), all);
    });
  });
}
