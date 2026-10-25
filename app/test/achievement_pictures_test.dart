// Spec 0014 amendment 3 (issue #88): each row of the Achievements screen
// starts with a 72 dp picture, centred on the height of the row, and keeps
// its words, its bar, its chips and its rim.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/ui/achievements_screen.dart';
import 'package:walkingrpg/ui/theme.dart' show plateShape;

import 'images_test.dart' show diskImages, loadFonts, socketIn;
import 'ui_test.dart' show game, openAchievements, pumpGame;

Finder _row(String id) => find.byKey(ValueKey('achievement-$id'));

/// Scrolls the Achievements list until the row of [id] shows. The list
/// groups the rows by stage, so each search starts at the top.
Future<void> _show(WidgetTester t, String id) async {
  final list = find.descendant(
    of: find.byType(AchievementsScreen),
    matching: find.byType(Scrollable),
  );
  t.state<ScrollableState>(list.first).position.jumpTo(0);
  await t.pump();
  await t.scrollUntilVisible(_row(id), 200, scrollable: list.first);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  testWidgets('criterion 3: the socket of each row is centred on the height '
      'of its row, with at least 8 dp above and below it', (t) async {
    final (c, _) = await pumpGame(t, images: diskImages);
    c.state.achievements.addAll(['first_steps', 'smith']);
    await openAchievements(t);
    for (final a in game.data.achievements.values) {
      await _show(t, a.id);
      final row = _row(a.id);
      // The plate of the card, without its margin below.
      final box = t.getRect(
        find.descendant(of: row, matching: find.byType(Material)).first,
      );
      final socket = t.getRect(socketIn(row));
      final what = '${a.id}: socket $socket in row $box';
      expect(
        (socket.center.dy - box.center.dy).abs(),
        lessThan(.5),
        reason: what,
      );
      expect(socket.top - box.top, greaterThanOrEqualTo(8), reason: what);
      expect(box.bottom - socket.bottom, greaterThanOrEqualTo(8), reason: what);
    }
  });

  testWidgets('criterion 4: a row still shows its name, its goal, its reward, '
      'its bar when locked, and "New" when fresh', (t) async {
    final (c, _) = await pumpGame(t, images: diskImages);
    c.state.achievements.add('first_steps');
    await openAchievements(t);
    final earned = _row('first_steps');
    for (final text in ['First Steps', 'Walk 10,000 steps']) {
      expect(
        find.descendant(of: earned, matching: find.text(text)),
        findsOneWidget,
        reason: text,
      );
    }
    expect(
      find.descendant(of: earned, matching: find.textContaining('Reward: ')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: earned,
        matching: find.byKey(const ValueKey('achievement-new-first_steps')),
      ),
      findsOneWidget,
    );
    await _show(t, 'prospector');
    expect(
      find.descendant(
        of: _row('prospector'),
        matching: find.byType(LinearProgressIndicator),
      ),
      findsOneWidget,
    );
  });

  testWidgets('change 3: a feat keeps its "Feat" chip in its row, and an '
      'earned row keeps its teal rim', (t) async {
    final (c, _) = await pumpGame(t, images: diskImages);
    c.state.achievements.add('first_steps');
    await openAchievements(t);
    final feat = game.data.achievements.values.firstWhere(
      (a) => a.kind == AchievementKind.feat,
    );
    await _show(t, feat.id);
    expect(
      find.descendant(
        of: _row(feat.id),
        matching: find.byKey(ValueKey('achievement-feat-${feat.id}')),
      ),
      findsOneWidget,
    );
    await _show(t, 'first_steps');
    expect(
      t.widget<Card>(_row('first_steps')).shape,
      plateShape(selected: true),
    );
    expect(t.widget<Card>(_row('prospector')).shape, plateShape());
  });
}
