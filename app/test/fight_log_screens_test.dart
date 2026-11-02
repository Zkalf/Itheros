// The fight log in the app: spec 0019 criteria 8-34 (plan 0039): the Now
// screen during a fight, the fight sheet and the look of the swings. The
// rules (criteria 1-7, 35-36) are in game_core's fight_log_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/ui/theme.dart';

import 'ui_test.dart';

void main() {
  FightSummary won(int number, int rounds, {int taken = 0, int crits = 0}) =>
      FightSummary(
        number: number,
        outcome: FightOutcome.won,
        rounds: rounds,
        taken: taken,
        crits: crits,
      );

  FightSummary lost(int number, int rounds, {int taken = 0}) => FightSummary(
    number: number,
    outcome: FightOutcome.lost,
    rounds: rounds,
    taken: taken,
    crits: 0,
  );

  /// A running fight against [enemy] with [fights] and the round log [log];
  /// [won] and [lost] are the action's tally.
  void Function(GameState) fight({
    String enemy = 'goblin',
    List<FightSummary> fights = const [],
    List<RoundLog> log = const [],
    int won = 0,
    int lost = 0,
  }) =>
      (s) => s.activity = RunningActivity(
        Activity.fight(enemy),
        fight: FightState(playerHp: 20, enemyHp: 10, round: log.length),
        won: won,
        lost: lost,
        fights: [...fights],
        log: [...log],
      );

  /// Rounds 1 to [n] in which the player hits for 4 and the Goblin misses.
  List<RoundLog> plain(int n, {int from = 1}) => [
    for (var i = from; i < from + n; i++)
      RoundLog(
        round: i,
        dealt: 4,
        taken: 0,
        mine: Swing.hit,
        theirs: Swing.miss,
      ),
  ];

  Future<void> openSheet(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('fight-details')));
    await t.pumpAndSettle();
  }

  TextStyle? styleOf(WidgetTester t, String text) =>
      t.widget<Text>(find.text(text)).style;

  group('the Now screen', () {
    testWidgets('criterion 8: no round lines during a fight', (t) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        prepare: fight(log: plain(3)),
      );
      expect(find.textContaining('Round '), findsNothing);
      expect(find.textContaining('You hit for'), findsNothing);
    });

    testWidgets('criterion 9: after a won fight', (t) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        prepare: fight(fights: [won(1, 4)], won: 1),
      );
      expect(
        find.text('Last fight: Goblin beaten in 4 rounds'),
        findsOneWidget,
      );
    });

    testWidgets('criterion 10: after a lost fight', (t) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        prepare: fight(fights: [lost(1, 6)], lost: 1),
      );
      expect(
        find.text('Last fight: beaten by the Goblin in 6 rounds'),
        findsOneWidget,
      );
    });

    testWidgets('criterion 11: a fight of one round reads "1 round"', (
      t,
    ) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        prepare: fight(fights: [won(1, 1)], won: 1),
      );
      expect(find.text('Last fight: Goblin beaten in 1 round'), findsOneWidget);
    });

    testWidgets('criterion 12: Fight details shows once the action has a '
        'round or a summary', (t) async {
      await pumpGame(t, location: 'goblin_woods', prepare: fight());
      expect(find.byKey(const ValueKey('fight-details')), findsNothing);
    });

    testWidgets('criterion 12: Fight details shows with a round', (t) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        prepare: fight(log: plain(1)),
      );
      expect(find.byKey(const ValueKey('fight-details')), findsOneWidget);
      expect(find.text('Fight details'), findsOneWidget);
    });

    testWidgets('criterion 13: a tap on Fight details opens the sheet', (
      t,
    ) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        prepare: fight(log: plain(1)),
      );
      await openSheet(t);
      expect(find.byKey(const ValueKey('fight-sheet')), findsOneWidget);
    });
  });

  group('the fight sheet', () {
    testWidgets('criteria 14-21: the title and the last fights', (t) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        prepare: fight(
          fights: [
            won(3, 4, taken: 9, crits: 1),
            lost(4, 6, taken: 30),
            won(5, 3, crits: 2),
          ],
          won: 4,
          lost: 1,
          log: plain(1),
        ),
      );
      await openSheet(t);
      expect(find.text('Fights: Goblin'), findsOneWidget);
      expect(find.text('Last fights'), findsOneWidget);
      const first = 'Fight 3 · beaten in 4 rounds · took 9 damage · 1 crit';
      const second = 'Fight 4 · you are beaten in 6 rounds · took 30 damage';
      const third = 'Fight 5 · beaten in 3 rounds · took no damage · 2 crits';
      expect(find.text(first), findsOneWidget);
      expect(find.text(second), findsOneWidget);
      expect(find.text(third), findsOneWidget);
      // The oldest at the top (criterion 15).
      expect(
        t.getTopLeft(find.text(first)).dy,
        lessThan(t.getTopLeft(find.text(second)).dy),
      );
      expect(
        t.getTopLeft(find.text(second)).dy,
        lessThan(t.getTopLeft(find.text(third)).dy),
      );
      // A check mark for a won fight, a cross for a lost one (criterion 21).
      final check = t.widget<Icon>(find.byKey(const ValueKey('fight-won-3')));
      expect(check.icon, Icons.check);
      expect(check.color, Quiet.met);
      final cross = t.widget<Icon>(find.byKey(const ValueKey('fight-lost-4')));
      expect(cross.icon, Icons.close);
      expect(cross.color, Quiet.short);
    });

    testWidgets('criteria 22-23: round by round, round 1 at the top', (
      t,
    ) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        prepare: fight(won: 3, lost: 1, log: plain(3)),
      );
      await openSheet(t);
      expect(find.text('Fight 5, round by round'), findsOneWidget);
      expect(
        t.getTopLeft(find.text('Round 1')).dy,
        lessThan(t.getTopLeft(find.text('Round 2')).dy),
      );
      expect(
        t.getTopLeft(find.text('Round 2')).dy,
        lessThan(t.getTopLeft(find.text('Round 3')).dy),
      );
      expect(styleOf(t, 'Round 1')?.color, Quiet.faint);
    });

    testWidgets('criterion 24: a quick monster swings first in its row', (
      t,
    ) async {
      await pumpGame(
        t,
        location: 'grey_moor',
        level: 12,
        prepare: fight(
          enemy: 'wolf',
          log: [
            const RoundLog(
              round: 1,
              dealt: 4,
              taken: 3,
              mine: Swing.hit,
              theirs: Swing.hit,
            ),
          ],
        ),
      );
      await openSheet(t);
      expect(
        t.getTopLeft(find.text('Wolf hits you for 3')).dx,
        lessThan(t.getTopLeft(find.text('You hit for 4')).dx),
      );
    });

    testWidgets('criterion 25: the last row of an ended fight says who was '
        'beaten', (t) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        prepare: fight(
          won: 1,
          fights: [won(1, 2)],
          log: [
            ...plain(1),
            const RoundLog(
              round: 2,
              dealt: 4,
              mine: Swing.hit,
              outcome: FightOutcome.won,
            ),
          ],
        ),
      );
      await openSheet(t);
      expect(find.text('Fight 1, round by round'), findsOneWidget);
      expect(find.text('Goblin is beaten'), findsOneWidget);
    });

    testWidgets('criterion 26: a fight longer than the round log', (t) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        prepare: fight(log: plain(50, from: 11)),
      );
      await openSheet(t);
      expect(find.text('Earlier rounds are not kept'), findsOneWidget);
    });

    testWidgets('criterion 26: no such line for a whole fight', (t) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        prepare: fight(log: plain(3)),
      );
      await openSheet(t);
      expect(find.text('Earlier rounds are not kept'), findsNothing);
    });

    testWidgets('criterion 27: the sheet opens at the bottom', (t) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        prepare: fight(
          fights: [for (var i = 1; i <= 10; i++) won(i, 4)],
          won: 10,
          log: plain(50, from: 11),
        ),
      );
      // The Fairphone: 408 × 900 dp.
      t.view.physicalSize = const Size(1224, 2700);
      t.view.devicePixelRatio = 3;
      await t.pumpAndSettle();
      await openSheet(t);
      expect(find.text('Round 60').hitTestable(), findsOneWidget);
      expect(find.text('Round 11').hitTestable(), findsNothing);
    });

    testWidgets('criterion 28: a fight that ends while the sheet is open '
        'shows in it', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods', level: 3);
      await c.startActivity(const Activity.fight('goblin'));
      await settle(t, c);
      await c.testWalk(c.game.data.combatRoundSteps);
      await settle(t, c);
      await t.pumpAndSettle();
      await openSheet(t);
      expect(find.textContaining('Fight 1 ·'), findsNothing);
      while (c.state.activity!.won + c.state.activity!.lost == 0) {
        await c.testWalk(c.game.data.combatRoundSteps);
        await settle(t, c);
      }
      await t.pumpAndSettle();
      expect(find.textContaining('Fight 1 ·'), findsOneWidget);
    });
  });

  group('the look of the swings', () {
    final log = [
      const RoundLog(
        round: 1,
        dealt: 14,
        taken: 3,
        mine: Swing.crit,
        theirs: Swing.hit,
      ),
      const RoundLog(
        round: 2,
        dealt: 4,
        taken: 1,
        mine: Swing.hit,
        theirs: Swing.block,
      ),
      const RoundLog(round: 3, dealt: 0, mine: Swing.miss, theirs: Swing.dodge),
      const RoundLog(
        round: 4,
        dealt: 0,
        taken: 0,
        mine: Swing.dodge,
        theirs: Swing.miss,
      ),
      const RoundLog(round: 5, dealt: 6, mine: Swing.hit),
    ];

    Future<void> open(WidgetTester t) async {
      await pumpGame(
        t,
        location: 'goblin_woods',
        prepare: fight(log: log),
      );
      await openSheet(t);
    }

    testWidgets('criterion 29: a crit is bright, bold and larger', (t) async {
      await open(t);
      final crit = styleOf(t, 'Critical hit for 14')!;
      final hit = styleOf(t, 'You hit for 4')!;
      expect(crit.color, Quiet.risky);
      expect(crit.fontWeight, FontWeight.bold);
      expect(crit.fontSize, greaterThan(hit.fontSize!));
    });

    testWidgets('criterion 30: a block is steel', (t) async {
      await open(t);
      expect(styleOf(t, 'You block: 1 damage')?.color, Quiet.steel);
    });

    testWidgets('criterion 31: a dodge is teal, on either side', (t) async {
      await open(t);
      expect(styleOf(t, 'You dodge')?.color, Quiet.teal);
      expect(styleOf(t, 'Goblin dodges')?.color, Quiet.teal);
    });

    testWidgets('criterion 32: a miss is faint, on either side', (t) async {
      await open(t);
      expect(styleOf(t, 'You miss')?.color, Quiet.faint);
      expect(styleOf(t, 'Goblin misses')?.color, Quiet.faint);
    });

    testWidgets('criterion 33: a hit on the player is red', (t) async {
      await open(t);
      expect(styleOf(t, 'Goblin hits you for 3')?.color, Quiet.short);
    });

    testWidgets('criterion 34: a hit for a quarter of the full HP is bold', (
      t,
    ) async {
      await open(t);
      // The Goblin has 19 HP: 6 is more than a quarter, 4 is less.
      expect(styleOf(t, 'You hit for 6')?.fontWeight, FontWeight.bold);
      expect(styleOf(t, 'You hit for 4')?.fontWeight, isNot(FontWeight.bold));
      expect(styleOf(t, 'You hit for 4')?.color, Quiet.text);
    });
  });
}
