// Issue #121: a sheet over the World map opened at about 20 frames a
// second on the Fairphone, because the map was drawn again on each frame of
// the sheet animation, its fog most of all. Once the map image has loaded,
// the whole fog (the blurred, pale map, the veil, the holes and the clouds) is
// one image, made when the fog changes, with no live filter or layer.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/images.dart' show Picture;
import 'package:walkingrpg/ui/world_tab.dart' show FogImage;

import 'ui_test.dart' show openTab, pumpGame;

void main() {
  testWidgets('the fog of a loaded map is one image, with no live filter', (
    t,
  ) async {
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
    final made = find.descendant(of: fog, matching: find.byType(FogImage));
    expect(made, findsOneWidget, reason: 'the fog, made once');
    for (final type in [ImageFiltered, ColorFiltered, CustomPaint]) {
      expect(
        find.descendant(of: fog, matching: find.byType(type)),
        findsNothing,
        reason: 'no live $type on each frame',
      );
    }
    // A tap on a place still opens its sheet.
    await t.tap(find.byKey(const ValueKey('area-camp')));
    await t.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
  });
}
