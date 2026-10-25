// Spec 0014 amendment 2 (issue #68): each name on the World map stays next to
// its own place, keeps the middle of its text off the roads, and does not move
// when Smugglers' Cove shows or a place leaves the fog.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/world_tab.dart';

import 'images_test.dart' show loadFonts, socketIn;
import 'ui_test.dart' show game;
import 'world_route_test.dart'
    show area, nameBox, painterIn, platesOf, pumpWorld, textIn;

final _world = find.byType(WorldTab);
final _places = game.data.locations.keys.toList();

String _name(String place) => game.data.locations[place]!.name;

/// The distance from [x] to the segment from [a] to [b].
double _toSegment(Offset x, Offset a, Offset b) {
  final d = b - a;
  final t = (((x - a).dx * d.dx + (x - a).dy * d.dy) / d.distanceSquared).clamp(
    0.0,
    1.0,
  );
  return (x - (a + d * t)).distance;
}

/// The shortest distance from [x] to [r]; 0 inside it.
double _toRect(Offset x, Rect r) =>
    (x - Offset(x.dx.clamp(r.left, r.right), x.dy.clamp(r.top, r.bottom)))
        .distance;

/// The rect of the name of each place on the World map.
Map<String, Rect> _names(WidgetTester t, {String Function(String)? shown}) => {
  for (final p in _places)
    if (area(p).evaluate().isNotEmpty)
      p: nameBox(t, area(p), (shown ?? _name)(p)),
};

bool _contains(Rect outer, Rect r) =>
    r.left >= outer.left - .01 &&
    r.top >= outer.top - .01 &&
    r.right <= outer.right + .01 &&
    r.bottom <= outer.bottom + .01;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  group('spec 0014 amendment 2: placement', () {
    testWidgets('criterion 1: at 360 dp, for each current place, the marker '
        'nearest to the middle of each name is the marker of its own place', (
      t,
    ) async {
      for (final here in _places) {
        await pumpWorld(t, here);
        final markers = {
          for (final p in _places) p: t.getRect(socketIn(area(p))),
        };
        for (final MapEntry(key: p, value: name) in _names(t).entries) {
          final nearest = _places.reduce(
            (a, b) =>
                _toRect(name.center, markers[a]!) <=
                    _toRect(name.center, markers[b]!)
                ? a
                : b,
          );
          expect(
            nearest,
            p,
            reason: 'at $here: the name of $p is nearest to $nearest',
          );
        }
      }
    });

    testWidgets('criterion 2: at 360 dp, for each current place, the middle '
        'of each name is at least half its height from each road with a '
        'step plate', (t) async {
      for (final here in _places) {
        await pumpWorld(t, here);
        final (painter, box) = painterIn(t, _world);
        final roads = [for (final (_, a, b) in platesOf(painter, box)) (a, b)];
        expect(roads, isNotEmpty, reason: 'at $here');
        for (final MapEntry(key: p, value: name) in _names(t).entries) {
          for (final (a, b) in roads) {
            expect(
              _toSegment(name.center, a, b),
              greaterThanOrEqualTo(name.height / 2 - .01),
              reason: 'at $here: a road runs through the name of $p',
            );
          }
        }
      }
    });

    testWidgets('criterion 4: the names on the map are 13 dp', (t) async {
      await pumpWorld(t, 'camp');
      for (final p in _places) {
        final text = t.widget<RichText>(textIn(area(p), _name(p)));
        expect(text.text.style?.fontSize, 13, reason: p);
      }
    });
  });

  group('spec 0014 amendment 2: names do not move', () {
    testWidgets('criterion 5: at 360 dp, with Camp as the current place, '
        "each name has the same rect before and after Smugglers' Cove shows", (
      t,
    ) async {
      await pumpWorld(
        t,
        'camp',
        change: (s) => s.revealed.remove('smugglers_cove'),
      );
      expect(area('smugglers_cove'), findsNothing);
      final before = _names(t);
      await pumpWorld(t, 'camp');
      final after = _names(t);
      for (final MapEntry(key: p, value: rect) in before.entries) {
        expect(after[p], rect, reason: 'the name of $p moved');
      }
    });

    testWidgets('criterion 6: at 360 dp, with Camp as the current place, the '
        '"???" name of a place in the fog lies inside the rect of its real '
        'name', (t) async {
      final c = await pumpWorld(t, 'camp', everywhere: false);
      final fogged = [
        for (final p in _places)
          if (area(p).evaluate().isNotEmpty && c.game.isFogged(c.state, p)) p,
      ];
      expect(fogged, isNotEmpty);
      final inFog = {for (final p in fogged) p: nameBox(t, area(p), '???')};
      await pumpWorld(t, 'camp');
      final real = _names(t);
      for (final p in fogged) {
        expect(
          _contains(real[p]!, inFog[p]!),
          isTrue,
          reason: 'the "???" of $p at ${inFog[p]} lies outside ${real[p]}',
        );
      }
    });

    testWidgets('criterion 7: the World map draws no hidden place, no road to '
        'a hidden place and no step count on a road into the fog', (t) async {
      final c = await pumpWorld(t, 'camp', everywhere: false);
      expect(area('smugglers_cove'), findsNothing);
      final (painter, box) = painterIn(t, _world);
      final visible = [
        for (final r in game.data.routes)
          if (!c.game.isHidden(c.state, r.from) &&
              !c.game.isHidden(c.state, r.to))
            r,
      ];
      expect(painter.paths, hasLength(visible.length));
      final counted = visible.where(
        (r) =>
            !c.game.isFogged(c.state, r.from) &&
            !c.game.isFogged(c.state, r.to),
      );
      expect(platesOf(painter, box), hasLength(counted.length));
    });
  });

  group('spec 0014 amendment 2: places', () {
    test('criteria 8 and 9: Camp, Mirror Lake and Copper Hills have their new '
        'map points, and each other place keeps its map point', () {
      const points = {
        'camp': (0.36, 0.92),
        'goblin_woods': (0.42, 0.76),
        'copper_hills': (0.84, 0.76),
        'old_graveyard': (0.14, 0.68),
        'grey_moor': (0.32, 0.45),
        'iron_ridge': (0.8, 0.47),
        'troll_bridge': (0.22, 0.3),
        'mountain_pass': (0.55, 0.19),
        'mithril_deep': (0.85, 0.27),
        'dragons_peak': (0.3, 0.06),
        'mirror_lake': (0.72, 0.89),
        'smugglers_cove': (0.95, 0.96),
      };
      expect(game.data.locations.keys.toSet(), points.keys.toSet());
      for (final MapEntry(key: p, value: (x, y)) in points.entries) {
        final m = game.data.locations[p]!.map!;
        expect((m.x, m.y), (x, y), reason: p);
      }
    });
  });
}
