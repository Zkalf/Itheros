// The monster roster with damage rolls: spec 0002 §5.2–§5.3, acceptance
// criteria 4 and 6 (as amended by amendment 1), held by spec 0009 criterion
// 15. Each monster is fought 200 times by an even-level player wearing that
// stretch's crafted gear, with the one-hander of the type strong against it
// and a shield (spec 0009 §9.1). Then spec 0009 criterion 6: the two-hander
// and shield targets of §4.2.
import 'dart:math' as math;

import 'package:game_core/game_core.dart';
import 'package:game_core/simulation.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final bossIds = {for (final b in bosses(game.data)) b.id};

  /// Spec 0002 §3: XP per step for a monster of [level].
  double rate(int level) => 0.2 * math.pow(1.1, level - 1);

  // Gear made from a boss's own drops is never worn against it.
  FightRecord even(EnemyDef e) => measureFights(
    game,
    referencePlayer(
      game,
      e.level,
      without: bossOnlyItems(game, e.id),
      vs: e.id,
    ),
    e.id,
  );

  final normal =
      game.data.enemies.values
          .where((e) => !bossIds.contains(e.id) && !e.lurker)
          .toList()
        ..sort((a, b) => a.level.compareTo(b.level));
  final records = {for (final e in normal) e.id: even(e)};

  test('criterion 4: each monster pays more per step, by at most a third', () {
    for (var i = 1; i < normal.length; i++) {
      final before = records[normal[i - 1].id]!.xpPerStep;
      final now = records[normal[i].id]!.xpPerStep;
      expect(now, greaterThan(before), reason: normal[i].id);
      expect(now, lessThanOrEqualTo(before * 4 / 3), reason: normal[i].id);
    }
  });

  test('§5.2: an even-level geared player wins at least 90%', () {
    for (final e in normal) {
      expect(records[e.id]!.winRate, greaterThanOrEqualTo(0.9), reason: e.id);
    }
  });

  test('§5.2: normal fights take 4-8 rounds, slow tanks 12-20', () {
    for (final e in normal) {
      final range = e.has(Trait.slow) ? (12, 20) : (4, 8);
      expect(
        records[e.id]!.roundsPerFight,
        inInclusiveRange(range.$1, range.$2),
        reason: e.id,
      );
    }
  });

  test('§3: XP per step is within 15% of the rate for its level', () {
    final everyone = [
      ...normal,
      for (final e in game.data.enemies.values)
        if (bossIds.contains(e.id) || e.lurker) e,
    ];
    for (final e in everyone) {
      final r = records[e.id] ?? even(e);
      expect(
        r.xpPerStep / rate(e.level),
        inInclusiveRange(0.85, 1.15),
        reason: e.id,
      );
    }
  });

  for (final b in bosses(game.data)) {
    group('criterion 6: ${b.id}', () {
      final check = bossCheck(game, b.id);

      test('even level without gear wins at most 10%', () {
        expect(check.bare.winRate, lessThanOrEqualTo(0.1));
      });

      test('even level with the stretch\'s crafted gear wins at least 70%', () {
        expect(check.geared.winRate, greaterThanOrEqualTo(0.7));
      });

      if (check.first) {
        test('5 levels above without gear wins at least 50%', () {
          expect(check.other.winRate, greaterThanOrEqualTo(0.5));
        });
      } else {
        test('3 levels below with their own gear wins at most 10%', () {
          expect(check.other.winRate, lessThanOrEqualTo(0.1));
        });
      }

      test('a fight takes 25-40 rounds', () {
        expect(check.geared.roundsPerFight, inInclusiveRange(25, 40));
      });
    });
  }

  test('spec 0009 §9.1: the reference player arms the strong type', () {
    for (final e in game.data.enemies.values) {
      if (e.level < 3) continue; // no recipe yet: bare hands
      final p = referencePlayer(game, e.level, vs: e.id);
      final weapon = game.data.itemOf(p.equipment['mainHand']!)!;
      expect(
        weapon.damageType,
        game.data.combat.strongAgainst(e.armour),
        reason: e.id,
      );
      expect(weapon.twoHanded, isFalse, reason: e.id);
    }
  });

  group('spec 0009 criterion 6: one hand and shield, or two hands', () {
    for (final h in handsChecks(game)) {
      test('${h.twoHander} wins in about 25% fewer rounds (at least 15%)', () {
        expect(h.roundsCut, inInclusiveRange(0.15, 0.35));
      });

      test('the shield takes at least 20% off the damage (${h.twoHander} '
          'stretch)', () {
        expect(h.shieldCut, greaterThanOrEqualTo(0.2));
      });
    }
  });
}
