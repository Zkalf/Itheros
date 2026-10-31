// Spot tips: Sigrun and Wen tell what lives at each spot. Spec 0010
// amendment 8, criteria 1-11 and 15-18 (plan 0030 M1).
import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;

  /// The ids of [profession]'s tips waiting in [s].
  List<String> waiting(GameState s, String profession) => [
    for (final t in game.tipsWaiting(s, profession)) t.id,
  ];

  /// A new game in camp with [profession] learned from its teacher and
  /// the tips told, as the teacher sheet does after Learn.
  GameState learned(String profession) {
    final s = game.learn(game.newGame(seed: 1), profession);
    return game.talk(s, profession);
  }

  /// Every spot tip in the data, with its teacher's profession.
  final spotTips = [
    for (final p in data.professions.values)
      for (final t in p.tips)
        if (t.node != null) (p.id, t),
  ];

  group('told at the right time', () {
    test('criterion 1: learning Hunting tells the Deer trail tip', () {
      final s = learned('hunting');
      expect(s.tips, containsAll(['sigrun_1', 'sigrun_deer_trail']));
      expect(s.tips, isNot(contains('sigrun_moor_tracks')));
    });

    test('criterion 2: no Moor tracks tip at Hunting 9', () {
      final s = stateAt(game, professionLevel: 9);
      expect(waiting(s, 'hunting'), isNot(contains('sigrun_moor_tracks')));
    });

    test('criterion 3: the Moor tracks tip waits at Hunting 10', () {
      final s = stateAt(game, professionLevel: 10);
      expect(waiting(s, 'hunting'), contains('sigrun_moor_tracks'));
    });

    test('criterion 4: learning Fishing tells the Mirror Lake tip', () {
      expect(learned('fishing').tips, contains('wen_lake_shore'));
    });

    test('criterion 5: no Cove rocks tip without the cove revealed', () {
      final s = stateAt(game, professionLevel: 15);
      expect(waiting(s, 'fishing'), isNot(contains('wen_cove_rocks')));
      expect(game.tipHidden(s, tip('wen_cove_rocks')), isTrue);
    });

    test('criterion 6: the Cove rocks tip waits with the cove revealed', () {
      final s = stateAt(game, professionLevel: 15)
        ..revealed.add('smugglers_cove');
      expect(waiting(s, 'fishing'), contains('wen_cove_rocks'));
      expect(game.tipHidden(s, tip('wen_cove_rocks')), isFalse);
    });

    test('criterion 8: an old save at Hunting 12 has the tip waiting', () {
      final old = stateAt(game, professionLevel: 12)
        ..tips.addAll(['sigrun_1', 'sigrun_10']);
      final s = game.migrate(GameState.fromJson(old.toJson()));
      expect(waiting(s, 'hunting'), [
        'sigrun_deer_trail',
        'sigrun_moor_tracks',
      ]);
    });
  });

  group('what a spot tip does', () {
    test('criterion 9: spot tips reveal no monster', () {
      final s = stateAt(game, professionLevel: 1);
      final told = stateAt(game, professionLevel: 1)
        ..tips.addAll([for (final (_, t) in spotTips) t.id]);
      for (final e in data.enemies.keys) {
        expect(game.knowledge(told, e).armour, game.knowledge(s, e).armour);
        expect(game.knowledge(told, e).weakness, game.knowledge(s, e).weakness);
      }
    });

    test('three hunting spots for Sigrun, four waters for Wen', () {
      expect(
        [for (final (p, t) in spotTips) (p, t.node, t.level)],
        [
          ('fishing', 'lake_shore', 1),
          ('fishing', 'under_the_bridge', 10),
          ('fishing', 'cove_rocks', 15),
          ('fishing', 'cold_tarn', 20),
          ('hunting', 'deer_trail', 1),
          ('hunting', 'moor_tracks', 10),
          ('hunting', 'high_crags', 20),
        ],
      );
    });

    // A catch is named by its animal (hunting) or its fish (fishing).
    String catchName(CatchDef c) =>
        (c.animal ?? data.items[c.item]!.name).toLowerCase();

    test('criterion 10: each text names the common and uncommon catch', () {
      for (final (_, t) in spotTips) {
        final text = t.text.toLowerCase();
        for (final c in data.nodes[t.node]!.catches.take(2)) {
          // "Wild boar" is "wild boar's"; "Eel" is "eels".
          expect(text, contains(catchName(c)), reason: t.id);
        }
      }
    });

    test('criterion 11: each text names the rare animal or fish', () {
      for (final (_, t) in spotTips) {
        final n = data.nodes[t.node]!;
        final rare = (n.rareAnimal ?? data.items[n.rareFind]!.name)
            .toLowerCase();
        final hint = switch (n.id) {
          // Wen calls the cove's trophy "a fish with one eye".
          'cove_rocks' => 'one eye',
          // "The Pale One" is "something pale".
          'cold_tarn' => 'pale',
          // Sigrun says "a lynx's print" up in the snow.
          'high_crags' => 'lynx',
          _ => rare.replaceFirst('the ', ''),
        };
        expect(t.text.toLowerCase(), contains(hint), reason: t.id);
      }
    });
  });

  group('data', () {
    /// `professions.json` with Sigrun's first tip replaced by [tip].
    Map<String, Object?> withTip(Map<String, Object?> tip) {
      final json = dataJson('professions');
      final hunting = (json['professions']! as List)
          .cast<Map<String, Object?>>()
          .firstWhere((p) => p['id'] == 'hunting');
      final teacher = hunting['teacher']! as Map<String, Object?>;
      (teacher['tips']! as List)[0] = {
        'id': 'test_tip',
        'title': 'Test',
        'text': 'Test.',
        ...tip,
      };
      return json;
    }

    void refused(Map<String, Object?> tip) => expect(
      () => loadGameData(overrides: {'professions': withTip(tip)}),
      throwsFormatException,
    );

    test('criterion 15: a tip with both enemy and node is refused', () {
      refused({'level': 1, 'enemy': 'goblin_brute', 'node': 'deer_trail'});
    });

    test('criterion 16: a tip with neither enemy nor node is refused', () {
      refused({'level': 1});
    });

    test('criterion 17: a spot of another profession is refused', () {
      refused({'level': 1, 'node': 'lake_shore'});
    });

    test("criterion 18: a level unlike the spot's is refused", () {
      refused({'level': 5, 'node': 'deer_trail'});
    });

    test('a tip about an unknown spot is refused', () {
      refused({'level': 1, 'node': 'deer_trial'});
    });

    test('tips out of level order are refused', () {
      // Sigrun's first tip moved to level 20, before her level 1 tips.
      refused({'level': 20, 'node': 'high_crags'});
    });

    test('the real data loads', () {
      expect(loadGameData().professions['hunting']!.tips, hasLength(6));
    });
  });
}

/// The tip [id] in the real data.
TipDef tip(String id) => newTestGame().data.professions.values
    .expand((p) => p.tips)
    .firstWhere((t) => t.id == id);
