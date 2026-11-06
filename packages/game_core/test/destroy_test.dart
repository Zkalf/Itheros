// Destroy an item: spec 0021 amendment 2 criteria 1-6 (plan 0049). The
// screens (criteria 7-15) are in the app's tests.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();

  GameState at(
    String location, {
    Map<String, int> bag = const {},
    Map<String, int> bank = const {},
  }) =>
      stateAt(game, location: location, level: 5, inventory: bag)
        ..itemBank.addAll(bank);

  test('criterion 1: a destroy of 3 of a stack of 12 leaves 9', () {
    final n = game.destroy(
      at('camp', bag: {'goblin_hide': 12}),
      'goblin_hide',
      3,
    );
    expect(n.inventory['goblin_hide'], 9);
  });

  test('criterion 2: a destroy of the whole stack frees its bag space', () {
    final s = at('camp', bag: {'goblin_hide': 12, 'copper_ore': 2});
    final n = game.destroy(s, 'goblin_hide', 12);
    expect(n.inventory.containsKey('goblin_hide'), isFalse);
    expect(game.spacesUsed(n), game.spacesUsed(s) - 1);
  });

  test('criterion 3: a destroy from the bank takes from the bank, not the '
      'bag', () {
    final s = at('camp', bag: {'goblin_hide': 4}, bank: {'goblin_hide': 10});
    final n = game.destroy(s, 'goblin_hide', 6, fromBank: true);
    expect(n.itemBank['goblin_hide'], 4);
    expect(n.inventory['goblin_hide'], 4);
    final all = game.destroy(n, 'goblin_hide', 4, fromBank: true);
    expect(all.itemBank.containsKey('goblin_hide'), isFalse);
  });

  test('criterion 4: a destroy away from Camp works, from the bag and the '
      'bank', () {
    final s = at('goblin_woods', bag: {'goblin_hide': 2}, bank: {'oak_log': 3});
    expect(game.hasBank(s.location), isFalse);
    expect(
      game.destroy(s, 'goblin_hide', 2).inventory,
      isNot(contains('goblin_hide')),
    );
    expect(
      game.destroy(s, 'oak_log', 1, fromBank: true).itemBank['oak_log'],
      2,
    );
  });

  test(
    'criterion 5: a destroy gives no dust, no shard, no steps and no XP',
    () {
      const sword = 'bone_sword@rare+crit2';
      final s = at('camp', bag: {sword: 1, 'goblin_hide': 1})..stepBank = 500;
      final n = game.destroy(s, sword, 1);
      expect(n.inventory, {'goblin_hide': 1});
      expect(n.itemBank, s.itemBank);
      expect(n.stepBank, s.stepBank);
      expect(n.xp, s.xp);
      expect(n.professions, s.professions);
      expect(n.counters, s.counters);
    },
  );

  test('criterion 6: a destroy of more than the stack, or of nothing, is '
      'refused', () {
    final s = at('camp', bag: {'goblin_hide': 2}, bank: {'oak_log': 1});
    for (final (key, count, fromBank) in [
      ('goblin_hide', 3, false),
      ('goblin_hide', 0, false),
      ('copper_ore', 1, false),
      ('oak_log', 2, true),
      ('goblin_hide', 1, true),
    ]) {
      expect(
        () => game.destroy(s, key, count, fromBank: fromBank),
        throwsA(isA<ActivityError>()),
        reason: '$key ×$count${fromBank ? ' from the bank' : ''}',
      );
    }
    // A refusal changes nothing.
    expect(s.inventory, {'goblin_hide': 2});
  });

  test('worn gear is not in the bag, so a destroy refuses it', () {
    final s = at('camp')..equipment['mainHand'] = 'bone_sword';
    expect(
      () => game.destroy(s, 'bone_sword', 1),
      throwsA(isA<ActivityError>()),
    );
    expect(s.equipment['mainHand'], 'bone_sword');
  });
}
