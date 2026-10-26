// Spec 0014 (Quiet Teal), plan 0017 M1: the checks that read files on disk.
// - Criterion 1: the Android window themes, the launch backgrounds and the
//   v31 splash screen backgrounds use #060708.
// - Criterion 2: each colour literal in lib/ is a colour that the spec allows.
// - Criterion 3: the nine font files, their four licence texts and
//   pubspec.yaml.
// - Criteria 27 and 28 hold today. They guard the rules, the numbers, the
//   packages and the manifest.
// - Criterion 24 (plan 0017 M5): the launcher files. The adaptive icon, the
//   PNG files of the emblem in each density, and the icon of the Android 12
//   splash screen.
// The widget tests of criteria 1 to 7 are in quiet_teal_test.dart. That file
// uses the colours and the font names below. The widget tests of criterion 24
// are in start_screens_test.dart.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data' show Uint8List;
import 'dart:ui' as ui;

import 'package:flutter/material.dart' show Color;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/game_controller.dart';
import 'package:walkingrpg/game_data_loader.dart';
import 'package:walkingrpg/persistence/save_data.dart';
import 'package:walkingrpg/persistence/save_store.dart';
import 'package:walkingrpg/steps/fake_step_source.dart';
import 'package:walkingrpg/sync/day_key.dart';

import 'support.dart';

// The colours of spec 0014 §2.1, as RGB.
const caseRgb = 0x060708;
const plateRgb = 0x171C21;
const slateRgb = 0x2B333B;
const slateLowRgb = 0x1E242A;
const litRgb = 0x2E3740;
const tealRgb = 0x8AC7BC;
const onTealRgb = 0x0D1416;
const deepTealRgb = 0x17292C;
const steelRgb = 0xB9C2C9;
const mistRgb = 0x8FA2AE;
const textRgb = 0xE3EAEC;
const mutedRgb = 0xA8B3B8;
const faintRgb = 0x7F8A90;
const shortRgb = 0xE08A7C;
const riskyRgb = 0xFBB15A;

/// The fill of a selected chip, segment or tab (spec 0014 amendment 4).
const selectedRgb = 0x4C6768;

const spec21Rgb = {
  selectedRgb,
  caseRgb,
  plateRgb,
  slateRgb,
  slateLowRgb,
  litRgb,
  tealRgb,
  onTealRgb,
  deepTealRgb,
  steelRgb,
  mistRgb,
  textRgb,
  mutedRgb,
  faintRgb,
  shortRgb,
  riskyRgb,
};

/// The band colours of `LevelBadge.colorOf` on `main` at 9942052: grey,
/// green, yellow, orange, red and skull. Spec 0014 §2.1 keeps them. The test
/// keeps its own copy, so that a change in the code cannot widen the allowed
/// colours.
const bandRgb = {0x9E9E9E, 0x43A047, 0xFBC02D, 0xFB8C00, 0xE53935, 0x8E0000};

/// Black and white, the neutrals of plan 0017. Transparent has the RGB of
/// black.
const neutralRgb = {0x000000, 0xFFFFFF};

/// Each colour that spec 0014 allows: the colours of §2.1, the quality
/// colours of the game data, the band colours and the neutrals.
Set<int> allowedRgb(Game game) => {
  ...spec21Rgb,
  for (final q in game.data.qualities)
    int.parse(q.colour.substring(1), radix: 16),
  ...bandRgb,
  ...neutralRgb,
};

/// The RGB of [c]. The alpha does not count: steel at 85% is steel.
int rgb(Color c) => c.toARGB32() & 0xFFFFFF;

String hex(int rgb) =>
    '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

// The four families of spec 0014 §2.2, as pubspec.yaml declares them.
const cormorant = 'Cormorant Garamond';
const alegreya = 'Alegreya Sans';
const alegreyaSc = 'Alegreya Sans SC';
const spectral = 'Spectral';

/// The font table of plan 0017: each family with its files in
/// `assets/fonts/`, as (file, weight, style).
const fontTable = {
  cormorant: [('CormorantGaramond-SemiBold.ttf', 600, 'normal')],
  alegreya: [
    ('AlegreyaSans-Regular.ttf', 400, 'normal'),
    ('AlegreyaSans-Bold.ttf', 700, 'normal'),
    ('AlegreyaSans-Italic.ttf', 400, 'italic'),
  ],
  alegreyaSc: [
    ('AlegreyaSansSC-Bold.ttf', 700, 'normal'),
    ('AlegreyaSansSC-ExtraBold.ttf', 800, 'normal'),
  ],
  spectral: [
    ('Spectral-Medium.ttf', 500, 'normal'),
    ('Spectral-SemiBold.ttf', 600, 'normal'),
    ('Spectral-Bold.ttf', 700, 'normal'),
  ],
};

/// The licence text of each family in `assets/fonts/`.
const licenceFiles = {
  cormorant: 'OFL-CormorantGaramond.txt',
  alegreya: 'OFL-AlegreyaSans.txt',
  alegreyaSc: 'OFL-AlegreyaSansSC.txt',
  spectral: 'OFL-Spectral.txt',
};

const _res = 'android/app/src/main/res';
const _manifest = 'android/app/src/main/AndroidManifest.xml';

/// The five densities of the launcher files, each with the width of the
/// adaptive icon in pixels: 108 dp at 1, 1.5, 2, 3 and 4 pixels for each dp.
const _densities = {
  'mdpi': 108,
  'hdpi': 162,
  'xhdpi': 216,
  'xxhdpi': 324,
  'xxxhdpi': 432,
};

String get _pubspec => File('pubspec.yaml').readAsStringSync();
final _xmlComment = RegExp(r'<!--[\s\S]*?-->');

void main() {
  // Criterion 27 reads the game data from the app bundle.
  TestWidgetsFlutterBinding.ensureInitialized();
  final game = loadTestGame();

  group('spec 0014 criterion 1: the Android windows are dark', () {
    test('both window themes have a dark parent and a #060708 window', () {
      final colours = _colourResources();
      for (final dir in ['values', 'values-night']) {
        final styles = _darkStyles(dir, colours);
        expect(styles.keys, containsAll(['LaunchTheme', 'NormalTheme']));
        final launch = styles['LaunchTheme']!.$2['android:windowBackground'];
        // The launch background file has its own test below.
        if (launch != '@drawable/launch_background') {
          _expectCase(launch, colours, '$dir: the window of LaunchTheme');
        }
      }
    });

    test('both launch backgrounds use #060708', () {
      final colours = _colourResources();
      for (final path in [
        'drawable/launch_background.xml',
        'drawable-v21/launch_background.xml',
      ]) {
        final xml = File('$_res/$path')
            .readAsStringSync()
            .replaceAll(_xmlComment, '');
        // Images (the emblem of M5) are not colours.
        final values = [
          for (final m in RegExp(
            r'android:(?:drawable|color)="([^"]+)"',
          ).allMatches(xml))
            if (!m[1]!.startsWith('@drawable/') &&
                !m[1]!.startsWith('@mipmap/'))
              m[1]!,
        ];
        expect(values, isNotEmpty, reason: '$path names no colour');
        for (final v in values) {
          _expectCase(v, colours, path);
        }
      }
    });

    test('the v31 styles set the splash screen background to #060708', () {
      final colours = _colourResources();
      final launch = RegExp(r'<activity\b[^>]*android:theme="@style/([^"]+)"')
          .firstMatch(File(_manifest).readAsStringSync())![1]!;
      for (final dir in ['values-v31', 'values-night-v31']) {
        final styles = _darkStyles(dir, colours);
        _expectCase(
          styles[launch]?.$2['android:windowSplashScreenBackground'],
          colours,
          '$dir: android:windowSplashScreenBackground of $launch',
        );
      }
    });
  });

  group('spec 0014 criterion 2: the colours of §2.1, no other warm colour', () {
    test('each colour in lib/ is a literal of an allowed colour, black, '
        'white or transparent', () {
      final allowed = allowedRgb(game);
      final outside = <String>[];
      var colours = 0;
      final files = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final f in files) {
        final code = _withoutComments(f.readAsStringSync());
        for (final (at, text, ok) in _colours(code, allowed)) {
          colours++;
          final line = '\n'.allMatches(code.substring(0, at)).length + 1;
          if (!ok) outside.add('${f.path}:$line: $text');
        }
      }
      expect(colours, greaterThan(0), reason: 'the scan finds no colour');
      expect(
        outside,
        isEmpty,
        reason:
            'Spec 0014 allows only the colours of §2.1, the quality and '
            'band colours, black, white and transparent.',
      );
    });
  });

  group('spec 0014 criterion 3: the four fonts and their licences', () {
    test('pubspec.yaml declares the four families with the nine files', () {
      expect(_fonts(), {
        for (final MapEntry(key: family, value: files) in fontTable.entries)
          family: {
            for (final (file, weight, style) in files)
              ('assets/fonts/$file', weight, style),
          },
      });
    });

    test('each of the nine font files is a TrueType file', () {
      for (final (file, _, _) in fontTable.values.expand((f) => f)) {
        final f = File('assets/fonts/$file');
        expect(f.existsSync(), isTrue, reason: 'assets/fonts/$file');
        expect(f.readAsBytesSync().take(4).toList(), [
          0x00,
          0x01,
          0x00,
          0x00,
        ], reason: '$file starts with the TrueType tag');
      }
    });

    test('the four licence texts are assets and hold the SIL OFL 1.1', () {
      final assets = _assets();
      for (final file in licenceFiles.values) {
        final path = 'assets/fonts/$file';
        final f = File(path);
        expect(f.existsSync(), isTrue, reason: path);
        // A folder entry ("assets/fonts/") also bundles each file in it.
        expect(
          assets.contains(path) || assets.contains('assets/fonts/'),
          isTrue,
          reason: '$path is listed under assets:',
        );
        expect(
          f.readAsStringSync(),
          contains('SIL OPEN FONT LICENSE Version 1.1'),
          reason: path,
        );
      }
    });
  });

  group('spec 0014 criterion 24: the launcher shows the emblem on #060708', () {
    test('the adaptive icon has the background #060708, the emblem as its '
        'foreground and the one-colour emblem as its monochrome layer', () {
      final manifest = File(_manifest).readAsStringSync();
      for (final attribute in ['icon', 'roundIcon']) {
        expect(manifest, contains('android:$attribute="@mipmap/ic_launcher"'));
      }
      final icon = File('$_res/mipmap-anydpi-v26/ic_launcher.xml')
          .readAsStringSync()
          .replaceAll(_xmlComment, '');
      String? layer(String name) =>
          RegExp('<$name\\b[^>]*\\bandroid:drawable="([^"]+)"')
              .firstMatch(icon)?[1];
      _expectCase(
        layer('background'),
        _colourResources(),
        'the background of the adaptive icon',
      );
      expect(layer('foreground'), '@mipmap/ic_launcher_foreground');
      expect(layer('monochrome'), '@mipmap/ic_launcher_monochrome');
      expect(
        File('$_res/drawable/ic_launcher_foreground.xml').existsSync(),
        isFalse,
        reason: 'the sword and the boot go',
      );
    });

    // The safe zone of an adaptive icon is the centred circle of 66 dp in its
    // 108 dp. A pixel shows when its alpha is above 0. It lies in the zone
    // when its centre is at most half its diagonal (0.71 px) outside the
    // circle.
    test('in each density, the emblem and the one-colour emblem are PNG files '
        'of 108 dp, transparent outside the safe zone', () async {
      for (final MapEntry(key: density, value: px) in _densities.entries) {
        for (final name in [
          'ic_launcher_foreground',
          'ic_launcher_monochrome',
        ]) {
          final path = '$_res/mipmap-$density/$name.png';
          final rgba = await _png(path, px);
          final zone = px * 33 / 108 + math.sqrt1_2;
          final outside = <String>[];
          var opaque = 0;
          for (var y = 0; y < px; y++) {
            for (var x = 0; x < px; x++) {
              final alpha = rgba[(y * px + x) * 4 + 3];
              if (alpha == 255) opaque++;
              final d = ui.Offset(x + .5 - px / 2, y + .5 - px / 2).distance;
              if (alpha > 0 && d > zone) outside.add('($x, $y)');
            }
          }
          expect(
            outside,
            isEmpty,
            reason:
                '$path: the pixels outside the safe zone '
                '(${outside.length}), for example ${outside.take(4)}',
          );
          expect(opaque, greaterThan(0), reason: '$path shows no emblem');
        }
      }
    });

    // Android draws the monochrome layer in a colour of its own, by its alpha.
    // The test asks for one colour, so that the full-colour emblem does not
    // pass for the one-colour emblem. It allows a little noise. A pixel with
    // an alpha below 128 does not count, because its colour is less exact.
    test('in each density, the one-colour emblem has one colour', () async {
      for (final MapEntry(key: density, value: px) in _densities.entries) {
        final path = '$_res/mipmap-$density/ic_launcher_monochrome.png';
        final rgba = await _png(path, px);
        final channels = [<int>[], <int>[], <int>[]];
        for (var i = 0; i < rgba.length; i += 4) {
          if (rgba[i + 3] < 128) continue;
          for (final (c, values) in channels.indexed) {
            values.add(rgba[i + c]);
          }
        }
        expect(channels.first, isNotEmpty, reason: '$path shows no emblem');
        for (final (c, values) in channels.indexed) {
          expect(
            values.reduce(math.max) - values.reduce(math.min),
            lessThanOrEqualTo(16),
            reason: '$path: ${['red', 'green', 'blue'][c]} varies',
          );
        }
      }
    });

    test('both v31 styles show the emblem on the splash screen of Android 12 '
        'and later', () {
      final launch = RegExp(r'<activity\b[^>]*android:theme="@style/([^"]+)"')
          .firstMatch(File(_manifest).readAsStringSync())![1]!;
      for (final dir in ['values-v31', 'values-night-v31']) {
        expect(
          _styles(
            File('$_res/$dir/styles.xml'),
          )[launch]?.$2['android:windowSplashScreenAnimatedIcon'],
          '@mipmap/ic_launcher_foreground',
          reason: '$dir: $launch',
        );
      }
    });
  });

  // A unit test cannot see the diff of M1, and a hash of the rules would
  // break each later data-only change. So these tests guard criterion 27 from
  // the side of the app.
  group('spec 0014 criterion 27: rules and numbers do not change', () {
    test('the app loads the game data on disk, parsed the same way', () async {
      final dir = Directory('../packages/game_core/data');
      final names = [
        for (final f in dir.listSync().whereType<File>())
          if (f.path.endsWith('.json')) f.uri.pathSegments.last,
      ];
      expect(names, isNotEmpty);
      for (final name in names) {
        final bundled = await rootBundle.loadString(
          'packages/game_core/data/$name',
        );
        expect(
          jsonDecode(bundled),
          jsonDecode(File('${dir.path}/$name').readAsStringSync()),
          reason: '$name in the app bundle',
        );
      }

      final app = Game(await loadBundledGameData());
      final disk = loadTestGame();
      expect(app.data.enemies.keys, disk.data.enemies.keys);
      expect(app.data.items.keys, disk.data.items.keys);
      expect(app.data.locations.keys, disk.data.locations.keys);
      expect(app.data.recipes.keys, disk.data.recipes.keys);
      expect(app.data.achievements.keys, disk.data.achievements.keys);
      // The same walk ends in the same state with each copy of the data.
      for (final (place, activity) in const [
        ('goblin_woods', Activity.fight('goblin')),
        ('camp', Activity.travel('goblin_woods')),
      ]) {
        String walk(Game g) {
          final s = g.newGame(seed: 1)
            ..location = place
            ..explored.add(place);
          final run = g.applySteps(g.startActivity(s, activity), 3000);
          return jsonEncode(run.state.toJson());
        }

        expect(walk(app), walk(disk), reason: '$activity');
      }
    });

    test('a walk through the controller ends where applySteps ends', () async {
      var now = DateTime(2026, 10, 18, 9);
      final source = FakeStepSource();
      final start = game.newGame(seed: 1)
        ..location = 'goblin_woods'
        ..explored.add('goblin_woods');
      final c = GameController(
        game: game,
        source: source,
        permissions: source,
        store: MemorySaveStore(
          SaveData(
            game: start,
            firstDay: dayKey(now),
            credited: const {},
          ).toJson(),
        ),
        clock: () => now,
        syncInterval: null,
        newSeed: () => 1,
      );
      addTearDown(c.dispose);
      await c.start();
      await c.startActivity(const Activity.fight('goblin'));
      final before = c.state.copy();

      // Two syncs on one day: the controller gives each one its new steps.
      source.walk(DateTime(2026, 10, 18, 9, 30), 700);
      now = DateTime(2026, 10, 18, 10);
      await c.syncNow();
      source.walk(DateTime(2026, 10, 18, 10, 30), 800);
      now = DateTime(2026, 10, 18, 11);
      await c.syncNow();

      final expected = game
          .applySteps(game.applySteps(before, 700).state, 800)
          .state;
      expect(
        jsonEncode(c.state.toJson()),
        isNot(jsonEncode(before.toJson())),
        reason: 'the walk changes the state',
      );
      expect(jsonEncode(c.state.toJson()), jsonEncode(expected.toJson()));
    });
  });

  group('spec 0014 criterion 28: no INTERNET permission, no new package', () {
    test("pubspec.yaml keeps today's packages", () {
      final yaml = _pubspec;
      expect(_packages(yaml, 'dependencies'), {
        'flutter',
        'game_core',
        'health',
        'path_provider',
      });
      expect(_packages(yaml, 'dev_dependencies'), {
        'flutter_test',
        'flutter_lints',
      });
      expect(_packages(yaml, 'dependency_overrides'), isEmpty);
    });

    test('the manifest has no INTERNET permission and keeps '
        'allowBackup="false"', () {
      final manifest = File(_manifest).readAsStringSync();
      expect(manifest, isNot(contains('android.permission.INTERNET')));
      expect(manifest, contains('android:allowBackup="false"'));
    });
  });
}

/// Each `<color>` of the `res/values*/` files, by name.
Map<String, String> _colourResources() {
  final out = <String, String>{};
  for (final dir in Directory(_res).listSync().whereType<Directory>()) {
    if (!dir.path.split(RegExp(r'[\\/]')).last.startsWith('values')) continue;
    for (final f in dir.listSync().whereType<File>()) {
      if (!f.path.endsWith('.xml')) continue;
      final xml = f.readAsStringSync().replaceAll(_xmlComment, '');
      for (final m in RegExp(
        r'<color\s+name="([^"]+)"\s*>\s*([^<\s]+)\s*</color>',
      ).allMatches(xml)) {
        out[m[1]!] = m[2]!;
      }
    }
  }
  return out;
}

/// [value] as "#RRGGBB": a colour literal, or a `@color/` reference to a
/// colour of `res/values*/`. Anything else stays as it is, so that a failure
/// shows it.
String? _resolved(String? value, Map<String, String> colours) {
  var v = value;
  for (var i = 0; i < 5 && v != null && v.startsWith('@color/'); i++) {
    v = colours[v.substring('@color/'.length)];
  }
  if (v == null || !v.startsWith('#')) return v;
  final h = v.substring(1);
  final rrggbb = switch (h.length) {
    3 => [for (final c in h.split('')) '$c$c'].join(),
    4 => [for (final c in h.substring(1).split('')) '$c$c'].join(),
    6 => h,
    8 => h.substring(2),
    _ => null,
  };
  final n = rrggbb == null ? null : int.tryParse(rrggbb, radix: 16);
  return n == null ? v : hex(n);
}

/// The styles of [file] by name, each with its parent and its items.
Map<String, (String, Map<String, String>)> _styles(File file) {
  final xml = file.readAsStringSync().replaceAll(_xmlComment, '');
  final out = <String, (String, Map<String, String>)>{};
  for (final m in RegExp(
    r'<style\b([^>]*?)(?:/>|>([\s\S]*?)</style>)',
  ).allMatches(xml)) {
    final name = RegExp(r'\bname="([^"]*)"').firstMatch(m[1]!)?[1];
    if (name == null) continue;
    out[name] = (
      RegExp(r'\bparent="([^"]*)"').firstMatch(m[1]!)?[1] ?? '',
      {
        for (final i in RegExp(
          r'<item\s+name="([^"]+)"\s*>\s*([^<]*?)\s*</item>',
        ).allMatches(m[2] ?? ''))
          i[1]!: i[2]!,
      },
    );
  }
  return out;
}

/// The styles of `res/[dir]/styles.xml`. Expects each style to be dark: a
/// parent theme that is dark for each phone setting (no Light theme and no
/// DayNight theme), and a #060708 window for NormalTheme where the file has
/// it.
Map<String, (String, Map<String, String>)> _darkStyles(
  String dir,
  Map<String, String> colours,
) {
  final file = File('$_res/$dir/styles.xml');
  expect(file.existsSync(), isTrue, reason: '$dir/styles.xml');
  final styles = _styles(file);
  for (final MapEntry(key: name, value: (parent, _)) in styles.entries) {
    expect(parent, isNotEmpty, reason: '$dir: $name has no parent theme');
    expect(parent, isNot(contains('Light')), reason: '$dir: $name');
    expect(parent, isNot(contains('DayNight')), reason: '$dir: $name');
  }
  if (styles['NormalTheme'] case (_, final items)) {
    _expectCase(
      items['android:windowBackground'],
      colours,
      '$dir: the window of NormalTheme',
    );
  }
  return styles;
}

/// The pixels of the PNG file at [path], as straight RGBA: the alpha is not
/// multiplied into the colour. Expects a PNG file of [size] x [size] pixels.
Future<Uint8List> _png(String path, int size) async {
  final file = File(path);
  expect(file.existsSync(), isTrue, reason: path);
  final bytes = file.readAsBytesSync();
  expect(bytes.take(8).toList(), [
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
  ], reason: '$path is a PNG file');
  final codec = await ui.instantiateImageCodec(bytes);
  final image = (await codec.getNextFrame()).image;
  expect((image.width, image.height), (size, size), reason: path);
  final data = await image.toByteData(
    format: ui.ImageByteFormat.rawStraightRgba,
  );
  image.dispose();
  codec.dispose();
  return data!.buffer.asUint8List();
}

/// Expects [value] to be #060708, as a literal or a `@color/` reference.
void _expectCase(String? value, Map<String, String> colours, String what) =>
    expect(_resolved(value, colours), hex(caseRgb), reason: '$what: $value');

/// [code] with each comment replaced by spaces, so that offsets and line
/// numbers stay.
String _withoutComments(String code) => code
    .replaceAllMapped(
      RegExp(r'/\*[\s\S]*?\*/'),
      (m) => m[0]!.replaceAll(RegExp(r'[^\n]'), ' '),
    )
    .replaceAllMapped(RegExp(r'//[^\n]*'), (m) => ' ' * m[0]!.length);

/// Each colour expression of [code], with its offset, its text and whether
/// spec 0014 allows it. These pass:
/// - a `Color(0x...)` literal whose RGB is allowed;
/// - `Colors.black`, `Colors.white` and `Colors.transparent`;
/// - a `Color(...)` made from a colour of the game data (`.colour` inside
///   its parentheses): the quality colours.
/// Each other colour expression fails: each other `Colors` name, each named
/// constructor or static of Color (`fromARGB`, `fromRGBO`, `from`, `lerp`),
/// a swatch or an HSV or HSL colour, each other `Color(...)` (also as
/// `ui.Color`), and a change of the red, green or blue of a colour
/// (`withRed`, `withGreen`, `withBlue`, `withValues` with a channel).
Iterable<(int, String, bool)> _colours(String code, Set<int> allowed) sync* {
  // The text between the parenthesis at [open] and the one that closes it.
  String inside(int open) {
    var depth = 0;
    for (var i = open; i < code.length; i++) {
      if (code[i] == '(') depth++;
      if (code[i] == ')' && --depth == 0) return code.substring(open + 1, i);
    }
    return code.substring(open + 1);
  }

  for (final m in RegExp(r'(?<![\w.])Colors\.(\w+)').allMatches(code)) {
    yield (m.start, m[0]!, {'black', 'white', 'transparent'}.contains(m[1]));
  }
  for (final m in RegExp(
    r'(?<![\w.])(?:MaterialColor|MaterialAccentColor|ColorSwatch|HSVColor'
    r'|HSLColor)\b',
  ).allMatches(code)) {
    yield (m.start, m[0]!, false);
  }
  for (final m in RegExp(
    r'(?<![\w.])(?:ui\.)?Color(\.\w+|\()',
  ).allMatches(code)) {
    if (m[1] != '(') {
      yield (m.start, m[0]!, false);
      continue;
    }
    final arg = inside(m.end - 1).trim();
    final literal = RegExp(r'^0x([0-9A-Fa-f]{1,8})$').firstMatch(arg);
    yield (
      m.start,
      '${m[0]}$arg)',
      literal != null
          ? allowed.contains(int.parse(literal[1]!, radix: 16) & 0xFFFFFF)
          : arg.contains('.colour'),
    );
  }
  for (final m in RegExp(r'\.with(Red|Green|Blue|Values)\(').allMatches(code)) {
    final arg = inside(m.end - 1);
    if (m[1] != 'Values' || RegExp(r'\b(?:red|green|blue)\s*:').hasMatch(arg)) {
      yield (m.start, '${m[0]}$arg)', false);
    }
  }
}

/// The lines of the block under `  [key]:` in the `flutter:` section of
/// pubspec.yaml, trimmed, without comments and empty lines.
List<String> _flutterBlock(String key) {
  final out = <String>[];
  var section = '';
  var block = '';
  for (final raw in _pubspec.split('\n')) {
    final line = raw.replaceAll(RegExp(r'\r|\s*#.*$'), '');
    if (line.trim().isEmpty) continue;
    if (!line.startsWith(' ')) {
      section = line;
    } else if (!line.startsWith('   ')) {
      block = line.trim();
    } else if (section == 'flutter:' && block == '$key:') {
      out.add(line.trim());
    }
  }
  return out;
}

/// The assets of pubspec.yaml.
List<String> _assets() => [
  for (final line in _flutterBlock('assets'))
    if (RegExp(r'''^- ["']?(.+?)["']?$''').firstMatch(line) case final m?)
      m[1]!,
];

/// The font families of pubspec.yaml, each with its files as (asset,
/// weight, style). A file without a weight has weight 400, and a file
/// without a style is normal.
Map<String, Set<(String, int, String)>> _fonts() {
  final files = <(String, String, int, String)>[];
  var family = '';
  for (final line in _flutterBlock('fonts')) {
    if (RegExp(r'''^- family: ["']?(.+?)["']?$''').firstMatch(line)
        case final m?) {
      family = m[1]!;
    } else if (RegExp(r'^- asset: (\S+)$').firstMatch(line) case final m?) {
      files.add((family, m[1]!, 400, 'normal'));
    } else if (RegExp(r'^weight: (\d+)$').firstMatch(line) case final m?) {
      final (f, a, _, s) = files.removeLast();
      files.add((f, a, int.parse(m[1]!), s));
    } else if (RegExp(r'^style: (\w+)$').firstMatch(line) case final m?) {
      final (f, a, w, _) = files.removeLast();
      files.add((f, a, w, m[1]!));
    }
  }
  return {
    for (final (name, _, _, _) in files)
      name: {
        for (final (f, asset, weight, style) in files)
          if (f == name) (asset, weight, style),
      },
  };
}

/// The packages under the top-level [key] of pubspec.yaml.
Set<String> _packages(String yaml, String key) {
  final out = <String>{};
  var inside = false;
  for (final raw in yaml.split('\n')) {
    final line = raw.replaceAll('\r', '');
    if (line.trim().isEmpty || line.trim().startsWith('#')) continue;
    if (!line.startsWith(' ')) {
      inside = line.trim() == '$key:';
      continue;
    }
    final m = RegExp(r'^  ([\w-]+):').firstMatch(line);
    if (inside && m != null) out.add(m[1]!);
  }
  return out;
}
