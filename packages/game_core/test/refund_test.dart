// Spec 0001 amendment 2: unspent activity steps return to the bank, and the
// player can stop an activity.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();

  GameState fighting({int bank = 0}) => game.startActivity(
    stateAt(game, location: 'goblin_woods', bank: bank),
    const Activity.fight('goblin'),
  );

  test('criterion 1: switching refunds the unfinished round to the bank', () {
    var s = game.applySteps(fighting(), 7).state;
    expect(s.activity!.progress, 7);

    s = game.startActivity(s, const Activity.travel('camp'));

    expect(s.bank, 7);
    expect(s.activity!.progress, 0);
  });

  test('criterion 2: a boosted refund equals walking while resting', () {
    // Travel, not a fight: 18 steps of progress would complete a 10-step
    // combat round (see amendment 2 erratum).
    var s = game.startActivity(
      stateAt(game, bank: 100),
      const Activity.travel('goblin_woods'),
    );
    s = game.applySteps(s, 9).state;
    expect((s.activity!.progress, s.bank), (18, 91));

    s = game.stopActivity(s);

    final resting = game.applySteps(stateAt(game, bank: 100), 9).state;
    expect(s.bank, 109);
    expect(s.bank, resting.bank);
  });

  test('a fight refunds only the unfinished round', () {
    var s = game.applySteps(fighting(bank: 100), 9).state;
    // 18 progress: one 10-step round was fought and paid, 8 are unspent.
    expect((s.activity!.progress, s.bank), (8, 91));

    s = game.stopActivity(s);

    expect(s.bank, 99);
  });

  test('criterion 3: stopping refunds and leaves the character resting', () {
    var s = game.applySteps(fighting(), 7).state;

    s = game.stopActivity(s);

    expect(s.activity, isNull);
    expect(s.bank, 7);
    expect(game.applySteps(s, 5).state.bank, 12);
  });

  test('criterion 4: the refund respects the bank cap', () {
    final s = fighting()
      ..bank = game.bankCap(stateAt(game)) - 5
      ..activity!.progress = 18;

    final stopped = game.stopActivity(s);

    expect(stopped.bank, game.bankCap(stopped));
  });

  test('criterion 5: leaving a craft keeps materials and refunds steps', () {
    var s = stateAt(game, level: 3, inventory: {'copper_ore': 5});
    s = game.startActivity(s, const Activity.craft('copper_sword'));
    s = game.applySteps(s, 100).state;

    final switched = game.startActivity(
      s,
      const Activity.travel('goblin_woods'),
    );
    final stopped = game.stopActivity(s);

    for (final r in [switched, stopped]) {
      expect(r.inventory['copper_ore'], 5);
      expect(r.bank, 100);
    }
  });

  test('an activity ending by itself refunds its leftover boost step', () {
    var s = stateAt(game, level: 3, bank: 1, inventory: {'copper_ore': 5});
    s = game.startActivity(s, const Activity.craft('copper_sword'))
      ..activity!.progress = 149;

    // One walked step + one boost step = 151 progress: the sword completes,
    // nothing is left to craft, and the 1 leftover step goes back.
    final r = game.applySteps(s, 1);

    expect(r.state.inventory['copper_sword'], 1);
    expect(r.state.activity, isNull);
    expect(r.state.bank, 1);
  });

  test('stopping while resting is refused', () {
    expect(
      () => game.stopActivity(stateAt(game)),
      throwsA(isA<ActivityError>()),
    );
  });
}
