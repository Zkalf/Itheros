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
      expect(r.state.bank, 0);
      expect(r.state.activity, isNotNull, reason: 'still fighting');
    });

    test('fighting, bank 50, 100 steps: 150 activity steps, bank 0', () {
      var s = stateAt(game, location: 'goblin_woods', bank: 50);
      s = game.startActivity(s, const Activity.fight('goblin'));

      final r = game.applySteps(s, 100);

      expect(r.activitySteps, 150);
      expect(r.boostUsed, 50);
      expect(r.state.bank, 0);
    });

    test('idle, bank 1,400, cap 1,500, 300 steps: bank 1,500, 200 lost', () {
      final s = stateAt(game, bank: 1400);
      expect(game.bankCap(s), 1500);

      final r = game.applySteps(s, 300);

      expect(r.banked, 100);
      expect(r.lost, 200);
      expect(r.state.bank, 1500);
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
      expect(r.state.bank, 250);
      expect(
        r.events.whereType<ActivityEnded>().single.reason,
        EndReason.noMaterials,
      );
    });
  });

  test('banked steps are not spent while idle', () {
    final r = game.applySteps(stateAt(game, bank: 500), 100);
    expect(r.boostUsed, 0);
    expect(r.state.bank, 600);
  });

  test('steps walked are counted whether idle or active', () {
    var s = stateAt(game, location: 'goblin_woods');
    s = game.applySteps(s, 30).state;
    s = game.startActivity(s, const Activity.fight('goblin'));
    s = game.applySteps(s, 70).state;
    expect(s.counters['steps.walked'], 100);
  });

  test('applying steps in chunks equals applying them at once', () {
    var start = stateAt(game, bank: 300, seed: 7);
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

  test('applySteps does not modify its input state', () {
    final s = stateAt(game, bank: 10);
    final before = s.toJson();
    game.applySteps(s, 50);
    expect(s.toJson(), before);
  });
}
