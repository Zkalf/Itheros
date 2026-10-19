// The content of spec 0002 §6–§8 hangs together: every level unlocks
// something, everything can be obtained, every place can be reached.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;

  test('every level from 2 to 30 brings a named unlock (spec 0002 §8)', () {
    for (var level = 2; level <= 30; level++) {
      final named = game
          .levelNews(level)
          .where((n) => n.kind != NewsKind.talentPoint);
      expect(named, isNotEmpty, reason: 'level $level');
    }
  });

  test('level 10 is the Adventurer rank with the whole map', () {
    final news = game.levelNews(10);
    expect(news, contains(const LevelNews(NewsKind.rank, 'Adventurer')));
    expect(news, contains(const LevelNews(NewsKind.talentPoint, '')));
    expect(
      news.where((n) => n.kind == NewsKind.area).map((n) => n.id),
      containsAll(['grey_moor', 'troll_bridge', 'dragons_peak']),
    );
    expect(
      news,
      contains(const LevelNews(NewsKind.yourLevel, 'graveyard_king')),
    );
  });

  test('goblins turn grey at level 8', () {
    // Goblins are level 1: grey from 7 below. Level 8 is the turn.
    expect(
      game.levelNews(8),
      contains(const LevelNews(NewsKind.turnedGrey, 'goblin')),
    );
    expect(
      game.levelNews(9).where((n) => n.kind == NewsKind.turnedGrey),
      isNot(contains(const LevelNews(NewsKind.turnedGrey, 'goblin'))),
    );
  });

  test('ranks and talent points', () {
    expect(game.rank(1).name, 'Recruit');
    expect(game.rank(19).name, 'Adventurer');
    expect(game.rank(20).name, 'Veteran');
    expect(game.talentPoints(9), 0);
    expect(game.talentPoints(10), 1);
    expect(game.talentPoints(30), 21);
  });

  test('every material and item can be obtained', () {
    final obtainable = {
      for (final n in data.nodes.values) n.item,
      for (final r in data.recipes.values) r.output,
      for (final e in data.enemies.values) ...[
        for (final d in e.drops) d.item,
        for (final d in e.firstKillDrops) d.item,
      ],
    };
    expect(data.items.keys.toSet().difference(obtainable), isEmpty);
  });

  test('every location can be reached from camp', () {
    final seen = {data.startLocation};
    var frontier = [data.startLocation];
    while (frontier.isNotEmpty) {
      frontier = [
        for (final l in frontier)
          for (final to in data.destinationsFrom(l))
            if (seen.add(to)) to,
      ];
    }
    expect(seen, data.locations.keys.toSet());
  });

  test('every monster and gathering spot is in exactly one location', () {
    for (final id in [...data.enemies.keys, ...data.nodes.keys]) {
      final homes = data.locations.values.where(
        (l) => l.enemies.contains(id) || l.nodes.contains(id),
      );
      expect(homes, hasLength(1), reason: id);
    }
  });

  test('every monster has a flavour line and a loss hint', () {
    for (final e in data.enemies.values) {
      expect(e.flavour, isNotNull, reason: e.id);
      expect(e.lossHint, isNotNull, reason: e.id);
    }
  });

  test('bosses drop a unique item once (spec 0002 §5.3)', () {
    for (final boss in ['graveyard_king', 'ogre_chieftain', 'young_dragon']) {
      expect(data.enemies[boss]!.firstKillDrops, hasLength(1), reason: boss);
    }
  });
}
