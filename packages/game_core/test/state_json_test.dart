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
      ..equipment['weapon'] = 'rusty_dagger';
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

  test('a new game starts at camp, level 1, empty bank', () {
    final s = game.newGame(seed: 5);
    expect(s.location, 'camp');
    expect(game.level(s), 1);
    expect(s.bank, 0);
    expect(s.activity, isNull);
    expect(s.inventory, isEmpty);
  });
}
