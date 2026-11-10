// Recipe lists start with the highest level the player can make: spec 0010
// amendment 12 criteria 1-9 (plan 0061).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_test.dart' show game, openProfession, pumpGame;

void main() {
  const prefix = 'option-craft-';
  final data = game.data;

  /// The recipes of [profession] in the order of the list before this
  /// amendment: by level, the lowest first, then the order of the data.
  List<String> before(String profession) {
    final all = [
      for (final r in data.recipes.values)
        if (r.profession == profession) r.id,
    ];
    final at = {for (final (i, id) in all.indexed) id: i};
    int level(String id) => data.recipes[id]!.craftingLevel;
    return all..sort((a, b) {
      final byLevel = level(a).compareTo(level(b));
      return byLevel != 0 ? byLevel : at[a]!.compareTo(at[b]!);
    });
  }

  /// The recipe rows on the screen, top to bottom.
  List<String> rows(WidgetTester t) {
    final found = find.byWidgetPredicate(
      (w) => switch (w.key) {
        ValueKey<String>(:final value) => value.startsWith(prefix),
        _ => false,
      },
    );
    // Each recipe once: a row drawn twice would hide in the map below.
    final ids = [
      for (final e in found.evaluate())
        (e.widget.key! as ValueKey<String>).value,
    ];
    expect(ids.toSet().length, ids.length);
    final tops = {
      for (final e in found.evaluate())
        (e.widget.key! as ValueKey<String>).value.substring(prefix.length): t
            .getTopLeft(find.byWidget(e.widget))
            .dy,
    };
    return tops.keys.toList()..sort((a, b) => tops[a]!.compareTo(tops[b]!));
  }

  int levelOf(String id) => data.recipes[id]!.craftingLevel;

  for (final profession in ['crafting', 'cooking']) {
    testWidgets('criteria 1-6 and 9: $profession at level 13 shows the open '
        'recipes from the highest level, then the locked ones from the '
        'lowest', (t) async {
      await pumpGame(t, level: 13, professionLevel: 13);
      await openProfession(t, profession);
      final old = before(profession);
      final shown = rows(t);
      // Criterion 9: the same recipes, each once.
      expect(shown, unorderedEquals(old));
      final open = shown.where((id) => levelOf(id) <= 13).toList();
      final locked = shown.where((id) => levelOf(id) > 13).toList();
      expect(open.length, greaterThan(1));
      expect(locked.length, greaterThan(1));
      // Criterion 1: the first row has the highest open level of the data.
      final top = open.map(levelOf).reduce((a, b) => a > b ? a : b);
      expect(levelOf(shown.first), top);
      // Criterion 3: each locked recipe stands under every open one.
      expect(shown, [...open, ...locked]);
      // Criteria 2, 4 and 5: the order of each part, with ties as before.
      int byOld(String a, String b) => old.indexOf(a).compareTo(old.indexOf(b));
      expect(
        open,
        [...open]..sort((a, b) {
          final byLevel = levelOf(b).compareTo(levelOf(a));
          return byLevel != 0 ? byLevel : byOld(a, b);
        }),
      );
      expect(locked, [...locked]..sort(byOld));
      // The data has ties and more than one level in each part, so the
      // checks above tell the orders apart.
      expect(open.map(levelOf).toSet().length, greaterThan(1));
      expect(locked.map(levelOf).toSet().length, greaterThan(1));
      expect(open.length, greaterThan(open.map(levelOf).toSet().length));
    });
  }

  testWidgets('criterion 7: at profession level 1 the list is in the order '
      'of before', (t) async {
    await pumpGame(t);
    await openProfession(t, 'crafting');
    expect(rows(t), before('crafting'));
  });

  testWidgets('criterion 8: "Have level" shows the open recipes in their '
      'order; "Up to 5 levels ahead" adds the near locked ones under them', (
    t,
  ) async {
    await pumpGame(t, level: 13, professionLevel: 13);
    await openProfession(t, 'crafting');
    final all = rows(t);
    final open = all.where((id) => levelOf(id) <= 13).toList();
    final near = all.where((id) => levelOf(id) <= 18).toList();
    expect(near.length, greaterThan(open.length));

    await t.tap(find.byKey(const ValueKey('filter-level')));
    await t.pumpAndSettle();
    expect(rows(t), open);

    await t.tap(find.byKey(const ValueKey('filter-ahead')));
    await t.pumpAndSettle();
    expect(rows(t), near);
  });
}
