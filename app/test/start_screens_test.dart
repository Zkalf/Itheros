// Spec 0014 (Quiet Teal), plan 0017 M5: the widget tests of criterion 24.
// - The splash, the welcome and "Health Connect is needed" show the splash
//   picture (§3.3). The splash also shows ITHEROS, and a plate with the
//   loading bar, "Reading your steps" and the version.
// - The status bar icons are dark on the splash picture, and light on the
//   screens after it (§2.1).
// Each test reads what the player sees on a phone of 360 x 800 dp, with a
// status bar, a gesture bar and the app's fonts: the Image of the picture by
// its asset name and its place, the plates, the texts, and the style that the
// app gives the status bar. No test decodes an image. The splash picture
// comes with the code of M5.
// quiet_teal_files_test.dart holds the launcher files of criterion 24, and
// quiet_teal_test.dart the checks of criteria 2, 3 and 4 on these screens.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/game_controller.dart';
import 'package:walkingrpg/persistence/save_store.dart';
import 'package:walkingrpg/steps/fake_step_source.dart';
import 'package:walkingrpg/ui/app.dart';
import 'package:walkingrpg/ui/character_creation_screen.dart';
import 'package:walkingrpg/ui/level_up_screen.dart';
import 'package:walkingrpg/version.dart';

import 'images_test.dart' show assetName, imagesIn, loadFonts, markIn;
import 'quiet_teal_files_test.dart' show tealRgb;
import 'quiet_teal_test.dart'
    show barColour, byElement, drawnBy, expectRgb, isPlate, squash, walkAway;
import 'ui_test.dart' show game, pumpGame, settle;

/// The splash picture (spec 0014 §3.1 and §3.3).
const splashAsset = 'assets/images/pictures/splash.webp';

/// A phone of 360 x 800 dp with a status bar of 24 dp and a gesture bar of
/// 16 dp.
const phone = Size(360, 800);
const statusBar = 24.0;
const gestureBar = 16.0;

/// Today's words of the two screens of `_Message`: the title, the text and
/// the button (onboarding_screens.dart at 902c722).
const welcomeWords = [
  'Your steps are your power',
  'Every fight, ore and crafted item is paid for with steps you walk. Allow '
      'step access so your walks count. Your step data stays on this phone. '
      "Steps walked before you install the game don't count.",
  'Allow step access',
];
const unavailableWords = [
  'Health Connect is needed',
  'This game reads your steps from Health Connect. Install or update Health '
      'Connect from the Play Store, then try again.',
  'Try again',
];

/// The three screens of criterion 24, each with the way to open it.
final startScreens = <(String, Future<void> Function(WidgetTester))>[
  ('the splash', (t) => pumpSplash(t)),
  ('the welcome', (t) => pumpWelcome(t)),
  ('"Health Connect is needed"', (t) => pumpUnavailable(t)),
];

void main() {
  setUpAll(loadFonts);
  group('spec 0014 criterion 24: the splash, the welcome and "Health '
      'Connect is needed"', () {
    testWidgets('the splash: the splash picture fills the screen, behind the '
        'status bar and the gesture bar', (t) async {
      await pumpSplash(t);
      expect(t.getRect(await expectPicture(t)), Offset.zero & phone);
    });

    testWidgets('the splash: ITHEROS near the top, and a plate at the bottom '
        'with the teal loading bar, "Reading your steps" and the version, '
        'both on the picture', (t) async {
      await pumpSplash(t);
      final picture = t.element(await expectPicture(t));
      final wordmark = find.text('ITHEROS');
      expect(wordmark, findsOneWidget);
      final w = t.getRect(wordmark);
      expect(
        w.top >= statusBar &&
            w.bottom <= phone.height / 3 &&
            w.left >= 0 &&
            w.right <= phone.width,
        isTrue,
        reason:
            'ITHEROS at $w lies below the status bar, inside the screen '
            'and in its top third',
      );

      final bar = find.byType(LinearProgressIndicator);
      expect(bar, findsOneWidget, reason: 'the loading bar');
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expectRgb(barColour(t.element(bar)), tealRgb, 'the loading bar');
      final plate = plateAbove(t.element(bar), 'the loading bar');
      expect(
        [for (final (_, text) in textsOn(t, plate)) text],
        unorderedEquals(['Reading your steps', 'Version $appVersion']),
        reason: 'the texts on the plate',
      );
      final p = t.getRect(byElement(plate));
      final bottom = phone.height - gestureBar;
      expect(
        p.bottom,
        inInclusiveRange(bottom - 24, bottom),
        reason: 'the plate $p at the bottom, above the gesture bar',
      );
      for (final (what, e) in [
        ('ITHEROS', t.element(wordmark)),
        ('the plate', plate),
      ]) {
        expectOnPicture(t, e, picture, what);
      }
    });

    for (final ((screen, open), words) in [
      (startScreens[1], welcomeWords),
      (startScreens[2], unavailableWords),
    ]) {
      testWidgets('$screen: the splash picture at the top, and below it on a '
          "plate today's words and the teal button", (t) async {
        await open(t);
        final picture = t.getRect(await expectPicture(t));
        expect(
          (picture.left, picture.top, picture.right),
          (0.0, 0.0, phone.width),
          reason: 'the picture $picture lies at the top, across the screen',
        );
        expect(
          picture.height,
          greaterThanOrEqualTo(phone.height / 3),
          reason: 'the picture $picture takes a third of the screen or more',
        );
        final button = find.ancestor(
          of: find.text(words.last),
          matching: find.byWidgetPredicate((w) => w is FilledButton),
        );
        expect(button, findsOneWidget, reason: 'the teal button');
        final plate = plateAbove(t.element(button), 'the button');
        final texts = textsOn(t, plate);
        expect(
          squash([for (final (_, text) in texts) text].join(' ')),
          squash(words.join(' ')),
          reason: "today's words on the plate, and no other",
        );
        for (final (rect, text) in texts) {
          expect(
            rect.top,
            greaterThanOrEqualTo(picture.bottom - .01),
            reason: '"$text" at $rect lies below the picture $picture',
          );
        }
        expect(
          t.getRect(byElement(plate)).bottom,
          lessThanOrEqualTo(phone.height - gestureBar),
          reason: 'the plate lies above the gesture bar',
        );
        for (final icon in [
          Icons.directions_walk,
          Icons.health_and_safety_outlined,
        ]) {
          expect(find.byIcon(icon), findsNothing, reason: 'the 64 dp icon');
        }
      });
    }

    // §2.1: "Status bar icons are light. They are dark on the splash
    // picture." A style stays on the phone until a screen gives another one.
    // So the screens that can follow with no top bar give the light style
    // themselves.
    testWidgets('the status bar icons are dark on the three screens, and '
        'light on "Who are you?" and on a level-up card', (t) async {
      for (final (screen, open) in startScreens) {
        await open(t);
        expect(statusBarIcons(t), Brightness.dark, reason: screen);
      }
      final c = await pumpWelcome(t);
      await t.tap(find.text('Allow step access'));
      await settle(t, c);
      expect(find.byType(CharacterCreationScreen), findsOneWidget);
      expect(statusBarIcons(t), Brightness.light, reason: '"Who are you?"');
      await walkAway(t, steps: 5000);
      expect(find.byType(LevelUpScreen), findsOneWidget);
      expect(statusBarIcons(t), Brightness.light, reason: 'a level-up card');
    });
  });
}

// Screens.

// Each screen opens on [phone]. With onPhone false, it keeps the view of the
// test: a file that draws text in the test font, with its wide letters, needs
// more room than a phone.

/// Opens the splash: the app before its controller starts.
Future<void> pumpSplash(WidgetTester t, {bool onPhone = true}) async {
  final source = FakeStepSource();
  final c = GameController(
    game: game,
    source: source,
    permissions: source,
    store: MemorySaveStore(),
    clock: () => DateTime(2026, 10, 18, 9),
    syncInterval: null,
  );
  addTearDown(c.dispose);
  // A new tree, so that no state of an earlier screen stays.
  await t.pumpWidget(const SizedBox());
  await t.pumpWidget(WalkingRpgApp(controller: c));
  await _show(t, onPhone);
}

/// Opens the welcome: the player has not allowed step access.
Future<GameController> pumpWelcome(
  WidgetTester t, {
  bool onPhone = true,
}) async {
  await t.pumpWidget(const SizedBox());
  final (c, _) = await pumpGame(t, granted: false);
  await _show(t, onPhone);
  return c;
}

/// Opens "Health Connect is needed": the phone has no Health Connect.
Future<void> pumpUnavailable(WidgetTester t, {bool onPhone = true}) async {
  await t.pumpWidget(const SizedBox());
  final (c, source) = await pumpGame(t, granted: false);
  source.available = false;
  await c.start();
  await _show(t, onPhone);
}

/// Draws the screen, on [phone] at 3 pixels for each dp if [onPhone]. The
/// view resets after the test.
Future<void> _show(WidgetTester t, bool onPhone) async {
  if (onPhone) {
    const bars = FakeViewPadding(top: statusBar * 3, bottom: gestureBar * 3);
    t.view
      ..physicalSize = phone * 3
      ..devicePixelRatio = 3
      ..padding = bars
      ..viewPadding = bars;
    addTearDown(t.view.reset);
  }
  // The load of an asset that does not exist fails one frame later.
  await t.pump();
  await t.pump();
}

// What the screens show.

/// Expects the splash picture once on the screen: an Image of its asset that
/// covers its box. It is a picture, not a placeholder: it has no PH mark, and
/// a screen reader does not say "placeholder picture".
Future<Finder> expectPicture(WidgetTester t) async {
  final picture = find.byWidgetPredicate(
    (w) => w is Image && assetName(w.image) == splashAsset,
  );
  expect(
    picture,
    findsOneWidget,
    reason: 'the images: ${imagesIn(t, find.byType(Scaffold))}',
  );
  expect(t.widget<Image>(picture).fit, BoxFit.cover);
  expect(markIn(find.byType(Scaffold)), findsNothing, reason: 'a PH mark');
  final semantics = t.ensureSemantics();
  await t.pump();
  expect(find.bySemanticsLabel(RegExp('placeholder picture')), findsNothing);
  semantics.dispose();
  return picture;
}

/// The closest plate above [e]: the plate colour, radius 16 and the 1 dp teal
/// hairline.
Element plateAbove(Element e, String what) {
  Element? plate;
  e.visitAncestorElements((a) {
    if (drawnBy(a) case final d? when isPlate(d)) plate = a;
    return plate == null;
  });
  expect(plate, isNotNull, reason: '$what stands on no plate');
  return plate!;
}

/// Each text on [plate] with its rect, top first, then left first.
List<(Rect, String)> textsOn(WidgetTester t, Element plate) =>
    [
      for (final e
          in find
              .descendant(of: byElement(plate), matching: find.byType(RichText))
              .evaluate())
        (t.getRect(byElement(e)), (e.widget as RichText).text.toPlainText()),
    ]..sort(
      (a, b) => a.$1.top == b.$1.top
          ? a.$1.left.compareTo(b.$1.left)
          : a.$1.top.compareTo(b.$1.top),
    );

/// Expects [top] to paint above [picture]: it comes later in the tree.
void expectOnPicture(
  WidgetTester t,
  Element top,
  Element picture,
  String what,
) {
  final order = collectAllElementsFrom(
    t.binding.rootElement!,
    skipOffstage: true,
  ).toList();
  expect(
    order.indexOf(top),
    greaterThan(order.indexOf(picture)),
    reason: '$what paints above the picture',
  );
}

/// The brightness of the status bar icons that the app asks for: the style
/// at the middle of the status bar in the layers of the screen. After each
/// frame, RenderView finds it there and sends it to the phone. Null when the
/// screen gives no style.
Brightness? statusBarIcons(WidgetTester t) {
  final view = t.binding.renderViews.single;
  return view.debugLayer!
      .find<SystemUiOverlayStyle>(
        Offset(view.paintBounds.center.dx, t.view.padding.top / 2),
      )
      ?.statusBarIconBrightness;
}
