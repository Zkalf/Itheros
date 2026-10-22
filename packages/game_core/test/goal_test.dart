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
    // Spec 0011 §7 gear may send it hunting in the open woods; never to a
    // monster in the fog.
    if (goal case CollectGoal(:final source)) {
      expect(source.kind, isNot(ActivityKind.fight));
    }
  });

  test('2: a recipe that improves a slot and can be crafted now', () {
    final s = stateAt(game, level: 3, inventory: {'copper_ore': 5});
    final goal = game.nextGoal(s);
    expect(goal, isA<CraftGoal>());
    expect((goal! as CraftGoal).recipe, 'copper_sword');
  });

  test('3: missing materials, from the most generous low monster', () {
    // At level 9, with a bone shield worn, stitched armour is the biggest
    // upgrade (without it, the shield's Block ranks first: spec 0009 §5.3
    // weighs every stat). Brutes (green) always drop 2 hides; goblins (grey)
    // half the time.
    final s = stateAt(game, level: 9, inventory: {'goblin_hide': 2})
      ..equipment['offHand'] = 'bone_shield';
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

  // Crafting 1 makes the copper gear from level 1 (spec 0010 amendment 1),
  // so the player here already wears it.
  test('4: otherwise the yellow monster that pays best', () {
    final s = stateAt(game)
      ..equipment.addAll({'mainHand': 'copper_sword', 'chest': 'hide_vest'});
    expect(game.nextGoal(s), isA<FightGoal>());
    expect((game.nextGoal(s)! as FightGoal).enemy, 'goblin');
  });

  // Spec 0010 §8.4: the best upgrade for the character's level is out of
  // reach only because of a profession level.
  test('a recipe held back by Crafting names the level to reach', () {
    final s = stateAt(game, level: 30, professionLevel: 1);
    final goal = game.nextGoal(s);
    expect(goal, isA<ProfessionGoal>());
    final g = goal! as ProfessionGoal;
    expect(g.profession, 'crafting');
    expect(g.current, 1);
    final r = game.data.recipes[g.target.target]!;
    expect(g.target.kind, ActivityKind.craft);
    expect(g.level, r.craftingLevel);
    expect(r.level, lessThanOrEqualTo(30));
  });

  test('a vein held back by Mining names the vein', () {
    final s = stateAt(game, level: 25, professionLevel: 25)
      ..professions['mining'] = game.data.professionXpForLevel(15)
      // Next door to Mithril Deep; no monster drops mithril ore.
      ..explored.add('mountain_pass')
      ..inventory['star_diamond'] = 1;
    // The best of everything worn but rings: the star-diamond ring is the
    // upgrade, and only its mithril ore is missing.
    for (final slot in game.data.gearSlots) {
      if (slot.id.startsWith('ring')) continue;
      final fits = [
        for (final i in game.data.items.values)
          if (game.slotsFor(i.id).contains(slot.id)) i,
      ]..sort((a, b) => b.score.compareTo(a.score));
      if (fits.isNotEmpty) s.equipment[slot.id] = fits.first.id;
    }
    final g = game.nextGoal(s)! as ProfessionGoal;
    expect((g.profession, g.level, g.current), ('mining', 20, 15));
    expect(g.target, const Activity.gather('mithril_vein'));
  });
}
