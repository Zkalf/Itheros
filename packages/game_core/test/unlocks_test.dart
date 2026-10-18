// Unlock gating and activity validation: spec 0001 §5 and acceptance criterion 8.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();

  test('level 1 at camp: only Goblin Woods is reachable, no crafting', () {
    final s = stateAt(game);
    expect(game.travelDestinations(s), ['goblin_woods']);
    expect(game.availableRecipes(s), isEmpty);
  });

  test('level 1 in Goblin Woods: goblins only, no brute', () {
    final s = stateAt(game, location: 'goblin_woods');
    expect(game.availableEnemies(s), ['goblin']);
    expect(game.availableNodes(s), isEmpty);
  });

  test('level 2 unlocks Copper Hills and mining', () {
    final s = stateAt(game, level: 2, location: 'goblin_woods');
    expect(game.travelDestinations(s), contains('copper_hills'));
    final atHills = stateAt(game, level: 2, location: 'copper_hills');
    expect(game.availableNodes(atHills), ['copper_vein']);
  });

  test('level 3 unlocks crafting at camp', () {
    final s = stateAt(game, level: 3);
    expect(game.availableRecipes(s), ['copper_sword', 'hide_vest']);
  });

  test('level 4 unlocks the goblin brute', () {
    final s = stateAt(game, level: 4, location: 'goblin_woods');
    expect(game.availableEnemies(s), ['goblin', 'goblin_brute']);
  });

  group('startActivity rejects', () {
    void rejects(GameState s, Activity a) =>
        expect(() => game.startActivity(s, a), throwsA(isA<ActivityError>()));

    test('a locked enemy', () {
      rejects(
        stateAt(game, location: 'goblin_woods'),
        const Activity.fight('goblin_brute'),
      );
    });
    test('an enemy at another location', () {
      rejects(stateAt(game), const Activity.fight('goblin'));
    });
    test('a locked node', () {
      rejects(
        stateAt(game, location: 'copper_hills'),
        const Activity.gather('copper_vein'),
      );
    });
    test('a locked destination', () {
      rejects(stateAt(game), const Activity.travel('copper_hills'));
    });
    test('travel without a route, or to where you are', () {
      rejects(stateAt(game), const Activity.travel('camp'));
    });
    test('crafting away from camp', () {
      rejects(
        stateAt(
          game,
          level: 3,
          location: 'goblin_woods',
          inventory: {'copper_ore': 5},
        ),
        const Activity.craft('copper_sword'),
      );
    });
    test('crafting without materials', () {
      rejects(
        stateAt(game, level: 3, inventory: {'copper_ore': 4}),
        const Activity.craft('copper_sword'),
      );
    });
  });

  test('switching activity discards progress and keeps materials', () {
    var s = stateAt(game, level: 3, inventory: {'copper_ore': 5});
    s = game.startActivity(s, const Activity.craft('copper_sword'));
    s = game.applySteps(s, 100).state;
    expect(s.activity!.progress, 100);

    s = game.startActivity(s, const Activity.travel('goblin_woods'));
    expect(s.activity!.progress, 0);
    expect(s.inventory['copper_ore'], 5);
  });
}
