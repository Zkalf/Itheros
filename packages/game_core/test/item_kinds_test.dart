// The four kinds of item: spec 0020 amendment 2 criterion 1 (plan 0046). The
// screens (criteria 2-29) are in the app's tests.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final data = newTestGame().data;

  test('criterion 1: a sword, a pickaxe, a meal and an ore are Gear, Tools, '
      'Meals and Materials', () {
    expect(data.kindOf('bone_sword'), ItemKind.gear);
    expect(data.kindOf('copper_pickaxe'), ItemKind.tool);
    expect(data.kindOf('venison_skewer'), ItemKind.meal);
    expect(data.kindOf('copper_ore'), ItemKind.material);
  });

  test('a rolled item keeps the kind of its base item', () {
    expect(data.kindOf('bone_sword@rare+crit2+hp10'), ItemKind.gear);
    expect(data.kindOf(data.keyFor('copper_pickaxe', 'rare')), ItemKind.tool);
  });

  test('an item the data no longer has is a material', () {
    expect(data.kindOf('gone_item'), ItemKind.material);
  });

  test('every item of the data has one of the four kinds', () {
    final kinds = {for (final id in data.items.keys) data.kindOf(id)};
    expect(kinds, ItemKind.values.toSet());
  });
}
