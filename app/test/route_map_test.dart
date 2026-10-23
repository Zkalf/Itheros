// Plan 0017 M3 review: the route map keeps the rule of the map labels for
// each route, on a phone of 360 dp and on one of 320 dp (spec 0014 §2.3 and
// §5). Each route is a journal entry of a save, so the Journal shows its
// route map. The checks read the rects as drawn: the route map may be drawn
// smaller than its layout.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/persistence/save_data.dart';
import 'package:walkingrpg/sync/away_summary.dart';

import 'images_test.dart' show loadFonts;
import 'quiet_teal_test.dart' show openJournal;
import 'ui_test.dart' show ada, game, pumpSave;
import 'world_route_test.dart' show expectRouteMap;

void main() {
  // The fonts load from disk, so that the names have the size that the
  // player sees.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  final routes = {
    // Each road of the world as a route of two places.
    for (final r in game.data.routes) '${r.from} to ${r.to}': [r.from, r.to],
    // The route of the design board of M3.
    'the route of the design board': [
      'goblin_woods',
      'camp',
      'mirror_lake',
      'smugglers_cove',
    ],
    'a route through all 12 places': [
      'camp',
      'goblin_woods',
      'old_graveyard',
      'grey_moor',
      'troll_bridge',
      'mountain_pass',
      'dragons_peak',
      'mountain_pass',
      'mithril_deep',
      'mountain_pass',
      'troll_bridge',
      'grey_moor',
      'iron_ridge',
      'grey_moor',
      'old_graveyard',
      'camp',
      'copper_hills',
      'mirror_lake',
      'smugglers_cove',
    ],
  };

  for (final width in [360.0, 320.0]) {
    group('spec 0014 §2.3 and §5: on a phone of $width dp, the route map '
        'keeps the rule of the map labels', () {
      test('the routes hold each place, and one route for each road', () {
        expect(
          routes.values.expand((r) => r).toSet(),
          game.data.locations.keys.toSet(),
        );
        expect(routes, hasLength(game.data.routes.length + 2));
      });

      for (final MapEntry(key: name, value: route) in routes.entries) {
        testWidgets(name, (t) async {
          await pumpJournal(t, route, width);
          expectRouteMap(
            t,
            find.byKey(const ValueKey('route-map')),
            route,
            '$name at $width dp',
          );
        });
      }
    });
  }
}

/// Starts the app on a save with one journal entry with [route], on a phone
/// [width] dp wide, and opens the Journal.
Future<void> pumpJournal(
  WidgetTester t,
  List<String> route,
  double width,
) async {
  final state = game.newGame(seed: 1)..character = ada;
  await pumpSave(
    t,
    SaveData(
      game: state,
      firstDay: '2026-10-18',
      credited: const {},
      journal: [
        JournalEntry(
          started: DateTime(2026, 10, 18, 8),
          summary: AwaySummary(walked: 1000, route: route),
        ),
      ],
    ).toJson(),
  );
  t.view.physicalSize = Size(width, 2400);
  await t.pumpAndSettle();
  await openJournal(t);
}
