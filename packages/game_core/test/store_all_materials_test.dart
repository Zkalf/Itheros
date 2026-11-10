// Store all materials: spec 0020 amendment 5 criteria 7, 8, 15 and 16 (plan
// 0059). The buttons (criteria 1-6, 9-14, 17) are in the app's tests.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  const bag = {
    'copper_ore': 7,
    'goblin_hide': 120,
    'common_dust': 3,
    'copper_sword': 1,
    'copper_pickaxe': 1,
    'grilled_perch': 2,
  };

  test('criterion 7: the whole stack of every material moves to the bank', () {
    final s = stateAt(game, inventory: bag)..itemBank['copper_ore'] = 5;
    final n = game.storeAllMaterials(s);
    expect(n.itemBank, {
      'copper_ore': 12,
      'goblin_hide': 120,
      'common_dust': 3,
    });
    for (final key in ['copper_ore', 'goblin_hide', 'common_dust']) {
      expect(n.inventory[key], isNull, reason: key);
    }
    // The state it got stays as it was.
    expect(s.inventory['copper_ore'], 7);
    expect(s.itemBank, {'copper_ore': 5});
  });

  test('criterion 8: gear, a tool and a meal stay in the bag', () {
    final n = game.storeAllMaterials(stateAt(game, inventory: bag));
    expect(n.inventory, {
      'copper_sword': 1,
      'copper_pickaxe': 1,
      'grilled_perch': 2,
    });
  });

  test('criterion 15: away from a place with a bank the move is refused', () {
    final s = stateAt(game, location: 'goblin_woods', inventory: bag);
    expect(
      () => game.storeAllMaterials(s),
      throwsA(
        isA<ActivityError>().having(
          (e) => e.message,
          'message',
          'Items move only at a bank.',
        ),
      ),
    );
  });

  test('criterion 16: the move uses no steps and no roll', () {
    final s = stateAt(game, inventory: bag, stepBank: 400);
    final n = game.storeAllMaterials(s);
    expect(n.stepBank, 400);
    expect(n.xp, s.xp);
    expect(n.rngState, s.rngState);
    expect(n.professionRng, s.professionRng);
  });

  test('with no material in the bag, nothing moves', () {
    final s = stateAt(game, inventory: {'copper_sword': 1});
    final n = game.storeAllMaterials(s);
    expect(n.inventory, {'copper_sword': 1});
    expect(n.itemBank, isEmpty);
  });
}
