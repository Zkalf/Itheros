// Issue #114: a spot's found catches, for "Until I have N".
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();

  test('a new player: only the spot item', () {
    final s = stateAt(game, location: 'goblin_woods');
    expect(game.foundCatches(s, 'deer_trail'), ['deer_hide']);
    expect(game.foundCatches(s, 'copper_vein'), ['copper_ore']);
  });

  test('a catch joins the list once gathered', () {
    var s = game.startActivity(
      stateAt(game, location: 'goblin_woods', professionLevel: 10),
      const Activity.gather('deer_trail'),
      stop: const StopCondition.never(),
    );
    s = game.applySteps(s, 20000).state;
    expect(s.counters['gathered.venison'], greaterThan(0));
    expect(game.foundCatches(s, 'deer_trail'), contains('venison'));
    expect(
      game.foundCatches(s, 'deer_trail'),
      everyElement(
        isIn(game.countableItems(const Activity.gather('deer_trail'))),
      ),
    );
  });

  test('an owned item counts as found', () {
    final s = stateAt(
      game,
      location: 'goblin_woods',
      inventory: {'boar_meat': 1},
    );
    expect(game.foundCatches(s, 'deer_trail'), ['deer_hide', 'boar_meat']);
  });
}
