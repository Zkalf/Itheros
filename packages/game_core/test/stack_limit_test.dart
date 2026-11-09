// A stack limit for each kind of item: spec 0021 amendment 4, criteria 1-8
// and 15 (plan 0056). The screens (criteria 9-14) are in the app's tests.
import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:game_core/simulation.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;
  const full = StopCondition.untilFull();
  final vein = {'copper_ore', 'garnet'};

  /// [n] kinds of material, one of each, none of [except].
  Map<String, int> filler(int n, {Set<String> except = const {}}) => {
    for (final id
        in data.items.keys
            .where(
              (id) =>
                  data.kindOf(id) == ItemKind.material && !except.contains(id),
            )
            .take(n))
      id: 1,
  };

  EndReason? endOf(StepReport r) =>
      r.events.whereType<ActivityEnded>().firstOrNull?.reason;

  group('the rule', () {
    test('criterion 1: economy.json has the stack sizes', () {
      expect(data.bagStacks, {
        'material': 100,
        'meal': 20,
        'gear': 1,
        'tool': 1,
      });
      expect(data.stackOf('copper_ore'), 100);
    });

    test('criterion 2: 100 copper ore use 1 space, 101 use 2, 237 use 3', () {
      for (final (n, spaces) in [(100, 1), (101, 2), (237, 3)]) {
        expect(game.spacesOf('copper_ore', n), spaces, reason: '$n ore');
        final s = stateAt(game, inventory: {'copper_ore': n});
        expect(game.spacesUsed(s), spaces, reason: '$n ore in the bag');
      }
    });

    test('criterion 3: 21 of one meal use 2 spaces', () {
      expect(data.kindOf('grilled_perch'), ItemKind.meal);
      expect(data.stackOf('grilled_perch'), 20);
      final s = stateAt(game, inventory: {'grilled_perch': 21});
      expect(game.spacesUsed(s), 2);
    });

    test('criterion 4: two pieces of gear with the same roll use 2 spaces', () {
      const vest = 'hide_vest@rare+hp10';
      expect(data.kindOf(vest), ItemKind.gear);
      final s = stateAt(game, inventory: {vest: 2});
      expect(game.spacesUsed(s), 2);
    });

    test('criterion 5: items in the bank use no space, in any amount', () {
      final s = stateAt(game)..itemBank['copper_ore'] = 5000;
      expect(game.spacesUsed(s), 0);
      expect(game.overloaded(s), isFalse);
    });

    test('criterion 6: a bag of 39 spaces with 100 copper ore is full after '
        'one more ore, and "Until the bag is full" stops at it', () {
      final s = stateAt(
        game,
        location: 'copper_hills',
        level: 5,
        inventory: {
          ...filler(37, except: vein),
          'copper_ore': 100,
          'garnet': 1,
        },
      );
      expect(game.spacesUsed(s), 39);
      final r = game.applySteps(
        game.startActivity(s, const Activity.gather('copper_vein'), stop: full),
        1000,
      );
      expect(
        r.state.inventory['copper_ore'],
        101,
        reason: 'one unit, then stop',
      );
      expect(game.spacesUsed(r.state), 40);
      expect(r.state.activity, isNull);
      expect(endOf(r), EndReason.bagFull);
    });

    test('criterion 7: "Until the bag is full" goes on while the catch fits in '
        'a stack the bag holds', () {
      final s = stateAt(
        game,
        location: 'copper_hills',
        level: 5,
        inventory: {
          ...filler(37, except: vein),
          'copper_ore': 50,
          'garnet': 1,
        },
      );
      expect(game.spacesUsed(s), 39);
      final r = game.applySteps(
        game.startActivity(s, const Activity.gather('copper_vein'), stop: full),
        500,
      );
      expect(r.state.inventory['copper_ore'], greaterThan(52));
      expect(r.state.inventory['copper_ore'], lessThanOrEqualTo(100));
      expect(r.state.activity?.activity, const Activity.gather('copper_vein'));
      expect(endOf(r), isNull);
    });

    test('criterion 8: a save with more than 100 of a material loads with all '
        'its items, its spaces counted by the new rule', () {
      final s = stateAt(game, inventory: {'copper_ore': 4500, 'oak_log': 3});
      final back = GameState.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, Object?>,
      );
      expect(back.inventory['copper_ore'], 4500);
      expect(back.inventory['oak_log'], 3);
      expect(game.spacesUsed(back), 46);
      expect(game.overloaded(back), isTrue);
    });
  });

  group('the sim walker', () {
    test('criterion 15: before a take from the bank, it counts the spaces the '
        'take would use (spacesWith)', () {
      final s = stateAt(
        game,
        inventory: {
          ...filler(38, except: vein),
          'copper_ore': 50,
        },
      );
      expect(game.spacesUsed(s), 39);
      expect(game.spacesWith(s, 'copper_ore', 50), 39, reason: 'fits');
      expect(game.spacesWith(s, 'copper_ore', 51), 40, reason: 'a new stack');
      expect(game.spacesWith(s, 'copper_ore', 251), 42);
      expect(game.spacesWith(s, 'garnet', 1), 40, reason: 'a new kind');
      expect(game.spacesWith(s, 'copper_ore', 0), 39);
    });

    test('criterion 15: it goes to the bank when only big stacks overload the '
        'bag', () {
      // One kind of material in 45 stacks: 45 spaces of 40.
      final s = stateAt(
        game,
        location: 'copper_hills',
        level: 5,
        inventory: {'copper_ore': 4500},
      );
      expect(game.overloaded(s), isTrue);
      final next = SensiblePlayer(game).decide(s);
      expect(next.activity?.activity, const Activity.travel('camp'));
    });

    test(
      'criterion 15: it stays when the stacks it would keep (meals) overload '
      'the bag on their own',
      () {
        // 900 of one meal: 45 spaces that a store of materials can't free.
        final s = stateAt(
          game,
          location: 'copper_hills',
          level: 5,
          inventory: {'grilled_perch': 900, 'oak_log': 1},
        );
        expect(game.overloaded(s), isTrue);
        final next = SensiblePlayer(game).decide(s);
        expect(next.activity?.activity, isNot(const Activity.travel('camp')));
      },
    );
  });
}
