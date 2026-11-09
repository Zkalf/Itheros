// The monster roster with damage rolls: the reference checks that stay after
// spec 0002 amendment 3. The fight length, the win rates at even level and
// the XP per step are walker targets now (amendment 3, targets 3-6, in
// pacing_test.dart). Here: the bosses' gear checks without gear and 3
// levels below (spec 0002 §5.3, amendment 1), the strong weapon type (spec
// 0009 §9.1) and spec 0009 criterion 6, the two-hander and shield targets
// of §4.2.
import 'package:game_core/simulation.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();

  for (final b in bosses(game.data)) {
    group('criterion 6: ${b.id}', () {
      final check = bossCheck(game, b.id);

      test('even level without gear wins at most 10%', () {
        expect(check.bare.winRate, lessThanOrEqualTo(0.1));
      });

      if (!check.first) {
        test('3 levels below with their own gear wins at most 10%', () {
          expect(check.other.winRate, lessThanOrEqualTo(0.1));
        });
      }
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

  // In common crafted gear a player now loses often at even level, so the
  // weapons are compared 5 levels above each monster, where the one-hander
  // wins (spec 0002 amendment 3, erratum 1).
  group('spec 0009 criterion 6: one hand and shield, or two hands', () {
    for (final h in handsChecks(game, above: 5)) {
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
