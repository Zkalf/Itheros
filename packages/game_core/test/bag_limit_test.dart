// The bag limit: spec 0021 criteria 1-29 and 37-39 (plan 0041 M1). The
// screens (criteria 30-36) are in the app's tests; the sim targets
// (criteria 40-41) are in tool/bag.dart and the pacing test.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;
  const vest = 'hide_vest@rare+hp10';
  const used = {'copper_ore', 'perch', 'rare_dust', 'hide_vest', 'goblin_hide'};

  /// [n] kinds of item that the tests do not use, one of each.
  Map<String, int> filler(int n) {
    final keys = [
      for (final id in data.items.keys)
        if (!used.contains(id)) id,
    ];
    return {for (final k in keys.take(n)) k: 1};
  }

  /// At [location] with [kinds] filler kinds plus [bag] in the bag.
  GameState at(
    String location, {
    int kinds = 0,
    Map<String, int> bag = const {},
    int level = 12,
  }) => stateAt(
    game,
    location: location,
    level: level,
    inventory: {...filler(kinds), ...bag},
  );

  int cost(GameState s, Activity a) =>
      game.unitCost(game.startActivity(s, a))!;

  int times(int steps, double f) => (steps * f - 1e-9).ceil();

  group('spaces', () {
    test('criterion 1: 40 kinds in 40 spaces is not overloaded', () {
      final s = at('camp', kinds: 40);
      expect(game.spacesUsed(s), 40);
      expect(game.bagSpaces(s), 40);
      expect(game.overloaded(s), isFalse);
      expect(game.overload(s), 0);
    });

    test('criterion 2: 41 kinds in 40 spaces is overloaded', () {
      final s = at('camp', kinds: 41);
      expect(game.overloaded(s), isTrue);
      expect(game.overload(s), closeTo(0.05, 1e-9));
    });

    test('criterion 3: a kind with a count of 40 uses one space', () {
      expect(game.spacesUsed(at('camp', bag: {'copper_ore': 40})), 1);
    });

    test('criterion 4: two rolls of the same gear use two spaces', () {
      final s = at('camp', bag: {vest: 1, 'hide_vest@rare+hp9': 1});
      expect(game.spacesUsed(s), 2);
    });

    test('criterion 5: worn gear and worn tools use no space', () {
      final s = at('camp')..equipment['body'] = vest;
      expect(s.tools, isNotEmpty);
      expect(game.spacesUsed(s), 0);
    });

    test('criterion 6: items in the bank use no space', () {
      final s = at('camp')..itemBank.addAll(filler(50));
      expect(game.spacesUsed(s), 0);
      expect(game.overloaded(s), isFalse);
    });

    test('criterion 7: an unopened supply chest uses no space', () {
      final s = at('camp')
        ..supplyChests.add(SupplyChest('2026-01-01', filler(50)));
      expect(game.spacesUsed(s), 0);
    });

    test('criterion 8: the spaces come from bag.spaces in economy.json', () {
      final economy = dataJson('economy');
      expect((economy['bag']! as Map)['spaces'], 40);
      final small = newTestGame(
        overrides: {
          'economy': {
            ...economy,
            'bag': {...economy['bag']! as Map, 'spaces': 5},
          },
        },
      );
      expect(small.data.bagSpaces, 5);
      expect(small.bagSpaces(stateAt(small)), 5);
    });
  });

  group('nothing is lost', () {
    test('criterion 9: loot goes into a bag over its spaces', () {
      var s = at('goblin_woods', kinds: 50);
      s = game.startActivity(s, const Activity.fight('goblin'));
      final before = s.inventory.values.fold(0, (a, b) => a + b);
      s = game.applySteps(s, 3000).state;
      final after = s.inventory.values.fold(0, (a, b) => a + b);
      expect(after, greaterThan(before));
    });

    test('criterion 10: a craft and a cook fill a bag over its spaces', () {
      var s = at('camp', kinds: 50, bag: {'copper_ore': 5, 'perch': 2});
      s = game.startActivity(
        s,
        const Activity.craft('copper_sword'),
        stop: const StopCondition.untilCrafted(1),
      );
      s = game.applySteps(s, 1000).state;
      expect(game.owned(s, 'copper_sword'), 1);
      s = game.startActivity(
        s,
        const Activity.craft('grilled_perch'),
        stop: const StopCondition.untilCrafted(1),
      );
      s = game.applySteps(s, 1000).state;
      expect(game.owned(s, 'grilled_perch'), 1);
    });

    test('criterion 11: a supply chest opens into a bag over its spaces', () {
      final s = at('camp', kinds: 50)
        ..supplyChests.add(SupplyChest('2026-01-01', {'copper_ore': 3}));
      final r = game.openSupplyChest(s);
      expect(r.state.inventory['copper_ore'], 3);
    });

    test('criterion 12: a take from the bank works in a bag over', () {
      final s = at('camp', kinds: 50)..itemBank['copper_ore'] = 4;
      final t = game.take(s, 'copper_ore', 4);
      expect(t.inventory['copper_ore'], 4);
      expect(game.spacesUsed(t), 51);
    });
  });

  group('the step cost', () {
    // 3 spaces over: +15%.
    test('criterion 13: a fight round costs combatRoundSteps x 1.15', () {
      const a = Activity.fight('goblin');
      expect(cost(at('goblin_woods'), a), data.combatRoundSteps);
      expect(
        cost(at('goblin_woods', kinds: 43), a),
        times(data.combatRoundSteps, 1.15),
      );
    });

    test('criterion 14: a gathered item costs its steps x 1.15', () {
      const a = Activity.gather('copper_vein');
      final today = cost(at('copper_hills'), a);
      expect(cost(at('copper_hills', kinds: 43), a), times(today, 1.15));
    });

    test('criterion 15: a craft at Grey Moor costs its steps x 1.15', () {
      const a = Activity.craft('copper_sword');
      final today = cost(at('grey_moor', bag: {'copper_ore': 5}), a);
      expect(
        cost(at('grey_moor', kinds: 42, bag: {'copper_ore': 5}), a),
        times(today, 1.15),
      );
    });

    test('criterion 16: a reroll at Grey Moor costs its steps x 1.15', () {
      const a = Activity.reroll(vest);
      final bag = {vest: 1, 'rare_dust': data.rerollDust};
      final today = cost(at('grey_moor', bag: bag), a);
      expect(cost(at('grey_moor', kinds: 41, bag: bag), a), times(today, 1.15));
    });

    test('criterion 17: a travel leg costs its steps x 1.15', () {
      const a = Activity.travel('copper_hills');
      final today = cost(at('goblin_woods'), a);
      expect(cost(at('goblin_woods', kinds: 43), a), times(today, 1.15));
    });

    test('criterion 18: the leg out of Camp costs its steps x 1.15', () {
      const a = Activity.travel('goblin_woods');
      final today = cost(at('camp'), a);
      expect(today, 200);
      expect(cost(at('camp', kinds: 43), a), times(today, 1.15));
    });

    test('criterion 19: a craft at Camp costs no more', () {
      const a = Activity.craft('copper_sword');
      final today = cost(at('camp', bag: {'copper_ore': 5}), a);
      expect(cost(at('camp', kinds: 42, bag: {'copper_ore': 5}), a), today);
    });

    test('criterion 20: a cook at Camp costs no more', () {
      const a = Activity.craft('grilled_perch');
      final today = cost(at('camp', bag: {'perch': 2}), a);
      expect(cost(at('camp', kinds: 42, bag: {'perch': 2}), a), today);
    });

    test('criterion 21: a reroll at Camp costs no more', () {
      const a = Activity.reroll(vest);
      final bag = {vest: 1, 'rare_dust': data.rerollDust};
      final today = cost(at('camp', bag: bag), a);
      expect(cost(at('camp', kinds: 41, bag: bag), a), today);
    });

    test('criterion 22: 10 and 20 spaces over both add 50%', () {
      const a = Activity.fight('goblin');
      final top = times(data.combatRoundSteps, 1.5);
      expect(cost(at('goblin_woods', kinds: 50), a), top);
      expect(cost(at('goblin_woods', kinds: 60), a), top);
    });

    test('criterion 23: a bag not over its spaces costs the steps of today', () {
      const a = Activity.fight('goblin');
      expect(cost(at('goblin_woods', kinds: 40), a), data.combatRoundSteps);
    });

    test('criterion 24: a store that ends the overload lowers the cost', () {
      var s = game.startActivity(
        at('camp', kinds: 40, bag: {'copper_ore': 3}),
        const Activity.travel('goblin_woods'),
      );
      expect(game.unitCost(s), times(200, 1.05));
      s = game.store(s, 'copper_ore', 3);
      expect(game.unitCost(s), 200);
    });

    test('criterion 25: Swift strikes gives back the same steps', () {
      final light = at('goblin_woods')..talents['swift_strikes'] = 5;
      final heavy = at('goblin_woods', kinds: 50)
        ..talents['swift_strikes'] = 5;
      expect(game.fightStepsBack(light, 10), greaterThan(0));
      expect(game.fightStepsBack(heavy, 10), game.fightStepsBack(light, 10));
    });

    test('criterion 26: unitCost includes the overload', () {
      final s = game.startActivity(
        at('goblin_woods', kinds: 44),
        const Activity.fight('goblin'),
      );
      expect(game.unitCost(s), times(data.combatRoundSteps, 1.2));
    });
  });

  group('the talent', () {
    test('criterion 27: Bigger bag is in Utility row 1, column 2', () {
      final t = data.talents['bigger_bag']!;
      expect(t.tree, 'utility');
      expect(t.row, 1);
      expect(t.column, 2);
      expect(t.ranks, 5);
      expect(t.name, 'Bigger bag');
      expect(t.effect, TalentEffect.bagSpaces);
    });

    test('criterion 28: each rank adds 2 spaces', () {
      for (var r = 0; r <= 5; r++) {
        final s = at('camp')..talents['bigger_bag'] = r;
        expect(game.bagSpaces(s), 40 + 2 * r);
      }
      final full = at('camp', kinds: 50)..talents['bigger_bag'] = 5;
      expect(game.overload(full), 0);
    });

    test('criterion 29: a reset removes the spaces and keeps the items', () {
      final s = at(data.trainer.location, kinds: 48)
        ..talents['bigger_bag'] = 5;
      expect(game.overloaded(s), isFalse);
      final r = game.resetTalents(s);
      expect(game.bagSpaces(r), 40);
      expect(r.inventory, s.inventory);
      expect(game.overloaded(r), isTrue);
    });
  });

  group('save', () {
    test('criterion 37: the save version stays 16', () {
      expect(GameState.schemaVersion, 16);
    });

    test('criterion 38: a save with 45 kinds loads overloaded', () {
      final s = at('camp', kinds: 45);
      final loaded = GameState.fromJson(s.toJson());
      expect(loaded.inventory, s.inventory);
      expect(game.spacesUsed(loaded), 45);
      expect(game.overloaded(loaded), isTrue);
    });
    // Criterion 39 (every save fixture loads): app/test's fixture tests.
  });
}
