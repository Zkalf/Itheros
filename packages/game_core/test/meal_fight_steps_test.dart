// Meals that speed up fights: spec 0011 amendment 2 criteria 2-7 (plan
// 0054). Criterion 1 (6,000 steps) is in meals_test.dart.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;

  GameState fed(String meal, {Map<String, int> talents = const {}}) =>
      stateAt(game)
        ..meal = ActiveMeal(meal, data.mealStepsOf(meal))
        ..talents.addAll(talents);

  // 10 rounds of `combatRoundSteps` steps each.
  final roundSteps = 10 * data.combatRoundSteps;
  int share(double s) => (roundSteps * s + 1e-9).floor();

  group('criteria 2-5: which meals give fight steps back', () {
    for (final (meal, tier, kind) in [
      ('venison_skewer', 1, 'Attack'),
      ('elk_roast', 2, 'Attack'),
      ('ibex_haunch', 3, 'Attack'),
      ('grilled_perch', 1, 'HP'),
      ('smoked_trout', 2, 'HP'),
      ('char_soup', 3, 'HP'),
      ('mossback_feast', 1, 'a feast'),
      ('pale_one_feast', 3, 'a feast'),
    ]) {
      test('$kind meal $meal (tier $tier) gives back '
          '${data.mealFightSteps[tier - 1]}% of the round steps', () {
        expect(data.itemOf(meal)!.meal!.tier, tier);
        expect(
          game.fightStepsBack(fed(meal), 10),
          share(data.mealFightSteps[tier - 1] / 100),
        );
        expect(game.fightStepsBack(fed(meal), 10), greaterThan(0));
      });
    }

    for (final meal in [
      'pike_steak',
      'golden_carp_curry',
      'boar_stew',
      'grouse_pie',
    ]) {
      test('criterion 5: $meal (${data.itemOf(meal)!.meal!.buffs.single}) '
          'gives back no fight steps', () {
        expect(game.fightStepsBack(fed(meal), 10), 0);
      });
    }

    test('no meal gives back no fight steps', () {
      expect(game.fightStepsBack(stateAt(game), 10), 0);
    });
  });

  test('criterion 6: Swift strikes and the meal add up', () {
    const ranks = {'swift_strikes': 5};
    final talent = 5 * data.talents['swift_strikes']!.value;
    final both = fed('venison_skewer', talents: ranks);
    expect(game.fightStepsBack(both, 10), share(talent + 0.12));
    expect(
      game.fightStepsBack(both, 10),
      greaterThan(game.fightStepsBack(fed('venison_skewer'), 10)),
    );
    expect(
      game.fightStepsBack(both, 10),
      greaterThan(
        game.fightStepsBack(stateAt(game)..talents.addAll(ranks), 10),
      ),
    );
  });

  test('criterion 7: the shares and the length come from economy.json', () {
    final meals = dataJson('economy')['meals']! as Map<String, Object?>;
    expect(meals['fightSteps'], [12, 20, 28]);
    expect(meals['steps'], 6000);
    expect(data.mealFightSteps, [12, 20, 28]);
    expect(data.mealSteps, 6000);
    // A changed number in the data changes the rule.
    final other = newTestGame(
      overrides: {
        'economy': {
          ...dataJson('economy'),
          'meals': {
            ...meals,
            'fightSteps': [50, 50, 50],
          },
        },
      },
    );
    final s = stateAt(other)
      ..meal = ActiveMeal('venison_skewer', other.data.mealSteps);
    expect(other.fightStepsBack(s, 10), share(0.5));
  });

  test('a won fight in the arena gives the HP meal share back as progress', () {
    // Attack 5 against 30 HP, sure hits: six rounds. An HP meal does not
    // change the damage, so the fight still takes six rounds.
    final arena = arenaGame([monster('dummy', hp: 30)]);
    final s = arena.startActivity(
      arena.newGame(seed: 1)..meal = ActiveMeal('grilled_perch', 6000),
      const Activity.fight('dummy'),
    );
    final steps = 6 * arena.data.combatRoundSteps;
    final r = arena.applySteps(s, steps);
    expect(r.events.whereType<FightWon>(), hasLength(1));
    expect(
      r.state.activity!.progress,
      (steps * arena.data.mealFightSteps[0] / 100 + 1e-9).floor(),
    );
    expect(r.state.activity!.progress, greaterThan(0));
  });
}
