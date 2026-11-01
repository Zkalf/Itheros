// "Low XP" on grey monsters: spec 0002 amendment 2, criteria 13-16
// (plan 0033).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

import 'quiet_teal_test.dart' show piecesOf;
import 'support.dart';
import 'ui_test.dart' show pumpGame;

void main() {
  final game = loadTestGame();

  /// The fight row of [enemy] on Now.
  Finder row(String enemy) => find.byKey(ValueKey('option-fight-$enemy'));

  /// Each piece of text in the row of [enemy], with its style.
  List<(String, TextStyle)> pieces(WidgetTester t, String enemy) => [
    for (final rich in t.widgetList<RichText>(
      find.descendant(of: row(enemy), matching: find.byType(RichText)),
    ))
      ...piecesOf(rich),
  ];

  /// The band of [enemy] for a player at [level].
  LevelColour colour(GameState s, String enemy) =>
      game.enemyBand(s, enemy).colour;

  testWidgets('criteria 13-14: a grey row starts with "Low XP", in grey', (
    t,
  ) async {
    final (c, _) = await pumpGame(t, level: 11, location: 'goblin_woods');
    expect(colour(c.state, 'goblin'), LevelColour.grey);
    final all = pieces(t, 'goblin');
    final low = [
      for (final p in all)
        if (p.$1.contains('Low XP')) p,
    ];
    expect(low, hasLength(1));
    // Only the words are grey: the piece holds "Low XP" and nothing else.
    expect(low.single.$1, 'Low XP');
    expect(low.single.$2.color?.toARGB32(), 0xFF9E9E9E);
    // It comes first, before the stats.
    final text = all.map((p) => p.$1).join();
    expect(text, contains('Low XP · '));
    // The stats: "HP …" when known, "Stats unknown" before the first fight.
    final stats = text.indexOf(RegExp('HP |Stats unknown'));
    expect(stats, greaterThan(-1));
    expect(text.indexOf('Low XP'), lessThan(stats));
  });

  testWidgets('criterion 15: yellow and orange rows do not say "Low XP"', (
    t,
  ) async {
    final (c, _) = await pumpGame(t, location: 'goblin_woods');
    expect(colour(c.state, 'goblin'), LevelColour.yellow);
    expect(colour(c.state, 'goblin_brute'), LevelColour.orange);
    for (final e in ['goblin', 'goblin_brute']) {
      expect(
        pieces(t, e).where((p) => p.$1.contains('Low XP')),
        isEmpty,
        reason: e,
      );
    }
  });

  testWidgets('criterion 15: a green row does not say "Low XP"', (t) async {
    final (c, _) = await pumpGame(t, level: 8, location: 'goblin_woods');
    expect(colour(c.state, 'goblin_brute'), LevelColour.green);
    expect(
      pieces(t, 'goblin_brute').where((p) => p.$1.contains('Low XP')),
      isEmpty,
    );
  });

  testWidgets('criterion 16: a grey fight starts with no question', (t) async {
    await pumpGame(t, level: 11, location: 'goblin_woods');
    await t.tap(row('goblin'));
    await t.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Deadly'), findsNothing);
  });
}
