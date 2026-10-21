// Save format: the whole state, including a fight in progress and the RNG,
// survives a JSON round trip, so catch-up after reload is identical.
import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();

  test('round trip mid-fight continues identically', () {
    var s = stateAt(game, location: 'goblin_woods', bank: 40, seed: 99)
      ..inventory['copper_ore'] = 2
      ..equipment['mainHand'] = 'rusty_dagger';
    s = game.startActivity(s, const Activity.fight('goblin'));
    s = game.applySteps(s, 137).state;
    while (s.activity!.fight == null) {
      s = game.applySteps(s, 3).state;
    }

    final reloaded = GameState.fromJson(
      jsonDecode(jsonEncode(s.toJson())) as Map<String, Object?>,
    );
    expect(reloaded.toJson(), s.toJson());

    final a = game.applySteps(s, 500).state;
    final b = game.applySteps(reloaded, 500).state;
    expect(b.toJson(), a.toJson());
  });

  group('criterion 11: a version 1 save keeps its level (spec 0002 §2)', () {
    // Spec 0001's XP table, which version 1 saves were measured against.
    const v1 = [0, 20, 100, 300, 700, 1540, 3390, 7460, 16400, 28000];

    GameState loadV1(int xp, {Map<String, Object?>? activity}) {
      final json = game.newGame(seed: 3).toJson()
        ..['version'] = 1
        ..['xp'] = xp
        ..['activity'] = activity;
      return game.migrate(GameState.fromJson(json));
    }

    test('progress through the level is kept as a fraction', () {
      final s = loadV1(v1[7] + (v1[8] - v1[7]) ~/ 2); // halfway through 8
      final floor = game.data.xpForLevel(8);
      final next = game.data.xpForLevel(9);
      expect(game.level(s), 8);
      expect(s.xp, floor + (next - floor) ~/ 2);
    });

    test('XP past the old level 10 cap carries into level 10', () {
      final floor = game.data.xpForLevel(10);
      final s = loadV1(28000 + 2000);
      expect(game.level(s), 10);
      expect(s.xp, floor + 2000);
    });

    test('...but never past level 10', () {
      final s = loadV1(500000);
      expect(game.level(s), 10);
      expect(s.xp, game.data.xpForLevel(11) - 1);
    });

    test('a fight in progress carries over', () {
      final s = loadV1(
        30,
        activity: {
          'kind': 'fight',
          'target': 'goblin',
          'progress': 4,
          'fight': {'playerHp': 20, 'enemyHp': 7},
        },
      );
      expect(s.activity!.fight!.enemyHp, 7);
      expect(s.activity!.fight!.round, 0);
    });

    test('migrating a current save changes nothing', () {
      final s = stateAt(game, level: 6)..xp += 123;
      expect(game.migrate(s.copy()).toJson(), s.toJson());
    });
  });

  test('unknown save versions are rejected', () {
    final json = game.newGame(seed: 1).toJson()..['version'] = 99;
    expect(() => GameState.fromJson(json), throwsFormatException);
  });

  test('a new game starts at camp, level 1, empty bank', () {
    final s = game.newGame(seed: 5);
    expect(s.location, 'camp');
    expect(game.level(s), 1);
    expect(s.bank, 0);
    expect(s.activity, isNull);
    expect(s.inventory, isEmpty);
  });
}
