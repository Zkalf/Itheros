// Spec 0023 §3.3 (role-play, chapter 1), plan 0069 M2: the Lore tab groups
// its lore by place. Criteria 34-39.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/ui/images.dart' show lorePageKey;
import 'package:walkingrpg/ui/socket.dart';

import 'images_test.dart' show diskImages;
import 'ui_test.dart' show game, pumpGame;

void main() {
  Finder group(String place) => find.byKey(ValueKey('lore-group-$place'));
  Finder entry(String id) => find.byKey(ValueKey('lore-$id'));

  Future<void> openLore(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 12000);
    await t.tap(find.byKey(const ValueKey('journal-button')));
    await t.pumpAndSettle();
    await t.tap(find.text('Lore'));
    await t.pumpAndSettle();
  }

  int total() =>
      {for (final place in game.data.locations.keys) ...game.data.loreOf(place)}
          .length;

  testWidgets('criterion 34: the groups follow the order of world.json', (
    t,
  ) async {
    await pumpGame(t);
    await openLore(t);
    final places = [
      for (final p in game.data.locations.keys)
        if (p != 'smugglers_cove' && game.data.loreOf(p).isNotEmpty) p,
    ];
    expect(places.first, 'camp');
    for (var i = 1; i < places.length; i++) {
      expect(
        t.getTopLeft(group(places[i])).dy,
        greaterThan(t.getTopLeft(group(places[i - 1])).dy),
        reason: places[i],
      );
    }
  });

  testWidgets('criterion 35: each heading names its place and "N of M"', (
    t,
  ) async {
    await pumpGame(t, prepare: (s) => s.lore.add('lore_goblin_brute'));
    await openLore(t);
    expect(
      find.descendant(
        of: group('goblin_woods'),
        matching: find.text('Goblin Woods · 1 of 5'),
      ),
      findsOneWidget,
    );
    // A new game holds The Guild's charter.
    expect(
      find.descendant(of: group('camp'), matching: find.text('Camp · 1 of 2')),
      findsOneWidget,
    );
    expect(find.text('2 of ${total()} found'), findsOneWidget);
  });

  testWidgets('criterion 36: a found page shows its picture, title and text', (
    t,
  ) async {
    await pumpGame(t, images: diskImages);
    await openLore(t);
    final page = game.data.pages['page_charter']!;
    final e = entry('page_charter');
    final socket = t.widget<PictureSocket>(
      find.descendant(of: e, matching: find.byType(PictureSocket)),
    );
    expect(socket.picture.key, lorePageKey);
    expect(socket.picture.placeholder, isFalse);
    expect(find.descendant(of: e, matching: find.text(page.title)), findsOne);
    expect(find.descendant(of: e, matching: find.text(page.text)), findsOne);
  });

  testWidgets('a found note shows the picture of its monster, its title and '
      'its text', (t) async {
    await pumpGame(
      t,
      images: diskImages,
      prepare: (s) => s.lore.add('lore_goblin_brute'),
    );
    await openLore(t);
    final note = game.data.loreNotes.firstWhere(
      (n) => n.id == 'lore_goblin_brute',
    );
    final e = entry(note.id);
    final socket = t.widget<PictureSocket>(
      find.descendant(of: e, matching: find.byType(PictureSocket)),
    );
    expect(socket.picture.key, 'monsters/goblin_brute');
    expect(find.descendant(of: e, matching: find.text(note.title)), findsOne);
    expect(find.descendant(of: e, matching: find.text(note.text)), findsOne);
  });

  testWidgets('criterion 37: lore not found shows the placeholder and "Not '
      'found yet"', (t) async {
    await pumpGame(t);
    await openLore(t);
    final e = entry('page_odda_ledger');
    expect(
      find.descendant(of: e, matching: find.text('Not found yet')),
      findsOneWidget,
    );
    final socket = t.widget<PictureSocket>(
      find.descendant(of: e, matching: find.byType(PictureSocket)),
    );
    expect(socket.picture.placeholder, isTrue);
    // Its title and text stay hidden.
    final page = game.data.pages['page_odda_ledger']!;
    expect(find.text(page.title), findsNothing);
  });

  testWidgets("criterion 38: Smugglers' Cove has no group before the reveal", (
    t,
  ) async {
    await pumpGame(t);
    await openLore(t);
    expect(group('smugglers_cove'), findsNothing);
  });

  testWidgets("criterion 38: Smugglers' Cove has its group once revealed", (
    t,
  ) async {
    await pumpGame(t, prepare: (s) => s.revealed.add('smugglers_cove'));
    await openLore(t);
    expect(group('smugglers_cove'), findsOneWidget);
  });

  testWidgets('criterion 39: the tips stay below the groups', (t) async {
    await pumpGame(t, prepare: (s) => s.tips.add('hilde_1'));
    await openLore(t);
    final hilde = find.text('Hilde, the miner');
    expect(hilde, findsOneWidget);
    final last = [
      for (final p in game.data.locations.keys)
        if (group(p).evaluate().isNotEmpty) p,
    ].last;
    expect(
      t.getTopLeft(hilde).dy,
      greaterThan(t.getBottomLeft(group(last)).dy),
    );
  });
}
