// "Until the bag is full": spec 0021 amendment 3 criteria 4-7 and 9 (plan
// 0051, #224). The screens (criteria 1-3, 8) are in the app's tests.
import 'dart:convert';

import 'package:game_core/game_core.dart';
import 'package:test/test.dart';

import 'support.dart';

void main() {
  final game = newTestGame();
  final data = game.data;
  const full = StopCondition.untilFull();

  /// [n] kinds of material for the bag, none of [except].
  Map<String, int> filler(int n, {Set<String> except = const {}}) => {
    for (final id
        in data.items.keys
            .where((id) {
              final i = data.items[id]!;
              return i.slot == null &&
                  i.tool == null &&
                  i.meal == null &&
                  !except.contains(id);
            })
            .take(n))
      id: 1,
  };

  /// The reason an action ended in [r], if one did.
  EndReason? endOf(StepReport r) =>
      r.events.whereType<ActivityEnded>().firstOrNull?.reason;

  final vein = {'copper_ore', 'garnet'};

  test('the bag of 40 spaces is what the tests fill', () {
    final s = stateAt(game, location: 'copper_hills', level: 5);
    expect(game.bagSpaces(s), 40);
    expect(filler(39, except: vein), hasLength(39));
  });

  test('criterion 4: with one free space, a gather stops at the unit that '
      'brings a new kind of item into the bag', () {
    final s = stateAt(
      game,
      location: 'copper_hills',
      level: 5,
      inventory: filler(39, except: vein),
    );
    expect(game.spacesUsed(s), 39);
    final r = game.applySteps(
      game.startActivity(s, const Activity.gather('copper_vein'), stop: full),
      1000,
    );
    expect(r.state.inventory['copper_ore'], 1, reason: 'one unit, then stop');
    expect(game.spacesUsed(r.state), 40);
    expect(r.state.activity, isNull);
    expect(endOf(r), EndReason.bagFull);
  });

  test('criterion 5: a gather goes on while its catch only adds to a stack '
      'in the bag', () {
    final s = stateAt(
      game,
      location: 'copper_hills',
      level: 5,
      // The vein's ore and its rare find (garnet) both have a stack already,
      // so no roll can use the free space.
      inventory: {
        ...filler(37, except: vein),
        'copper_ore': 1,
        'garnet': 1,
      },
    );
    expect(game.spacesUsed(s), 39);
    final r = game.applySteps(
      game.startActivity(s, const Activity.gather('copper_vein'), stop: full),
      500,
    );
    expect(r.state.inventory['copper_ore'], greaterThan(3));
    expect(r.state.activity?.activity, const Activity.gather('copper_vein'));
    expect(endOf(r), isNull);
  });

  test('criterion 6: a fight stops at the fight whose loot uses the last free '
      'space', () {
    final drops = {for (final d in data.enemies['goblin']!.drops) d.item};
    final s = stateAt(
      game,
      location: 'goblin_woods',
      level: 8,
      inventory: filler(39, except: drops),
    );
    expect(game.spacesUsed(s), 39);
    final r = game.applySteps(
      game.startActivity(s, const Activity.fight('goblin'), stop: full),
      20000,
    );
    expect(endOf(r), EndReason.bagFull);
    // One fight's loot can hold two new kinds (two drops, or a drop of a
    // quality with its own key), so the bag ends at 40 or 41: the game does
    // not know the loot before the roll.
    expect(game.spacesUsed(r.state), inInclusiveRange(40, 41));
    expect(r.state.activity, isNull);
    // It stopped at the first fight that brought a new kind: every new kind
    // came from that one fight, so the fights before it brought none.
    final wins = r.events.whereType<FightWon>().toList();
    expect(wins, isNotEmpty);
    expect(
      wins
          .take(wins.length - 1)
          .every((w) => w.drops.keys.every(s.inventory.containsKey)),
      isTrue,
      reason: 'an earlier fight already brought a new kind',
    );
    // The loot of one fight brought the bag to 40 or a little past it.
    expect(r.state.inventory.keys.where(drops.contains), isNotEmpty);
  });

  test('criterion 7: with no free space left, an action with this stop is '
      'refused with "Your bag is already full"', () {
    final s = stateAt(
      game,
      location: 'copper_hills',
      level: 5,
      inventory: filler(40, except: vein),
    );
    expect(
      () => game.startActivity(
        s,
        const Activity.gather('copper_vein'),
        stop: full,
      ),
      throwsA(
        isA<ActivityError>().having(
          (e) => e.message,
          'message',
          'Your bag is already full',
        ),
      ),
    );
  });

  test(
    'criterion 9: a save with this stop in its queue loads and keeps it',
    () {
      final s = stateAt(game, location: 'goblin_woods', level: 8)
        ..queue.add(const PlannedAction(Activity.fight('goblin'), full));
      final json = jsonEncode(s.toJson());
      expect(json, contains('"untilFull"'));
      final back = GameState.fromJson(jsonDecode(json) as Map<String, Object?>);
      expect(back.queue.single.stop, full);
    },
  );

  test('only fights and gathering offer it', () {
    final s = stateAt(game, level: 5);
    expect(
      game.stopKindsFor(s, const Activity.fight('goblin')),
      contains(StopKind.untilFull),
    );
    expect(
      game.stopKindsFor(s, const Activity.gather('copper_vein')),
      contains(StopKind.untilFull),
    );
    for (final a in const [
      Activity.craft('copper_sword'),
      Activity.travel('goblin_woods'),
    ]) {
      expect(
        game.stopKindsFor(s, a),
        isNot(contains(StopKind.untilFull)),
        reason: '$a',
      );
    }
  });
}
