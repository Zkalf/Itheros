// A journal entry with every kind of report line survives the save
// (spec 0004 criterion 1).
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/sync/away_summary.dart';

void main() {
  final entry = JournalEntry(
    started: DateTime(2026, 10, 18, 14, 5),
    testWalk: true,
    summary: const AwaySummary(
      walked: 2000,
      activitySteps: 1800,
      boostUsed: 900,
      banked: 200,
      lost: 10,
      levelsReached: [5, 6],
      achievements: ['marathon'],
      actions: [
        ActionLog(
          Activity.fight('zombie'),
          wins: 4,
          xp: 120,
          items: {'grave_cloth': 3},
          losses: [FightLost('zombie', 37, 0.8)],
          ended: EndReason.defeated,
          next: Activity.craft('bone_shield'),
        ),
        ActionLog(
          Activity.craft('bone_shield'),
          skipped: SkipReason.noMaterials,
          missing: {'bones': 2},
        ),
      ],
    ),
  );

  test('every line comes back the same', () {
    final back = JournalEntry.fromJson(entry.toJson());
    expect(back.toJson(), entry.toJson());
    final fight = back.summary.actions.first;
    expect(fight.losses.single.share, 0.8);
    expect(fight.ended, EndReason.defeated);
    expect(fight.next, const Activity.craft('bone_shield'));
    expect(back.summary.actions.last.missing, {'bones': 2});
  });

  test('an end or skip reason this version does not know still loads', () {
    final json = entry.toJson();
    final actions =
        (json['summary']! as Map<String, Object?>)['actions']! as List<Object?>;
    (actions[0]! as Map<String, Object?>)['ended'] = 'renamed';
    (actions[1]! as Map<String, Object?>)['skipped'] = 'renamed';
    final back = JournalEntry.fromJson(json);
    expect(back.summary.walked, 2000);
  });
}
