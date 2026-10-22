import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/ui/labels.dart';

import 'support.dart';

void main() {
  final labels = Labels(loadTestGame().data);

  test('the fight log shows the newest round first, a line between fights', () {
    const log = [
      RoundLog(round: 5, dealt: 9, mine: Swing.hit),
      RoundLog(
        round: 6,
        dealt: 18,
        mine: Swing.crit,
        outcome: FightOutcome.won,
      ),
      RoundLog(round: 1, taken: 3, mine: Swing.miss, theirs: Swing.hit),
      RoundLog(round: 2, dealt: 8, mine: Swing.hit),
    ];
    expect(labels.fightLog(log, 'goblin'), [
      'Round 2: You hit for 8',
      'Round 1: You miss',
      'Goblin hits you for 3',
      newFight,
      'Round 6: Critical hit for 18',
      'Goblin is beaten',
      'Round 5: You hit for 9',
    ]);
  });

  test('one fight has no line', () {
    const log = [
      RoundLog(round: 1, dealt: 4, mine: Swing.hit),
      RoundLog(round: 2, dealt: 5, mine: Swing.hit),
    ];
    expect(labels.fightLog(log, 'goblin'), [
      'Round 2: You hit for 5',
      'Round 1: You hit for 4',
    ]);
  });
}
