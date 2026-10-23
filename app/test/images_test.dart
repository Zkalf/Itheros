// Spec 0014 (Quiet Teal), plan 0017 M2: the tests of criteria 8, 9, 11, 13,
// 14, 16, 17 and 23. Each test reads what the player sees: the Image of a
// socket by its asset name, the quality ring, the count badge, the PH mark
// with its style and its place, and the semantics. No test decodes an image.
// - The index of the image files comes from the files in assets/images/,
//   with synchronous reads before the pump.
// - No portrait has a file yet. The portrait tests use an index with the
//   keys of the portraits, and they drop the error of each portrait file that
//   does not exist.
// placeholders_test.dart holds the placeholder check of criterion 15.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data' show ByteData;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show AssetManifest, FontLoader, rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/ui/images.dart';
import 'package:walkingrpg/ui/item_square.dart' show ItemSquare, slotIcon;
import 'package:walkingrpg/ui/labels.dart' show genderName;
import 'package:walkingrpg/ui/socket.dart';
import 'package:walkingrpg/ui/theme.dart' show quietTheme;

import 'quiet_teal_files_test.dart' show fontTable;
import 'quiet_teal_test.dart'
    show byElement, drawnBy, expectRgb, openItem, piecesOf;
import 'ui_test.dart' show ada, closeSheet, game, openTab, pumpGame;

void main() {
  // The test of the asset manifest reads the app bundle.
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  criterion8();
  criterion9();
  criterion11();
  criterion13();
  criterion14();
  criterion16();
  criterion17();
  criterion23();
}

// The image files and the placeholders.

/// The path of each file in assets/images/, with "/" between the folders.
List<String> imageFiles() {
  final dir = Directory('assets/images');
  if (!dir.existsSync()) return const [];
  return [
    for (final f in dir.listSync(recursive: true).whereType<File>())
      f.path.replaceAll(r'\', '/'),
  ];
}

/// Loads the four fonts of the app from assets/fonts/. A widget test draws
/// text in a test font with square letters, so without this the PH mark and
/// the count badge do not have the size that the player sees.
Future<void> loadFonts() async {
  for (final MapEntry(key: family, value: files) in fontTable.entries) {
    final loader = FontLoader(family);
    for (final (file, _, _) in files) {
      final bytes = File('assets/fonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}

/// The keys of the image files on disk.
final diskImages = ImageIndex.fromAssets(imageFiles());

String assetOf(String key) => 'assets/images/$key.webp';

/// The 14 slot kinds and the 6 professions that have a placeholder.
const _slotKinds =
    'head neck shoulder cloak chest bracer gloves belt legs boots ring '
    'trinket mainHand offHand';
const _professions = 'mining woodcutting fishing hunting crafting cooking';

/// The 25 placeholders of plan 0017.
final placeholderKeys = {
  for (final kind in _slotKinds.split(' ')) 'placeholders/gear_$kind',
  for (final p in _professions.split(' ')) 'placeholders/tool_$p',
  for (final kind in ['material', 'meal', 'monster', 'player', 'generic'])
    'placeholders/$kind',
};

/// A ring with no image file. It shows the ring placeholder.
String get bareRing {
  final ring = game.data.items.values
      .where((i) => i.slot == 'ring' && !diskImages.has('items/${i.id}'))
      .firstOrNull;
  if (ring == null) {
    fail('each ring has an image; these tests need one without');
  }
  return ring.id;
}

/// The picture of each of the 25 placeholders, by key: the picture of a thing
/// of its kind with no image.
Map<String, Picture> placeholderPictures() {
  final data = game.data;
  String first(bool Function(ItemDef) test) =>
      data.items.values.firstWhere(test).id;
  final things = <Thing>[
    for (final key in placeholderKeys)
      if (key.startsWith('placeholders/gear_'))
        ItemThing(first((i) => i.slot == key.substring(18)))
      else if (key.startsWith('placeholders/tool_'))
        ItemThing(first((i) => i.tool?.profession == key.substring(18))),
    ItemThing('goblin_hide'),
    ItemThing('grilled_perch'),
    MonsterThing('goblin'),
    PlayerThing('coast_fisher', Gender.female),
    RankThing(data.ranks.first.name),
  ];
  final pictures = {
    for (final p in [
      for (final thing in things) ImageIndex.empty.pictureOf(data, thing),
    ])
      p.key ?? '': p,
  };
  expect(pictures.keys.toSet(), placeholderKeys);
  return pictures;
}

/// Runs [body] while no portrait has its file: the sockets ask the bundle for
/// portrait files that do not exist yet. The test drops each error "Unable to
/// load asset" of a portrait file, and keeps each other error.
Future<void> withoutPortraitFiles(
  WidgetTester t,
  Future<void> Function() body,
) async {
  final report = FlutterError.onError;
  final portrait = RegExp(
    r'Unable to load asset: "assets/images/players/\w+\.webp"',
  );
  FlutterError.onError = (details) {
    if (!portrait.hasMatch('${details.exception}')) report?.call(details);
  };
  try {
    await body();
    // A load fails one frame later.
    await t.pump();
  } finally {
    FlutterError.onError = report;
  }
}

// What the screens show.

/// The asset of an AssetImage, inside a ResizeImage or not.
String? assetName(ImageProvider provider) => switch (provider) {
  AssetImage(:final assetName) => assetName,
  ResizeImage(:final imageProvider) => assetName(imageProvider),
  _ => null,
};

/// The asset of each Image in [within].
List<String?> imagesIn(WidgetTester t, Finder within) => [
  for (final i in t.widgetList<Image>(
    find.descendant(of: within, matching: find.byType(Image)),
  ))
    assetName(i.image),
];

Finder keyIn(Finder within, String key) =>
    find.descendant(of: within, matching: find.byKey(ValueKey(key)));

Finder markIn(Finder within) => keyIn(within, 'ph-mark');

/// The socket in [within]. Expects one.
Finder socketIn(Finder within) {
  final socket = find.descendant(
    of: within,
    matching: find.byType(PictureSocket),
  );
  expect(socket, findsOneWidget, reason: 'one socket in $within');
  return socket;
}

Finder bagSquare(String key) => find.byKey(ValueKey('bag-$key'));

Future<void> openBag(WidgetTester t) async {
  await openTab(t, 'character');
  await t.tap(find.byKey(const ValueKey('tab-bag')));
  await t.pumpAndSettle();
}

/// Expects [where] to show the picture of [thing] with the files on disk: the
/// Image of its asset, or its icon. Only a placeholder has the PH mark
/// (criterion 13).
void expectShows(WidgetTester t, Finder where, Thing thing, String what) {
  final picture = diskImages.pictureOf(game.data, thing);
  if (picture.icon case final icon?) {
    expect(
      find.descendant(of: where, matching: find.byIcon(icon)),
      findsWidgets,
      reason: '$what shows its icon',
    );
  } else {
    expect(imagesIn(t, where), contains(picture.asset), reason: what);
  }
  expect(
    markIn(where),
    picture.placeholder ? findsOneWidget : findsNothing,
    reason: '$what shows ${picture.key}: a PH mark only on a placeholder',
  );
}

/// Pumps one socket in the theme of the app, in the middle of the screen.
Future<Finder> pumpSocket(
  WidgetTester t,
  Picture picture, {
  double size = 72,
  QualityDef? quality,
  int count = 1,
}) async {
  await t.pumpWidget(
    MaterialApp(
      theme: quietTheme,
      home: Scaffold(
        body: Center(
          child: PictureSocket(
            picture: picture,
            size: size,
            quality: quality,
            count: count,
          ),
        ),
      ),
    ),
  );
  return find.byType(PictureSocket);
}

// The PH mark.

/// One of the two texts "PH" of a mark, with the style of its letters.
typedef MarkText = ({TextStyle style, RichText rich, RenderBox box});

/// The fill and the stroke of the one PH mark in [within].
({MarkText fill, MarkText stroke}) markTexts(WidgetTester t, Finder within) {
  final mark = markIn(within);
  expect(mark, findsOneWidget, reason: 'one PH mark');
  final texts = <MarkText>[
    for (final e
        in find
            .descendant(of: mark, matching: find.byType(RichText))
            .evaluate())
      (
        style:
            piecesOf(e.widget as RichText).firstOrNull?.$2 ?? const TextStyle(),
        rich: e.widget as RichText,
        box: e.renderObject! as RenderBox,
      ),
  ];
  expect(
    [for (final x in texts) x.rich.text.toPlainText()],
    ['PH', 'PH'],
    reason: 'the mark is two texts "PH": a fill and a stroke',
  );
  bool stroke(MarkText x) => x.style.foreground?.style == PaintingStyle.stroke;
  expect(texts.where(stroke), hasLength(1), reason: 'one text is the stroke');
  return (
    fill: texts.firstWhere((x) => !stroke(x)),
    stroke: texts.firstWhere(stroke),
  );
}

/// The colour of the fill of a mark, as a colour or as a paint.
Color? fillColour(MarkText fill) =>
    fill.style.foreground?.color ?? fill.style.color;

/// The four corners of [box] on the screen, after each transform above it.
List<Offset> cornersOf(RenderBox box) => [
  for (final p in [
    Offset.zero,
    box.size.topRight(Offset.zero),
    box.size.bottomRight(Offset.zero),
    box.size.bottomLeft(Offset.zero),
  ])
    box.localToGlobal(p),
];

/// The font size of [text] in dp on the screen: its style, its text scale and
/// the scale of each transform above it.
double drawnFontSize(MarkText text) {
  final scale =
      (text.box.localToGlobal(const Offset(1, 0)) -
              text.box.localToGlobal(Offset.zero))
          .distance;
  return text.rich.textScaler.scale(text.style.fontSize ?? 14) * scale;
}

/// Whether the convex polygons [a] and [b] share more than an edge.
bool overlaps(List<Offset> a, List<Offset> b) {
  for (final polygon in [a, b]) {
    for (var i = 0; i < polygon.length; i++) {
      final edge = polygon[(i + 1) % polygon.length] - polygon[i];
      double along(Offset p) => p.dx * -edge.dy + p.dy * edge.dx;
      final pa = a.map(along);
      final pb = b.map(along);
      if (pa.reduce(math.max) <= pb.reduce(math.min) + 1e-6 ||
          pb.reduce(math.max) <= pa.reduce(math.min) + 1e-6) {
        return false;
      }
    }
  }
  return true;
}

/// The font size of the PH mark at each socket size (spec 0014 §3.2): 22% of
/// the socket width, from 9 dp to 16 dp.
final markSizes = {72.0: 15.84, 48.0: 10.56, 32.0: 9.0};

// The count badge and the ring.

/// The badge of the count in [socket]: the closest widget above the count
/// that draws a border, and its rect.
(Element, Rect) badgeOf(WidgetTester t, Finder socket) {
  final count = keyIn(socket, 'count');
  expect(count, findsOneWidget, reason: 'one count');
  Element? badge;
  t.element(count).visitAncestorElements((a) {
    if (a.widget is PictureSocket) return false;
    if ((drawnBy(a)?.sides ?? const []).any(
      (s) => s.style != BorderStyle.none && s.width > 0 && s.color.a > 0,
    )) {
      badge = a;
    }
    return badge == null;
  });
  expect(badge, isNotNull, reason: 'the count stands in a badge with a border');
  return (badge!, t.getRect(byElement(badge!)));
}

/// The text of the count in [within].
String countText(WidgetTester t, Finder within) {
  final count = keyIn(within, 'count');
  expect(count, findsOneWidget, reason: 'one count');
  return t
      .widget<RichText>(
        find.descendant(
          of: count,
          matching: find.byType(RichText),
          matchRoot: true,
        ),
      )
      .text
      .toPlainText();
}

/// Expects [text] in a badge that reaches past the right edge and the bottom
/// edge of [socket], and covers its lower right corner.
void expectBadge(WidgetTester t, Finder socket, String text, String what) {
  expect(countText(t, socket), text, reason: what);
  final edge = t.getRect(socket);
  final (_, badge) = badgeOf(t, socket);
  expect(badge.right, greaterThan(edge.right), reason: '$what: $badge');
  expect(badge.bottom, greaterThan(edge.bottom), reason: '$what: $badge');
  expect(
    badge.inflate(0.5).contains(edge.bottomRight),
    isTrue,
    reason: '$what: the badge $badge hangs off the corner ${edge.bottomRight}',
  );
}

/// The border of the quality ring in [within], or null for no ring.
Border? ringIn(WidgetTester t, Finder within) {
  final ring = keyIn(within, 'ring');
  if (ring.evaluate().isEmpty) return null;
  expect(ring, findsOneWidget, reason: 'one ring');
  final decoration = switch (t.widget(ring)) {
    Container(:final decoration) => decoration,
    DecoratedBox(:final decoration) => decoration,
    _ => null,
  };
  expect(decoration, isA<BoxDecoration>(), reason: 'the ring is a box');
  final border = (decoration! as BoxDecoration).border;
  expect(border, isA<Border>(), reason: 'the ring has a border');
  return border! as Border;
}

/// Expects the ring in [within] to be 2 dp of [colour] on each side.
void expectRing(WidgetTester t, Finder within, int colour, String what) {
  final border = ringIn(t, within);
  expect(border, isNotNull, reason: '$what has no ring');
  for (final s in [border!.top, border.right, border.bottom, border.left]) {
    expect((s.style, s.width), (BorderStyle.solid, 2.0), reason: what);
    expectRgb(s.color, colour, what);
  }
}

int qualityRgb(String id) => int.parse(
  game.data.qualities.firstWhere((q) => q.id == id).colour.substring(1),
  radix: 16,
);

// The criteria.

void criterion8() {
  group('spec 0014 criterion 8: the Character header', () {
    testWidgets('the header shows the name, the rank and the origin, the eight '
        'stats, the talent line, and the portrait next to the name', (t) async {
      const level = 12;
      await pumpGame(t, level: level);
      await openTab(t, 'character');
      String text(String key) =>
          t.widget<Text>(find.byKey(ValueKey(key))).data!;
      expect(text('character-name'), ada.name);
      expect(find.text(game.rank(level).name), findsOneWidget);
      expect(
        text('character-origin'),
        '· ${game.fill(game.data.origins[ada.origin]!.title, ada)}',
      );
      for (final stat in 'Level HP Attack Defense Crit Hit Dodge Block'.split(
        ' ',
      )) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey('stat-$stat')),
            matching: find.text(stat),
          ),
          findsOneWidget,
          reason: 'the stat $stat',
        );
      }
      expect(
        find.text(
          '${game.talentPoints(level)} talent points waiting. Talents arrive '
          'in a later update.',
        ),
        findsOneWidget,
      );

      final portrait = find.byKey(const ValueKey('character-portrait'));
      expect(portrait, findsOneWidget, reason: 'the portrait');
      expect(t.widget(portrait), isA<PictureSocket>());
      expect(t.getSize(portrait), const Size(72, 72));
      // Next to the name: on its line, beside it, and at most 24 dp away.
      final p = t.getRect(portrait);
      final name = t.getRect(find.byKey(const ValueKey('character-name')));
      expect(
        p.top < name.center.dy && name.center.dy < p.bottom,
        isTrue,
        reason: 'the name $name is on the line of the portrait $p',
      );
      expect(
        math.max(p.left, name.left) - math.min(p.right, name.right),
        inInclusiveRange(0, 24),
        reason: 'the gap between the portrait $p and the name $name',
      );
    });

    testWidgets('seven quick taps on the rank turn on the test walk', (
      t,
    ) async {
      final (c, _) = await pumpGame(t);
      await openTab(t, 'character');
      for (var i = 0; i < 7; i++) {
        await t.tap(find.text(game.rank(1).name));
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.pumpAndSettle();
      expect(c.testWalkOn, isTrue);
      expect(find.text('Test walk on'), findsOneWidget);
    });
  });
}

void criterion9() {
  group('spec 0014 criterion 9: the doll and the bag', () {
    testWidgets('the doll has a square for each of the 16 gear slots, and '
        'each socket fills its square', (t) async {
      await pumpGame(
        t,
        equipment: {'chest': 'hide_vest', 'mainHand': 'copper_sword'},
      );
      await openTab(t, 'character');
      expect(game.data.gearSlots, hasLength(16));
      for (final g in game.data.gearSlots) {
        expect(find.byKey(ValueKey('slot-${g.id}')), findsOneWidget);
      }
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('paper-doll')),
          matching: find.byType(ItemSquare),
        ),
        findsNWidgets(16),
      );
      for (final slot in ['chest', 'mainHand']) {
        final square = find.byKey(ValueKey('slot-$slot'));
        expect(
          t.getRect(socketIn(square)),
          rectMoreOrLessEquals(t.getRect(square), epsilon: 0.5),
          reason: 'the socket of $slot fills its square',
        );
      }
    });

    testWidgets('the bag has 5 columns, with gear first; each socket is 48 '
        'dp, in the centre of its cell', (t) async {
      await pumpGame(
        t,
        inventory: {
          'goblin_hide': 3,
          'grilled_perch': 1,
          'copper_pickaxe': 1,
          'bones': 2,
          'hide_vest@rare': 1,
          'copper_sword': 1,
          'iron_helm': 1,
        },
      );
      await openBag(t);
      final squares = find
          .descendant(
            of: find.byKey(const ValueKey('bag')),
            matching: find.byType(ItemSquare),
          )
          .evaluate()
          .toList();
      final keys = [for (final e in squares) (e.widget as ItemSquare).item!];
      expect(
        [for (final k in keys) game.data.itemOf(k)!.slot != null],
        [true, true, true, false, false, false, false],
        reason: 'gear first, then the rest: $keys',
      );
      final cells = [for (final e in squares) t.getRect(byElement(e))];
      for (var i = 1; i < 5; i++) {
        expect(cells[i].top, cells[0].top, reason: 'square ${i + 1} in row 1');
        expect(cells[i].left, greaterThan(cells[i - 1].left));
      }
      expect(cells[5].top, greaterThan(cells[0].top), reason: 'a new row');
      expect(cells[5].left, cells[0].left, reason: 'the sixth square');
      for (final (i, key) in keys.indexed) {
        final socket = socketIn(bagSquare(key));
        expect(t.getSize(socket), const Size(48, 48), reason: key);
        expect(
          t.getCenter(socket),
          offsetMoreOrLessEquals(cells[i].center, epsilon: 0.5),
          reason: '$key in the centre of its cell',
        );
      }
    });
  });
}

void criterion11() {
  final data = game.data;
  final ring = data.items.values.firstWhere((i) => i.slot == 'ring').id;
  final tools = {
    for (final p in data.professions.keys)
      p: data.items.values.firstWhere((i) => i.tool?.profession == p).id,
  };
  // The kind of each place, as plan 0017 choice 5 and the World map today
  // give it.
  final kinds = {
    for (final p in ['camp', 'grey_moor', 'mountain_pass']) p: 'forge',
    for (final p in ['mirror_lake', 'smugglers_cove']) p: 'water',
    for (final p in ['copper_hills', 'iron_ridge', 'mithril_deep'])
      p: 'no_monsters',
    for (final p in ['goblin_woods', 'old_graveyard', 'troll_bridge'])
      p: 'monsters',
    'dragons_peak': 'monsters',
  };
  // Each row of the table of pictureOf: a name, the thing, the key of its
  // image, and its placeholder with no image (null for the water icon).
  final rows = <(String, Thing, String, String?)>[
    ('goblin', MonsterThing('goblin'), 'monsters/goblin', 'monster'),
    (ring, ItemThing(ring), 'items/$ring', 'gear_ring'),
    ('hide_vest', ItemThing('hide_vest'), 'items/hide_vest', 'gear_chest'),
    (
      'copper_sword',
      ItemThing('copper_sword'),
      'items/copper_sword',
      'gear_mainHand',
    ),
    for (final MapEntry(key: p, value: id) in tools.entries)
      (id, ItemThing(id), 'items/$id', 'tool_$p'),
    ('goblin_hide', ItemThing('goblin_hide'), 'items/goblin_hide', 'material'),
    (
      'grilled_perch',
      ItemThing('grilled_perch'),
      'items/grilled_perch',
      'meal',
    ),
    (
      'first_steps, earned',
      AchievementThing('first_steps', earned: true),
      'achievements/first_steps',
      'generic',
    ),
    ('Recruit', RankThing('Recruit'), 'achievements/rank_recruit', 'generic'),
    (
      'grey_moor, fogged',
      PlaceThing('grey_moor', fogged: true),
      'places/fog',
      'generic',
    ),
    (
      'goblin_woods, with its own marker',
      PlaceThing('goblin_woods', fogged: false),
      'places/goblin_woods',
      'generic',
    ),
    for (final MapEntry(key: id, value: kind) in kinds.entries)
      (
        '$id, by its kind',
        PlaceThing(id, fogged: false),
        'places/$kind',
        kind == 'water' ? null : 'generic',
      ),
    for (final g in Gender.values)
      (
        'coast_fisher, ${g.name}',
        PlayerThing('coast_fisher', g),
        'players/coast_fisher_${g.name}',
        'player',
      ),
  ];

  /// Expects [p] to be the picture of [key] (no key: the water icon).
  void expectPicture(Picture p, String? key, String what) => expect(
    (key: p.key, asset: p.asset, placeholder: p.placeholder, icon: p.icon),
    (
      key: key,
      asset: key == null ? null : assetOf(key),
      placeholder: key != null && key.startsWith('placeholders/'),
      icon: key == null ? Icons.water : null,
    ),
    reason: what,
  );

  group('spec 0014 criterion 11: each thing shows its image by its key, or '
      'its placeholder', () {
    test('ImageIndex.fromAssets keeps the .webp files under assets/images/ '
        'as keys, and nothing else', () {
      final index = ImageIndex.fromAssets([
        'assets/images/items/hide_vest.webp',
        'assets/images/placeholders/gear_ring.webp',
        'assets/images/items/notes.txt',
        'assets/fonts/emblem.webp',
        'packages/game_core/data/items.json',
      ]);
      expect(index.has('items/hide_vest'), isTrue);
      expect(index.has('placeholders/gear_ring'), isTrue);
      for (final key in [
        'items/notes',
        'items/notes.txt',
        'fonts/emblem',
        'assets/fonts/emblem',
        'items/hide_vest.webp',
      ]) {
        expect(index.has(key), isFalse, reason: key);
      }
      expect(ImageIndex.empty.has('items/hide_vest'), isFalse);
    });

    test('the app bundles each image file: the index of the asset manifest '
        'has each key of the files on disk', () async {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final bundled = ImageIndex.fromAssets(manifest.listAssets());
      final files = imageFiles().where((f) => f.endsWith('.webp')).toList();
      expect(files, isNotEmpty, reason: 'assets/images/ holds no image');
      for (final f in files) {
        final key = f.substring('assets/images/'.length, f.length - 5);
        expect(diskImages.has(key), isTrue, reason: f);
        expect(bundled.has(key), isTrue, reason: '$f is in the app bundle');
      }
    });

    test('phSpots has the 25 placeholders of the plan, each with its file '
        'and a spot on the image', () {
      expect(phSpots.keys.toSet(), placeholderKeys);
      for (final MapEntry(key: key, value: spot) in phSpots.entries) {
        expect(File(assetOf(key)).existsSync(), isTrue, reason: assetOf(key));
        expect(spot.x, inInclusiveRange(0, 1), reason: '$key: x');
        expect(spot.y, inInclusiveRange(0, 1), reason: '$key: y');
      }
    });

    for (final (what, thing, image, placeholder) in rows) {
      final shown = placeholder == null
          ? 'the water icon'
          : 'placeholders/$placeholder';
      test('$what: $image, else $shown', () {
        expectPicture(ImageIndex({image}).pictureOf(data, thing), image, what);
        expectPicture(
          ImageIndex.empty.pictureOf(data, thing),
          placeholder == null ? null : 'placeholders/$placeholder',
          '$what with no image',
        );
      });
    }

    test('a locked achievement shows the locked patch, which is no '
        'placeholder, with or without the image of the achievement', () {
      for (final index in [
        ImageIndex.empty,
        ImageIndex({'achievements/first_steps', 'pictures/locked_patch'}),
      ]) {
        expectPicture(
          index.pictureOf(data, AchievementThing('first_steps', earned: false)),
          'pictures/locked_patch',
          'a locked achievement',
        );
      }
    });

    test('a fogged place shows the fog marker, never its own marker or the '
        'marker of its kind', () {
      final fogged = PlaceThing('grey_moor', fogged: true);
      const markers = {'places/grey_moor', 'places/forge'};
      expectPicture(
        ImageIndex({...markers, 'places/fog'}).pictureOf(data, fogged),
        'places/fog',
        'with the fog marker',
      );
      expectPicture(
        ImageIndex(markers).pictureOf(data, fogged),
        'placeholders/generic',
        'with no fog marker',
      );
    });

    test('a place shows its own marker before the marker of its kind', () {
      expectPicture(
        ImageIndex({'places/goblin_woods', 'places/monsters'})
            .pictureOf(data, PlaceThing('goblin_woods', fogged: false)),
        'places/goblin_woods',
        'Goblin Woods',
      );
    });

    test('an item key with a quality and bonus rolls shows the image of its '
        'item', () {
      final index = ImageIndex({'items/hide_vest', 'items/bone_sword'});
      for (final (key, image) in [
        ('hide_vest@rare', 'items/hide_vest'),
        ('bone_sword@rare+crit2+hp10', 'items/bone_sword'),
      ]) {
        expectPicture(index.pictureOf(data, ItemThing(key)), image, key);
      }
      expectPicture(
        ImageIndex.empty.pictureOf(data, ItemThing('hide_vest@rare')),
        'placeholders/gear_chest',
        'hide_vest@rare with no image',
      );
    });

    test('gear never shows the material placeholder: each gear item, with no '
        'image files and with the files on disk', () {
      final gear = data.items.values.where((i) => i.slot != null).toList();
      expect(gear, isNotEmpty);
      for (final item in gear) {
        final own = 'placeholders/gear_${item.slot}';
        final bare = ImageIndex.empty.pictureOf(data, ItemThing(item.id));
        expect(bare.key, own, reason: item.id);
        final disk = diskImages.pictureOf(data, ItemThing(item.id)).key;
        expect(disk, isNot('placeholders/material'), reason: item.id);
        expect(disk, anyOf('items/${item.id}', own), reason: item.id);
      }
    });

    test('a slot kind or a profession that phSpots does not have shows the '
        'generic placeholder', () {
      final copy = gameWith({
        ('economy', 'gearSlots'): [
          {'id': 'tail'},
        ],
        ('items', 'items'): [
          {'id': 'test_tail', 'name': 'Test tail', 'slot': 'tail'},
          {
            'id': 'test_still',
            'name': 'Test still',
            'tool': {'profession': 'alchemy', 'stepFactor': 1},
          },
        ],
        // The data takes a tool only of a profession that it has.
        ('professions', 'professions'): [
          {
            'id': 'alchemy',
            'name': 'Alchemy',
            'icon': 'pot',
            'tool': 'Still',
            'tiers': [
              {'level': 1, 'name': 'Simple'},
            ],
            'teacher': {
              'name': 'Ida',
              'title': 'the alchemist',
              'location': 'camp',
              'starterTool': 'test_still',
              'learnLine': 'Take my still.',
              'greeting': 'Hello, {name}.',
              'kinLine': 'Kin, {name}.',
              'tips': <Object?>[],
            },
          },
        ],
      });
      for (final item in ['test_tail', 'test_still']) {
        expectPicture(
          ImageIndex.empty.pictureOf(copy.data, ItemThing(item)),
          'placeholders/generic',
          item,
        );
      }
    });

    test('with the files on disk, Hide vest shows its image and a ring with '
        'no file shows the ring placeholder', () {
      expectPicture(
        diskImages.pictureOf(data, ItemThing('hide_vest')),
        'items/hide_vest',
        'Hide vest',
      );
      expectPicture(
        diskImages.pictureOf(data, ItemThing(bareRing)),
        'placeholders/gear_ring',
        bareRing,
      );
    });

    for (final (screen, check) in m2Screens) {
      testWidgets(
        '$screen shows the picture of each thing, with the PH mark '
        'on placeholders only',
        check,
      );
    }
  });
}

/// The real game data with more in its files: each entry of [added] adds its
/// maps to one list of one file.
Game gameWith(Map<(String, String), List<Map<String, Object?>>> added) {
  final files = {
    for (final f in Directory(
      '../packages/game_core/data',
    ).listSync().whereType<File>())
      if (f.path.endsWith('.json'))
        f.uri.pathSegments.last.replaceAll('.json', ''): f.readAsStringSync(),
  };
  for (final MapEntry(key: (file, list), value: maps) in added.entries) {
    final json = jsonDecode(files[file]!) as Map<String, Object?>;
    (json[list]! as List<Object?>).addAll(maps);
    files[file] = jsonEncode(json);
  }
  return Game(GameData.fromJsonStrings(files));
}

/// The screens of M2, each with its check: each thing on the screen shows
/// the picture that pictureOf gives with the files on disk. M3 and M4 add
/// their screens to this list.
final m2Screens = <(String, Future<void> Function(WidgetTester))>[
  (
    'the doll',
    (t) async {
      await pumpGame(
        t,
        images: diskImages,
        equipment: {'chest': 'hide_vest', 'ring1': bareRing},
      );
      await openTab(t, 'character');
      for (final (slot, item) in [
        ('chest', 'hide_vest'),
        ('ring1', bareRing),
      ]) {
        expectShows(
          t,
          find.byKey(ValueKey('slot-$slot')),
          ItemThing(item),
          '$item on the doll',
        );
      }
    },
  ),
  (
    'the bag',
    (t) async {
      await pumpGame(
        t,
        images: diskImages,
        inventory: {'hide_vest': 1, bareRing: 1},
      );
      await openBag(t);
      for (final item in ['hide_vest', bareRing]) {
        expectShows(t, bagSquare(item), ItemThing(item), '$item in the bag');
      }
    },
  ),
  (
    'the item card',
    (t) async {
      await pumpGame(
        t,
        images: diskImages,
        inventory: {'hide_vest': 1, bareRing: 1},
      );
      for (final item in ['hide_vest', bareRing]) {
        await openItem(t, item);
        expectShows(
          t,
          find.byKey(const ValueKey('item-card')),
          ItemThing(item),
          'the card of $item',
        );
        await closeSheet(t);
      }
    },
  ),
  (
    'the Character header',
    (t) async {
      await pumpGame(t, images: diskImages);
      await openTab(t, 'character');
      expectShows(
        t,
        find.byKey(const ValueKey('character-portrait')),
        PlayerThing(ada.origin, ada.gender),
        'the portrait of Ada',
      );
    },
  ),
  (
    '"Who are you?"',
    (t) async {
      await pumpGame(t, images: diskImages, character: null);
      for (final o in game.data.origins.keys) {
        expectShows(
          t,
          find.byKey(ValueKey('portrait-$o')),
          PlayerThing(o, Gender.neither),
          'the card of $o',
        );
      }
    },
  ),
];

void criterion13() {
  group('spec 0014 criterion 13: the PH mark', () {
    // The screen tests of criterion 11 also check that only the placeholders
    // on the screens of M2 have the mark.
    testWidgets('only a placeholder has the mark: no mark on a real image, '
        'the locked patch or the water icon', (t) async {
      final data = game.data;
      for (final (what, index, thing, mark) in [
        ('a placeholder', ImageIndex.empty, ItemThing('hide_vest'), true),
        ('Hide vest with its image', diskImages, ItemThing('hide_vest'), false),
        (
          'the locked patch',
          ImageIndex.empty,
          AchievementThing('first_steps', earned: false),
          false,
        ),
        (
          'the water icon',
          ImageIndex.empty,
          PlaceThing('mirror_lake', fogged: false),
          false,
        ),
      ]) {
        final socket = await pumpSocket(t, index.pictureOf(data, thing));
        expect(
          markIn(socket),
          mark ? findsOneWidget : findsNothing,
          reason: what,
        );
      }
      expect(find.byIcon(Icons.water), findsOneWidget, reason: 'water icon');
    });

    testWidgets('an empty doll slot shows its faint slot icon and no mark; the '
        'off hand under a two-hander shows the link icon', (t) async {
      await pumpGame(
        t,
        images: diskImages,
        equipment: {'mainHand': 'iron_pike'},
      );
      await openTab(t, 'character');
      for (final g in game.data.gearSlots) {
        if (g.id == 'mainHand') continue;
        final square = find.byKey(ValueKey('slot-${g.id}'));
        expect(markIn(square), findsNothing, reason: g.id);
        expect(imagesIn(t, square), isEmpty, reason: g.id);
        final icon = g.id == 'offHand' ? Icons.link : slotIcon(g.id);
        expect(
          find.descendant(of: square, matching: find.byIcon(icon)),
          findsOneWidget,
          reason: 'the icon of ${g.id}',
        );
      }
    });

    testWidgets('each of the 25 placeholders at 72, 48 and 32 dp: a fill in '
        'steel at 85% and a thin black stroke, in Alegreya Sans SC 800, at '
        '22% of the socket from 9 dp to 16 dp', (t) async {
      for (final MapEntry(key: key, value: picture)
          in placeholderPictures().entries) {
        for (final MapEntry(key: size, value: fontSize) in markSizes.entries) {
          final what = '$key at $size dp';
          final socket = await pumpSocket(t, picture, size: size);
          final (:fill, :stroke) = markTexts(t, socket);
          for (final (part, x) in [('fill', fill), ('stroke', stroke)]) {
            expect(
              (x.style.fontFamily, x.style.fontWeight),
              ('Alegreya Sans SC', FontWeight.w800),
              reason: '$what: the font of the $part',
            );
            expect(
              drawnFontSize(x),
              moreOrLessEquals(fontSize, epsilon: 0.01),
              reason: '$what: the font size of the $part',
            );
          }
          expectRgb(fillColour(fill), 0xB9C2C9, '$what: the fill');
          expect(
            fillColour(fill)!.a,
            moreOrLessEquals(0.85, epsilon: 0.005),
            reason: '$what: the fill is steel at 85%',
          );
          final paint = stroke.style.foreground!;
          expectRgb(paint.color, 0x000000, '$what: the stroke');
          expect(
            paint.strokeWidth,
            inInclusiveRange(0, 2),
            reason: '$what: a thin stroke',
          );
          // The stroke traces the letters of the fill.
          final under = cornersOf(fill.box);
          for (final (i, corner) in cornersOf(stroke.box).indexed) {
            expect(
              corner,
              offsetMoreOrLessEquals(under[i], epsilon: 0.5),
              reason: '$what: the stroke lies on the fill',
            );
          }
        }
      }
    });

    testWidgets('the mark is never on the ring or below the count badge: it '
        'lies 2 dp inside the socket and the ring, and it does not meet the '
        'badge of 14', (t) async {
      final common = game.data.qualities.first;
      for (final MapEntry(key: key, value: picture)
          in placeholderPictures().entries) {
        for (final size in markSizes.keys) {
          for (final count in [1, 14]) {
            final what = '$key at $size dp with a count of $count';
            final socket = await pumpSocket(
              t,
              picture,
              size: size,
              quality: common,
              count: count,
            );
            final (:fill, :stroke) = markTexts(t, socket);
            final mark = cornersOf(fill.box);
            for (final edge in [
              t.getRect(socket).deflate(2),
              t.getRect(keyIn(socket, 'ring')).deflate(2),
            ]) {
              for (final corner in [...mark, ...cornersOf(stroke.box)]) {
                expect(
                  edge.inflate(0.01).contains(corner),
                  isTrue,
                  reason: '$what: the corner $corner of the mark lies in $edge',
                );
              }
            }
            if (count > 1) {
              final (_, badge) = badgeOf(t, socket);
              expect(
                overlaps(mark, [
                  badge.topLeft,
                  badge.topRight,
                  badge.bottomRight,
                  badge.bottomLeft,
                ]),
                isFalse,
                reason: '$what: the mark $mark meets the badge $badge',
              );
            }
          }
        }
      }
    });
  });
}

void criterion14() {
  group('spec 0014 criterion 14: "placeholder picture" and "Picture coming '
      'later"', () {
    final label = RegExp(r'\bplaceholder picture\b');

    testWidgets('a placeholder has the semantics label "placeholder '
        'picture"; a real image has none', (t) async {
      final semantics = t.ensureSemantics();
      final vest = ItemThing('hide_vest');
      await pumpSocket(t, ImageIndex.empty.pictureOf(game.data, vest));
      expect(find.bySemanticsLabel('placeholder picture'), findsOneWidget);
      await pumpSocket(t, diskImages.pictureOf(game.data, vest));
      expect(find.bySemanticsLabel(label), findsNothing);
      semantics.dispose();
    });

    testWidgets('the card of a placeholder says "Picture coming later" and '
        'has the label; the card of Hide vest with its image has neither', (
      t,
    ) async {
      final semantics = t.ensureSemantics();
      await pumpGame(
        t,
        images: diskImages,
        inventory: {'hide_vest': 1, bareRing: 1},
      );
      final card = find.byKey(const ValueKey('item-card'));
      for (final (item, placeholder) in [
        (bareRing, true),
        ('hide_vest', false),
      ]) {
        await openItem(t, item);
        for (final finder in [
          find.text('Picture coming later'),
          find.bySemanticsLabel(label),
        ]) {
          expect(
            find.descendant(of: card, matching: finder),
            placeholder ? findsOneWidget : findsNothing,
            reason: '$finder on the card of $item',
          );
        }
        await closeSheet(t);
      }
      semantics.dispose();
    });
  });
}

void criterion16() {
  group('spec 0014 criterion 16: the socket and the count badge', () {
    testWidgets('a socket of 72, 48 or 32 dp shows the Image of its picture', (
      t,
    ) async {
      for (final picture in [
        diskImages.pictureOf(game.data, ItemThing('hide_vest')),
        ImageIndex.empty.pictureOf(game.data, ItemThing('goblin_hide')),
      ]) {
        for (final size in markSizes.keys) {
          final socket = await pumpSocket(t, picture, size: size);
          expect(t.getSize(socket), Size(size, size), reason: picture.key);
          expect(imagesIn(t, socket), [picture.asset]);
        }
      }
    });

    testWidgets('a count of 2 or more shows "×N" in a badge that hangs off '
        'the lower right corner; a count of 1 shows no badge', (t) async {
      final picture = ImageIndex.empty.pictureOf(
        game.data,
        ItemThing('goblin_hide'),
      );
      for (final size in markSizes.keys) {
        final socket = await pumpSocket(t, picture, size: size);
        expect(keyIn(socket, 'count'), findsNothing, reason: '1 at $size dp');
        expect(find.textContaining('×'), findsNothing);
        for (final count in [2, 14]) {
          await pumpSocket(t, picture, size: size, count: count);
          expectBadge(t, socket, '×$count', '$count at $size dp');
        }
      }
    });

    testWidgets('in the bag, Goblin hide with 3 shows "×3", and one sword '
        'shows no count', (t) async {
      await pumpGame(t, inventory: {'goblin_hide': 3, 'copper_sword': 1});
      await openBag(t);
      expectBadge(t, socketIn(bagSquare('goblin_hide')), '×3', 'Goblin hide');
      expect(keyIn(bagSquare('copper_sword'), 'count'), findsNothing);
    });
  });
}

void criterion17() {
  group('spec 0014 criterion 17: the quality ring', () {
    testWidgets('a socket with a quality has a 2 dp ring in the colour of the '
        'quality, Common #E0E0E0; a socket with no quality has none', (
      t,
    ) async {
      expect(qualityRgb('common'), 0xE0E0E0);
      final picture = ImageIndex.empty.pictureOf(
        game.data,
        ItemThing('copper_sword'),
      );
      for (final q in game.data.qualities) {
        final socket = await pumpSocket(t, picture, quality: q);
        expectRing(t, socket, qualityRgb(q.id), q.name);
      }
      expect(ringIn(t, await pumpSocket(t, picture)), isNull);
    });

    testWidgets('in the bag, gear and tools have the ring of their quality; a '
        'material and a meal have none', (t) async {
      await pumpGame(
        t,
        inventory: {
          'hide_vest@rare': 1,
          'copper_sword': 1,
          'copper_pickaxe@uncommon': 1,
          'goblin_hide': 3,
          'grilled_perch': 1,
        },
      );
      await openBag(t);
      expect(qualityRgb('rare'), 0x42A5F5);
      for (final (key, quality) in [
        ('hide_vest@rare', 'rare'),
        ('copper_sword', 'common'),
        ('copper_pickaxe@uncommon', 'uncommon'),
      ]) {
        expectRing(t, bagSquare(key), qualityRgb(quality), key);
      }
      for (final key in ['goblin_hide', 'grilled_perch']) {
        expect(ringIn(t, bagSquare(key)), isNull, reason: '$key has no ring');
      }
    });
  });
}

void criterion23() {
  group('spec 0014 criterion 23: the portrait follows the origin and the '
      'gender', () {
    final portraits = ImageIndex({
      for (final o in game.data.origins.keys)
        for (final g in Gender.values) 'players/${o}_${g.name}',
    });

    Finder portraitOf(String origin) =>
        keyIn(find.byKey(ValueKey('origin-$origin')), 'portrait-$origin');

    void expectPortraits(WidgetTester t, Gender g) {
      for (final o in game.data.origins.keys) {
        expect(portraitOf(o), findsOneWidget, reason: 'the portrait of $o');
        expect(t.widget(portraitOf(o)), isA<PictureSocket>(), reason: o);
        expect(t.getSize(portraitOf(o)), const Size(72, 72), reason: o);
        expect(imagesIn(t, portraitOf(o)), [
          assetOf('players/${o}_${g.name}'),
        ], reason: o);
      }
    }

    testWidgets('each "Who are you?" card shows the portrait of its origin '
        'and the picked gender; a tap on another gender changes each '
        'portrait', (t) async {
      await withoutPortraitFiles(t, () async {
        await pumpGame(t, images: portraits, character: null);
        expectPortraits(t, Gender.neither);
        for (final g in [Gender.female, Gender.male, Gender.neither]) {
          await t.tap(
            find.descendant(
              of: find.byType(SegmentedButton<Gender>),
              matching: find.text(genderName(g)),
            ),
          );
          await t.pump();
          expectPortraits(t, g);
        }
      });
    });

    testWidgets('the Character header shows the portrait of the origin and '
        'the gender of the character', (t) async {
      await withoutPortraitFiles(t, () async {
        for (final who in [
          ada,
          const Character(
            name: 'Wen',
            gender: Gender.female,
            origin: 'coast_fisher',
          ),
          const Character(
            name: 'Hal',
            gender: Gender.male,
            origin: 'miners_child',
          ),
        ]) {
          await t.pumpWidget(const SizedBox());
          await pumpGame(t, images: portraits, character: who);
          await openTab(t, 'character');
          expect(
            imagesIn(t, find.byKey(const ValueKey('character-portrait'))),
            [assetOf('players/${who.origin}_${who.gender.name}')],
            reason: who.name,
          );
        }
      });
    });

    testWidgets('with no portrait images, the cards and the header show the '
        'player placeholder', (t) async {
      final placeholder = assetOf('placeholders/player');
      await pumpGame(t, character: null);
      for (final o in game.data.origins.keys) {
        expect(imagesIn(t, portraitOf(o)), [placeholder], reason: o);
      }
      await pumpGame(t);
      await openTab(t, 'character');
      expect(imagesIn(t, find.byKey(const ValueKey('character-portrait'))), [
        placeholder,
      ]);
    });
  });
}
