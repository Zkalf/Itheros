// #179: the Character tab opens on the Bag pane.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ui_test.dart';

void main() {
  testWidgets('the Character tab opens on Bag', (t) async {
    await pumpGame(t);
    await openTab(t, 'character');
    expect(find.byKey(const ValueKey('bag-spaces')), findsOneWidget);
  });
}
