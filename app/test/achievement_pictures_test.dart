// Spec 0014 amendment 3 (issue #88): each row of the Achievements screen
// starts with a 72 dp picture, centred on the height of the row, and keeps
// its words, its bar and its "New" chip.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'images_test.dart' show diskImages, loadFonts, socketIn;
import 'ui_test.dart' show game, openAchievements, pumpGame;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  testWidgets('criterion 3: the socket of each row is centred on the height '
      'of its row', (t) async {
    final (c, _) = await pumpGame(t, images: diskImages);
    c.state.achievements.addAll(['first_steps', 'smith']);
    await openAchievements(t);
    for (final a in game.data.achievements.values) {
      final row = find.byKey(ValueKey('achievement-${a.id}'));
      await t.scrollUntilVisible(row, 200);
      // The plate of the card, without its margin below.
      final box = t.getRect(
        find.descendant(of: row, matching: find.byType(Material)).first,
      );
      final socket = t.getRect(socketIn(row));
      expect(
        (socket.center.dy - box.center.dy).abs(),
        lessThan(.5),
        reason: '${a.id}: socket $socket in row $box',
      );
    }
  });

  testWidgets('criterion 4: a row still shows its name, its goal, its reward, '
      'its bar when locked, and "New" when fresh', (t) async {
    final (c, _) = await pumpGame(t, images: diskImages);
    c.state.achievements.add('first_steps');
    await openAchievements(t);
    final earned = find.byKey(const ValueKey('achievement-first_steps'));
    expect(
      find.descendant(of: earned, matching: find.text('First Steps')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: earned, matching: find.text('Walk 10,000 steps')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: earned,
        matching: find.textContaining('Reward: '),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('achievement-new-first_steps')),
      findsOneWidget,
    );
    final locked = find.byKey(const ValueKey('achievement-prospector'));
    expect(
      find.descendant(
        of: locked,
        matching: find.byType(LinearProgressIndicator),
      ),
      findsOneWidget,
    );
  });
}
