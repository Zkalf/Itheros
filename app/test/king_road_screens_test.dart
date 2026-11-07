// The Graveyard King opens the river, on screen: spec 0008 amendment 5,
// criteria 14-17, 19 and 22, and the skip line of change 7.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/sync/away_summary.dart';
import 'package:walkingrpg/ui/away_summary_card.dart';
import 'package:walkingrpg/ui/camp_tour.dart';
import 'package:walkingrpg/ui/labels.dart';
import 'package:walkingrpg/ui/world_tab.dart';

import 'support.dart';
import 'ui_test.dart' show openTab, pumpGame;

void main() {
  const lock = ValueKey('road-lock-old_graveyard-grey_moor');
  const line = 'Beat the Graveyard King to cross.';

  /// A player who has stood in Old Graveyard: Grey Moor shows across the
  /// river. [king]: the King fell once.
  void Function(GameState) south({bool king = false}) => (s) {
    s.explored.add('old_graveyard');
    if (king) s.counters['kills.graveyard_king'] = 1;
  };

  Future<void> openMoor(WidgetTester t) async {
    await openTab(t, 'world');
    await t.tap(find.byKey(const ValueKey('area-grey_moor')));
    await t.pumpAndSettle();
  }

  group('the World map', () {
    /// The step count the map draws on the road across the river.
    String? riverCount(WidgetTester t) => t
        .widget<MapView>(find.byType(MapView))
        .roads
        .singleWhere(
          (r) => {r.$1, r.$2}.containsAll(['old_graveyard', 'grey_moor']),
        )
        .$3;

    testWidgets('criterion 14: the closed road shows the lock, and no step '
        'count (owner, 2026-11-07)', (t) async {
      await pumpGame(t, prepare: south());
      await openTab(t, 'world');
      expect(find.byKey(lock), findsOneWidget);
      expect(riverCount(t), isNull);
    });

    testWidgets('criterion 15: an open road shows no lock, and its count', (
      t,
    ) async {
      await pumpGame(t, prepare: south(king: true));
      await openTab(t, 'world');
      expect(find.byKey(lock), findsNothing);
      expect(riverCount(t), '800');
    });

    testWidgets('criterion 16: Grey Moor says to beat the King, with no Walk '
        'here', (t) async {
      await pumpGame(t, prepare: south());
      await openMoor(t);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('road-closed')),
          matching: find.textContaining(line, findRichText: true),
        ),
        findsOneWidget,
      );
      expect(find.text('Walk here'), findsNothing);
      // At the top, under the name, so it shows at text size 2.0 too
      // (owner, 2026-11-07).
      expect(find.text('No open road leads here'), findsNothing);
      expect(
        t.getTopLeft(find.byKey(const ValueKey('road-closed'))).dy,
        lessThan(t.getTopLeft(find.text('Wolf')).dy),
      );
    });

    testWidgets('criterion 17: with the road open, Grey Moor has Walk here', (
      t,
    ) async {
      await pumpGame(t, prepare: south(king: true));
      await openMoor(t);
      expect(find.text('Walk here'), findsOneWidget);
      expect(find.byKey(const ValueKey('road-closed')), findsNothing);
    });

    testWidgets('a place with no closed road in the way has no such line', (
      t,
    ) async {
      await pumpGame(t, prepare: south());
      await openTab(t, 'world');
      await t.tap(find.byKey(const ValueKey('area-goblin_woods')));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('road-closed')), findsNothing);
      expect(find.text('Walk here'), findsOneWidget);
    });
  });

  group('the report', () {
    final game = loadTestGame();
    final labels = Labels(game.data);

    /// A level 30 player at Old Graveyard fights the King until he falls.
    StepReport fight({bool killed = false}) {
      final s = game.newGame(seed: 1)
        ..location = 'old_graveyard'
        ..xp = game.data.xpForLevel(30)
        ..explored.add('old_graveyard');
      if (killed) s.counters['kills.graveyard_king'] = 1;
      return game.applySteps(
        game.startActivity(s, const Activity.fight('graveyard_king')),
        20000,
      );
    }

    List<String> news(StepReport r) => [
      for (final (_, text) in reportNews(AwaySummary.fromReports([r]), labels))
        text,
    ];

    test('criterion 19: the first King kill says the road is open', () {
      final r = fight();
      expect(r.events.whereType<FightWon>(), isNotEmpty);
      expect(
        news(r),
        contains('The King falls. The road to Grey Moor is open.'),
      );
      // It comes with the King's picture.
      final summary = AwaySummary.fromReports([r]);
      expect(summary.roadsOpened, [('graveyard_king', 'grey_moor')]);
      // It survives the journal's save.
      expect(
        AwaySummary.fromJson(summary.toJson()).roadsOpened,
        summary.roadsOpened,
      );
    });

    test('a later King kill says nothing of the road', () {
      final r = fight(killed: true);
      expect(r.events.whereType<FightWon>(), isNotEmpty);
      expect(news(r).where((n) => n.contains('road')), isEmpty);
    });

    test('change 7: the report of a skipped walk across names the King, also '
        'after the journal saves it', () {
      final s = game.startActivity(
        game.newGame(seed: 1)..explored.add('old_graveyard'),
        const Activity.travel('old_graveyard'),
      );
      // A queue from before the road closed, as an old save may hold.
      s.queue.add(
        PlannedAction(
          const Activity.travel('grey_moor'),
          StopCondition.defaultFor(const Activity.travel('grey_moor')),
        ),
      );
      final summary = AwaySummary.fromReports([game.applySteps(s, 2000)]);
      const said =
          'Skipped the walk to Grey Moor: beat the Graveyard King to cross.';
      final skip = summary.actions.singleWhere((a) => a.skipped != null);
      expect(skip.closedBy, 'graveyard_king');
      expect(labels.actionLines(skip), [said]);
      final again = AwaySummary.fromJson(summary.toJson());
      expect(
        labels.actionLines(again.actions.singleWhere((a) => a.skipped != null)),
        [said],
      );
    });

    test('change 7: a skipped walk across the river names the King', () {
      expect(
        labels.skipLine(
          const Activity.travel('grey_moor'),
          SkipReason.noRoute,
          const {},
          closedBy: 'graveyard_king',
        ),
        'Skipped the walk to Grey Moor: beat the Graveyard King to cross.',
      );
      expect(
        labels.skipLine(
          const Activity.travel('grey_moor'),
          SkipReason.noRoute,
          const {},
        ),
        isNot(contains('King')),
      );
    });
  });

  test('criterion 22: card 2 of the camp tour names the King', () {
    expect(
      tourSteps[1].words,
      'This is the map. Tap a place to travel there, or to see what lives '
      'there. Beat the Graveyard King to cross the river.',
    );
  });
}
