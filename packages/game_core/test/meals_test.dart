// Cooking, meals, buffs and auto-eat: spec 0011 criteria 9-11 (plan 0013
// M1).
import 'dart:math' as math;

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;

  StepReport work(GameState s, Activity a, int steps) =>
      game.applySteps(game.startActivity(s, a), steps);

  group('criterion 9: cooking at the camp fire', () {
    test('the 22 meal recipes (spec 0011 §5.2)', () {
      final rows = [
        // id, Cooking level, tier, inputs, buffs
        ('grilled_perch', 1, 1, {'perch': 2}, ['hp']),
        ('pike_steak', 1, 1, {'pike': 2}, ['defense']),
        ('golden_carp_curry', 3, 1, {'golden_carp': 1, 'perch': 1}, ['crit']),
        ('venison_skewer', 1, 1, {'venison': 2}, ['attack']),
        ('boar_stew', 1, 1, {'boar_meat': 2}, ['steps']),
        (
          'mossback_feast',
          5,
          1,
          {'old_mossback': 1, 'venison': 2, 'perch': 2},
          ['hp', 'attack'],
        ),
        ('smoked_trout', 10, 2, {'brown_trout': 2}, ['hp']),
        ('eel_pie', 10, 2, {'eel': 2}, ['defense']),
        (
          'planked_salmon',
          12,
          2,
          {'silver_salmon': 1, 'brown_trout': 1},
          ['crit'],
        ),
        ('elk_roast', 10, 2, {'elk_meat': 2}, ['attack']),
        ('black_boar_stew', 10, 2, {'black_boar_meat': 2}, ['steps']),
        (
          'river_king_feast',
          15,
          2,
          {'river_king': 1, 'elk_meat': 2, 'brown_trout': 2},
          ['hp', 'attack'],
        ),
        ('baked_sea_bass', 15, 2, {'sea_bass': 2}, ['hp']),
        ('salted_mackerel', 15, 2, {'mackerel': 2}, ['defense']),
        ('moonfish_broth', 17, 2, {'moonfish': 1, 'sea_bass': 1}, ['crit']),
        (
          'one_eye_feast',
          18,
          2,
          {'old_one_eye': 1, 'elk_meat': 2, 'sea_bass': 2},
          ['hp', 'attack'],
        ),
        ('char_soup', 20, 3, {'arctic_char': 2}, ['hp']),
        ('frostfin_fillet', 20, 3, {'frostfin': 2}, ['defense']),
        (
          'glacier_pike_roast',
          22,
          3,
          {'glacier_pike': 1, 'arctic_char': 1},
          ['crit'],
        ),
        ('ibex_haunch', 20, 3, {'ibex_meat': 2}, ['attack']),
        ('grouse_pie', 20, 3, {'grouse': 2}, ['steps']),
        (
          'pale_one_feast',
          25,
          3,
          {'the_pale_one': 1, 'ibex_meat': 2, 'arctic_char': 2},
          ['hp', 'attack'],
        ),
      ];
      final meals = [
        for (final r in data.recipes.values)
          if (r.profession == 'cooking') r.id,
      ];
      expect(meals, [for (final r in rows) r.$1]);
      for (final (id, level, tier, inputs, buffs) in rows) {
        final r = data.recipes[id]!;
        final meal = data.items[id]!.meal!;
        final feast = buffs.length == 2;
        final (steps, xp) = switch (tier) {
          1 => (60, 15),
          2 => (80, 45),
          _ => (100, 140),
        };
        expect((r.craftingLevel, r.inputs), (level, inputs), reason: id);
        expect(
          (r.steps, r.xp),
          feast ? (steps * 2, xp * 2) : (steps, xp),
          reason: id,
        );
        expect((meal.tier, meal.buffs), (tier, buffs), reason: id);
        expect(data.items[id]!.slot, isNull);
      }
    });

    test('cooking runs only where there is a fire', () {
      expect(data.locations['camp']!.fire, isTrue);
      expect(data.locations['grey_moor']!.fire, isFalse);
      final moor = stateAt(
        game,
        location: 'grey_moor',
        inventory: {'perch': 2},
      );
      expect(game.availableRecipes(moor), isNot(contains('grilled_perch')));
      expect(game.availableRecipes(moor), contains('bone_sword'));
      // Started away from the fire, it walks to camp first.
      final s = game.startActivity(moor, const Activity.craft('grilled_perch'));
      expect(s.activity!.leg, isNotNull);
      final camp = stateAt(game, inventory: {'perch': 2});
      expect(game.availableRecipes(camp), contains('grilled_perch'));
      final r = work(camp, const Activity.craft('grilled_perch'), 60);
      expect(game.owned(r.state, 'grilled_perch'), 1);
      expect(r.state.inventory['perch'], isNull);
    });

    test('cooking pays Cooking XP; "until I have N" works', () {
      final s = stateAt(game, inventory: {'perch': 20});
      final started = game.startActivity(
        s,
        const Activity.craft('grilled_perch'),
        stop: const StopCondition.untilHave('grilled_perch', 3),
      );
      final r = game.applySteps(started, 60 * 10);
      expect(game.owned(r.state, 'grilled_perch'), 3);
      expect(
        r.state.professions['cooking']! - s.professions['cooking']!,
        3 * 15,
      );
    });

    test('a cook is perfect at about 10% with an old pot', () {
      final s = stateAt(game, inventory: {'perch': 2 * 5000});
      final r = work(s, const Activity.craft('grilled_perch'), 60 * 5000);
      final perfect = r.state.inventory[GameData.perfectKey('grilled_perch')]!;
      // Cooking soon climbs 10 levels past the recipe: +10% of the chance.
      expect(perfect / 5000, closeTo(0.11, 0.012));
      // They stack apart.
      expect(r.state.inventory['grilled_perch'], 5000 - perfect);
      expect(data.isPerfect(GameData.perfectKey('grilled_perch')), isTrue);
      expect(
        data.itemOf(GameData.perfectKey('grilled_perch'))!.id,
        'grilled_perch',
      );
    });

    test('the perfect chance: pot quality and Cooking above the recipe', () {
      final s = stateAt(game, professionLevel: 1);
      expect(game.perfectChance(s, 'grilled_perch'), closeTo(0.10, 1e-12));
      s
        ..tools['cooking'] = 'copper_pot@epic'
        ..professions['cooking'] = data.professionXpForLevel(30);
      expect(
        game.perfectChance(s, 'grilled_perch'),
        closeTo(0.10 * 1.15 * 1.10, 1e-12),
      );
    });

    test('a perfect dish lasts 6,000 steps, a plain one 3,000', () {
      expect(data.mealSteps, 3000);
      final s = stateAt(
        game,
        inventory: {
          'grilled_perch': 1,
          GameData.perfectKey('grilled_perch'): 1,
        },
      );
      expect(game.eat(s, 'grilled_perch').meal!.left, 3000);
      expect(
        game.eat(s, GameData.perfectKey('grilled_perch')).meal!.left,
        6000,
      );
    });
  });

  group('criterion 10: one meal and its buff', () {
    GameState geared(Map<String, int> meals) {
      final s = stateAt(game, level: 20, inventory: meals);
      s.equipment.addAll({
        'mainHand': 'iron_sword',
        'chest': 'troll_hide_armour',
        'head': 'iron_helm',
      });
      return s;
    }

    test('a stat buff is a percent of the total stat, rounded down, at '
        'least 1', () {
      final s = geared({
        'venison_skewer': 1,
        'grilled_perch': 1,
        'pike_steak': 1,
        'char_soup': 1,
        'golden_carp_curry': 1,
        'mossback_feast': 1,
      });
      final base = game.stats(s);
      Stats fed(String meal) => game.stats(game.eat(s, meal));
      expect(
        fed('venison_skewer').attack - base.attack,
        (base.attack * 6) ~/ 100,
      );
      expect(fed('grilled_perch').hp - base.hp, (base.hp * 6) ~/ 100);
      expect(
        fed('pike_steak').defense - base.defense,
        math.max(1, base.defense * 6 ~/ 100),
      );
      expect(fed('char_soup').hp - base.hp, (base.hp * 14) ~/ 100);
      expect(fed('golden_carp_curry').crit - base.crit, 2);
      final feast = fed('mossback_feast');
      expect(feast.hp - base.hp, (base.hp * 6) ~/ 100);
      expect(feast.attack - base.attack, (base.attack * 6) ~/ 100);
      expect(
        game.mealBonus(game.eat(s, 'venison_skewer')).attack,
        (base.attack * 6) ~/ 100,
      );
      // A tiny stat still gains 1.
      final weak = stateAt(game, inventory: {'pike_steak': 1});
      expect(
        game.stats(game.eat(weak, 'pike_steak')).defense -
            game.stats(weak).defense,
        1,
      );
    });

    test('eating replaces the running meal', () {
      final s = geared({'venison_skewer': 1, 'grilled_perch': 1});
      final a = game.eat(s, 'venison_skewer');
      final b = game.eat(a, 'grilled_perch');
      expect(b.meal!.key, 'grilled_perch');
      expect(b.inventory, isEmpty);
      expect(game.stats(b).attack, game.stats(s).attack);
      expect(() => game.eat(b, 'grilled_perch'), throwsA(isA<ActivityError>()));
      expect(() => game.eat(b, 'perch'), throwsA(isA<ActivityError>()));
    });

    test('fewer steps multiplies with the tool, rounded up', () {
      final s = stateAt(
        game,
        location: 'copper_hills',
        inventory: {'boar_stew': 1},
      );
      final fed = game.eat(s, 'boar_stew');
      int cost(GameState g) => game.unitCost(
        game.startActivity(g, const Activity.gather('copper_vein')),
      )!;
      expect(cost(s), 100);
      expect(cost(fed), 94);
      expect(cost(fed..tools['mining'] = 'copper_pickaxe'), 85);
      // Crafting and rerolls too; not fights or travel.
      final camp = game.eat(
        stateAt(game, inventory: {'boar_stew': 1, 'copper_ore': 5}),
        'boar_stew',
      );
      expect(
        game.unitCost(
          game.startActivity(camp, const Activity.craft('copper_sword')),
        ),
        141,
      );
      final woods = game.eat(
        stateAt(game, location: 'goblin_woods', inventory: {'boar_stew': 1}),
        'boar_stew',
      );
      expect(
        game.unitCost(
          game.startActivity(woods, const Activity.fight('goblin')),
        ),
        data.combatRoundSteps,
      );
    });

    test('it counts down on action and travel steps, not banked ones', () {
      final s = game.eat(
        stateAt(game, inventory: {'venison_skewer': 1}),
        'venison_skewer',
      );
      final rested = game.applySteps(s, 500).state;
      expect(rested.meal!.left, 3000);
      expect(rested.bank, 500);
      final walked = work(s, const Activity.travel('goblin_woods'), 200).state;
      expect(walked.meal!.left, 2800);
      // With the bank boosting, both steps of each walked step count.
      final boosted = work(
        s..bank = 100,
        const Activity.travel('goblin_woods'),
        100,
      ).state;
      expect(boosted.meal!.left, 2800);
    });

    test('a meal that runs out leaves no buff', () {
      final s = geared({'venison_skewer': 1});
      final fed = game.eat(s, 'venison_skewer');
      final r = work(
        fed..location = 'goblin_woods',
        const Activity.fight('goblin'),
        3000,
      );
      expect(r.state.meal, isNull);
      expect(game.stats(r.state).attack, game.stats(s).attack);
      expect(r.events.whereType<MealsOut>().single.meal, 'venison_skewer');
    });
  });

  group('criterion 11: auto-eat', () {
    GameState running(Map<String, int> meals, {int keep = 0, int left = 50}) {
      final s = stateAt(game, location: 'copper_hills', inventory: meals);
      final fed = game.eat(s, meals.keys.first)..meal!.left = left;
      return game.setAutoEat(
        fed,
        game.data.itemOf(meals.keys.first)!.id,
        keep: keep,
      );
    }

    test('it eats at the exact step the last meal ends', () {
      final s = running({'venison_skewer': 3});
      final r = work(s, const Activity.gather('copper_vein'), 100);
      expect(r.state.meal!.key, 'venison_skewer');
      expect(r.state.meal!.left, 3000 - 50);
      expect(r.state.inventory['venison_skewer'], 1);
      final ate = r.events.whereType<MealEaten>().single;
      expect((ate.key, ate.auto, ate.left), ('venison_skewer', true, 1));
    });

    test('"until out" eats until the bag has none, then says so once', () {
      final s = running({'venison_skewer': 3}, left: 10);
      final r = work(s, const Activity.gather('copper_vein'), 100 * 70);
      expect(r.events.whereType<MealEaten>(), hasLength(2));
      expect(r.state.inventory['venison_skewer'], isNull);
      expect(r.state.meal, isNull);
      expect(r.events.whereType<MealsOut>(), hasLength(1));
    });

    test('"only N" stops with N left', () {
      final s = running({'venison_skewer': 5}, keep: 2, left: 10);
      final r = work(s, const Activity.gather('copper_vein'), 100 * 150);
      expect(r.state.inventory['venison_skewer'], 2);
      expect(r.events.whereType<MealEaten>(), hasLength(2));
    });

    test('plain ones first, then perfect', () {
      final perfect = GameData.perfectKey('venison_skewer');
      final s = running({'venison_skewer': 2, perfect: 1}, left: 10);
      final r = work(s, const Activity.gather('copper_vein'), 100 * 31);
      expect(r.events.whereType<MealEaten>().map((e) => e.key), [
        'venison_skewer',
        perfect,
      ]);
      expect(r.state.meal!.key, perfect);
    });

    test(
      'one meal kind at a time; picking another replaces it; off clears it',
      () {
        final s = stateAt(
          game,
          inventory: {'venison_skewer': 1, 'grilled_perch': 1},
        );
        final a = game.setAutoEat(s, 'venison_skewer');
        expect(a.autoEat!.meal, 'venison_skewer');
        expect(a.autoEat!.keep, 0);
        final b = game.setAutoEat(a, 'grilled_perch', keep: 3);
        expect((b.autoEat!.meal, b.autoEat!.keep), ('grilled_perch', 3));
        expect(game.setAutoEat(b, null).autoEat, isNull);
        expect(
          () => game.setAutoEat(s, 'perch'),
          throwsA(isA<ActivityError>()),
        );
      },
    );
  });
}
