// Auto-resolved combat: spec 0001 §4 and acceptance criterion 2.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();

  GameState fighting(Game g, String enemy, {int level = 1, int seed = 1}) {
    final s = stateAt(g, location: 'goblin_woods', level: level, seed: seed);
    return g.startActivity(s, Activity.fight(enemy));
  }

  test('same state and seed always give the same result', () {
    final a = game.applySteps(fighting(game, 'goblin', seed: 42), 2000);
    final b = game.applySteps(fighting(game, 'goblin', seed: 42), 2000);
    expect(a.state.toJson(), b.state.toJson());
    expect(a.events.length, b.events.length);
  });

  test('different seeds give different fights', () {
    final a = game.applySteps(fighting(game, 'goblin', seed: 1), 2000);
    final b = game.applySteps(fighting(game, 'goblin', seed: 2), 2000);
    expect(a.state.toJson(), isNot(b.state.toJson()));
  });

  test('a level 1 character beats goblins and earns XP', () {
    final r = game.applySteps(fighting(game, 'goblin'), 200);
    expect(r.state.counters['kills.goblin'], greaterThanOrEqualTo(2));
    expect(r.state.xp, greaterThanOrEqualTo(20));
    expect(r.events.whereType<FightWon>(), isNotEmpty);
    expect(r.events.whereType<FightLost>(), isEmpty);
  });

  test('a combat round costs 10 steps', () {
    final r = game.applySteps(fighting(game, 'goblin'), 9);
    expect(r.state.activity!.progress, 9);
    expect(r.state.activity!.fight, isNull, reason: 'no round resolved yet');

    final r2 = game.applySteps(r.state, 1);
    expect(r2.state.activity!.progress, 0);
    expect(r2.state.activity!.fight, isNotNull, reason: 'fight under way');
  });

  test('3 defeats end the activity and later steps go to the bank', () {
    final g = newTestGame(
      overrides: {
        'enemies': {
          'enemies': [
            {
              'id': 'goblin',
              'name': 'Goblin champion',
              'hp': 500,
              'attack': 100,
              'defense': 50,
              'xp': 10,
              'drops': <Object>[],
            },
          ],
        },
        'world': {
          'startLocation': 'goblin_woods',
          'locations': [
            {
              'id': 'goblin_woods',
              'name': 'Goblin Woods',
              'crafting': false,
              'enemies': ['goblin'],
              'nodes': <Object>[],
            },
          ],
          'routes': <Object>[],
          'nodes': <Object>[],
        },
      },
    );
    final r = g.applySteps(fighting(g, 'goblin'), 100);

    expect(r.events.whereType<FightLost>(), hasLength(3));
    expect(
      r.events.whereType<ActivityEnded>().single.reason,
      EndReason.defeated,
    );
    expect(r.state.activity, isNull);
    expect(r.state.bank, 70, reason: '3 lost 10-step rounds, then 70 banked');
    expect(r.state.inventory, isEmpty, reason: 'nothing is lost on defeat');
  });

  test('HP is full at the start of each fight', () {
    var s = game.applySteps(fighting(game, 'goblin'), 10).state;
    final maxHp = game.stats(s).hp;
    // Run until the first fight ends and a new one starts.
    while ((s.counters['kills.goblin'] ?? 0) == 0) {
      s = game.applySteps(s, 10).state;
    }
    s = game.applySteps(s, 10).state;
    expect(s.activity!.fight!.playerHp, lessThanOrEqualTo(maxHp));
    expect(s.activity!.fight!.playerHp, greaterThan(maxHp - 10));
  });
}
