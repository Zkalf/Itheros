// The "Next goal" line: spec 0002 §9.3, first rule that applies.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();

  test('1: an owned item better than the one equipped', () {
    var s = stateAt(game, level: 7, inventory: {'bone_shield': 1});
    expect(game.nextGoal(s), isA<EquipGoal>());
    expect((game.nextGoal(s)! as EquipGoal).item, 'bone_shield');

    s = game.equip(s, 'bone_shield');
    expect(game.nextGoal(s), isNot(isA<EquipGoal>()));
  });

  test('every slot is open: a shield is suggested at level 1 (spec 0008)', () {
    final s = stateAt(game, inventory: {'bone_shield': 1});
    expect((game.nextGoal(s)! as EquipGoal).item, 'bone_shield');
  });

  test('monsters in the fog are never suggested (spec 0008 decision 5)', () {
    final s = stateAt(game, level: 11)
      ..equipment.addAll({
        'mainHand': 'kings_blade',
        'chest': 'stitched_armour',
        'offHand': 'bone_shield',
      });
    final goal = game.nextGoal(s);
    expect(goal, isNot(isA<CollectGoal>()));
  });

  test('2: a recipe that improves a slot and can be crafted now', () {
    final s = stateAt(game, level: 3, inventory: {'copper_ore': 5});
    final goal = game.nextGoal(s);
    expect(goal, isA<CraftGoal>());
    expect((goal! as CraftGoal).recipe, 'copper_sword');
  });

  test('3: missing materials, from the most generous low monster', () {
    // At level 9, stitched armour is the biggest upgrade. Brutes (green)
    // always drop 2 hides; goblins (grey) half the time.
    final s = stateAt(game, level: 9, inventory: {'goblin_hide': 2});
    final goal = game.nextGoal(s)! as CollectGoal;
    expect((goal.item, goal.count), ('goblin_hide', 4));
    expect(goal.source, const Activity.fight('goblin_brute'));
  });

  test('materials from a monster of your level', () {
    // Wolf pelts come only from level 11 wolves.
    final s = stateAt(game, level: 11)
      ..explored.add('old_graveyard')
      ..equipment.addAll({
        'mainHand': 'kings_blade',
        'chest': 'stitched_armour',
        'offHand': 'bone_shield',
      });
    expect(game.nextGoal(s), isA<CollectGoal>());
    expect(
      (game.nextGoal(s)! as CollectGoal).source,
      const Activity.fight('wolf'),
    );
  });

  test('materials from a gathering spot', () {
    final s = stateAt(game, level: 3, inventory: {'goblin_hide': 4})
      ..equipment['chest'] = 'hide_vest'
      ..inventory.remove('goblin_hide');
    final goal = game.nextGoal(s);
    expect(goal, isA<CollectGoal>());
    expect((goal! as CollectGoal).source, const Activity.gather('copper_vein'));
  });

  test('4: otherwise the yellow monster that pays best', () {
    expect(game.nextGoal(stateAt(game)), isA<FightGoal>());
    expect((game.nextGoal(stateAt(game))! as FightGoal).enemy, 'goblin');
  });
}
