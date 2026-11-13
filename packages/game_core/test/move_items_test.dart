// Store and Take for a selection: spec 0020 amendment 8 criteria 1 to 6
// (plan 0067). The screens (criteria 7-34) are in the app's tests.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  const bag = {
    'copper_ore': 7,
    'goblin_hide': 120,
    'copper_sword': 1,
    'grilled_perch': 2,
  };
  final refused = throwsA(
    isA<ActivityError>().having(
      (e) => e.message,
      'message',
      'Items move only at a bank.',
    ),
  );

  test('criteria 1 and 3: Store moves the whole count of each given item, '
      'and the others stay', () {
    final s = stateAt(game, inventory: bag)..itemBank['copper_ore'] = 5;
    final n = game.storeItems(s, ['copper_ore', 'copper_sword']);
    expect(n.itemBank, {'copper_ore': 12, 'copper_sword': 1});
    expect(n.inventory, {'goblin_hide': 120, 'grilled_perch': 2});
    // The state it got stays as it was.
    expect(s.inventory['copper_ore'], 7);
    expect(s.itemBank, {'copper_ore': 5});
  });

  test('criteria 2 and 3: Take moves the whole count of each given item, '
      'and the others stay', () {
    final s = stateAt(game, inventory: {'copper_ore': 7})
      ..itemBank.addAll({'copper_ore': 5, 'bones': 3, 'copper_sword': 1});
    final n = game.takeItems(s, ['copper_ore', 'copper_sword']);
    expect(n.inventory, {'copper_ore': 12, 'copper_sword': 1});
    expect(n.itemBank, {'bones': 3});
    expect(s.itemBank['copper_ore'], 5);
  });

  test('criterion 4: an item that the list does not hold is skipped, and '
      'the rest move', () {
    final s = stateAt(game, inventory: bag)..itemBank['bones'] = 3;
    final stored = game.storeItems(s, ['bones', 'copper_ore']);
    expect(stored.itemBank, {'bones': 3, 'copper_ore': 7});
    expect(stored.inventory['copper_ore'], isNull);
    final taken = game.takeItems(s, ['copper_sword', 'bones']);
    expect(taken.inventory['bones'], 3);
    expect(taken.inventory['copper_sword'], 1);
    expect(taken.itemBank, isEmpty);
  });

  test('criterion 5: away from a place with a bank each move is refused', () {
    final s = stateAt(game, location: 'goblin_woods', inventory: bag)
      ..itemBank['bones'] = 3;
    expect(() => game.storeItems(s, ['copper_ore']), refused);
    expect(() => game.takeItems(s, ['bones']), refused);
    expect(s.inventory, bag);
    expect(s.itemBank, {'bones': 3});
  });

  test('criterion 6: the moves use no steps and no roll', () {
    final s = stateAt(game, inventory: bag, stepBank: 400)
      ..itemBank['bones'] = 3;
    for (final n in [
      game.storeItems(s, ['copper_ore', 'copper_sword']),
      game.takeItems(s, ['bones']),
    ]) {
      expect(n.stepBank, 400);
      expect(n.xp, s.xp);
      expect(n.rngState, s.rngState);
      expect(n.professionRng, s.professionRng);
    }
  });
}
