// The report counts items by item and quality, not by their bonus stats:
// list rows show none (spec 0009 §8.2).
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/sync/away_summary.dart';
import 'package:walkingrpg/ui/labels.dart';

import 'support.dart';

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

  // Spec 0009 §7.1–§7.2: the bestiary and lore news reach the report and
  // survive the journal.
  test('lore notes, weakness learned and Slayer are news', () {
    final game = loadTestGame();
    final note = game.data.enemies['zombie']!.lore!.id;
    final summary = AwaySummary.fromReports([
      StepReport(
        state: GameState(location: 'camp', rngState: 1),
        walked: 10,
        activitySteps: 10,
        boostUsed: 0,
        banked: 0,
        lost: 0,
        events: [
          LoreFound(note),
          const WeaknessLearned('goblin'),
          const SlayerEarned('goblin'),
        ],
      ),
    ]);
    final back = AwaySummary.fromJson(summary.toJson());
    expect(back.lore, [note]);
    expect(back.learned, ['goblin']);
    expect(back.slayers, ['goblin']);
    expect(back.isEventful, isTrue);
    final labels = Labels(game.data);
    expect(labels.loreFound(note), "Found a lore note: The King's armour");
    expect(labels.weaknessLearned('goblin'), 'Goblin: weakness learned');
    expect(labels.slayerEarned('goblin'), 'Slayer: Goblin');
  });

  test('a journal entry from before spec 0009 still loads', () {
    final json = const AwaySummary(walked: 5).toJson()
      ..remove('lore')
      ..remove('learned')
      ..remove('slayers');
    expect(AwaySummary.fromJson(json).lore, isEmpty);
  });
}
