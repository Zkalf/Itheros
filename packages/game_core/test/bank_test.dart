// The item bank: spec 0020 criteria 1-15, 26 and 27 (plan 0040). The
// screens (criteria 16-25, 31) are in the app's tests.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;
  const sword = 'copper_sword';

  /// At [location] with [bag] in the bag and [bank] in the bank.
  GameState at(
    String location, {
    Map<String, int> bag = const {},
    Map<String, int> itemBank = const {},
    int level = 3,
  }) =>
      stateAt(game, location: location, level: level, inventory: bag)
        ..itemBank.addAll(itemBank);

  GameState walk(GameState s, int steps) => game.applySteps(s, steps).state;

  group('moves', () {
    test('Camp has the bank, and only Camp', () {
      expect(game.hasBank('camp'), isTrue);
      for (final l in data.locations.values) {
        if (l.id != 'camp') expect(game.hasBank(l.id), isFalse, reason: l.id);
      }
    });

    test('criterion 1: Store moves the count from the bag to the bank', () {
      final s = game.store(at('camp', bag: {'copper_ore': 7}), 'copper_ore', 5);
      expect(s.inventory['copper_ore'], 2);
      expect(s.itemBank['copper_ore'], 5);
      final all = game.store(s, 'copper_ore', 2);
      expect(all.inventory['copper_ore'], isNull);
      expect(all.itemBank['copper_ore'], 7);
    });

    test('criterion 2: Take moves the count from the bank to the bag', () {
      final s = game.take(
        at('camp', itemBank: {'copper_ore': 7}),
        'copper_ore',
        3,
      );
      expect(s.itemBank['copper_ore'], 4);
      expect(s.inventory['copper_ore'], 3);
      final all = game.take(s, 'copper_ore', 4);
      expect(all.itemBank['copper_ore'], isNull);
      expect(all.inventory['copper_ore'], 7);
    });

    test('criterion 3: a move uses no steps and no roll', () {
      final s = at('camp', bag: {'copper_ore': 7});
      final moved = game.store(s, 'copper_ore', 7);
      expect(moved.itemBank, {'copper_ore': 7});
      // `bank` is the step bank.
      expect(moved.stepBank, s.stepBank);
      expect(moved.rngState, s.rngState);
      expect(moved.xp, s.xp);
    });

    test('criterion 4: away from Camp, a move is refused', () {
      final s = at(
        'goblin_woods',
        bag: {'copper_ore': 7},
        itemBank: {'oak_log': 2},
      );
      expect(
        () => game.store(s, 'copper_ore', 1),
        throwsA(isA<ActivityError>()),
      );
      expect(() => game.take(s, 'oak_log', 1), throwsA(isA<ActivityError>()));
    });

    test('criterion 5: a move of more than there is is refused', () {
      final s = at('camp', bag: {'copper_ore': 2}, itemBank: {'oak_log': 2});
      expect(
        () => game.store(s, 'copper_ore', 3),
        throwsA(isA<ActivityError>()),
      );
      expect(() => game.take(s, 'oak_log', 3), throwsA(isA<ActivityError>()));
      expect(
        () => game.store(s, 'copper_ore', 0),
        throwsA(isA<ActivityError>()),
      );
    });

    test('criterion 6: worn gear cannot be stored', () {
      final s = game.equip(at('camp', bag: {sword: 1}), sword);
      expect(s.inventory[sword], isNull);
      expect(() => game.store(s, sword, 1), throwsA(isA<ActivityError>()));
    });
  });

  group('crafting and cooking', () {
    test('criterion 7: at Camp, a craft with its inputs only in the bank '
        'starts and runs', () {
      final s = game.startActivity(
        at('camp', itemBank: {'copper_ore': 5}),
        const Activity.craft(sword),
      );
      final done = walk(s, 2000);
      expect(game.owned(done, sword), greaterThanOrEqualTo(1));
      expect(done.itemBank['copper_ore'], isNull);
    });

    test('criterion 8: at Camp, a craft takes from the bag first, then the '
        'bank', () {
      final s = game.startActivity(
        at('camp', bag: {'copper_ore': 3}, itemBank: {'copper_ore': 4}),
        const Activity.craft(sword),
        stop: const StopCondition.untilCrafted(1),
      );
      final done = walk(s, 2000);
      expect(done.inventory['copper_ore'], isNull);
      expect(done.itemBank['copper_ore'], 2);
    });

    test('criterion 9: at Camp, a cook uses inputs from the bank', () {
      final s = game.startActivity(
        at('camp', itemBank: {'perch': 2}),
        const Activity.craft('grilled_perch'),
      );
      final done = walk(s, 500);
      expect(game.owned(done, 'grilled_perch'), 1);
      expect(done.itemBank['perch'], isNull);
    });

    test('criterion 10: what a craft at Camp makes goes into the bag', () {
      final s = game.startActivity(
        at('camp', itemBank: {'copper_ore': 5}),
        const Activity.craft(sword),
      );
      final done = walk(s, 2000);
      final made = done.inventory.keys.where(
        (k) => data.itemOf(k)?.id == sword,
      );
      expect(made, hasLength(1));
      expect(
        done.itemBank.keys.where((k) => data.itemOf(k)?.id == sword),
        isEmpty,
      );
    });

    test('criterion 11: away from Camp, a craft does not count the bank', () {
      final s = at('mountain_pass', itemBank: {'copper_ore': 5});
      expect(game.hasMaterials(s, sword), isFalse);
      expect(
        () => game.startActivity(s, const Activity.craft(sword)),
        throwsA(isA<ActivityError>()),
      );
    });

    test('criterion 12: a craft queued for Camp counts the bank', () {
      // No fire on the Grey Moor: the cook walks to Camp first.
      final s = game.startActivity(
        at('grey_moor', itemBank: {'perch': 2}),
        const Activity.craft('grilled_perch'),
      );
      expect(s.activity!.leg, isNotNull);
      final done = walk(s, 5000);
      expect(done.location, 'camp');
      expect(game.owned(done, 'grilled_perch'), 1);
      expect(done.itemBank['perch'], isNull);
    });
  });

  group('owning', () {
    test('criterion 13: "Until I have N" counts the bank', () {
      final s = game.startActivity(
        at('copper_hills', itemBank: {'copper_ore': 2}),
        const Activity.gather('copper_vein'),
        stop: const StopCondition.untilHave('copper_ore', 3),
      );
      final done = walk(s, 5000);
      expect(done.activity, isNull);
      expect(done.inventory['copper_ore'], 1);
    });

    test(
      'criterion 14: gear in the bank counts as owned for the next goal',
      () {
        final s = at('camp', level: 3, bag: {'copper_ore': 5});
        expect(game.nextGoal(s), isA<CraftGoal>());
        expect((game.nextGoal(s)! as CraftGoal).recipe, sword);
        final banked = at(
          'camp',
          level: 3,
          bag: {'copper_ore': 5},
          itemBank: {sword: 1},
        );
        expect(game.owned(banked, sword), 1);
        final goal = game.nextGoal(banked);
        expect(goal is CraftGoal && goal.recipe == sword, isFalse);
      },
    );

    test('criterion 15: eat, wear and salvage refuse an item only in the '
        'bank', () {
      final s = at('camp', itemBank: {sword: 1, 'grilled_perch': 1});
      expect(() => game.equip(s, sword), throwsA(isA<ActivityError>()));
      expect(() => game.eat(s, 'grilled_perch'), throwsA(isA<ActivityError>()));
      expect(() => game.salvage(s, sword), throwsA(isA<ActivityError>()));
    });
  });

  group('review of PR #172', () {
    test('the next goal counts the bank in what is left to collect', () {
      // At level 3 the next goal is a Hide vest: 4 Goblin hides.
      final none = at('camp', level: 3);
      final first = game.nextGoal(none)! as CollectGoal;
      expect((first.item, first.count), ('goblin_hide', 4));
      final s = at(
        'camp',
        level: 3,
        bag: {'goblin_hide': 1},
        itemBank: {'goblin_hide': 2},
      );
      expect(game.nextGoal(s), isA<CollectGoal>());
      final goal = game.nextGoal(s)! as CollectGoal;
      expect(goal.item, 'goblin_hide');
      expect(goal.count, 1, reason: '4 needed, 3 in the bag and the bank');
    });

    test('the bag after the queue takes a waiting craft out of the bank', () {
      final s = at('camp', itemBank: {'copper_ore': 10})
        ..activity = RunningActivity(
          const Activity.craft(sword),
          stop: const StopCondition.untilCrafted(1),
        );
      expect(game.bagAfterQueue(s, withBank: true)['copper_ore'], 5);
      expect(game.bagAfterQueue(s)['copper_ore'] ?? 0, 0);
    });

    test('the bag count of a meal leaves out the bank', () {
      final s = at(
        'camp',
        bag: {'grilled_perch': 1},
        itemBank: {'grilled_perch': 4},
      );
      expect(game.inBag(s, 'grilled_perch'), 1);
      expect(game.owned(s, 'grilled_perch'), 5);
    });
  });

  group('save', () {
    test('criterion 26: the save version is 16', () {
      expect(GameState.schemaVersion, 16);
      final s = at('camp', itemBank: {'copper_ore': 3});
      expect(s.toJson()['version'], 16);
      expect(GameState.fromJson(s.toJson()).itemBank, {'copper_ore': 3});
    });

    test('erratum 1: the step bank saves as stepBank; an old "bank" '
        'loads into it', () {
      final s = stateAt(game, stepBank: 42);
      final json = s.toJson();
      expect(json['stepBank'], 42);
      expect(json.containsKey('bank'), isFalse);
      expect(GameState.fromJson(json).stepBank, 42);
      final old = Map.of(json)
        ..remove('stepBank')
        ..['bank'] = 17;
      expect(GameState.fromJson(old).stepBank, 17);
    });

    test('criterion 27: a schema 15 save loads with an empty bank', () {
      final json = at('camp').toJson()
        ..remove('itemBank')
        ..['version'] = 15;
      final back = game.migrate(GameState.fromJson(json));
      expect(back.itemBank, isEmpty);
    });
  });
}
