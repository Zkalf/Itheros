// Spec 0014 §3.3, plan 0017 M5: main() decodes the splash picture before the
// first frame, so that the splash shows its picture from its first frame.
// Without the decode, the first frame shows the dark wordmark on the black
// case, and the picture comes some frames later.
// start_screens_test.dart holds the tests of criterion 24.
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderImage;
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/onboarding_screens.dart';

void main() {
  testWidgets('after precacheSplash, the first frame of the splash has the '
      'splash picture', (t) async {
    // The decode is real work outside the fake clock of the test.
    await t.runAsync(precacheSplash);
    t.view
      ..physicalSize = const Size(1080, 2400)
      ..devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(const MaterialApp(home: LoadingScreen()));
    final picture = t.renderObject<RenderImage>(find.byType(RawImage)).image;
    expect(picture, isNotNull, reason: 'the image cache has no picture yet');
    expect((picture!.width, picture.height), (1024, 1536));
  });
}
