// Unlock gating and activity validation: spec 0001 §5 and acceptance criterion 8,
// as spec 0008 (no level gates, fog) changed them.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();

  // Spec 0008 decision 1 replaced the level gates below level 10.
  test('level 1 at camp: every neighbour is reachable, every recipe shows', () {
    final s = stateAt(game);
    expect(game.travelDestinations(s), [
      'goblin_woods',
      'copper_hills',
      'old_graveyard',
    ]);
    expect(game.availableRecipes(s), game.data.recipes.keys.toList());
  });

  test('level 1 in Goblin Woods: every monster there', () {
    final s = stateAt(game, location: 'goblin_woods');
    expect(game.availableEnemies(s), ['goblin', 'goblin_brute', 'old_bear']);
    expect(game.availableNodes(s), isEmpty);
  });

  test('level 2 opens mining (spec 0008 amendment 1)', () {
    final atHills = stateAt(game, level: 2, location: 'copper_hills');
    expect(game.availableNodes(atHills), ['copper_vein']);
    expect(game.nodeLevelMet(atHills, 'copper_vein'), isTrue);
  });

  group('startActivity rejects', () {
    void rejects(GameState s, Activity a) =>
        expect(() => game.startActivity(s, a), throwsA(isA<ActivityError>()));

    test('an enemy in the fog (spec 0008 decision 6)', () {
      rejects(stateAt(game), const Activity.fight('wolf'));
    });
    test('a node above the player level', () {
      rejects(
        stateAt(game, location: 'copper_hills'),
        const Activity.gather('copper_vein'),
      );
    });
    test('a destination in the fog', () {
      rejects(stateAt(game), const Activity.travel('grey_moor'));
    });
    test('travel without a route, or to where you are', () {
      rejects(stateAt(game), const Activity.travel('camp'));
    });
    test('crafting without materials', () {
      rejects(
        stateAt(game, level: 3, inventory: {'copper_ore': 4}),
        const Activity.craft('copper_sword'),
      );
    });
  });

  test('switching activity refunds progress and keeps materials', () {
    var s = stateAt(game, level: 3, inventory: {'copper_ore': 5});
    s = game.startActivity(s, const Activity.craft('copper_sword'));
    s = game.applySteps(s, 100).state;
    expect(s.activity!.progress, 100);

    s = game.startActivity(s, const Activity.travel('goblin_woods'));
    expect(s.activity!.progress, 0);
    expect(s.bank, 100, reason: 'spec 0001 amendment 2');
    expect(s.inventory['copper_ore'], 5);
  });

  group('somewhere else: the character walks there first (spec 0003)', () {
    test('a fight', () {
      final s = game.startActivity(
        stateAt(game),
        const Activity.fight('goblin'),
      );
      expect(s.activity!.leg, 'goblin_woods');
    });

    test('crafting goes to the nearest crafting place', () {
      final s = game.startActivity(
        stateAt(
          game,
          level: 3,
          location: 'goblin_woods',
          inventory: {'copper_ore': 5},
        ),
        const Activity.craft('copper_sword'),
      );
      expect(s.activity!.leg, 'camp');
    });
  });
}
