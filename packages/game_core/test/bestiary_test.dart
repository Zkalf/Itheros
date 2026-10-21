// Learning foes: spec 0009 §7, acceptance criteria 11 and 12.
import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();

  GameState withKills(String enemy, int kills) => stateAt(game)
    ..counters['kills.$enemy'] = kills
    ..fought.add(enemy);

  group('criterion 11: the bestiary', () {
    test('nothing is known before the first fight', () {
      final k = game.knowledge(stateAt(game), 'skeleton');
      expect(
        (k.armour, k.weakness, k.stats, k.slayer, k.kills),
        (false, false, false, false, 0),
      );
    });

    test('the first fight, won or lost, shows the armour', () {
      final k = game.knowledge(withKills('skeleton', 0), 'skeleton');
      expect((k.armour, k.weakness, k.stats), (true, false, false));
    });

    test('10 kills show weakness and stats; 50 earn Slayer', () {
      final nine = game.knowledge(withKills('skeleton', 9), 'skeleton');
      expect((nine.weakness, nine.stats, nine.slayer), (false, false, false));
      expect(nine.killsToNext, 1);
      final ten = game.knowledge(withKills('skeleton', 10), 'skeleton');
      expect((ten.weakness, ten.stats, ten.slayer), (true, true, false));
      expect(ten.killsToNext, 40);
      final fifty = game.knowledge(withKills('skeleton', 50), 'skeleton');
      expect((fifty.weakness, fifty.stats, fifty.slayer), (true, true, true));
      expect(fifty.killsToNext, isNull);
    });

    test('its weakness is the damage type strong against its armour', () {
      expect(game.weakness('skeleton'), 'crush');
      expect(game.weakness('goblin'), 'slash');
      expect(game.weakness('bandit'), 'pierce');
    });

    test('a save with old kills opens with those cards filled in', () {
      final json = game.newGame(seed: 1).toJson()
        ..['version'] = 6
        ..remove('fought')
        ..remove('lore')
        ..['counters'] = {'kills.goblin': 300, 'kills.skeleton': 12};
      final s = game.migrate(
        GameState.fromJson(
          jsonDecode(jsonEncode(json)) as Map<String, Object?>,
        ),
      );
      final goblin = game.knowledge(s, 'goblin');
      expect((goblin.armour, goblin.stats, goblin.slayer), (true, true, true));
      final skeleton = game.knowledge(s, 'skeleton');
      expect((skeleton.stats, skeleton.slayer), (true, false));
      expect(game.knowledge(s, 'zombie').armour, isFalse);
    });

    test('the 10th and 50th kills are news', () {
      var s = withKills('goblin', 8);
      s = game.startActivity(
        s..location = 'goblin_woods',
        const Activity.fight('goblin'),
      );
      // Two kills: the 9th and the 10th.
      final events = <GameEvent>[];
      while ((s.counters['kills.goblin'] ?? 0) < 10) {
        final r = game.applySteps(s, 10);
        events.addAll(r.events);
        s = r.state;
      }
      expect(events.whereType<WeaknessLearned>().map((e) => e.enemy), [
        'goblin',
      ]);
      s.counters['kills.goblin'] = 49;
      final later = <GameEvent>[];
      while ((s.counters['kills.goblin'] ?? 0) < 51) {
        final r = game.applySteps(s, 10);
        later.addAll(r.events);
        s = r.state;
      }
      expect(later.whereType<SlayerEarned>().map((e) => e.enemy), ['goblin']);
      expect(later.whereType<WeaknessLearned>(), isEmpty);
    });
  });

  group('criterion 12: lore notes', () {
    test('16 notes, each from one monster about another', () {
      final notes = [
        for (final e in game.data.enemies.values)
          if (e.lore case final n?) (e.id, n.about),
      ];
      expect(notes, hasLength(16));
      expect(notes, contains(('goblin', 'goblin_brute')));
      expect(notes, contains(('fire_drake', 'young_dragon')));
      for (final (from, about) in notes) {
        expect(game.data.enemies.containsKey(about), isTrue, reason: from);
      }
      expect(game.data.combat.loreChance, 0.01);
    });

    // Every kill rolls the note: it drops on the first and never again.
    final sure = newTestGame(
      overrides: {
        'economy': {
          ...dataJson('economy'),
          'combat': combatJson({'loreChance': 1}),
        },
      },
    );

    test('drops only from its monster, at most once', () {
      var s = sure.startActivity(
        stateAt(sure, location: 'goblin_woods', level: 5),
        const Activity.fight('goblin'),
      );
      final r = sure.applySteps(s, 1000);
      final note = sure.data.enemies['goblin']!.lore!.id;
      expect(r.events.whereType<LoreFound>().map((e) => e.note), [note]);
      expect(r.state.lore, {note});
      expect(r.events.whereType<FightWon>().length, greaterThan(5));

      s = sure.startActivity(
        stateAt(sure, location: 'goblin_woods', level: 30),
        const Activity.fight('old_bear'),
      );
      final bear = sure.applySteps(s, 1000);
      expect(bear.events.whereType<FightWon>(), isNotEmpty);
      expect(bear.events.whereType<LoreFound>(), isEmpty, reason: 'no note');
    });

    test('a note reveals its subject\'s armour and weakness, not stats', () {
      final s = stateAt(game)..lore.add(game.data.enemies['goblin']!.lore!.id);
      final k = game.knowledge(s, 'goblin_brute');
      expect((k.armour, k.weakness, k.stats), (true, true, false));
      expect(game.knowledge(s, 'goblin').armour, isFalse);
    });

    test('notes keep the order they were found in', () {
      final s = stateAt(game)..lore.addAll(['note_b', 'note_a']);
      final back = GameState.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, Object?>,
      );
      expect(back.lore.toList(), ['note_b', 'note_a']);
    });
  });

  group('Next goal compares weapons within type and hands (§5.3)', () {
    test('it never suggests a sword for the mace you hold', () {
      final s = stateAt(game, level: 8, inventory: {'bone_sword': 1})
        ..equipment['mainHand'] = 'copper_mace';
      expect(game.nextGoal(s), isNot(isA<EquipGoal>()));
      s.inventory['bone_club'] = 1;
      expect(
        game.nextGoal(s),
        isA<EquipGoal>().having((g) => g.item, 'item', 'bone_club'),
      );
    });
  });
}
