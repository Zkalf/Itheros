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

  // Spec 0010 §2.2, §5.1, §7.2-7.3: profession levels, rare finds and
  // rerolls are news in the report, and survive the journal.
  test('profession levels, finds and rerolls are news', () {
    final game = loadTestGame();
    const sword = 'bone_sword@rare+crit2+hp10';
    const legendary = 'iron_sword@legendary+crit2+crit1+hp11+hp10';
    final summary = AwaySummary.fromReports([
      StepReport(
        state: GameState(location: 'camp', rngState: 1),
        walked: 10,
        activitySteps: 10,
        boostUsed: 0,
        banked: 0,
        lost: 0,
        events: const [
          ProfessionLevelUp('mining', 2),
          ProfessionLevelUp('mining', 10),
          ProfessionLevelUp('crafting', 14),
          RareFound('garnet'),
          Rerolled(sword, 'bone_sword@epic+crit2+hp10+hit3'),
          Rerolled(sword, sword),
          Rerolled(legendary, '$legendary+~1.hit4'),
        ],
      ),
    ]);
    final back = AwaySummary.fromJson(summary.toJson());
    expect(back.isEventful, isTrue);
    final labels = Labels(game.data);
    expect(
      [for (final (p, l) in back.professionLevels) labels.professionLevel(p, l)],
      [
        'Reached Mining 2!',
        'Mining 10: the Iron vein is yours to work',
        'Crafting 14: new recipes',
      ],
    );
    expect([for (final f in back.finds) labels.rareFound(f)], [
      'Found a Garnet!',
    ]);
    expect(
      [for (final (a, b) in back.rerolls) labels.rerollNews(a, b)],
      [
        'Bone sword reroll: Rare → Epic',
        'Bone sword reroll: stays Rare',
        'Iron sword: new roll ready at the forge',
      ],
    );
  });

  test('a journal entry from before spec 0010 still loads', () {
    final json = const AwaySummary(walked: 5).toJson()
      ..remove('professionLevels')
      ..remove('finds')
      ..remove('rerolls');
    final back = AwaySummary.fromJson(json);
    expect(back.professionLevels, isEmpty);
    expect(back.rerolls, isEmpty);
  });

  // Spec 0010 §7.1: salvage is instant, so its news is a message at once.
  test('salvage names the dust and a shard with how many are held', () {
    final game = loadTestGame();
    final labels = Labels(game.data);
    final s = GameState(location: 'camp', rngState: 1)
      ..inventory.addAll({'common_dust': 1, 'kings_shard': 3});
    expect(
      labels.salvaged(
        'bone_sword',
        SalvageResult(s, 'common_dust', 'kings_shard'),
      ),
      'Salvaged the Bone sword: Common dust. '
      'Found a Shard of the Graveyard King (3 of 10)!',
    );
    expect(
      labels.salvaged('bone_sword', SalvageResult(s, 'common_dust', null)),
      'Salvaged the Bone sword: Common dust.',
    );
  });
}
