// Spec 0014 (Quiet Teal), plan 0017 M2: the placeholder check of §3.2
// (criterion 15). It asks pictureOf for each thing of §3.1, with the image
// files on disk, and lists each id that shows a placeholder. It never fails
// because of a placeholder, so new content does not need an image.
// check.ps1 runs it with each other test in app/test/.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/ui/images.dart';

import 'images_test.dart' show diskImages;
import 'support.dart';

void main() {
  group('spec 0014 criterion 15: the placeholder check', () {
    test('lists each thing that shows a placeholder, and passes', () {
      final data = loadTestGame().data;
      final things = thingsOf(data);
      // Each thing of §3.1 once: each monster, item, achievement, rank and
      // place, each origin with each gender, and each gathering spot
      // (amendment 1).
      expect(
        {for (final (kind, _, _) in things) kind: count(things, kind)},
        {
          'monster': data.enemies.length,
          'gear': data.items.values.where((i) => i.slot != null).length,
          'tool': data.items.values.where((i) => i.tool != null).length,
          'material': data.items.values.where(isMaterial).length,
          'meal': data.items.values.where((i) => i.meal != null).length,
          'achievement': data.achievements.length,
          'rank': data.ranks.length,
          'place': data.locations.length,
          'player': data.origins.length * Gender.values.length,
          'spot': data.nodes.length,
        },
      );
      final list = placeholdersOf(data, diskImages);
      stdout.writeln(describe(list, things));
      for (final (kind, id, key) in list) {
        expect(phSpots.keys, contains(key), reason: 'the $kind $id: $key');
      }
      // Each thing that the list does not hold shows an image file on disk,
      // or the water icon.
      for (final (kind, id, thing) in things) {
        final p = diskImages.pictureOf(data, thing);
        if (p.placeholder) continue;
        expect(
          p.icon != null || File(p.asset ?? '').existsSync(),
          isTrue,
          reason: 'the $kind $id shows ${p.key}, which has no file',
        );
      }
    });

    test('content without an image passes: an item with no image joins the '
        'list', () {
      final data = loadTestGame(
        items: [
          {'id': 'test_lantern', 'name': 'Test lantern'},
        ],
      ).data;
      final list = placeholdersOf(data, diskImages);
      expect(
        list,
        contains(('material', 'test_lantern', 'placeholders/material')),
      );
    });

    test('amendment 1 criterion 9: the list holds each spot with the tool '
        'placeholder of its profession', () {
      final data = loadTestGame().data;
      final list = placeholdersOf(data, diskImages);
      for (final n in data.nodes.values) {
        expect(
          list,
          contains(('spot', n.id, 'placeholders/tool_${n.profession}')),
        );
      }
    });
  });
}

/// The kinds of things of spec 0014 §3.1, in the order of its table.
const kinds = [
  'monster',
  'gear',
  'tool',
  'material',
  'meal',
  'achievement',
  'rank',
  'place',
  'player',
  'spot',
];

bool isMaterial(ItemDef i) =>
    i.slot == null && i.tool == null && i.meal == null;

/// Each thing of spec 0014 §3.1 in [data], as (kind, id, thing). An
/// achievement counts as earned, and a place as out of the fog, so that each
/// shows its own image or its placeholder.
List<(String, String, Thing)> thingsOf(GameData data) => [
  for (final id in data.enemies.keys) ('monster', id, MonsterThing(id)),
  for (final i in data.items.values)
    (
      i.slot != null
          ? 'gear'
          : i.tool != null
          ? 'tool'
          : i.meal != null
          ? 'meal'
          : 'material',
      i.id,
      ItemThing(i.id),
    ),
  for (final id in data.achievements.keys)
    ('achievement', id, AchievementThing(id, earned: true)),
  for (final r in data.ranks) ('rank', r.name, RankThing(r.name)),
  for (final id in data.locations.keys)
    ('place', id, PlaceThing(id, fogged: false)),
  for (final o in data.origins.keys)
    for (final g in Gender.values)
      ('player', '${o}_${g.name}', PlayerThing(o, g)),
  for (final id in data.nodes.keys) ('spot', id, SpotThing(id)),
];

int count(List<(String, String, Thing)> things, String kind) =>
    things.where((x) => x.$1 == kind).length;

/// Each thing of [data] that shows a placeholder with [images], as (kind, id,
/// placeholder key).
List<(String, String, String)> placeholdersOf(
  GameData data,
  ImageIndex images,
) => [
  for (final (kind, id, thing) in thingsOf(data))
    if (images.pictureOf(data, thing) case Picture(
      placeholder: true,
      :final key?,
    ))
      (kind, id, key),
];

/// The list for the test output: a count in all, then each kind with its
/// count and its ids.
String describe(
  List<(String, String, String)> list,
  List<(String, String, Thing)> things,
) {
  final out = StringBuffer(
    'Placeholders (spec 0014 §3.2): ${list.length} of ${things.length} '
    'things show a placeholder.\n',
  );
  for (final kind in kinds) {
    final shown = [
      for (final x in list)
        if (x.$1 == kind) x,
    ];
    out.writeln('$kind: ${shown.length} of ${count(things, kind)}');
    for (final (_, id, key) in shown) {
      out.writeln('  $id: $key');
    }
  }
  return out.toString().trimRight();
}
