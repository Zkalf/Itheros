// The content of spec 0002 §6–§8 hangs together: every level unlocks
// something, everything can be obtained, every place can be reached.
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;

  // Spec 0008 decision 1: levels no longer open areas, monsters or recipes,
  // so a level may bring only stats (concern 3).
  test('level 10 is the Adventurer rank', () {
    final news = game.levelNews(10);
    expect(news, contains(const LevelNews(NewsKind.rank, 'Adventurer')));
    expect(news, contains(const LevelNews(NewsKind.talentPoint, '')));
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
      // Teachers give the starter tools (spec 0010 §3.1).
      for (final p in data.professions.values) p.teacher.starterTool,
      // Rare finds, salvage's dust and shards (spec 0010 §5, §7.1).
      for (final n in data.nodes.values) ?n.rareFind,
      for (final q in data.qualities) GameData.dustOf(q.id),
      ...data.shards,
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

  group('spec 0009 criterion 5: armour and weapons', () {
    test('every monster wears the §3 armour, five have Dodge', () {
      const armour = {
        'light': [
          'goblin',
          'goblin_brute',
          'zombie',
          'wolf',
          'ghost',
          'troll',
          'harpy',
        ],
        'medium': [
          'old_bear',
          'bandit',
          'giant_spider',
          'ogre_chieftain',
          'wraith',
          'wyvern',
        ],
        'heavy': [
          'skeleton',
          'graveyard_king',
          'stone_golem',
          'fire_drake',
          'young_dragon',
        ],
      };
      expect(
        {for (final e in data.enemies.values) e.id: e.armour},
        {
          for (final MapEntry(key: a, value: ids) in armour.entries)
            for (final id in ids) id: a,
        },
      );
      expect(
        {
          for (final e in data.enemies.values)
            if (e.stats.dodge > 0) e.id: e.stats.dodge,
        },
        {'wolf': 8, 'ghost': 5, 'harpy': 10, 'giant_spider': 8, 'wyvern': 5},
      );
    });

    test('the weapon list matches §4.1', () {
      // id: (damage type, two-handed, recipe level or null for drops).
      const weapons = {
        'copper_sword': ('slash', false, 3),
        'copper_spear': ('pierce', false, 3),
        'copper_mace': ('crush', false, 3),
        'rusty_dagger': ('pierce', false, null),
        'bone_sword': ('slash', false, 6),
        'bone_spear': ('pierce', false, 6),
        'bone_club': ('crush', false, 6),
        'bone_greataxe': ('slash', true, 8),
        // Also made from ten shards (spec 0010 §7.4).
        'kings_blade': ('slash', false, 10),
        'iron_sword': ('slash', false, 14),
        'iron_spear': ('pierce', false, 14),
        'iron_mace': ('crush', false, 14),
        'iron_pike': ('pierce', true, 16),
        'troll_bone_maul': ('crush', true, 19),
        'mithril_sword': ('slash', false, 22),
        'mithril_spear': ('pierce', false, 22),
        'mithril_mace': ('crush', false, 22),
        'mithril_greatsword': ('slash', true, 24),
        'drake_fang_blade': ('slash', false, 28),
        'drake_fang_spear': ('pierce', false, 28),
        'drake_fang_hammer': ('crush', false, 28),
        'drake_fang_halberd': ('pierce', true, 29),
      };
      expect({
        for (final i in data.items.values)
          if (i.slot == 'mainHand')
            i.id: (i.damageType, i.twoHanded, data.recipes[i.id]?.level),
      }, weapons);
    });

    // Spec 0010 §4 adds logs to hafts; they are left out here.
    Map<String, int> noLogs(String recipe) => {
      for (final MapEntry(:key, :value) in data.recipes[recipe]!.inputs.entries)
        if (!key.endsWith('_log')) key: value,
    };

    test('the two-handers\' recipes and costs (§4.1)', () {
      const inputs = {
        'bone_greataxe': {'bones': 10, 'copper_ore': 3},
        'iron_pike': {'iron_ore': 12, 'leather': 2},
        'mithril_greatsword': {'mithril_ore': 12, 'stone_core': 2},
        'drake_fang_halberd': {'drake_fang': 6, 'mithril_ore': 10},
      };
      for (final MapEntry(key: id, value: wanted) in inputs.entries) {
        expect(noLogs(id), wanted, reason: id);
      }
    });

    test('a spear or mace has its tier sword\'s Attack, materials, steps', () {
      const tiers = {
        'copper_sword': ['copper_spear', 'copper_mace'],
        'bone_sword': ['bone_spear', 'bone_club'],
        'iron_sword': ['iron_spear', 'iron_mace'],
        'mithril_sword': ['mithril_spear', 'mithril_mace'],
        'drake_fang_blade': ['drake_fang_spear', 'drake_fang_hammer'],
      };
      for (final MapEntry(key: sword, value: others) in tiers.entries) {
        for (final id in others) {
          expect(
            data.items[id]!.bonus.attack,
            data.items[sword]!.bonus.attack,
            reason: id,
          );
          expect(noLogs(id), data.recipes[sword]!.inputs);
          expect(data.recipes[id]!.steps, data.recipes[sword]!.steps);
        }
      }
    });

    test('two-handers hit harder than their tier\'s one-handers', () {
      const pairs = {
        'bone_greataxe': 'bone_sword',
        'iron_pike': 'iron_spear',
        'troll_bone_maul': 'iron_mace',
        'mithril_greatsword': 'mithril_sword',
        'drake_fang_halberd': 'drake_fang_spear',
      };
      pairs.forEach((two, one) {
        expect(
          data.items[two]!.bonus.attack,
          greaterThan(data.items[one]!.bonus.attack),
          reason: two,
        );
      });
    });

    test('shields carry Block; armour pieces carry the §6 types', () {
      for (final id in [
        'bone_shield',
        'ectoplasm_ward',
        'iron_shield',
        'golem_core_shield',
      ]) {
        expect(data.items[id]!.bonus.block, greaterThan(0), reason: id);
      }
      expect(
        {
          for (final i in data.items.values)
            if (i.armourType != null) i.id: (i.armourType, i.bonus.dodge),
        },
        {
          'hide_vest': ('light', 2),
          'stitched_armour': ('light', 2),
          'wolf_pelt_vest': ('light', 3),
          'bear_pelt_cloak': ('light', 2),
          'silk_boots': ('light', 2),
          'feather_boots': ('light', 3),
          'studded_leather': ('medium', 0),
          'troll_hide_armour': ('medium', 0),
          'wyvern_scale_armour': ('medium', 0),
          'iron_helm': ('heavy', 0),
          'mithril_armour': ('heavy', 0),
          'mithril_helm': ('heavy', 0),
          'dragon_scale_armour': ('heavy', 0),
          'dragon_helm': ('heavy', 0),
        },
      );
    });

    test('data without an armour or a damage type is rejected', () {
      final enemies = dataJson('enemies');
      (enemies['enemies']! as List).cast<Map<String, Object?>>().first.remove(
        'armour',
      );
      expect(
        () => newTestGame(overrides: {'enemies': enemies}),
        throwsA(isA<TypeError>()),
      );
      final items = dataJson('items');
      (items['items']! as List)
          .cast<Map<String, Object?>>()
          .firstWhere((i) => i['id'] == 'copper_sword')
          .remove('damageType');
      expect(
        () => newTestGame(overrides: {'items': items}),
        throwsFormatException,
      );
    });
  });
}
