// Spec 0017 (achievements rework), plan 0021 M1: criteria 1, 2 and 4-25.
// The counts of the feats come from the sim in M2 (criterion 3), so the
// tests read each count from the data.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;
  AchievementDef a(String id) => data.achievements[id]!;
  int need(String id) => switch (a(id).criterion) {
    CounterCriterion(:final atLeast) => atLeast,
    _ => throw StateError('$id has no counter'),
  };
  String counter(String id) => (a(id).criterion as CounterCriterion).counter;

  /// [s] after one step, and its events.
  StepReport step(GameState s) => game.applySteps(s, 1);

  Iterable<String> unlocked(StepReport r) =>
      r.events.whereType<AchievementUnlocked>().map((e) => e.id);

  /// An old save: [s] written and read back as save [version].
  GameState saved(GameState s, {int version = GameState.schemaVersion}) =>
      GameState.fromJson({...s.toJson(), 'version': version});

  group('criteria 1 and 2: the list of spec 0017 §2', () {
    const stages = {
      AchievementStage.early: [
        ('first_steps', AchievementKind.milestone),
        ('prospector', AchievementKind.milestone),
        ('smith', AchievementKind.milestone),
        ('kings_bane', AchievementKind.milestone),
        ('adventurer', AchievementKind.milestone),
        ('angler', AchievementKind.milestone),
        ('lucky_find', AchievementKind.milestone),
        ('goblin_slayer_1', AchievementKind.feat),
        ('brute_force', AchievementKind.feat),
        ('bone_collector', AchievementKind.feat),
      ],
      AchievementStage.mid: [
        ('marathon', AchievementKind.milestone),
        ('seasoned', AchievementKind.milestone),
        ('rare_find', AchievementKind.milestone),
        ('smugglers_secret', AchievementKind.milestone),
        ('chieftains_bane', AchievementKind.feat),
        ('bear_hunter', AchievementKind.feat),
        ('wolf_pack', AchievementKind.feat),
        ('ghost_hunter', AchievementKind.feat),
      ],
      AchievementStage.late: [
        ('travelling_salesman', AchievementKind.milestone),
        ('the_long_road', AchievementKind.milestone),
        ('champion', AchievementKind.milestone),
        ('epic_find', AchievementKind.milestone),
        // Amendment 3: after level 20, so its helm comes late.
        ('master_smith', AchievementKind.milestone),
        ('dragonslayer', AchievementKind.feat),
        ('golem_breaker', AchievementKind.feat),
        ('troll_slayer', AchievementKind.feat),
        ('wyvern_hunter', AchievementKind.feat),
        ('legendary_find', AchievementKind.feat),
        ('master_of_a_trade', AchievementKind.feat),
        ('deep_waters', AchievementKind.feat),
      ],
    };

    test('30 achievements: 10 early, 8 mid and 12 late (amendment 3), with '
        'their kinds', () {
      expect(data.achievements, hasLength(30));
      expect([for (final l in stages.values) l.length], [10, 8, 12]);
      stages.forEach((stage, list) {
        for (final (id, kind) in list) {
          expect(a(id).stage, stage, reason: id);
          expect(a(id).kind, kind, reason: id);
        }
      });
    });

    test('the 11 achievements of today keep their ids and names', () {
      const today = {
        'first_steps': 'First Steps',
        'goblin_slayer_1': 'Goblin Slayer I',
        'prospector': 'Prospector',
        'smith': 'Smith',
        'brute_force': 'Brute Force',
        'marathon': 'Marathon',
        'kings_bane': "King's Bane",
        'chieftains_bane': "Chieftain's Bane",
        'dragonslayer': 'Dragonslayer',
        'bear_hunter': 'Bear Hunter',
        'travelling_salesman': 'Travelling Salesman',
      };
      today.forEach((id, name) => expect(a(id).name, name));
    });

    test('the criteria and rewards of §2', () {
      CounterCriterion kills(String enemy) =>
          CounterCriterion('kills.$enemy', 0);
      final criteria = <String, Object>{
        'first_steps': const CounterCriterion('steps.walked', 10000),
        // Amendment 3: milestones that come on the way.
        'prospector': const CounterCriterion('gathered.copper_ore', 30),
        'smith': const CounterCriterion('crafted.total', 15),
        'kings_bane': const CounterCriterion('kills.graveyard_king', 1),
        'adventurer': const LevelCriterion(10),
        'angler': const CounterCriterion('gathered.lake_scale', 5),
        'lucky_find': const QualityCriterion('uncommon'),
        'goblin_slayer_1': kills('goblin'),
        'brute_force': kills('goblin_brute'),
        'bone_collector': kills('skeleton'),
        'marathon': const CounterCriterion('steps.walked', 100000),
        'seasoned': const LevelCriterion(20),
        'master_smith': const CounterCriterion('crafted.total', 60),
        'rare_find': const QualityCriterion('rare'),
        'smugglers_secret': const CounterCriterion('visited.smugglers_cove', 1),
        'chieftains_bane': kills('ogre_chieftain'),
        'bear_hunter': kills('old_bear'),
        'wolf_pack': kills('wolf'),
        'ghost_hunter': kills('ghost'),
        'travelling_salesman': const CounterCriterion('areas.visited', 11),
        'the_long_road': const CounterCriterion('steps.walked', 350000),
        'champion': const LevelCriterion(30),
        'epic_find': const QualityCriterion('epic'),
        'dragonslayer': kills('young_dragon'),
        'golem_breaker': kills('stone_golem'),
        'troll_slayer': kills('troll'),
        'wyvern_hunter': kills('wyvern'),
        'legendary_find': const QualityCriterion('legendary'),
        // Spec 0017 amendment 1: the four gathering professions.
        'master_of_a_trade': const EachProfessionCriterion([
          'mining',
          'woodcutting',
          'fishing',
          'hunting',
        ], 30),
        // Spec 0017 amendment 2: catches at Cold tarn, one tarn scale each.
        'deep_waters': const CounterCriterion('gathered.tarn_scale', 0),
      };
      criteria.forEach((id, c) {
        final got = a(id).criterion;
        // A feat's count comes from the sim (criterion 3): only its counter
        // is fixed here.
        if (a(id).kind == AchievementKind.feat && c is CounterCriterion) {
          expect(got, isA<CounterCriterion>(), reason: id);
          expect((got as CounterCriterion).counter, c.counter, reason: id);
          expect(got.atLeast, greaterThan(0), reason: id);
        } else {
          expect(got, c, reason: id);
        }
      });
      final rewards = <String, Reward>{
        'first_steps': const BankCapReward(250),
        'prospector': const BankCapReward(250),
        'smith': const BankCapReward(500),
        'kings_bane': const BankCapReward(500),
        'adventurer': const BankCapReward(500),
        'angler': const BankCapReward(250),
        'lucky_find': const BankCapReward(250),
        'goblin_slayer_1': const BonusReward(Stats(attack: 4)),
        'brute_force': const BonusReward(Stats(hp: 40)),
        'bone_collector': const BonusReward(Stats(defense: 4)),
        'marathon': const BankCapReward(500),
        'seasoned': const BankCapReward(1000),
        'master_smith': const ItemReward('mithril_helm', 'rare'),
        'rare_find': const BankCapReward(500),
        'smugglers_secret': const ItemReward('sapphire_ring', 'rare'),
        'chieftains_bane': const QueueSlotReward(),
        'bear_hunter': const BonusReward(Stats(crit: 4)),
        'wolf_pack': const BonusReward(Stats(attack: 7)),
        'ghost_hunter': const BonusReward(Stats(dodge: 4)),
        'travelling_salesman': const BankCapReward(500),
        'the_long_road': const BankCapReward(1500),
        'champion': const ItemReward('star_diamond_ring', 'epic'),
        'epic_find': const BankCapReward(1000),
        'dragonslayer': const BonusReward(Stats(attack: 10)),
        'golem_breaker': const BonusReward(Stats(defense: 10)),
        'troll_slayer': const BonusReward(Stats(block: 6)),
        'wyvern_hunter': const BonusReward(Stats(hp: 130)),
        'legendary_find': const BonusReward(Stats(crit: 6)),
        'master_of_a_trade': const BonusReward(Stats(hit: 6)),
        'deep_waters': const BonusReward(Stats(block: 6)),
      };
      rewards.forEach((id, r) => expect(a(id).reward, r, reason: id));
    });
  });

  group('criteria 4-9: when an achievement is earned', () {
    test('criterion 4: a counter criterion at its number', () {
      final s = stateAt(game)
        ..counters['kills.goblin'] = need('goblin_slayer_1') - 1;
      expect(unlocked(step(s)), isNot(contains('goblin_slayer_1')));
      s.counters['kills.goblin'] = need('goblin_slayer_1');
      expect(unlocked(step(s)), contains('goblin_slayer_1'));
    });

    test('criterion 5: a level criterion at its level', () {
      final s = stateAt(game, level: 9);
      expect(unlocked(step(s)), isNot(contains('adventurer')));
      s.xp = data.xpForLevel(10);
      expect(unlocked(step(s)), contains('adventurer'));
    });

    // Amendment 3 made Angler a count, so the data has no profession
    // criterion now: a test achievement has one.
    test('criterion 6: a profession criterion at its level', () {
      final withOne = newTestGame(
        overrides: {
          'achievements': {
            'achievements': [
              ...dataJson('achievements')['achievements']! as List,
              {
                'id': 'test_fisher',
                'name': 'Test Fisher',
                'stage': 'early',
                'kind': 'milestone',
                'criterion': {'profession': 'fishing', 'level': 10},
                'reward': {'bankCap': 1},
              },
            ],
          },
        },
      );
      final s = stateAt(withOne, professionLevel: 9);
      Iterable<String> earned(GameState s) => withOne
          .applySteps(s, 1)
          .events
          .whereType<AchievementUnlocked>()
          .map((e) => e.id);
      expect(earned(s), isNot(contains('test_fisher')));
      s.professions['fishing'] = data.professionXpForLevel(10);
      expect(earned(s), contains('test_fisher'));
    });

    test('criterion 7 (amendment 1): each profession of the list at its '
        'level', () {
      final s = stateAt(game, professionLevel: 29);
      for (final p in ['mining', 'woodcutting', 'fishing', 'cooking']) {
        s.professions[p] = data.professionXpForLevel(30);
      }
      expect(unlocked(step(s)), isNot(contains('master_of_a_trade')));
      s.professions['hunting'] = data.professionXpForLevel(30);
      expect(unlocked(step(s)), contains('master_of_a_trade'));
    });

    test('criterion 8: a quality criterion when a drop has that quality', () {
      // Every drop is Uncommon: the lowest quality has no chance.
      final economy = dataJson('economy');
      final qualities = [
        for (final q in economy['qualities']! as List<Object?>)
          {
            ...q! as Map<String, Object?>,
            'chance': (q as Map)['id'] == 'uncommon' ? 1.0 : 0.0,
          },
      ];
      final arena = arenaGame(
        [
          {
            'id': 'dummy',
            'name': 'Dummy',
            'level': 1,
            'armour': 'light',
            'hp': 1,
            'attack': 0,
            'defense': 0,
            'xp': 1,
            'drops': [
              {'item': 'rusty_dagger', 'chance': 1.0, 'count': 1},
            ],
          },
        ],
        economy: {'qualities': qualities, 'qualityPerLevel': 0},
      );
      var s = stateAt(arena, location: 'arena');
      s = arena.startActivity(s, const Activity.fight('dummy'));
      final r = arena.applySteps(s, 50);
      expect(
        r.state.inventory.keys.where((k) => k.startsWith('rusty_dagger')),
        isNotEmpty,
      );
      expect(r.state.achievements, contains('lucky_find'));
      expect(r.state.achievements, isNot(contains('rare_find')));
    });

    test('criterion 9: an item from an achievement does not count for a '
        'quality criterion', () {
      final s = stateAt(game)..counters['crafted.total'] = need('master_smith');
      final r = step(s);
      expect(r.state.achievements, contains('master_smith'));
      expect(r.state.inventory[data.keyFor('mithril_helm', 'rare')], 1);
      expect(r.state.counters[Game.foundQualityCounter], isNull);
      expect(r.state.achievements, isNot(contains('lucky_find')));
      expect(r.state.achievements, isNot(contains('rare_find')));
    });
  });

  group('criteria 10-15: rewards', () {
    test('criterion 10: a bank cap reward raises the cap by its number', () {
      final s = stateAt(game)
        ..counters['steps.walked'] = need('first_steps') - 1;
      final before = game.bankCap(s);
      final r = step(s);
      expect(r.state.achievements, contains('first_steps'));
      expect(game.bankCap(r.state), before + 250);
    });

    test('criterion 11: an item reward goes into the bag at its quality', () {
      final s = stateAt(game)..counters['crafted.total'] = need('master_smith');
      expect(step(s).state.inventory[data.keyFor('mithril_helm', 'rare')], 1);
    });

    test('criterion 12: a bonus raises its stat, and two bonuses to one '
        'stat add up', () {
      final s = stateAt(game);
      final before = game.stats(s);
      s.achievements.addAll(['goblin_slayer_1', 'wolf_pack', 'brute_force']);
      final after = game.stats(s);
      expect(after.attack - before.attack, 4 + 7);
      expect(after.hp - before.hp, 40);
      expect(after.defense, before.defense);
    });

    test('criterion 13: Chieftain\'s Bane raises the queue to 6 actions', () {
      final s = stateAt(game);
      expect(game.queueSlots(s), 5);
      s.counters['kills.ogre_chieftain'] = need('chieftains_bane');
      expect(game.queueSlots(step(s).state), 6);
    });

    test('criterion 14: only feats give bonuses or the queue slot', () {
      for (final x in data.achievements.values) {
        final big = x.reward is BonusReward || x.reward is QueueSlotReward;
        expect(big, x.kind == AchievementKind.feat, reason: x.id);
      }
    });

    test('criterion 14: the data check refuses a bonus on a milestone', () {
      final json = dataJson('achievements');
      final list = [...json['achievements']! as List<Object?>];
      list[0] = {
        ...list[0]! as Map<String, Object?>,
        'reward': {'attack': 1},
      };
      expect(
        () => loadGameData(
          overrides: {
            'achievements': {'achievements': list},
          },
        ),
        throwsFormatException,
      );
    });

    test('criterion 15: no reward item comes from a monster or a spot of its '
        'criterion', () {
      for (final x in data.achievements.values) {
        final reward = x.reward;
        if (reward is! ItemReward) continue;
        final item = reward.item;
        final c = x.criterion;
        final monsters = [
          if (c case CounterCriterion(:final counter)
              when counter.startsWith('kills.'))
            data.enemies[counter.substring('kills.'.length)]!,
        ];
        for (final m in monsters) {
          final drops = {
            for (final d in [...m.drops, ...m.firstKillDrops]) d.item,
          };
          expect(drops, isNot(contains(item)), reason: '${x.id}: a drop');
          for (final r in data.recipes.values) {
            if (r.output != item) continue;
            expect(
              r.inputs.keys.toSet().intersection(drops),
              isEmpty,
              reason: '${x.id}: $item is made from a drop of ${m.id}',
            );
          }
        }
        final places = [
          if (c case CounterCriterion(:final counter)
              when counter.startsWith('visited.'))
            data.locations[counter.substring('visited.'.length)]!,
        ];
        for (final l in places) {
          for (final n in l.nodes) {
            expect(
              data.nodes[n]!.chest,
              isNot(item),
              reason: '${x.id}: the chest of $n',
            );
          }
        }
      }
    });
  });

  group('criteria 16-25: old saves and lost achievements', () {
    test(
      'criteria 16 and 22: a save loads, the game checks each '
      'achievement by the new criteria, and an event names each lost one',
      () {
        // First Steps under the old criterion: 100 steps.
        final s = stateAt(game)
          ..counters['steps.walked'] = 100
          ..achievements.add('first_steps');
        final loaded = game.load(saved(s));
        expect(loaded.state.achievements, isNot(contains('first_steps')));
        expect(loaded.events.whereType<AchievementLost>().map((e) => e.id), [
          'first_steps',
        ]);
      },
    );

    test('criterion 17: an earned achievement that meets its criterion stays '
        'earned, and its reward comes no second time', () {
      final s = stateAt(game)
        ..counters['crafted.total'] = need('master_smith')
        ..achievements.addAll(['smith', 'master_smith']);
      final loaded = game.load(saved(s));
      expect(loaded.state.achievements, contains('master_smith'));
      expect(
        loaded.state.inventory[data.keyFor('mithril_helm', 'rare')],
        isNull,
      );
      expect(loaded.events.whereType<AchievementUnlocked>(), isEmpty);
    });

    test('criterion 18: a lost bank cap reward lowers the cap, and steps '
        'above the new cap are lost', () {
      final s = stateAt(game)
        ..counters['steps.walked'] = 50000
        ..achievements.addAll(['first_steps', 'marathon']);
      s.bank = game.bankCap(s);
      final loaded = game.load(saved(s));
      final lost = loaded.events.whereType<AchievementLost>().single;
      expect(lost.id, 'marathon');
      expect(game.bankCap(loaded.state), game.bankCap(s) - 500);
      expect(loaded.state.bank, game.bankCap(loaded.state));
      expect(lost.bankSteps, 500);
    });

    group('criterion 19: a lost item reward', () {
      final ring = data.keyFor('star_diamond_ring', 'epic');
      GameState champion() => stateAt(game)..achievements.add('champion');

      test('goes from the bag first', () {
        final s = champion()
          ..inventory[ring] = 1
          ..equipment['ring1'] = ring;
        final loaded = game.load(saved(s));
        expect(loaded.state.inventory[ring], isNull);
        expect(loaded.state.equipment['ring1'], ring);
        expect(loaded.events.whereType<AchievementLost>().single.item, ring);
      });

      test('else from the doll, and the slot is empty', () {
        final s = champion()..equipment['ring1'] = ring;
        final loaded = game.load(saved(s));
        expect(loaded.state.equipment, isNot(contains('ring1')));
      });

      test('and nothing more when the player no longer has it', () {
        final loaded = game.load(saved(champion()));
        expect(loaded.state.achievements, isNot(contains('champion')));
        expect(loaded.events.whereType<AchievementLost>().single.item, isNull);
      });
    });

    test('criterion 20: a lost bonus lowers its stat', () {
      final s = stateAt(game)..achievements.add('goblin_slayer_1');
      final before = game.stats(s);
      final loaded = game.load(saved(s));
      expect(game.stats(loaded.state).attack, before.attack - 4);
    });

    test('criterion 21: a lost Chieftain\'s Bane gives a queue of 5; waiting '
        'actions beyond 5 go from the back; the current action stays', () {
      var s = stateAt(game, level: 30, location: 'goblin_woods')
        ..counters['kills.ogre_chieftain'] = need('chieftains_bane')
        ..achievements.add('chieftains_bane');
      final actions = [
        for (final e in ['goblin', 'goblin_brute']) Activity.fight(e),
      ];
      for (var i = 0; i < 6; i++) {
        s = game.addAction(
          s,
          actions[i % 2],
          stop: StopCondition.untilHave('goblin_hide', 90 + i),
        );
      }
      expect(s.activity, isNotNull);
      expect(s.queue, hasLength(5));
      final kept = [for (final p in s.queue.take(4)) p.stop.toJson()];
      final current = s.activity!.activity;
      s.counters['kills.ogre_chieftain'] = 0;
      final loaded = game.load(saved(s));
      expect(game.queueSlots(loaded.state), 5);
      expect(loaded.state.activity!.activity, current);
      expect([for (final p in loaded.state.queue) p.stop.toJson()], kept);
      expect(loaded.events.whereType<AchievementLost>().single.actions, 1);
    });

    test('criterion 23: a lost achievement can be earned again, and its '
        'reward comes again', () {
      final ring = data.keyFor('star_diamond_ring', 'epic');
      final s = stateAt(game)
        ..achievements.add('champion')
        ..inventory[ring] = 1;
      final loaded = game.load(saved(s)).state;
      expect(loaded.inventory[ring], isNull);
      loaded.xp = data.xpForLevel(30);
      final r = step(loaded);
      expect(unlocked(r), contains('champion'));
      expect(r.state.inventory[ring], 1);
    });

    test('criterion 24: an old save starts the quality counter at the best '
        'quality in its bag and on its doll', () {
      final rare = data.qualities.indexWhere((q) => q.id == 'rare');
      final epic = data.qualities.indexWhere((q) => q.id == 'epic');
      final bag = stateAt(game)
        ..inventory[data.keyFor('iron_sword', 'rare')] = 1;
      final fromBag = game.load(saved(bag, version: 11)).state;
      expect(fromBag.counters[Game.foundQualityCounter], rare + 1);
      expect(fromBag.achievements, containsAll(['lucky_find', 'rare_find']));
      expect(fromBag.achievements, isNot(contains('epic_find')));

      final doll = stateAt(game)
        ..equipment['head'] = data.keyFor('iron_helm', 'epic');
      final fromDoll = game.load(saved(doll, version: 11)).state;
      expect(fromDoll.counters[Game.foundQualityCounter], epic + 1);
      expect(fromDoll.achievements, contains('epic_find'));

      // A save of this version keeps its counter as it is.
      final now = game.load(saved(bag)).state;
      expect(now.counters[Game.foundQualityCounter], isNull);
    });

    test('criterion 25 (game_core part): the save version is 12', () {
      expect(GameState.schemaVersion, 12);
    });
  });

  test('the progress of an achievement', () {
    final s = stateAt(game, level: 7)..counters['kills.goblin'] = 12;
    expect(game.achievementProgress(s, 'goblin_slayer_1'), (
      have: 12,
      need: need('goblin_slayer_1'),
    ));
    expect(game.achievementProgress(s, 'adventurer'), (have: 7, need: 10));
    expect(game.achievementProgress(s, 'lucky_find'), (have: 0, need: 1));
    expect(counter('goblin_slayer_1'), 'kills.goblin');
  });

  // Amendments 2 and 3: a scale for each catch, from one spot only.
  test('only Cold tarn gives tarn scales, and only Lake shore gives lake '
      'scales', () {
    for (final (id, item, spot) in [
      ('deep_waters', 'tarn_scale', 'cold_tarn'),
      ('angler', 'lake_scale', 'lake_shore'),
    ]) {
      expect(counter(id), 'gathered.$item');
      expect(
        [
          for (final n in data.nodes.values)
            if (n.item == item || n.catches.any((c) => c.item == item)) n.id,
        ],
        [spot],
      );
    }
  });
}
