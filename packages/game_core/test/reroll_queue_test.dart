// A waiting reroll that can't start is skipped, with why (spec 0003 §1 and
// criterion 3): the queue must not stop when the dust runs out.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  const vest = 'hide_vest@rare+hp10';

  test('a waiting reroll without dust is skipped, with why', () {
    final need = game.data.rerollDust;
    // Dust for one reroll only; four more wait.
    var s = stateAt(game, level: 12, inventory: {vest: 1, 'rare_dust': need});
    s = game.startActivity(
      s,
      const Activity.reroll(vest),
      stop: const StopCondition.untilCrafted(1),
    );
    for (var i = 0; i < 4; i++) {
      s.queue.add(
        const PlannedAction(
          Activity.reroll(vest),
          StopCondition.untilCrafted(1),
        ),
      );
    }
    final r = game.applySteps(s, 1000);
    expect(r.state.activity, isNull);
    expect(r.state.queue, isEmpty);
    final skipped = r.events.whereType<ActionSkipped>().toList();
    expect(skipped, hasLength(4));
    for (final e in skipped) {
      expect(e.activity, const Activity.reroll(vest));
      expect(e.reason, SkipReason.noMaterials);
    }
  });
}
