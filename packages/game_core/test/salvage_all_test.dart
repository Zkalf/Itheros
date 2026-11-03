// Salvage all: spec 0010 amendment 9 criteria 1-7 (plan 0043). The screens
// (criteria 8-15) are in the app's tests.
import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;

  /// At Camp (a forge) with [bag] in the bag.
  GameState atForge(Map<String, int> bag, {int seed = 1}) =>
      stateAt(game, level: 20, seed: seed, inventory: bag);

  String json(GameState s) => jsonEncode(s.toJson());

  const mixed = {
    'bone_sword': 2,
    'copper_sword': 1,
    'copper_pickaxe': 1,
    'bone_sword@rare+crit2+hp10': 1,
    'copper_ore': 5,
    'old_pick': 1,
  };

  test('criterion 1: a quality batch takes every bag item of it', () {
    final s = atForge(mixed);
    final keys = game.salvageAllOf(s, 'common');
    expect(keys.toSet(), {'bone_sword', 'copper_sword', 'copper_pickaxe'});
    final r = game.salvageAll(s, keys);
    expect(r.count, 4);
    for (final k in keys) {
      expect(r.state.inventory.containsKey(k), isFalse, reason: k);
    }
    expect(r.state.inventory['bone_sword@rare+crit2+hp10'], 1);
    expect(r.state.inventory['copper_ore'], 5);
  });

  test('criterion 2: a batch leaves worn items as they are', () {
    final s = atForge({'bone_sword': 1})..equipment['mainHand'] = 'bone_sword';
    final r = game.salvageAll(s, game.salvageAllOf(s, 'common'));
    expect(r.state.equipment['mainHand'], 'bone_sword');
    expect(r.state.inventory.containsKey('bone_sword'), isFalse);
  });

  test('criterion 3: a batch leaves starter tools in the bag', () {
    final s = atForge(mixed);
    expect(game.salvageAllOf(s, 'common'), isNot(contains('old_pick')));
    final r = game.salvageAll(s, game.salvageAllOf(s, 'common'));
    expect(r.state.inventory['old_pick'], 1);
    expect(
      () => game.salvageAll(s, ['old_pick']),
      throwsA(isA<ActivityError>()),
    );
  });

  test('criterion 4: a batch leaves the bank as it is', () {
    final s = atForge({'bone_sword': 1})..itemBank['copper_sword'] = 2;
    expect(game.salvageAllOf(s, 'common'), ['bone_sword']);
    final r = game.salvageAll(s, game.salvageAllOf(s, 'common'));
    expect(r.state.itemBank, {'copper_sword': 2});
  });

  test('criterion 5: 3 Common items give 3 Common dust', () {
    final s = atForge({'bone_sword': 2, 'copper_sword': 1});
    final r = game.salvageAll(s, game.salvageAllOf(s, 'common'));
    expect(r.count, 3);
    expect(r.dust, {'common_dust': 3});
    expect(r.state.inventory['common_dust'], 3);
  });

  test('criterion 6: a batch equals single salvages in the bag order', () {
    // Many items over many seeds, so some batches find shards.
    final bag = {
      'bone_sword': 30,
      'copper_sword': 20,
      'iron_sword@epic+crit1+crit1+hp10': 1,
      'copper_pickaxe': 25,
    };
    var shardsSeen = 0;
    for (var seed = 1; seed <= 8; seed++) {
      final s = atForge(bag, seed: seed);
      final keys = bag.keys.toList();
      final batch = game.salvageAll(s, keys.reversed);
      var single = s;
      final shards = <String, int>{};
      for (final k in bagOrder(data, keys)) {
        for (var i = 0; i < bag[k]!; i++) {
          final r = game.salvage(single, k);
          single = r.state;
          if (r.shard case final shard?) {
            shards[shard] = (shards[shard] ?? 0) + 1;
          }
        }
      }
      expect(json(batch.state), json(single), reason: 'seed $seed');
      expect(batch.shards, shards, reason: 'seed $seed');
      shardsSeen += shards.length;
    }
    expect(shardsSeen, greaterThan(0));
  });

  test('criterion 7: a batch away from a forge throws, changes nothing', () {
    final s = atForge({'bone_sword': 2})..location = 'goblin_woods';
    final before = json(s);
    expect(
      () => game.salvageAll(s, ['bone_sword']),
      throwsA(isA<ActivityError>()),
    );
    expect(json(s), before);
  });

  test('an item batch takes the whole stack of that one square', () {
    final s = atForge({'bone_sword': 5, 'bone_sword@uncommon+crit2': 1});
    final r = game.salvageAll(s, ['bone_sword']);
    expect(r.count, 5);
    expect(r.state.inventory['bone_sword@uncommon+crit2'], 1);
  });
}
