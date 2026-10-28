// A change of the stop condition of an action: spec 0016 amendment 2,
// criteria 4, 9, 11-16 and 18-21.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  const goblins = Activity.fight('goblin');
  const sword = Activity.craft('copper_sword');
  const hides = StopCondition.untilHave('goblin_hide', 99);

  Matcher refused(String message) => throwsA(
    isA<ActivityError>().having((e) => e.message, 'message', message),
  );

  /// Fights goblins until 99 hides, with a second fight waiting.
  GameState twoFights() {
    var s = stateAt(game, location: 'goblin_woods');
    s = game.addAction(s, goblins, stop: hides);
    return game.addAction(s, goblins, stop: hides);
  }

  group('the change (criteria 11-16)', () {
    test('the current action gets the new stop condition and keeps its '
        'steps and its fight', () {
      // 25 steps: two rounds of 10 and 5 steps toward the third.
      var s = game.applySteps(twoFights(), 25).state;
      expect(s.activity!.fight, isNotNull, reason: 'fight under way');
      final fight = s.activity!.fight!.toJson();
      const stop = StopCondition.untilHave('goblin_hide', 50);

      s = game.changeStop(s, 0, stop);

      expect(s.activity!.activity, goblins);
      expect(s.activity!.stop, stop);
      expect(s.activity!.progress, 5);
      expect(s.activity!.fight!.toJson(), fight);
      expect(s.queue, hasLength(1), reason: 'the queue keeps its order');
    });

    test('a waiting action gets the new stop condition in its place', () {
      var s = twoFights();
      s = game.addAction(s, goblins, stop: hides);
      const stop = StopCondition.untilHave('goblin_hide', 40);

      s = game.changeStop(s, 1, stop);

      expect(s.queue.map((p) => p.stop), [stop, hides]);
      expect(s.queue.map((p) => p.activity), [goblins, goblins]);
    });

    test('"Until N crafted" counts the items crafted before the change', () {
      var s = stateAt(game, level: 3, inventory: {'copper_ore': 50});
      s = game.startActivity(s, sword, stop: StopCondition.untilCrafted(10));
      s = game.applySteps(s, 3 * 150 + 20).state;
      expect(s.activity!.crafted, 3);

      s = game.changeStop(s, 0, const StopCondition.untilCrafted(5));
      expect(s.activity!.crafted, 3);
      expect(s.activity!.progress, 20);

      final r = game.applySteps(s, 2 * 150 - 20);
      expect(r.state.activity, isNull, reason: '5 crafted in all');
      expect(
        r.events.whereType<ActivityEnded>().single.reason,
        EndReason.enough,
      );
      expect(game.owned(r.state, 'copper_sword'), 5);
    });

    test('no steps go to the bank when the goal is not reached', () {
      var s = game.applySteps(twoFights(), 25).state;
      final bank = s.bank;
      s = game.changeStop(
        s,
        0,
        const StopCondition.untilHave('goblin_hide', 50),
      );
      expect(s.bank, bank);
    });

    test('the change leaves the state it was given as it was', () {
      final s = twoFights();
      game.changeStop(s, 0, const StopCondition.untilHave('goblin_hide', 7));
      expect(s.activity!.stop, hides);
    });
  });

  group('refusals (criteria 4 and 9)', () {
    test('"Never" for an action with another action after it', () {
      final s = twoFights();
      expect(
        () => game.changeStop(s, 0, const StopCondition.never()),
        refused('Only the last action can go on without a stop.'),
      );
    });

    test('"Never" for the last action is fine', () {
      final s = game.changeStop(twoFights(), 1, const StopCondition.never());
      expect(s.queue.single.stop, const StopCondition.never());
    });

    test('a walk', () {
      final s = game.addAction(stateAt(game, level: 5), goblins, stop: hides);
      expect(s.activity!.activity.kind, ActivityKind.travel);
      expect(
        () => game.changeStop(s, 0, const StopCondition.never()),
        refused('A walk ends when it arrives.'),
      );
    });

    test('an index that names no action', () {
      expect(
        () => game.changeStop(twoFights(), 2, hides),
        refused('No action 2 in the queue'),
      );
    });

    test('a stop condition that does not fit the action', () {
      expect(
        () => game.changeStop(
          twoFights(),
          0,
          const StopCondition.untilCrafted(3),
        ),
        refused('That stop condition is not possible here.'),
      );
    });
  });

  group('a goal that is already reached (criteria 18-21)', () {
    test('stopReached is true for a reached goal, false otherwise', () {
      final s = stateAt(
        game,
        location: 'goblin_woods',
        inventory: {'goblin_hide': 4},
      );
      final q = game.addAction(
        game.addAction(s, goblins, stop: hides),
        goblins,
        stop: hides,
      );
      const four = StopCondition.untilHave('goblin_hide', 4);
      const five = StopCondition.untilHave('goblin_hide', 5);
      expect(game.stopReached(q, 0, four), isTrue);
      expect(game.stopReached(q, 0, five), isFalse);
      expect(game.stopReached(q, 1, four), isTrue);
      expect(game.stopReached(q, 1, five), isFalse);
    });

    test('stopReached counts what the current action crafted', () {
      var s = stateAt(game, level: 3, inventory: {'copper_ore': 50});
      s = game.startActivity(s, sword, stop: StopCondition.untilCrafted(10));
      s = game.applySteps(s, 3 * 150).state;
      expect(
        game.stopReached(s, 0, const StopCondition.untilCrafted(3)),
        isTrue,
      );
      expect(
        game.stopReached(s, 0, const StopCondition.untilCrafted(4)),
        isFalse,
      );
    });

    test('the current action ends with "enough", banks its steps and the '
        'next action starts', () {
      var s = game.applySteps(twoFights(), 9).state;
      expect(s.activity!.fight, isNull, reason: 'no round yet');
      s.inventory['goblin_hide'] = 2;
      final events = <GameEvent>[];

      s = game.changeStop(
        s,
        0,
        const StopCondition.untilHave('goblin_hide', 2),
        events: events,
      );

      expect(events.whereType<ActivityEnded>().single.reason, EndReason.enough);
      expect(events.whereType<ActionStarted>().single.activity, goblins);
      expect(s.bank, 9);
      expect(s.activity!.activity, goblins);
      expect(s.activity!.stop, hides);
      expect(s.queue, isEmpty);
    });

    test('during a fight the action ends after that fight', () {
      var s = game.applySteps(twoFights(), 10).state;
      expect(s.activity!.fight, isNotNull, reason: 'fight under way');
      s.inventory['goblin_hide'] = 2;

      s = game.changeStop(
        s,
        0,
        const StopCondition.untilHave('goblin_hide', 2),
      );
      expect(s.activity!.fight, isNotNull, reason: 'the fight goes on');
      expect(s.queue, hasLength(1));

      final r = game.applySteps(s, 500);
      final ended = r.events.whereType<ActivityEnded>().first;
      expect(ended.reason, EndReason.enough);
      expect(
        r.events.whereType<FightWon>().length +
            r.events.whereType<FightLost>().length,
        greaterThanOrEqualTo(1),
      );
      expect(
        r.events.indexOf(r.events.whereType<FightWon>().first),
        lessThan(r.events.indexOf(ended)),
      );
    });

    test('a waiting action with a reached goal stays in the queue', () {
      var s = twoFights();
      s.inventory['goblin_hide'] = 3;
      s = game.changeStop(
        s,
        1,
        const StopCondition.untilHave('goblin_hide', 3),
      );
      expect(s.queue, hasLength(1));
      expect(
        s.queue.single.stop,
        const StopCondition.untilHave('goblin_hide', 3),
      );
    });
  });

  // Review of PR #131: the sheet names an action by its place in the queue,
  // and a sync can move the queue before the change.
  group('the action that the player changes', () {
    test('a change refuses an index that now holds another action', () {
      final s = twoFights();
      expect(
        () => game.changeStop(
          s,
          0,
          const StopCondition.untilHave('goblin_hide', 20),
          expected: const Activity.fight('goblin_brute'),
        ),
        refused('The queue changed. Open the action again.'),
      );
    });

    test('a change goes through when the index holds the expected action', () {
      final s = game.changeStop(
        twoFights(),
        1,
        const StopCondition.untilHave('goblin_hide', 20),
        expected: goblins,
      );
      expect(s.queue.single.stop.count, 20);
    });

    test('stopReached is false for an index that is gone or moved', () {
      final s = twoFights()..inventory['goblin_hide'] = 9;
      const one = StopCondition.untilHave('goblin_hide', 1);
      expect(game.stopReached(s, 5, one), isFalse);
      expect(
        game.stopReached(s, 0, one, expected: const Activity.fight('rat')),
        isFalse,
      );
      expect(game.stopReached(s, 0, one, expected: goblins), isTrue);
    });

    test('a reroll is one roll: its stop condition does not change', () {
      final s = stateAt(game)
        ..activity = RunningActivity(const Activity.reroll('copper_sword'));
      expect(
        () => game.changeStop(s, 0, const StopCondition.untilCrafted(5)),
        refused('A reroll is one roll.'),
      );
    });
  });
}
