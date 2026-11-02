// The fight log: spec 0019 criteria 1-7, 35 and 36 (plan 0039). The Now
// screen and the fight sheet (criteria 8-34) are in the app's tests.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;

  /// A fight against [enemy] in Goblin Woods at [level].
  GameState fighting(String enemy, {int level = 3, Game? g}) =>
      (g ?? game).startActivity(
        stateAt(g ?? game, location: 'goblin_woods', level: level),
        Activity.fight(enemy),
      );

  /// One round: the steps of one round.
  GameState round(GameState s, [Game? g]) =>
      (g ?? game).applySteps(s, data.combatRoundSteps).state;

  /// Rounds until the fight in [s] ends with [outcome]. Returns the state
  /// and the rounds of that fight, as the round log saw them.
  (GameState, List<RoundLog>) untilEnd(GameState s, FightOutcome outcome) {
    for (var i = 0; i < 2000; i++) {
      s = round(s);
      final last = s.activity!.log.last;
      if (last.outcome == outcome) return (s, [...s.activity!.log]);
    }
    fail('no fight ended with $outcome');
  }

  group('fight summaries', () {
    test('criterion 1: a won fight leaves its number, "won", its rounds, '
        'the damage taken and the crits', () {
      final (s, rounds) = untilEnd(fighting('goblin'), FightOutcome.won);
      final f = s.activity!.fights.last;
      expect(f.number, s.activity!.won + s.activity!.lost);
      expect(f.outcome, FightOutcome.won);
      expect(f.rounds, rounds.last.round);
      expect(rounds.first.round, 1, reason: 'the log holds the whole fight');
      expect(f.taken, rounds.fold<int>(0, (n, r) => n + (r.taken ?? 0)));
      expect(f.crits, rounds.where((r) => r.mine == Swing.crit).length);
    });

    test('criterion 2: a lost fight leaves "lost"', () {
      final (s, _) = untilEnd(
        fighting('goblin_brute', level: 1),
        FightOutcome.lost,
      );
      expect(s.activity!.fights.last.outcome, FightOutcome.lost);
    });

    test('criterion 3: the action keeps 10 summaries at most', () {
      expect(data.fightLogFights, 10);
      var s = fighting('goblin', level: 10);
      while (s.activity!.won + s.activity!.lost < 11) {
        s = round(s);
      }
      final fights = s.activity!.fights;
      expect(fights, hasLength(10));
      expect(fights.first.number, 2);
      expect(fights.last.number, 11);
    });

    test('criterion 4: a new fight action starts with no summaries', () {
      final (s, _) = untilEnd(fighting('goblin'), FightOutcome.won);
      expect(s.activity!.fights, isNotEmpty);
      final again = game.startActivity(s, const Activity.fight('goblin'));
      expect(again.activity!.fights, isEmpty);
      expect(again.activity!.log, isEmpty);
    });

    test('criterion 5: the summaries use no roll', () {
      final one = newTestGame(
        overrides: {
          'economy': {...dataJson('economy'), 'fightLogFights': 1},
        },
      );
      var a = fighting('goblin', g: game);
      var b = fighting('goblin', g: one);
      for (var i = 0; i < 300; i++) {
        a = round(a);
        b = round(b, one);
      }
      expect(a.activity!.won, greaterThan(1));
      expect(b.rngState, a.rngState);
      expect(b.xp, a.xp);
      expect(b.inventory, a.inventory);
      expect(b.activity!.won, a.activity!.won);
      expect(b.activity!.lost, a.activity!.lost);
      expect(b.activity!.fights, hasLength(1));
    });
  });

  group('the round log', () {
    test('criterion 6: the first round of a new fight empties the log', () {
      final (won, _) = untilEnd(fighting('goblin'), FightOutcome.won);
      final next = round(won);
      expect(next.activity!.log.single.round, 1);
    });

    test('criterion 7: the round log keeps 50 rounds at most', () {
      expect(data.fightLogRounds, 50);
      // A dummy that never dies; each of its hits does 1 damage, so a
      // level 30 player outlasts 60 rounds: one long fight.
      final g = arenaGame([
        {
          'id': 'dummy',
          'name': 'Dummy',
          'level': 1,
          'armour': 'light',
          'hp': 100000,
          'attack': 0,
          'defense': 0,
          'xp': 1,
        },
      ]);
      var s = g.startActivity(
        stateAt(g, location: 'arena', level: 30),
        const Activity.fight('dummy'),
      );
      for (var i = 0; i < 60; i++) {
        s = g.applySteps(s, g.data.combatRoundSteps).state;
      }
      final log = s.activity!.log;
      expect(s.activity!.lost, 0);
      expect(log, hasLength(50));
      expect(log.first.round, 11);
      expect(log.last.round, 60);
    });
  });

  group('save', () {
    test('criterion 35: the save version is 15', () {
      expect(GameState.schemaVersion, 15);
      expect(fighting('goblin').toJson()['version'], 15);
    });

    test('criterion 36: a schema 14 save with a running fight loads with no '
        'summaries and its round log', () {
      var s = fighting('goblin');
      for (var i = 0; i < 2; i++) {
        s = round(s);
      }
      final json = s.toJson();
      final act = json['activity']! as Map<String, Object?>;
      act.remove('fights');
      (act['fight']! as Map<String, Object?>)
        ..remove('taken')
        ..remove('crits');
      json['version'] = 14;
      final back = game.migrate(GameState.fromJson(json));
      expect(back.activity!.fights, isEmpty);
      expect(
        [for (final r in back.activity!.log) r.toJson()],
        [for (final r in s.activity!.log) r.toJson()],
      );
      expect(back.activity!.fight!.taken, 0);
      expect(back.activity!.fight!.crits, 0);
    });

    test('a summary comes back from JSON as it was', () {
      final (s, _) = untilEnd(fighting('goblin'), FightOutcome.won);
      final back = GameState.fromJson(s.toJson());
      expect(
        [for (final f in back.activity!.fights) f.toJson()],
        [for (final f in s.activity!.fights) f.toJson()],
      );
    });
  });
}
