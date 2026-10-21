// The report counts items by item and quality, not by their bonus stats:
// list rows show none (spec 0009 §8.2).
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/sync/away_summary.dart';

void main() {
  test('two rare swords with different rolls are one line of 2', () {
    const craft = Activity.craft('copper_sword');
    final summary = AwaySummary.fromReports([
      StepReport(
        state: GameState(location: 'camp', rngState: 1),
        walked: 300,
        activitySteps: 300,
        boostUsed: 0,
        banked: 0,
        lost: 0,
        events: const [
          Crafted('copper_sword@rare+crit2+hp5', 30),
          Crafted('copper_sword@rare+hp8+hp4', 30),
          Crafted('copper_sword', 30),
          ActivityEnded(craft, EndReason.enough),
        ],
      ),
    ]);
    expect(summary.actions.single.items, {
      'copper_sword@rare': 2,
      'copper_sword': 1,
    });
  });
}
