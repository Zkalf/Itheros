// The materials a craft has, needs, uses and keeps: spec 0010 amendment 5,
// criteria 6, 10, 11 and 15-21 (plan 0022 M1).
import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  const sword = Activity.craft('copper_sword'); // copper_ore 5
  const spear = Activity.craft('copper_spear'); // copper_ore 5, oak_log 1
  const perch = Activity.craft('grilled_perch'); // perch 2
  const mining = Activity.gather('copper_vein');

  GameState at(Map<String, int> inventory) =>
      stateAt(game, level: 10, inventory: inventory);

  group('craftsAllowed', () {
    test('counts the crafts that the bag allows', () {
      expect(game.craftsAllowed({'copper_ore': 12}, 'copper_sword'), 2);
      expect(
        game.craftsAllowed({'copper_ore': 20, 'oak_log': 3}, 'copper_spear'),
        3,
      );
    });

    test('a short or missing material allows 0 crafts', () {
      expect(game.craftsAllowed({'copper_ore': 4}, 'copper_sword'), 0);
      expect(game.craftsAllowed({'copper_ore': 20}, 'copper_spear'), 0);
      expect(game.craftsAllowed({}, 'copper_sword'), 0);
    });
  });

  group('craftsFor (§2.2)', () {
    test('criterion 6: "Until 5 crafted" is 5 crafts', () {
      expect(game.craftsFor(sword, const StopCondition.untilCrafted(5), {}), 5);
    });

    test('criterion 10: a meal "Until I have N" is N minus the meals in the '
        'bag, at least 0', () {
      expect(
        game.craftsFor(
          perch,
          const StopCondition.untilHave('grilled_perch', 5),
          {'grilled_perch': 2},
        ),
        3,
      );
      expect(
        game.craftsFor(
          perch,
          const StopCondition.untilHave('grilled_perch', 1),
          {'grilled_perch': 4},
        ),
        0,
      );
    });

    test('criterion 11: "Until a quality" and "Never stop" are unknown', () {
      expect(
        game.craftsFor(sword, const StopCondition.untilQuality('rare'), {}),
        isNull,
      );
      expect(game.craftsFor(sword, const StopCondition.never(), {}), isNull);
    });
  });

  group('bagAfterQueue (§3)', () {
    test('with no action, it is the bag of now, by base item id', () {
      final s = at({'copper_ore': 7, 'grilled_perch@perfect': 1, 'perch': 2});
      final bag = game.bagAfterQueue(s);
      expect(bag['copper_ore'], 7);
      expect(bag['perch'], 2);
      expect(bag['grilled_perch'], 1, reason: 'a perfect meal is a meal');
    });

    test('criterion 15: a queued craft "Until 3 crafted" uses its inputs for 3 '
        'crafts and adds 3 outputs', () {
      final s = at({'copper_ore': 20, 'oak_log': 5})
        ..activity = RunningActivity(mining)
        ..queue.add(const PlannedAction(spear, StopCondition.untilCrafted(3)));
      final bag = game.bagAfterQueue(s);
      expect(bag['copper_ore'], 5);
      expect(bag['oak_log'], 2);
      expect(bag['copper_spear'], 3);
    });

    test('a queued craft with too few materials counts only the crafts they '
        'allow', () {
      final s = at({'copper_ore': 12})
        ..activity = RunningActivity(mining)
        ..queue.add(const PlannedAction(sword, StopCondition.untilCrafted(5)));
      final bag = game.bagAfterQueue(s);
      expect(bag['copper_ore'], 2);
      expect(bag['copper_sword'], 2);
    });

    test('criterion 16: a queued gather "Until I have 20 Copper ore" raises it '
        'to at least 20', () {
      GameState queued(int ore) => at({'copper_ore': ore})
        ..activity = RunningActivity(sword)
        ..queue.add(
          const PlannedAction(
            mining,
            StopCondition.untilHave('copper_ore', 20),
          ),
        );
      // The current craft "Never stop" uses all the ore it can first.
      expect(game.bagAfterQueue(queued(3))['copper_ore'], 20);
      expect(game.bagAfterQueue(queued(29))['copper_ore'], 20);
    });

    test('criterion 17: a queued gather "Until grey" or "Never stop" leaves '
        'the bag as it is', () {
      for (final stop in const [
        StopCondition.untilGrey(),
        StopCondition.never(),
      ]) {
        final s = at({'copper_ore': 4})
          ..activity = RunningActivity(
            sword,
            stop: const StopCondition.untilCrafted(1),
          )
          ..queue.add(PlannedAction(mining, stop));
        expect(game.bagAfterQueue(s)['copper_ore'], 4, reason: '$stop');
      }
    });

    test('criterion 18: a queued craft "Until a quality" uses all the crafts '
        'its materials allow', () {
      final s = at({'copper_ore': 23})
        ..activity = RunningActivity(mining)
        ..queue.add(
          const PlannedAction(sword, StopCondition.untilQuality('rare')),
        );
      final bag = game.bagAfterQueue(s);
      expect(bag['copper_ore'], 3);
      expect(bag['copper_sword'], 4);
    });

    test('criterion 19: the current action counts only its crafts still to '
        'come', () {
      final s = at({'copper_ore': 20})
        ..activity = RunningActivity(
          sword,
          stop: const StopCondition.untilCrafted(5),
          crafted: 2,
        );
      final bag = game.bagAfterQueue(s);
      expect(bag['copper_ore'], 5);
      expect(bag['copper_sword'], 3);
    });

    test('criterion 20: a queued reroll lowers its dust by 3', () {
      const key = 'bone_sword@uncommon+crit2';
      final s = at({key: 1, 'uncommon_dust': 7})
        ..activity = RunningActivity(mining)
        ..queue.add(
          const PlannedAction(
            Activity.reroll(key),
            StopCondition.untilCrafted(1),
          ),
        );
      expect(game.bagAfterQueue(s)['uncommon_dust'], 7 - game.data.rerollDust);
    });

    test('a travel action changes nothing in the bag', () {
      final s = at({'copper_ore': 6})
        ..activity = RunningActivity(const Activity.travel('goblin_woods'))
        ..queue.add(
          const PlannedAction(
            Activity.travel('copper_hills'),
            StopCondition.never(),
          ),
        );
      expect(game.bagAfterQueue(s)['copper_ore'], 6);
    });

    test('criterion 21: the count never changes the state', () {
      final s = at({'copper_ore': 20, 'oak_log': 5})
        ..activity = RunningActivity(
          sword,
          stop: const StopCondition.untilCrafted(2),
        )
        ..queue.add(const PlannedAction(spear, StopCondition.untilCrafted(3)));
      final before = jsonEncode(s.toJson());
      game.bagAfterQueue(s);
      expect(jsonEncode(s.toJson()), before);
    });
  });
}
