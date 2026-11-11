// The drawn icons of #198: the talents and the small icons of Camp and the
// level-up card replace the stock icons, tinted the same way. Without a file
// the stock icon stays (other tests run with no image files).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'images_test.dart' show diskImages, imagesIn;
import 'ui_test.dart';

void main() {
  Finder key(String k) => find.byKey(ValueKey(k));
  const icons = ['bank', 'forge', 'fire', 'trainer', 'level', 'spot', 'talent'];

  test('each talent image and each drawn icon has its file', () {
    final images = {for (final t in game.data.talents.values) t.image};
    expect(images, hasLength(17));
    for (final i in images) {
      expect(diskImages.has('talents/$i'), isTrue, reason: i);
    }
    for (final i in icons) {
      expect(diskImages.has('icons/$i'), isTrue, reason: i);
    }
  });

  testWidgets('each talent on the Talents tab shows its drawn icon in teal', (
    t,
  ) async {
    await pumpGame(t, level: 30, images: diskImages);
    await openTab(t, 'character');
    await t.tap(key('tab-talents'));
    await t.pumpAndSettle();
    final shown = t.widgetList<Image>(
      find.byWidgetPredicate(
        (w) =>
            w is Image &&
            switch (w.key) {
              ValueKey<String>(:final value) => value.startsWith(
                'talent-icon-',
              ),
              _ => false,
            },
      ),
    );
    expect(shown, isNotEmpty);
    for (final i in shown) {
      expect(i.colorBlendMode, BlendMode.srcIn);
      expect(i.color, isNotNull);
    }
    // No talent keeps a stock icon.
    for (final stock in [Icons.sports_martial_arts, Icons.favorite]) {
      expect(find.byIcon(stock), findsNothing);
    }
  });

  testWidgets('at Camp, the Bank, Forge, Camp fire and trainer rows show '
      'their drawn icons', (t) async {
    await pumpGame(t, images: diskImages);
    for (final (row, icon) in [
      ('bank-card', 'bank'),
      ('here-forge', 'forge'),
      ('here-fire', 'fire'),
      ('trainer', 'trainer'),
    ]) {
      expect(imagesIn(t, key(row)), [
        'assets/images/icons/$icon.webp',
      ], reason: row);
    }
  });

  testWidgets('without the files the rows keep their stock icons', (t) async {
    await pumpGame(t);
    expect(
      find.descendant(
        of: key('bank-card'),
        matching: find.byIcon(Icons.account_balance),
      ),
      findsOneWidget,
    );
    expect(key('drawn-icon-bank'), findsNothing);
  });
}
