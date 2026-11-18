// Spec 0025 (role-play and quests, chapters 2 and 3: the north), plan 0072
// M2: the screens. Criteria 1-5, 7, 13-14 and 18 on screen, 25 and 27.
// Criteria 34-36 (the end words on the card) are in `quest_card_test.dart`.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/ui/socket.dart';

import 'images_test.dart' show diskImages;
import 'ui_test.dart'
    show closeSheet, game, openAchievements, option, pumpGame, settle;

void main() {
  const chiefKill = 'kills.ogre_chieftain';
  const dragonKill = 'kills.young_dragon';
  const kingKill = 'kills.graveyard_king';
  Finder row(String id) => find.byKey(ValueKey('person-$id'));

  // The four new people, their place and a monster of that place.
  const north = [
    ('maud', 'Maud, the warden', 'grey_moor', 'wolf'),
    ('tobin', 'Tobin, the carter', 'troll_bridge', 'giant_spider'),
    ('corvin', 'Corvin, the lodge master', 'mountain_pass', 'stone_golem'),
    ('nessa', 'Nessa, the dragon-watcher', 'dragons_peak', 'wyvern'),
  ];

  group('the rows (spec 0025 §2.2)', () {
    for (final (id, name, place, monster) in north) {
      testWidgets('criteria 1-4: $id stands first under Here at $place', (
        t,
      ) async {
        await pumpGame(t, location: place, level: 20);
        expect(row(id), findsOneWidget);
        expect(
          t.getTopLeft(row(id)).dy,
          lessThan(t.getTopLeft(option('fight', monster)).dy),
        );
      });

      testWidgets("criterion 5: $id's row shows the portrait, the name and "
          'the title', (t) async {
        await pumpGame(t, location: place, level: 20, images: diskImages);
        expect(
          find.descendant(of: row(id), matching: find.text(name)),
          findsOneWidget,
        );
        final socket = t.widget<PictureSocket>(
          find.descendant(of: row(id), matching: find.byType(PictureSocket)),
        );
        expect(socket.picture.key, 'portraits/$id');
        expect(socket.picture.placeholder, isFalse);
      });
    }
  });

  test('criterion 7: the four new portraits are files of their own, unlike '
      'each other and the eleven of today', () {
    final all = [
      for (final p in game.data.people.values) p.id,
      for (final p in game.data.professions.values)
        p.teacher.name.toLowerCase(),
      game.data.trainer.name.toLowerCase(),
    ];
    expect(all, hasLength(15));
    final bytes = <String>{};
    for (final id in all) {
      expect(diskImages.has('portraits/$id'), isTrue, reason: id);
      final file = File('assets/images/portraits/$id.webp');
      expect(
        bytes.add(String.fromCharCodes(file.readAsBytesSync())),
        isTrue,
        reason: '$id is a copy of another portrait',
      );
    }
  });

  group('the Camp lines on the sheets (spec 0025 §2.4)', () {
    String quoted(Character? who, String id) =>
        '"${game.fill([for (final ls in game.data.campLines.values) ...ls].firstWhere((l) => l.id == id).text, who)}"';

    for (final (counters, kind) in [
      ({kingKill: 1, chiefKill: 1}, 'chief'),
      ({kingKill: 1, chiefKill: 1, dragonKill: 1}, 'dragon'),
    ]) {
      testWidgets('criteria 13-14: Marta and Ysolde show the $kind line at '
          'the top', (t) async {
        final (c, _) = await pumpGame(t, counters: counters);
        await t.tap(find.byKey(const ValueKey('teacher-cooking')));
        await settle(t, c);
        await t.pumpAndSettle();
        expect(
          find.text(quoted(c.state.character, '${kind}_marta')),
          findsOneWidget,
        );
        if (kind == 'dragon') {
          expect(
            find.text(quoted(c.state.character, 'chief_marta')),
            findsNothing,
          );
        }
        await closeSheet(t);
        await t.tap(find.byKey(const ValueKey('trainer')));
        await settle(t, c);
        await t.pumpAndSettle();
        expect(
          find.text(quoted(c.state.character, '${kind}_ysolde')),
          findsOneWidget,
        );
        if (kind == 'dragon') {
          expect(
            find.text(quoted(c.state.character, 'chief_ysolde')),
            findsNothing,
          );
        }
      });
    }

    testWidgets('criterion 18: the learn line and Learn do not change after '
        'both bosses', (t) async {
      final (c, _) = await pumpGame(
        t,
        learned: false,
        counters: {kingKill: 1, chiefKill: 1, dragonKill: 1},
      );
      await t.tap(find.byKey(const ValueKey('teacher-cooking')));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('learn-cooking')), findsOneWidget);
      expect(find.text('Marta teaches Cooking.'), findsOneWidget);
    });

    testWidgets("criterion 18: a learned teacher's tip line does not change "
        'after both bosses', (t) async {
      final (c, _) = await pumpGame(
        t,
        counters: {kingKill: 1, chiefKill: 1, dragonKill: 1},
      );
      await t.tap(find.byKey(const ValueKey('teacher-cooking')));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(
        find.textContaining("Cooking 1 · Simple. You've heard all my tips."),
        findsOneWidget,
      );
    });
  });

  testWidgets('criterion 25: the Lore tab has a group for each north place, '
      'in the order of world.json, with found N of M', (t) async {
    await pumpGame(t);
    t.view.physicalSize = const Size(1080, 30000);
    await t.tap(find.byKey(const ValueKey('journal-button')));
    await t.pumpAndSettle();
    await t.tap(find.text('Lore'));
    await t.pumpAndSettle();
    final order = [
      for (final l in game.data.locations.values)
        if (!l.hidden) l.id,
    ];
    double top(String place) =>
        t.getTopLeft(find.byKey(ValueKey('lore-group-$place'))).dy;
    for (var i = 1; i < order.length; i++) {
      expect(top(order[i]), greaterThan(top(order[i - 1])), reason: order[i]);
    }
    for (final (place, name, total) in [
      ('grey_moor', 'Grey Moor', 6),
      ('iron_ridge', 'Iron Ridge', 2),
      ('troll_bridge', 'Troll Bridge', 7),
      ('mountain_pass', 'Mountain Pass', 6),
      ('mithril_deep', 'Mithril Deep', 2),
      ('dragons_peak', "Dragon's Peak", 7),
    ]) {
      expect(find.text('$name · 0 of $total'), findsOneWidget, reason: place);
    }
  });

  testWidgets('criterion 27: the six lore achievements of the north show '
      'with their stage', (t) async {
    await pumpGame(t);
    t.view.physicalSize = const Size(1080, 12000);
    await openAchievements(t);
    double top(String key) => t.getTopLeft(find.byKey(ValueKey(key))).dy;
    for (final id in [
      'lore_grey_moor',
      'lore_iron_ridge',
      'lore_troll_bridge',
    ]) {
      expect(
        top('achievement-$id'),
        allOf(
          greaterThan(top('achievement-stage-mid')),
          lessThan(top('achievement-stage-late')),
        ),
        reason: id,
      );
    }
    for (final id in [
      'lore_mountain_pass',
      'lore_mithril_deep',
      'lore_dragons_peak',
    ]) {
      expect(
        top('achievement-$id'),
        greaterThan(top('achievement-stage-late')),
        reason: id,
      );
    }
    expect(find.text('Find all the lore of Grey Moor'), findsOneWidget);
  });
}
