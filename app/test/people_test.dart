// Spec 0023 (role-play, chapter 1), plan 0069 M2: the people's rows and
// sheets, the King lines at Camp, the report and the Journal. Criteria 1-7,
// 12, 14-16, 20-21, 26, 31-32 and 41.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/sync/away_summary.dart';
import 'package:walkingrpg/ui/images.dart';
import 'package:walkingrpg/ui/item_square.dart' show ProfessionPicture;
import 'package:walkingrpg/ui/labels.dart';
import 'package:walkingrpg/ui/socket.dart';

import 'images_test.dart' show diskImages;
import 'ui_test.dart'
    show closeSheet, game, openAchievements, option, pumpGame, settle;

void main() {
  const kingKill = 'kills.graveyard_king';
  Finder row(String id) => find.byKey(ValueKey('person-$id'));
  Finder dot(String id) => find.byKey(ValueKey('person-dot-$id'));
  final sheet = find.byKey(const ValueKey('person-sheet'));
  Finder inSheet(Finder f) => find.descendant(of: sheet, matching: f);
  String line(String person, String id) => game.fill(
    game.data.people[person]!.lines.firstWhere((l) => l.id == id).text,
    const Character(name: 'Ada', gender: Gender.neither, origin: 'tavern_cook'),
  );

  group('the rows (spec 0023 §3.1)', () {
    testWidgets("criterion 1: Odda's row stands after the trainer's at Camp", (
      t,
    ) async {
      await pumpGame(t);
      expect(row('odda'), findsOneWidget);
      expect(
        t.getTopLeft(row('odda')).dy,
        greaterThan(t.getTopLeft(find.byKey(const ValueKey('trainer'))).dy),
      );
    });

    for (final (person, place, monster) in [
      ('pell', 'goblin_woods', 'goblin'),
      ('aldous', 'old_graveyard', 'skeleton'),
    ]) {
      testWidgets('criteria 2-3: $person stands first under Here at $place', (
        t,
      ) async {
        await pumpGame(t, location: place, level: 5);
        expect(row(person), findsOneWidget);
        expect(
          t.getTopLeft(row(person)).dy,
          lessThan(t.getTopLeft(option('fight', monster)).dy),
        );
      });
    }

    testWidgets("criterion 4: Jory's row stands first at Smugglers' Cove", (
      t,
    ) async {
      await pumpGame(
        t,
        location: 'smugglers_cove',
        level: 15,
        prepare: (s) => s.revealed.add('smugglers_cove'),
      );
      expect(row('jory'), findsOneWidget);
      expect(
        t.getTopLeft(row('jory')).dy,
        lessThan(t.getTopLeft(option('gather', 'cove_rocks')).dy),
      );
    });

    testWidgets("criterion 5: Jory's row does not show before the reveal", (
      t,
    ) async {
      await pumpGame(t, location: 'smugglers_cove', level: 15);
      expect(row('jory'), findsNothing);
    });

    testWidgets('criterion 6: a row shows the portrait, the name and the '
        'title', (t) async {
      await pumpGame(t, location: 'goblin_woods', level: 5);
      expect(
        find.descendant(of: row('pell'), matching: find.byType(PictureSocket)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: row('pell'),
          matching: find.text('Pell, the charcoal burner'),
        ),
        findsOneWidget,
      );
    });

    testWidgets("criterion 6: with the files on disk, the row shows Pell's "
        'portrait, not the placeholder', (t) async {
      await pumpGame(t, location: 'goblin_woods', level: 5, images: diskImages);
      final socket = t.widget<PictureSocket>(
        find.descendant(of: row('pell'), matching: find.byType(PictureSocket)),
      );
      expect(socket.picture.key, 'portraits/pell');
      expect(socket.picture.placeholder, isFalse);
    });

    testWidgets("criterion 7: a tap on a row opens the person's sheet", (
      t,
    ) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods', level: 5);
      await t.tap(row('pell'));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(sheet, findsOneWidget);
      expect(inSheet(find.text('Pell, the charcoal burner')), findsOneWidget);
    });
  });

  group('the dot (spec 0023 §3.1)', () {
    testWidgets('criteria 12 and 14: a dot while a line is not heard, none '
        'after the sheet opens, and again for a new line', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods', level: 5);
      expect(dot('pell'), findsOneWidget);
      await t.tap(row('pell'));
      await settle(t, c);
      await t.pumpAndSettle();
      await closeSheet(t);
      expect(dot('pell'), findsNothing);
      expect(c.state.heard, contains('pell_1'));
      // A new line opens: the dot comes back.
      c.state.counters['kills.goblin'] = 50;
      // Any saved change redraws Now.
      await c.markSeen(const []);
      await t.pump();
      expect(dot('pell'), findsOneWidget);
    });
  });

  group('the sheet (spec 0023 §3.2)', () {
    testWidgets('criteria 15-16 and 26: the newest line on top, the new '
        'page, and the other lines under "What Pell told you"', (t) async {
      final (c, _) = await pumpGame(
        t,
        location: 'goblin_woods',
        level: 5,
        counters: {'kills.goblin': 50},
      );
      await t.tap(row('pell'));
      await settle(t, c);
      await t.pumpAndSettle();
      final newest = inSheet(find.text('"${line('pell', 'pell_2')}"'));
      expect(newest, findsOneWidget);
      expect(inSheet(find.text("New lore page: Pell's story")), findsOneWidget);
      expect(inSheet(find.text('What Pell told you')), findsOneWidget);
      final older = inSheet(find.text('"${line('pell', 'pell_1')}"'));
      expect(older, findsOneWidget);
      expect(t.getTopLeft(newest).dy, lessThan(t.getTopLeft(older).dy));
      expect(c.state.lore, contains('page_pell'));
    });

    testWidgets('a tap on "New lore page" opens the Lore tab', (t) async {
      final (c, _) = await pumpGame(
        t,
        location: 'goblin_woods',
        level: 5,
        counters: {'kills.goblin': 50},
      );
      await t.tap(row('pell'));
      await settle(t, c);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('person-new-page-page_pell')));
      await t.pumpAndSettle();
      expect(sheet, findsNothing);
      expect(find.byKey(const ValueKey('lore-page_pell')), findsOneWidget);
    });

    testWidgets('no "New lore page" when the opening gave none', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods', level: 5);
      await t.tap(row('pell'));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(inSheet(find.textContaining('New lore page')), findsNothing);
      expect(inSheet(find.text('What Pell told you')), findsNothing);
    });
  });

  group('Camp after the King (spec 0023 §2.5, §3.2)', () {
    testWidgets("criterion 20: Ysolde's King line puts a dot on her row "
        'until her sheet opens', (t) async {
      final (c, _) = await pumpGame(t, counters: {kingKill: 1});
      final trainerDot = find.byKey(const ValueKey('trainer-dot'));
      expect(trainerDot, findsOneWidget);
      await t.tap(find.byKey(const ValueKey('trainer')));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(
        find.text(
          '"${game.fill(game.data.campLines[GameData.trainerId]!.first.text, c.state.character)}"',
        ),
        findsOneWidget,
      );
      await closeSheet(t);
      expect(trainerDot, findsNothing);
    });

    testWidgets("criterion 20: Marta's King line puts a dot on her row until "
        'her sheet opens', (t) async {
      final (c, _) = await pumpGame(t, counters: {kingKill: 1});
      final martaDot = find.byKey(const ValueKey('teacher-dot-cooking'));
      expect(martaDot, findsOneWidget);
      await t.tap(find.byKey(const ValueKey('teacher-cooking')));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(
        find.text(
          '"${game.fill(game.data.campLines['cooking']!.first.text, c.state.character)}"',
        ),
        findsOneWidget,
      );
      await closeSheet(t);
      expect(martaDot, findsNothing);
    });

    testWidgets('criterion 21: the learn line and Learn do not change', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, learned: false, counters: {kingKill: 1});
      await t.tap(find.byKey(const ValueKey('teacher-cooking')));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('learn-cooking')), findsOneWidget);
      expect(find.text('Marta teaches Cooking.'), findsOneWidget);
    });
  });

  group('the report and the Journal (spec 0023 §3.4)', () {
    test('criterion 31: the report names a page: "Found a lore page"', () {
      final labels = Labels(game.data);
      expect(
        labels.loreFound('page_kings_words'),
        "Found a lore page: The King's last words",
      );
      // A lore note keeps its words.
      expect(
        labels.loreFound('lore_graveyard_king'),
        "Found a lore note: The King's armour",
      );
    });

    test('criterion 31: a page found on a walk goes into the report', () {
      final s = game.newGame(seed: 1)
        ..location = 'old_graveyard'
        ..counters[kingKill] = 1;
      final summary = AwaySummary.fromReports([game.applySteps(s, 1)]);
      expect(summary.lore, contains('page_kings_words'));
      expect(summary.isEventful, isTrue);
    });

    testWidgets('criterion 32: a page from a line goes into the Journal', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        location: 'goblin_woods',
        level: 5,
        counters: {'kills.goblin': 50},
      );
      await t.tap(row('pell'));
      await settle(t, c);
      await t.pumpAndSettle();
      expect(c.journal.first.summary.lore, contains('page_pell'));
    });
  });

  group('achievements (spec 0023 §2.6)', () {
    testWidgets('criterion 41: the six lore achievements show with their '
        'stage', (t) async {
      await pumpGame(t);
      t.view.physicalSize = const Size(1080, 8000);
      await openAchievements(t);
      double top(String key) => t.getTopLeft(find.byKey(ValueKey(key))).dy;
      for (final id in [
        'lore_camp',
        'lore_goblin_woods',
        'lore_old_graveyard',
        'lore_copper_hills',
        'lore_mirror_lake',
      ]) {
        expect(top('achievement-$id'), lessThan(top('achievement-stage-mid')));
      }
      expect(
        top('achievement-lore_smugglers_cove'),
        allOf(
          greaterThan(top('achievement-stage-mid')),
          lessThan(top('achievement-stage-late')),
        ),
      );
      expect(find.text('Find all the lore of Goblin Woods'), findsOneWidget);
    });
  });

  group('the portraits at Camp (spec 0023 §3.6)', () {
    // The teachers' ids and Ysolde's: the name in lower case.
    final camp = {
      for (final p in game.data.professions.values)
        'teacher-${p.id}': p.teacher.name.toLowerCase(),
      'trainer': game.data.trainer.name.toLowerCase(),
    };
    PictureSocket socketIn(WidgetTester t, Finder of) =>
        t.widget<PictureSocket>(
          find.descendant(of: of, matching: find.byType(PictureSocket)),
        );

    test('criteria 53-54: each teacher and Ysolde has a portrait file', () {
      expect(camp, hasLength(7));
      for (final id in camp.values) {
        expect(diskImages.has('portraits/$id'), isTrue, reason: id);
      }
    });

    testWidgets("criteria 53-54: each teacher's row and Ysolde's row show "
        'their portrait, not the profession picture or the trainer icon', (
      t,
    ) async {
      await pumpGame(t, images: diskImages);
      for (final MapEntry(key: row, value: id) in camp.entries) {
        final socket = socketIn(t, find.byKey(ValueKey(row)));
        expect(socket.picture.key, 'portraits/$id', reason: row);
        expect(socket.picture.placeholder, isFalse, reason: row);
        expect(socket.size, 32, reason: row);
        expect(
          find.descendant(
            of: find.byKey(ValueKey(row)),
            matching: find.byType(ProfessionPicture),
          ),
          findsNothing,
          reason: row,
        );
      }
      expect(find.byKey(const ValueKey('drawn-icon-trainer')), findsNothing);
    });

    for (final (row, sheetKey, id, name) in [
      ('teacher-cooking', 'teacher-sheet', 'marta', 'Marta, the cook'),
      ('trainer', 'trainer-sheet', 'ysolde', 'Ysolde, the Guild trainer'),
    ]) {
      testWidgets('criterion 55: $sheetKey shows the portrait and the name at '
          'the top', (t) async {
        final (c, _) = await pumpGame(t, images: diskImages);
        await t.tap(find.byKey(ValueKey(row)));
        await settle(t, c);
        await t.pumpAndSettle();
        final sheetFinder = find.byKey(ValueKey(sheetKey));
        final socket = socketIn(t, sheetFinder);
        expect(socket.picture.key, 'portraits/$id');
        expect(socket.size, 72);
        final title = find.descendant(
          of: sheetFinder,
          matching: find.text(name),
        );
        expect(title, findsOneWidget);
        final line = find.descendant(
          of: sheetFinder,
          matching: find.textContaining('"'),
        );
        expect(
          t
              .getTopLeft(
                find.descendant(
                  of: sheetFinder,
                  matching: find.byType(PictureSocket),
                ),
              )
              .dy,
          lessThan(t.getTopLeft(line.first).dy),
        );
      });
    }
  });

  test('a person shows the portrait of their id', () {
    expect(
      const ImageIndex({'portraits/pell'})
          .pictureOf(game.data, const GuideThing('pell')),
      isA<Picture>().having((p) => p.key, 'key', 'portraits/pell'),
    );
  });
}
