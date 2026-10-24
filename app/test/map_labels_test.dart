// Plan 0017 M3 review: placeMapLabels tells whether its placement keeps each
// rule of the map labels, or whether it fell back to the least overlap, and
// which size each name took (spec 0014 §2.3).
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/map_labels.dart';

import 'images_test.dart' show loadFonts;
import 'ui_test.dart' show game;
import 'world_route_test.dart' show realLabels;

void main() {
  // The fonts load from disk, so that the names have the size that the
  // player sees.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  group('spec 0014 §2.3: placeMapLabels tells how it placed the labels', () {
    test('on the World map at 360 dp, for each current place, the placement '
        'keeps each rule with no fallback, and each name has the index of '
        'its size', () {
      final map = Size(360, 360 * game.data.mapAspect);
      for (final here in game.data.locations.keys) {
        final (:names, :plates) = realLabels(here);
        final placed = placeMapLabels(map: map, names: names, plates: plates);
        expect(placed.clean, isTrue, reason: 'at $here');
        for (final n in names) {
          expect(
            n.sizes[placed.sizes[n.place]!],
            placed.names[n.place]!.size,
            reason: 'at $here: the size of the name of ${n.place}',
          );
        }
      }
    });

    test('a name that does not fit on one line takes its next size, index '
        '1', () {
      final placed = placeMapLabels(
        map: const Size(120, 200),
        names: [
          MapName(
            place: 'x',
            marker: Rect.fromCenter(
              center: const Offset(60, 100),
              width: 40,
              height: 40,
            ),
            sizes: const [Size(160, 18), Size(90, 36)],
          ),
        ],
        plates: const [],
      );
      expect(placed.clean, isTrue);
      expect(placed.sizes['x'], 1);
    });

    test('a name with no free spot makes the placement a fallback, and the '
        'name still gets a rect of its size', () {
      final placed = placeMapLabels(
        map: const Size(100, 100),
        names: [
          MapName(
            place: 'x',
            marker: Rect.fromCenter(
              center: const Offset(50, 50),
              width: 40,
              height: 40,
            ),
            sizes: const [Size(100, 40)],
          ),
        ],
        plates: const [],
      );
      expect(placed.clean, isFalse);
      expect(placed.sizes['x'], 0);
      expect(placed.names['x']!.size, const Size(100, 40));
    });
  });
}
