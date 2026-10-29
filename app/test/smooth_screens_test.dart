// Smooth screen changes and sheets (#136 step 1): a new screen slides in on
// Android, and the World map is drawn as one image while a sheet covers it.
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/theme.dart';
import 'package:walkingrpg/ui/world_tab.dart';

import 'ui_test.dart' show openTab, pumpGame;

void main() {
  test('a new screen slides in on Android, without the default fade', () {
    expect(
      quietTheme.pageTransitionsTheme.builders[TargetPlatform.android],
      isA<CupertinoPageTransitionsBuilder>(),
    );
  });

  testWidgets('the World map is one image while an area sheet covers it, and '
      'live again once the sheet has closed', (t) async {
    await pumpGame(t, location: 'goblin_woods');
    await openTab(t, 'world');
    bool snapshot() => t
        .widget<SnapshotWidget>(
          find.descendant(
            of: find.byType(WorldTab),
            matching: find.byType(SnapshotWidget),
          ),
        )
        .controller
        .allowSnapshotting;

    expect(snapshot(), isFalse, reason: 'live at rest');

    await t.tap(find.byKey(const ValueKey('area-goblin_woods')));
    await t.pumpAndSettle();
    expect(snapshot(), isTrue, reason: 'one image under the sheet');

    // Back: the sheet closes in 200 ms, and the image stays 350 ms more.
    await t.binding.handlePopRoute();
    await t.pump(const Duration(milliseconds: 200));
    expect(snapshot(), isTrue, reason: 'still one image while it closes');
    await t.pump(const Duration(milliseconds: 600));
    await t.pumpAndSettle();
    expect(snapshot(), isFalse, reason: 'live again');
  });
}
