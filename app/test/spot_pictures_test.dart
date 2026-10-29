// Spec 0014 amendment 1, plan 0020 M1: the picture of a gathering spot.
// A spot row starts with the tool placeholder of its profession in a 48 dp
// socket, and its level badge stands on the name line, before the name, as
// on a monster row (criteria 1-8). The placeholder check of criterion 9 is
// in placeholders_test.dart.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/ui/actions.dart' show professionColour;
import 'package:walkingrpg/ui/images.dart';
import 'package:walkingrpg/ui/level_badge.dart';
import 'package:walkingrpg/ui/socket.dart';

import 'images_test.dart' show diskImages, expectShows, loadFonts, socketIn;
import 'now_monsters_test.dart' show expectFirst, hereList, inSheet, inside;
import 'ui_test.dart' show game, openArea, openProfession, option, pumpGame;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);

  /// The places with spots, and their spots.
  final places = {
    for (final l in game.data.locations.values)
      if (l.nodes.isNotEmpty) l.id: l.nodes,
  };

  group('spec 0014 amendment 1 criteria 1-6: a spot row', () {
    test('there is a spot of each gathering profession', () {
      expect(
        {for (final n in game.data.nodes.values) n.profession},
        {'mining', 'woodcutting', 'fishing', 'hunting'},
      );
    });

    test('criterion 3: a spot without an image shows the tool placeholder of '
        'its profession', () {
      const placeholder = {
        'mining': 'placeholders/tool_mining',
        'woodcutting': 'placeholders/tool_woodcutting',
        'fishing': 'placeholders/tool_fishing',
        'hunting': 'placeholders/tool_hunting',
      };
      for (final n in game.data.nodes.values) {
        final p = ImageIndex.empty.pictureOf(game.data, SpotThing(n.id));
        expect(p.key, placeholder[n.profession], reason: n.id);
        expect(p.placeholder, isTrue, reason: n.id);
      }
    });

    test('criterion 4: a spot with an image file shows that image, with no '
        'PH mark', () {
      final p = const ImageIndex({'spots/copper_vein'})
          .pictureOf(game.data, const SpotThing('copper_vein'));
      expect(p.key, 'spots/copper_vein');
      expect(p.placeholder, isFalse);
    });

    testWidgets('criteria 1, 2, 5 and 6: each spot row on Now and on the area '
        'sheet starts with its picture in a 48 dp socket; its level badge '
        'keeps its number and colour, on the name line before the name', (
      t,
    ) async {
      for (final MapEntry(key: place, value: spots) in places.entries) {
        await t.pumpWidget(const SizedBox());
        final (c, _) = await pumpGame(t, images: diskImages, location: place);
        // A hidden place, such as the cove, is on the map once revealed.
        if (game.data.locations[place]!.hidden) c.state.revealed.add(place);
        for (final (where, within) in [
          ('Now', (Finder f) => inside(hereList, f)),
          ('the area sheet', inSheet),
        ]) {
          if (where != 'Now') await openArea(t, place);
          for (final id in spots) {
            final what = '$id on $where';
            final n = game.data.nodes[id]!;
            final row = within(option('gather', id));
            expect(row, findsOneWidget, reason: what);
            final socket = socketIn(row);
            expect(t.getSize(socket), const Size(48, 48), reason: what);
            expectShows(t, socket, SpotThing(id), what);
            expectFirst(t, row, socket, what);
            final badge = inside(row, find.byKey(ValueKey('spot-level-$id')));
            expect(badge, findsOneWidget, reason: '$what keeps its badge');
            final b = t.widget<LevelBadge>(badge);
            expect(b.level, n.level, reason: '$what: the number');
            expect(
              b.colour,
              professionColour(
                game,
                c.state,
                n.profession,
                n.level,
                open: game.nodeLevelMet(c.state, id),
              ),
              reason: '$what: the colour',
            );
            final br = t.getRect(badge);
            final name = t.getRect(inside(row, find.text(n.name)));
            expect(
              name.top < br.center.dy && br.center.dy < name.bottom,
              isTrue,
              reason: '$what: the badge $br on the line of the name $name',
            );
            expect(
              br.right <= name.left + .5,
              isTrue,
              reason: '$what: the badge $br before the name $name',
            );
            expect(
              br.left >= t.getRect(socket).right - .5,
              isTrue,
              reason: '$what: the badge $br after the picture',
            );
          }
        }
      }
    });
  });

  group('spec 0014 amendment 1 criteria 7 and 8: other rows keep their '
      'icons', () {
    testWidgets('the Forge row and the Walk here row show no socket', (
      t,
    ) async {
      await pumpGame(t, images: diskImages);
      expect(find.byKey(const ValueKey('here-forge')), findsOneWidget);
      expect(
        inside(
          find.byKey(const ValueKey('here-forge')),
          find.byType(PictureSocket),
        ),
        findsNothing,
      );
      await openArea(t, 'goblin_woods');
      final walk = inSheet(option('travel', 'goblin_woods'));
      expect(walk, findsOneWidget);
      expect(inside(walk, find.byIcon(Icons.signpost)), findsOneWidget);
      expect(inside(walk, find.byType(PictureSocket)), findsNothing);
    });

    testWidgets('the teacher rows on Now keep their icons', (t) async {
      await pumpGame(t, images: diskImages);
      final teachers = find.byWidgetPredicate(
        (w) => switch (w.key) {
          ValueKey<String>(:final value) =>
            value.startsWith('teacher-') && !value.startsWith('teacher-dot-'),
          _ => false,
        },
      );
      expect(teachers, findsWidgets);
      for (final e in teachers.evaluate()) {
        final row = find.byWidget(e.widget);
        expect(inside(row, find.byType(PictureSocket)), findsNothing);
        expect(inside(row, find.byType(Icon)), findsWidgets);
      }
    });

    testWidgets('the "Where to practise" row keeps its level badge alone', (
      t,
    ) async {
      await pumpGame(t, images: diskImages, location: 'copper_hills');
      await openProfession(t, 'mining');
      final go = find.ancestor(
        of: find.text('Where to practise'),
        matching: find.byType(ListTile),
      );
      expect(go, findsOneWidget);
      expect(inside(go, find.byType(PictureSocket)), findsNothing);
      expect(inside(go, find.byType(LevelBadge)), findsOneWidget);
    });
  });
}
