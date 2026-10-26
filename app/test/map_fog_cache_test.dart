// Issue #121: a sheet over the World map opened at about 20 frames a
// second on the Fairphone, because the fog blurred the whole map image again
// on each frame. Once the map image has loaded, the fog draws the blurred,
// pale map from an image made once, and no live blur is left.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/images.dart' show Picture;

import 'ui_test.dart' show openTab, pumpGame;

void main() {
  testWidgets('the fog of a loaded map has no live blur', (t) async {
    await pumpGame(t);
    await openTab(t, 'world');
    final fog = find.byKey(const ValueKey('map-fog'));
    expect(fog, findsOneWidget);
    // The map image decodes outside the fake clock of the test.
    await t.runAsync(
      () => precacheImage(
        AssetImage(const Picture('pictures/world_map').asset!),
        t.element(fog),
      ),
    );
    await t.pumpAndSettle();
    expect(
      find.descendant(of: fog, matching: find.byType(ImageFiltered)),
      findsNothing,
      reason: 'no blur on each frame',
    );
    expect(
      find.descendant(of: fog, matching: find.byType(RawImage)),
      findsOneWidget,
      reason: 'the blurred, pale map, made once',
    );
  });
}
