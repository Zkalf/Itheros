// Step economy: spec 0001 §2.2 allocation rule and the §2.3 worked examples.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();

  group('spec §2.3 worked examples', () {
    test('fighting, bank 0, 100 steps: 100 activity steps, bank 0', () {
      var s = stateAt(game, location: 'goblin_woods');
      s = game.startActivity(s, const Activity.fight('goblin'));

      final r = game.applySteps(s, 100);

      expect(r.activitySteps, 100);
      expect(r.boostUsed, 0);
      expect(r.state.stepBank, 0);
      expect(r.state.activity, isNotNull, reason: 'still fighting');
    });

    test('fighting, bank 50, 100 steps: 150 activity steps, bank 0', () {
      var s = stateAt(game, location: 'goblin_woods', stepBank: 50);
      s = game.startActivity(s, const Activity.fight('goblin'));

      final r = game.applySteps(s, 100);

      expect(r.activitySteps, 150);
      expect(r.boostUsed, 50);
      expect(r.state.stepBank, 0);
    });

    test('idle, bank 9,900, cap 10,000, 300 steps: bank 10,000, 200 lost', () {
      final s = stateAt(game, stepBank: 9900);
      expect(game.bankCap(s), 10000);

      final r = game.applySteps(s, 300);

      expect(r.banked, 100);
      expect(r.lost, 200);
      expect(r.state.stepBank, 10000);
    });

    test('crafting the last sword: done after 150 steps, ends, bank +250', () {
      var s = stateAt(game, level: 3, inventory: {'copper_ore': 5});
      s = game.startActivity(s, const Activity.craft('copper_sword'));

      final r = game.applySteps(s, 400);

      expect(r.state.inventory['copper_sword'], 1);
      expect(r.state.inventory['copper_ore'] ?? 0, 0);
      expect(r.state.activity, isNull);
      expect(r.activitySteps, 150);
      expect(r.banked, 250);
      expect(r.state.stepBank, 250);
      expect(
        r.events.whereType<ActivityEnded>().single.reason,
        EndReason.noMaterials,
      );
    });
  });

  test('banked steps are not spent while idle', () {
    final r = game.applySteps(stateAt(game, stepBank: 500), 100);
    expect(r.boostUsed, 0);
    expect(r.state.stepBank, 600);
  });

  test('steps walked are counted whether idle or active', () {
    var s = stateAt(game, location: 'goblin_woods');
    s = game.applySteps(s, 30).state;
    s = game.startActivity(s, const Activity.fight('goblin'));
    s = game.applySteps(s, 70).state;
    expect(s.counters['steps.walked'], 100);
  });

  test('applying steps in chunks equals applying them at once', () {
    var start = stateAt(game, stepBank: 300, seed: 7);
    start = game.startActivity(start, const Activity.travel('goblin_woods'));

    GameState run(List<int> chunks) {
      var s = start;
      for (final n in chunks) {
        s = game.applySteps(s, n).state;
        if (s.activity == null && s.location == 'goblin_woods') {
          s = game.startActivity(s, const Activity.fight('goblin'));
        }
      }
      return s;
    }

    // Travel ends exactly at a chunk boundary in both runs (200 steps with
    // the boost = 100 walked), so the restart happens at the same step.
    final once = run([100, 2000]);
    final chunked = run([100, 1, 7, 250, 742, 1000]);
    expect(chunked.toJson(), once.toJson());
  });

  // The engine reuses a unit's cost from step to step (run.dart). A walk in
  // one call must still match the same walk step by step, where nothing is
  // reused, when the cost changes on the way: here the meal ends inside a
  // unit (a boar stew takes steps off a cast) and the bag fills over its
  // spaces.
  test('a walk whose unit cost changes on the way equals the same walk '
      'step by step', () {
    final data = game.data;
    // A full bag of things the lake does not give: the first catch
    // overloads it.
    final lake = data.nodes['lake_shore']!;
    final catches = {
      lake.item,
      lake.rareFind,
      for (final c in lake.catches) c.item,
    };
    final materials = [
      for (final i in data.items.values)
        if (data.kindOf(i.id) == ItemKind.material && !catches.contains(i.id))
          i.id,
    ];
    var start = stateAt(
      game,
      location: 'mirror_lake',
      seed: 3,
      inventory: {for (final id in materials.take(40)) id: 1},
    )..inventory['boar_stew'] = 1;
    start = game.eat(start, 'boar_stew')..meal!.left = 250;
    start = game.startActivity(start, const Activity.gather('lake_shore'));
    final costs = {game.unitCost(start)};

    final once = game.applySteps(start, 1200).state;
    var stepped = start;
    for (var i = 0; i < 1200; i++) {
      stepped = game.applySteps(stepped, 1).state;
      costs.add(game.unitCost(stepped));
    }

    expect(stepped.toJson(), once.toJson());
    expect(once.meal, isNull, reason: 'the meal ended on the way');
    expect(game.overloaded(once), isTrue, reason: 'the bag filled');
    expect(costs.length, greaterThan(2), reason: 'the cost changed twice');
  });

  test('applySteps does not modify its input state', () {
    final s = stateAt(game, stepBank: 10);
    final before = s.toJson();
    game.applySteps(s, 50);
    expect(s.toJson(), before);
  });
}
