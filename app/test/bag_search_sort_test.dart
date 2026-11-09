// Search and sort in the bag and the bank: spec 0020 amendment 4 criteria
// 1-29 (plan 0052).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/ui/images.dart';
import 'package:walkingrpg/ui/item_square.dart';
import 'package:walkingrpg/ui/item_sort.dart';
import 'package:walkingrpg/ui/theme.dart' show BackPlate;

import 'images_test.dart' show diskImages;
import 'now_monsters_test.dart' show expectSocketFirst, inside;
import 'ui_test.dart';

void main() {
  final data = game.data;
  const sword = 'bone_sword';
  final uncommonSword = data.keyFor(sword, 'uncommon');
  final rareVest = data.keyFor('hide_vest', 'rare');
  const pick = 'copper_pickaxe';
  const meal = 'venison_skewer';
  final perfectMeal = GameData.perfectKey(meal);
  const deerHide = 'deer_hide';
  const goblinHide = 'goblin_hide';
  const ore = 'copper_ore';
  const bones = 'bones';
  final items = {
    sword: 3,
    uncommonSword: 2,
    rareVest: 1,
    pick: 1,
    meal: 4,
    perfectMeal: 1,
    deerHide: 7,
    goblinHide: 5,
    ore: 9,
    bones: 2,
  };
  final bag = bagOrder(data, items.keys);
  const lists = ['bag', 'bank-bag', 'bank-bank'];

  void Function(GameState) banked(Map<String, int> m) =>
      (s) => s.itemBank.addAll(m);

  Future<void> pumpItems(WidgetTester t, {bool pictures = false}) => pumpGame(
    t,
    images: pictures ? diskImages : ImageIndex.empty,
    inventory: items,
    prepare: banked(items),
  );

  Future<void> openBag(WidgetTester t) async {
    await openTab(t, 'character');
    await t.tap(find.byKey(const ValueKey('tab-bag')));
    await t.pumpAndSettle();
  }

  Future<void> bankTab(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('bank-tab-bank')));
    await t.pumpAndSettle();
  }

  Future<void> bagTab(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('bank-tab-bag')));
    await t.pumpAndSettle();
  }

  /// Opens the bank screen on its Bag tab.
  Future<void> openBank(WidgetTester t) async {
    await openBag(t);
    await t.ensureVisible(find.byKey(const ValueKey('bag-bank')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('bag-bank')));
    await t.pumpAndSettle();
    await bagTab(t);
  }

  Future<void> closeBank(WidgetTester t) async {
    await t.tap(find.byType(BackPlate));
    await t.pumpAndSettle();
  }

  Future<void> openList(WidgetTester t, String list) async {
    if (list == 'bag') return openBag(t);
    await openBank(t);
    if (list == 'bank-bank') await bankTab(t);
  }

  String rowPrefix(String list) => switch (list) {
    'bag' => 'bag',
    'bank-bag' => 'bank-bag',
    _ => 'bank-item',
  };

  /// The item keys of a list, in screen order.
  List<String> shown(WidgetTester t, String list) {
    if (list == 'bag') {
      return [
        // The first square of each item: an item has a square for each
        // stack (spec 0021 amendment 4).
        for (final w in t.widgetList<ItemSquare>(find.byType(ItemSquare)))
          if ((w.key! as ValueKey<String>).value == 'bag-${w.item}') w.item!,
      ];
    }
    final prefix = rowPrefix(list);
    return [
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
  }

  Finder field(String list) => find.byKey(ValueKey('search-$list'));
  Finder sortButton(String list) => find.byKey(ValueKey('sort-$list'));

  Future<void> search(WidgetTester t, String list, String text) async {
    await t.ensureVisible(field(list));
    await t.pumpAndSettle();
    await t.enterText(field(list), text);
    await t.pumpAndSettle();
  }

  Future<void> pickSort(WidgetTester t, String list, ItemSort s) async {
    await t.ensureVisible(sortButton(list));
    await t.pumpAndSettle();
    await t.tap(sortButton(list));
    await t.pumpAndSettle();
    await t.tap(find.byKey(ValueKey('sort-$list-${s.name}')).last);
    await t.pumpAndSettle();
  }

  Future<void> pickKind(WidgetTester t, String list, String id) async {
    final chip = find.byKey(ValueKey('kind-$list-$id'));
    await t.ensureVisible(chip);
    await t.pumpAndSettle();
    await t.tap(chip);
    await t.pumpAndSettle();
  }

  String typed(WidgetTester t, String list) =>
      t.widget<TextField>(field(list)).controller!.text;

  bool showsSort(WidgetTester t, String list, String word) =>
      inside(sortButton(list), find.text(word)).evaluate().length == 1;

  List<String> inBagOrder(bool Function(String) keep) => [
    for (final k in bag)
      if (keep(k)) k,
  ];

  group('where', () {
    for (final (n, list) in [(1, 'bag'), (2, 'bank-bag'), (3, 'bank-bank')]) {
      testWidgets('criterion $n: $list shows the search field and the sort '
          'button below the kind buttons', (t) async {
        await pumpItems(t);
        await openList(t, list);
        expect(field(list), findsOneWidget);
        expect(sortButton(list), findsOneWidget);
        final chips = t.getRect(find.byKey(ValueKey('kind-$list-all')));
        expect(t.getRect(field(list)).top, greaterThan(chips.bottom - 1));
        expect(t.getRect(sortButton(list)).top, greaterThan(chips.bottom - 1));
      });
    }
  });

  group('the search', () {
    testWidgets('criterion 4: the empty field shows the hint "Search"', (
      t,
    ) async {
      await pumpItems(t);
      for (final list in lists) {
        if (list == 'bank-bag') await openBank(t);
        if (list == 'bank-bank') await bankTab(t);
        if (list == 'bag') await openBag(t);
        expect(typed(t, list), '', reason: list);
        expect(inside(field(list), find.text('Search')), findsOneWidget);
      }
    });

    for (final list in lists) {
      testWidgets('criteria 5-9: in $list, the search matches the name and the '
          'quality, case ignored', (t) async {
        await pumpItems(t);
        await openList(t, list);
        final hides = [rareVest, deerHide, goblinHide];
        await search(t, list, 'hide');
        expect(shown(t, list), inBagOrder(hides.contains), reason: 'hide');
        await search(t, list, '  HIDE ');
        expect(shown(t, list), inBagOrder(hides.contains), reason: 'HIDE');
        await search(t, list, 'rare');
        expect(shown(t, list), [rareVest], reason: 'rare');
        await search(t, list, 'common');
        final commons = [
          for (final k in items.keys)
            if (data.qualityOf(k) == data.qualities.first) k,
        ];
        expect(shown(t, list), containsAll(commons), reason: 'common');
        expect(shown(t, list), isNot(contains(rareVest)), reason: 'common');
        await search(t, list, 'perfect');
        expect(shown(t, list), [perfectMeal], reason: 'perfect');
      });
    }

    testWidgets('criterion 10: the search and a kind button work together', (
      t,
    ) async {
      await pumpItems(t);
      await openBank(t);
      await pickKind(t, 'bank-bag', ItemKind.gear.name);
      await search(t, 'bank-bag', 'bone');
      expect(shown(t, 'bank-bag'), inBagOrder({sword, uncommonSword}.contains));
      expect(shown(t, 'bank-bag'), isNot(contains(bones)));
    });

    testWidgets('criterion 11: the clear button empties the field and shows '
        'every item of the kind again', (t) async {
      await pumpItems(t);
      await openBag(t);
      await pickKind(t, 'bag', ItemKind.material.name);
      final clear = find.byKey(const ValueKey('search-bag-clear'));
      expect(clear, findsNothing, reason: 'no clear button when empty');
      await search(t, 'bag', 'hide');
      expect(shown(t, 'bag'), inBagOrder({deerHide, goblinHide}.contains));
      await t.tap(clear);
      await t.pumpAndSettle();
      expect(typed(t, 'bag'), '');
      expect(clear, findsNothing);
      expect(
        shown(t, 'bag'),
        inBagOrder((k) => data.kindOf(k) == ItemKind.material),
      );
    });

    testWidgets('criterion 12: a search that matches nothing reads "Nothing '
        'here matches"', (t) async {
      await pumpItems(t);
      await openBank(t);
      await bankTab(t);
      await search(t, 'bank-bank', 'dragon');
      expect(shown(t, 'bank-bank'), isEmpty);
      expect(find.text('Nothing here matches "dragon".'), findsOneWidget);
      expect(find.text('Nothing of this kind here.'), findsNothing);
    });

    testWidgets('an empty field with an empty kind keeps "Nothing of this kind '
        'here."', (t) async {
      await pumpGame(t, inventory: {ore: 2});
      await openBag(t);
      await pickKind(t, 'bag', ItemKind.meal.name);
      expect(find.text('Nothing of this kind here.'), findsOneWidget);
    });

    testWidgets('criterion 13: the search is empty after the bank screen '
        'closes and opens again', (t) async {
      await pumpItems(t);
      await openBank(t);
      await search(t, 'bank-bag', 'hide');
      await bankTab(t);
      await search(t, 'bank-bank', 'bone');
      await closeBank(t);
      await openBank(t);
      expect(typed(t, 'bank-bag'), '');
      expect(shown(t, 'bank-bag'), bag);
      await bankTab(t);
      expect(typed(t, 'bank-bank'), '');
      expect(shown(t, 'bank-bank'), bag);
    });

    testWidgets('the search clears when the player opens the other tab of the '
        'bank screen', (t) async {
      await pumpItems(t);
      await openBank(t);
      await search(t, 'bank-bag', 'hide');
      await bankTab(t);
      await bagTab(t);
      expect(typed(t, 'bank-bag'), '');
    });

    testWidgets('a swipe that springs back keeps the search; a swipe to the '
        'other tab clears it', (t) async {
      await pumpItems(t);
      await openBank(t);
      await search(t, 'bank-bag', 'hide');
      // The Bag tab is the second: a small drag to the right springs back.
      await t.drag(find.byType(TabBarView), const Offset(80, 0));
      await t.pumpAndSettle();
      expect(typed(t, 'bank-bag'), 'hide', reason: 'the tab did not change');
      expect(shown(t, 'bank-bag'), hasLength(3));
      await t.fling(find.byType(TabBarView), const Offset(600, 0), 2000);
      await t.pumpAndSettle();
      await bagTab(t);
      expect(typed(t, 'bank-bag'), '', reason: 'the player left the tab');
    });

    testWidgets('criterion 14: the search of the bag is empty after another '
        'pane and back', (t) async {
      await pumpItems(t);
      await openBag(t);
      await search(t, 'bag', 'hide');
      expect(shown(t, 'bag'), hasLength(3));
      await t.tap(find.byKey(const ValueKey('tab-gear')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('tab-bag')));
      await t.pumpAndSettle();
      expect(typed(t, 'bag'), '');
      expect(shown(t, 'bag'), bag);
    });
  });

  group('the sort', () {
    testWidgets('criteria 15-16: each list starts on Bag order, and the menu '
        'offers four sorts', (t) async {
      await pumpItems(t);
      for (final list in lists) {
        if (list == 'bag') await openBag(t);
        if (list == 'bank-bag') await openBank(t);
        if (list == 'bank-bank') await bankTab(t);
        expect(showsSort(t, list, 'Bag order'), isTrue, reason: list);
      }
      await t.tap(sortButton('bank-bank'));
      await t.pumpAndSettle();
      for (final (s, word) in [
        (ItemSort.bagOrder, 'Bag order'),
        (ItemSort.name, 'Name'),
        (ItemSort.count, 'Count'),
        (ItemSort.quality, 'Quality'),
      ]) {
        final entry = find.byKey(ValueKey('sort-bank-bank-${s.name}'));
        expect(entry, findsOneWidget, reason: word);
        expect(inside(entry, find.text(word)), findsOneWidget, reason: word);
      }
    });

    for (final list in lists) {
      testWidgets('criteria 17-22: $list sorts by bag order, name, count and '
          'quality; ties keep the bag order', (t) async {
        await pumpItems(t);
        await openList(t, list);
        expect(shown(t, list), bag, reason: 'criterion 17');
        await pickSort(t, list, ItemSort.name);
        expect(showsSort(t, list, 'Name'), isTrue);
        expect(shown(t, list), [
          sword, // Bone sword
          uncommonSword, // Bone sword (Uncommon)
          bones, // Bones
          ore, // Copper ore
          pick, // Copper pickaxe
          deerHide, // Deer hide
          goblinHide, // Goblin hide
          rareVest, // Hide vest (Rare)
          meal, // Venison skewer
          perfectMeal, // Venison skewer (Perfect)
        ], reason: 'criterion 18');
        await pickSort(t, list, ItemSort.count);
        final byCount = shown(t, list);
        expect(byCount.take(5), [
          ore,
          deerHide,
          goblinHide,
          meal,
          sword,
        ], reason: 'criterion 19');
        expect(
          byCount.skip(5).take(2),
          inBagOrder({uncommonSword, bones}.contains),
          reason: 'criterion 22: the stacks of 2 in bag order',
        );
        expect(
          byCount.skip(7),
          inBagOrder((k) => items[k] == 1),
          reason: 'criterion 22: the stacks of 1 in bag order',
        );
        await pickSort(t, list, ItemSort.quality);
        final byQuality = shown(t, list);
        expect(byQuality.take(2), [
          rareVest,
          uncommonSword,
        ], reason: 'criterion 20');
        expect(byQuality[2], perfectMeal, reason: 'criterion 21');
        expect(
          byQuality.skip(3),
          inBagOrder(
            (k) =>
                data.qualityOf(k) == data.qualities.first && k != perfectMeal,
          ),
          reason: 'criterion 22: the Common items in bag order',
        );
        await pickSort(t, list, ItemSort.bagOrder);
        expect(shown(t, list), bag);
      });
    }

    test('criterion 22: ties keep the bag order in a long list', () {
      // Dart's sort keeps ties in order below 32 items, so this list is
      // long: every item of the data once, and two Rare bone swords with the
      // same name on the row.
      final many = {
        for (final id in data.items.keys) id: 1,
        'bone_sword@rare+crit2': 1,
        'bone_sword@rare+crit2+hp10': 1,
      };
      expect(many.length, greaterThan(64));
      final order = bagOrder(data, many.keys);
      expect(
        itemsShown(data, many, sort: ItemSort.count),
        order,
        reason: 'Count: every stack is 1',
      );
      final commons = {
        for (final k in many.keys)
          if (data.qualityOf(k) == data.qualities.first) k: 1,
      };
      expect(
        itemsShown(data, commons, sort: ItemSort.quality),
        bagOrder(data, commons.keys),
        reason: 'Quality: every item is Common',
      );
      final byName = itemsShown(data, many, sort: ItemSort.name);
      final swords = [
        for (final k in order)
          if (k.startsWith('bone_sword@rare')) k,
      ];
      expect(
        [
          for (final k in byName)
            if (k.startsWith('bone_sword@rare')) k,
        ],
        swords,
        reason: 'Name: two rows that read the same keep the bag order',
      );
    });

    testWidgets('the sort works with the search and a kind', (t) async {
      await pumpItems(t);
      await openBag(t);
      await pickKind(t, 'bag', ItemKind.material.name);
      await search(t, 'bag', 'e');
      await pickSort(t, 'bag', ItemSort.count);
      // Copper ore 9, Deer hide 7, Goblin hide 5, Bones 2.
      expect(shown(t, 'bag'), [ore, deerHide, goblinHide, bones]);
    });

    testWidgets('criterion 23: a sort in the bag leaves both bank tabs on Bag '
        'order', (t) async {
      await pumpItems(t);
      await openBag(t);
      await pickSort(t, 'bag', ItemSort.count);
      await openBank(t);
      expect(showsSort(t, 'bank-bag', 'Bag order'), isTrue);
      expect(shown(t, 'bank-bag'), bag);
      await bankTab(t);
      expect(showsSort(t, 'bank-bank', 'Bag order'), isTrue);
    });

    testWidgets(
      'criterion 24: a sort in the Bag tab leaves the Bank tab on its '
      'own sort',
      (t) async {
        await pumpItems(t);
        await openBank(t);
        await bankTab(t);
        await pickSort(t, 'bank-bank', ItemSort.quality);
        await bagTab(t);
        await pickSort(t, 'bank-bag', ItemSort.name);
        await bankTab(t);
        expect(showsSort(t, 'bank-bank', 'Quality'), isTrue);
        expect(shown(t, 'bank-bank').first, rareVest);
      },
    );

    testWidgets('criterion 25: a list keeps its sort after the bank screen '
        'closes and opens again', (t) async {
      await pumpItems(t);
      await openBank(t);
      await pickSort(t, 'bank-bag', ItemSort.count);
      await bankTab(t);
      await pickSort(t, 'bank-bank', ItemSort.name);
      await closeBank(t);
      await openTab(t, 'now');
      await openBank(t);
      expect(showsSort(t, 'bank-bag', 'Count'), isTrue);
      expect(shown(t, 'bank-bag').first, ore);
      await bankTab(t);
      expect(showsSort(t, 'bank-bank', 'Name'), isTrue);
      expect(shown(t, 'bank-bank').first, sword);
    });

    testWidgets('the bag keeps its sort after another pane and back', (
      t,
    ) async {
      await pumpItems(t);
      await openBag(t);
      await pickSort(t, 'bag', ItemSort.count);
      await t.tap(find.byKey(const ValueKey('tab-gear')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('tab-bag')));
      await t.pumpAndSettle();
      expect(showsSort(t, 'bag', 'Count'), isTrue);
      expect(shown(t, 'bag').first, ore);
    });

    testWidgets('criterion 26: after a restart, each list shows Bag order', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        inventory: items,
        prepare: banked(items),
      );
      final saved = jsonEncode(c.state.toJson());
      await openBag(t);
      await pickSort(t, 'bag', ItemSort.name);
      await openBank(t);
      await pickSort(t, 'bank-bag', ItemSort.count);
      await bankTab(t);
      await pickSort(t, 'bank-bank', ItemSort.quality);
      // The save does not keep the sorts (rule 15): the restart below gets
      // the same state either way, so check the save itself.
      expect(jsonEncode(c.state.toJson()), saved);
      expect(c.sortPicks, hasLength(3));
      // A new controller is a new start of the app.
      await t.pumpWidget(const SizedBox());
      await pumpItems(t);
      await openBag(t);
      expect(showsSort(t, 'bag', 'Bag order'), isTrue);
      expect(shown(t, 'bag'), bag);
      await openBank(t);
      expect(showsSort(t, 'bank-bag', 'Bag order'), isTrue);
      await bankTab(t);
      expect(showsSort(t, 'bank-bank', 'Bag order'), isTrue);
    });
  });

  group('what stays', () {
    testWidgets('criterion 27: the bag spaces line counts every item while a '
        'search hides some', (t) async {
      await pumpItems(t);
      await openBag(t);
      String spaces() =>
          t.widget<Text>(find.byKey(const ValueKey('bag-spaces'))).data!;
      final all = spaces();
      // Spaces count stacks (spec 0021 amendment 4): a piece of gear held
      // twice uses two.
      final spacesUsed = items.entries.fold(
        0,
        (n, e) => n + game.spacesOf(e.key, e.value),
      );
      expect(all, startsWith('Spaces $spacesUsed / '));
      await search(t, 'bag', 'hide');
      expect(shown(t, 'bag'), hasLength(3));
      expect(spaces(), all);
    });

    testWidgets('criterion 28: at a forge, Salvage all counts every item while '
        'a search hides some', (t) async {
      await pumpItems(t);
      await openBag(t);
      final button = find.byKey(const ValueKey('salvage-all-common'));
      String label() =>
          t.widget<Text>(inside(button, find.byType(Text)).first).data!;
      final all = label();
      await search(t, 'bag', 'ore');
      expect(shown(t, 'bag'), [ore]);
      expect(label(), all);
    });

    testWidgets('criterion 29: after a search and a sort, each row and square '
        'shows its picture and opens its card', (t) async {
      await pumpItems(t, pictures: true);
      await openBag(t);
      await search(t, 'bag', 'hide');
      await pickSort(t, 'bag', ItemSort.name);
      for (final key in shown(t, 'bag')) {
        final square = find.byKey(ValueKey('bag-$key'));
        expect(
          t.widget<ItemSquare>(square).item,
          key,
          reason: 'the square of $key shows its own item',
        );
        await t.ensureVisible(square);
        await t.pumpAndSettle();
        await t.tap(square);
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('item-card')), findsOneWidget);
        await t.tapAt(const Offset(10, 10));
        await t.pumpAndSettle();
      }
      await openBank(t);
      for (final list in ['bank-bag', 'bank-bank']) {
        if (list == 'bank-bank') await bankTab(t);
        await search(t, list, 'hide');
        await pickSort(t, list, ItemSort.count);
        final prefix = rowPrefix(list);
        final keys = shown(t, list);
        expect(keys, hasLength(3), reason: list);
        for (final key in keys) {
          final row = find.byKey(ValueKey('$prefix-$key'));
          expectSocketFirst(t, row, ItemThing(key), 48, '$key in $list');
          await t.tap(row);
          await t.pumpAndSettle();
          expect(find.byKey(const ValueKey('item-card')), findsOneWidget);
          await t.tapAt(const Offset(10, 10));
          await t.pumpAndSettle();
        }
      }
    });
  });
}
