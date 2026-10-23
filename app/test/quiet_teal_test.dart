// Spec 0014 (Quiet Teal), plan 0017 M1: the widget tests of criteria 1 to 7.
// Each test reads what the player sees: the resolved theme, the rendered
// widgets and their styles. Colours compare by RGB at any alpha, so that a
// hairline at a low alpha, or a colour under a light overlay, counts as its
// colour. A fill or a border with alpha 0 does not count, because nobody
// sees it. The tests use MemorySaveStore, and the Licences page reads its
// texts from a test bundle with synchronous reads, so no real I/O runs in
// the fake-async zone. quiet_teal_files_test.dart holds the checks that read
// files on disk, and the colours and font names of the spec.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/game_controller.dart';
import 'package:walkingrpg/persistence/save_store.dart';
import 'package:walkingrpg/steps/fake_step_source.dart';
import 'package:walkingrpg/ui/actions.dart' show Heading;
import 'package:walkingrpg/ui/app.dart';
import 'package:walkingrpg/ui/away_summary_card.dart' show ReportBanner;
import 'package:walkingrpg/ui/home_shell.dart';
import 'package:walkingrpg/ui/level_badge.dart';
import 'package:walkingrpg/ui/licences_screen.dart';
import 'package:walkingrpg/ui/world_tab.dart' show MapPainter;

import 'quiet_teal_files_test.dart'
    show
        alegreya,
        alegreyaSc,
        allowedRgb,
        caseRgb,
        cormorant,
        deepTealRgb,
        hex,
        licenceFiles,
        litRgb,
        mistRgb,
        onTealRgb,
        plateRgb,
        rgb,
        riskyRgb,
        shortRgb,
        slateRgb,
        spectral,
        steelRgb,
        tealRgb,
        textRgb;
import 'ui_test.dart'
    show
        ada,
        closeSheet,
        game,
        now,
        openAchievements,
        openArea,
        openProfession,
        openSettings,
        openTab,
        option,
        pumpGame,
        settle;

const _tabs = {
  'now': 'Now',
  'world': 'World',
  'professions': 'Professions',
  'character': 'Character',
};

/// Trophies, Journal and Settings, in the order of the top bar.
const _topBar = ['achievements-button', 'journal-button', 'settings-button'];

/// The five states of criterion 4, and a selected button that is pressed.
const _states = <String, Set<WidgetState>>{
  'default': {},
  'pressed': {WidgetState.pressed},
  'focused': {WidgetState.focused},
  'disabled': {WidgetState.disabled},
  'selected': {WidgetState.selected},
  'selected and pressed': {WidgetState.selected, WidgetState.pressed},
};

final _buttons = find.byWidgetPredicate((w) => w is ButtonStyleButton);

/// The status card on Now: the card with "Walked today".
Finder get _statusCard => find
    .ancestor(
      of: find.byKey(const ValueKey('walked-today')),
      matching: find.byType(Card),
    )
    .first;

void main() {
  criterion1();
  criterion2();
  criterion3();
  criterion4();
  criterion5();
  criterion6();
  criterion7();
}

void criterion1() {
  group('spec 0014 criterion 1: dark for each phone setting', () {
    for (final phone in Brightness.values) {
      testWidgets('with a ${phone.name} phone setting, Now is dark on #060708 '
          'with light status bar icons', (t) async {
        setPhone(t, phone);
        await pumpGame(t);
        final home = find.byType(HomeShell);
        expect(Theme.of(t.element(home)).brightness, Brightness.dark);
        expectRgb(scaffoldFill(t, home), caseRgb, 'the background of Now');
        final region = find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        );
        expect(
          t
              .widget<AnnotatedRegion<SystemUiOverlayStyle>>(region.first)
              .value
              .statusBarIconBrightness,
          Brightness.light,
          reason: 'light status bar icons (§2.1)',
        );
      });

      testWidgets('with a ${phone.name} phone setting, the start screens '
          'are dark on #060708', (t) async {
        setPhone(t, phone);
        for (final (screen, character, granted) in [
          ('Allow step access', ada, false),
          ('Who are you?', null, true),
        ]) {
          await pumpGame(t, character: character, granted: granted);
          final words = find.text(screen);
          expect(words, findsOneWidget);
          expect(Theme.of(t.element(words)).brightness, Brightness.dark);
          expectRgb(
            scaffoldFill(t, find.byType(Scaffold)),
            caseRgb,
            'the background of the screen with "$screen"',
          );
        }
      });
    }
  });
}

void criterion2() {
  group('spec 0014 criterion 2: the colours of §2.1', () {
    // The only warm colours that the spec allows are short, Risky, the
    // quality colours and the band colours. So this test also guards "no
    // other warm colour".
    testWidgets('each colour of the theme is a colour that the spec allows', (
      t,
    ) async {
      final allowed = allowedRgb(game);
      for (final phone in Brightness.values) {
        setPhone(t, phone);
        await pumpGame(t);
        final theme = Theme.of(t.element(find.byType(HomeShell)));
        expect(
          {
            for (final MapEntry(key: name, value: c) in themeColours(
              theme,
            ).entries)
              if (!allowed.contains(rgb(c))) name: hex(rgb(c)),
          },
          isEmpty,
          reason:
              'with a ${phone.name} phone setting, these theme colours are '
              'not in §2.1, the quality or band colours or the neutrals',
        );
      }
    });

    testWidgets('the case is the background of Now and of the pushed pages', (
      t,
    ) async {
      await pumpGame(t);
      expectRgb(scaffoldFill(t, find.byType(HomeShell)), caseRgb, 'Now');
      for (final (page, open) in [
        ('Achievements', openAchievements),
        ('the Journal', openJournal),
        ('Settings', openSettings),
      ]) {
        await open(t);
        expectRgb(scaffoldFill(t, find.byType(Scaffold).first), caseRgb, page);
        await t.pageBack();
        await t.pumpAndSettle();
      }
    });

    testWidgets('a card on Now, a sheet, a dialog and a snack bar are plates', (
      t,
    ) async {
      final (c, _) = await pumpGame(t);
      expectPlate(t, _statusCard, 'the status card on Now');

      await openArea(t, 'camp');
      expectPlate(t, find.byType(BottomSheet), 'the sheet of Camp', top: true);
      await closeSheet(t);

      // Seven taps on the rank show the snack bar "Test walk on".
      await openTab(t, 'character');
      final rank = find.text(game.rank(game.level(c.state)).name);
      for (var i = 0; i < 7; i++) {
        await t.tap(rank);
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.pumpAndSettle();
      expectPlate(t, find.byType(SnackBar), 'the snack bar');

      await openSettings(t);
      await t.tap(find.byKey(const ValueKey('settings-name')));
      await t.pumpAndSettle();
      expectPlate(t, find.byType(Dialog), 'the name dialog');
    });

    testWidgets('the top bar and the bottom bar are plates', (t) async {
      await pumpGame(t);
      for (final (bar, name) in [
        (find.byType(AppBar), 'the top bar'),
        (find.byType(NavigationBar), 'the bottom bar'),
      ]) {
        final drawn = [
          ...drawnAbove(t.element(bar)),
          ...drawnUnder(t.element(bar)),
        ];
        expect(
          drawn.any(isPlate),
          isTrue,
          reason: '$name stands on no plate: ${describeAll(drawn)}',
        );
      }
    });

    testWidgets('slate buttons and chips, the lit tab, selected chips and the '
        'selected segment', (t) async {
      await pumpGame(t, location: 'goblin_woods');
      expectRgb(
        materialOf(t.element(buttonWith('Open the World map'))).color,
        slateRgb,
        'Open the World map',
      );

      final lit = find.byKey(const ValueKey('tab-now'));
      final drawn = drawnUnder(t.element(lit));
      expect(
        drawn.any((d) => sameRgb(d.fill, litRgb)),
        isTrue,
        reason: 'the lit tab Now: ${describeAll(drawn)}',
      );
      expectRgb(
        styleOf(t, 'Now', within: lit).color,
        tealRgb,
        'the label of the lit tab',
      );

      await openArea(t, 'goblin_woods');
      await t.tap(option('fight', 'goblin'));
      await t.pumpAndSettle();
      final chips = find.byType(ChoiceChip);
      expect(chips, findsWidgets);
      for (final e in chips.evaluate()) {
        final selected = (e.widget as ChoiceChip).selected;
        final name = 'the chip ${nameOf(e)}${selected ? ', selected' : ''}';
        expectRgb(chipFill(e), selected ? litRgb : slateRgb, name);
        if (selected) {
          final label = find.descendant(
            of: byElement(e),
            matching: find.byType(Text),
          );
          expectRgb(
            rootStyle(richIn(t, label)).color,
            tealRgb,
            '$name: its label',
          );
        }
      }
      await closeSheet(t);

      await openTab(t, 'character');
      final segments = find.descendant(
        of: find.byType(SegmentedButton<bool>),
        matching: _buttons,
      );
      for (final (label, selected) in [('Gear', true), ('Bag', false)]) {
        final segment = find.ancestor(of: find.text(label), matching: segments);
        expectRgb(
          materialOf(t.element(segment)).color,
          selected ? litRgb : slateRgb,
          'the segment $label',
        );
      }
    });

    testWidgets('teal main buttons and deep teal banners', (t) async {
      await walkAway(t, steps: 300, toReport: true);
      final banners = find.byType(ReportBanner);
      expect(banners, findsWidgets);
      for (final e in banners.evaluate()) {
        expectRgb(
          firstPaint(drawnUnder(e))?.fill,
          deepTealRgb,
          'the banner ${nameOf(e)}',
        );
      }
      expectTeal(t, buttonWith('Continue'), 'Continue');
    });

    testWidgets('steel bars, a mist step bank, a teal loading spinner and '
        'teal bars on unearned achievements', (t) async {
      await pumpGame(t);
      final bars = find
          .descendant(
            of: _statusCard,
            matching: find.byType(LinearProgressIndicator),
          )
          .evaluate()
          .toList();
      expect(bars, hasLength(2), reason: 'the XP bar and the step bank');
      expectRgb(barColour(bars[0]), steelRgb, 'the XP bar');
      expectRgb(barColour(bars[1]), mistRgb, 'the step bank bar');

      await openTab(t, 'professions');
      final mining = find.descendant(
        of: find.byKey(const ValueKey('profession-button-mining')),
        matching: find.byType(LinearProgressIndicator),
      );
      expectRgb(barColour(t.element(mining)), steelRgb, 'the Mining bar');

      await openAchievements(t);
      final unearned = find.descendant(
        of: find.ancestor(
          of: find.text(game.data.achievements.values.first.name),
          matching: find.byType(Card),
        ),
        matching: find.byType(LinearProgressIndicator),
      );
      expectRgb(
        barColour(t.element(unearned)),
        tealRgb,
        'the bar of an unearned achievement',
      );

      // A controller that has not started shows the loading screen.
      final source = FakeStepSource();
      final c = GameController(
        game: game,
        source: source,
        permissions: source,
        store: MemorySaveStore(),
        clock: () => now,
        syncInterval: null,
      );
      addTearDown(c.dispose);
      // A new tree, so that the pushed Achievements page goes.
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(WalkingRpgApp(controller: c));
      await t.pump();
      final loading = find.byWidgetPredicate((w) => w is ProgressIndicator);
      expect(loading, findsOneWidget);
      expectRgb(barColour(t.element(loading)), tealRgb, 'the loading spinner');
    });

    testWidgets('body text is #E3EAEC', (t) async {
      await pumpGame(t);
      for (final f in [
        find.byKey(const ValueKey('walked-today')),
        find.textContaining('Your steps go to the step bank.'),
      ]) {
        expectRgb(rootStyle(richIn(t, f)).color, textRgb, 'body text on Now');
      }
    });

    testWidgets('short inputs on a recipe row are #E08A7C, and the word '
        '"Risky" is #FBB15A', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      expect(
        game.enemyBand(c.state, 'goblin_brute').colour,
        LevelColour.orange,
        reason: 'the Goblin brute is Risky at level 1',
      );
      await openArea(t, 'goblin_woods');
      final risky = piecesWith(
        t,
        'Risky',
        within: option('fight', 'goblin_brute'),
      );
      expect(risky, isNotEmpty);
      for (final (text, style) in risky) {
        expectRgb(style.color, riskyRgb, '"$text" on the Goblin brute row');
        expect(
          text.replaceAll(RegExp('[^A-Za-z]'), ''),
          'Risky',
          reason: 'only the word "Risky" is #FBB15A',
        );
      }
      await closeSheet(t);

      await openProfession(t, 'crafting');
      final input = game.data.recipes['copper_sword']!.inputs.keys.first;
      final name = game.data.items[input]!.name;
      final short = piecesWith(
        t,
        '$name 0/',
        within: option('craft', 'copper_sword'),
      );
      expect(short, hasLength(1), reason: 'the input $name');
      expectRgb(short.single.$2.color, shortRgb, 'the short input $name');
    });
  });
}

void criterion3() {
  group('spec 0014 criterion 3: the four fonts and the Licences page', () {
    testWidgets('the text theme follows the role table', (t) async {
      await pumpGame(t);
      final text = Theme.of(t.element(find.byType(HomeShell))).textTheme;
      for (final (role, style, family, weight) in [
        ('displaySmall', text.displaySmall, cormorant, FontWeight.w600),
        ('headlineSmall', text.headlineSmall, cormorant, FontWeight.w600),
        ('titleLarge', text.titleLarge, cormorant, FontWeight.w600),
        ('titleMedium', text.titleMedium, cormorant, FontWeight.w600),
        ('titleSmall', text.titleSmall, cormorant, FontWeight.w600),
        ('bodyLarge', text.bodyLarge, alegreya, FontWeight.w400),
        ('bodyMedium', text.bodyMedium, alegreya, FontWeight.w400),
        ('bodySmall', text.bodySmall, alegreya, FontWeight.w400),
        ('labelLarge', text.labelLarge, alegreyaSc, FontWeight.w700),
        ('labelMedium', text.labelMedium, alegreya, FontWeight.w400),
        ('labelSmall', text.labelSmall, alegreyaSc, FontWeight.w700),
      ]) {
        expect(style?.fontFamily, family, reason: role);
        expect(style?.fontWeight ?? FontWeight.w400, weight, reason: role);
      }
    });

    testWidgets('a button label and a list heading are in Alegreya Sans SC '
        '700', (t) async {
      await pumpGame(t);
      for (final (name, style) in [
        (
          'the label of Open the World map',
          styleOf(
            t,
            'Open the World map',
            within: buttonWith('Open the World map'),
          ),
        ),
        (
          'the heading of Here on Now',
          rootStyle(richIn(t, find.byType(Heading).first)),
        ),
      ]) {
        expect(style.fontFamily, alegreyaSc, reason: name);
        expect(style.fontWeight, FontWeight.w700, reason: name);
      }
    });

    testWidgets('the tab labels of the bottom bar and of the Journal are in '
        'Alegreya Sans', (t) async {
      await pumpGame(t);
      for (final MapEntry(key: tab, value: label) in _tabs.entries) {
        expect(
          styleOf(
            t,
            label,
            within: find.byKey(ValueKey('tab-$tab')),
          ).fontFamily,
          alegreya,
          reason: 'the tab $label',
        );
      }
      await openJournal(t);
      for (final label in ['Log', 'Bestiary', 'Lore']) {
        expect(
          styleOf(t, label, within: find.byType(TabBar)).fontFamily,
          alegreya,
          reason: 'the tab $label',
        );
      }
    });

    testWidgets('a flavour line is in Alegreya Sans italic', (t) async {
      await pumpGame(t);
      final style = styleOf(t, game.data.locations['camp']!.flavour!);
      expect(style.fontFamily, alegreya);
      expect(style.fontStyle, FontStyle.italic);
    });

    // §2.2: "Cormorant Garamond for the wordmark, titles and names." The
    // name of a thing of the game is a name, also as the title of a row and
    // on the map. The places come from a new game at Camp, as pumpGame
    // makes it: each place out of the fog shows its name.
    final fresh = game.newGame(seed: 1);
    final hilde = game.data.professions['mining']!.teacher;
    for (final (where, open, names)
        in <
          (String, Future<void> Function(WidgetTester), List<(Finder?, String)>)
        >[
          (
            'a monster row and a gathering spot row on an area sheet',
            (t) => openArea(t, 'goblin_woods'),
            [
              (option('fight', 'goblin'), game.data.enemies['goblin']!.name),
              (option('gather', 'oak_tree'), game.data.nodes['oak_tree']!.name),
            ],
          ),
          (
            'a teacher row on Now',
            (t) async {},
            [
              (
                find.byKey(const ValueKey('teacher-mining')),
                '${hilde.name}, ${hilde.title}',
              ),
            ],
          ),
          (
            'a recipe row on a profession screen',
            (t) => openProfession(t, 'crafting'),
            [
              (
                option('craft', 'copper_sword'),
                game
                    .data
                    .items[game.data.recipes['copper_sword']!.output]!
                    .name,
              ),
            ],
          ),
          (
            'an achievement',
            openAchievements,
            [(null, game.data.achievements.values.first.name)],
          ),
          (
            'a Bestiary row',
            (t) async {
              await openJournal(t);
              await t.tap(find.text('Bestiary'));
              await t.pumpAndSettle();
            },
            [
              (
                find.byKey(const ValueKey('bestiary-goblin')),
                game.data.enemies['goblin']!.name,
              ),
            ],
          ),
          (
            'each place name on the World map, the current place included',
            (t) => openTab(t, 'world'),
            [
              for (final l in game.data.locations.values)
                if (!game.isHidden(fresh, l.id) && !game.isFogged(fresh, l.id))
                  (find.byKey(ValueKey('area-${l.id}')), l.name),
            ],
          ),
        ]) {
      testWidgets('a name is in Cormorant Garamond: $where', (t) async {
        await pumpGame(t);
        await open(t);
        for (final (within, name) in names) {
          expect(
            styleOf(t, name, within: within).fontFamily,
            cormorant,
            reason: '"$name" in $where',
          );
        }
      });
    }

    // A label row is no name: the rows of Settings stay body text, as the
    // design phone of Settings (31) shows.
    testWidgets('a label row is no name: the rows of Settings stay in '
        'Alegreya Sans', (t) async {
      await pumpGame(t);
      await openSettings(t);
      for (final label in ['Name', 'Gender', 'Show "Next goal"', 'Licences']) {
        expect(styleOf(t, label).fontFamily, alegreya, reason: label);
      }
    });

    testWidgets('the stat values of the Character header and the level '
        'numbers of the badges are in Spectral', (t) async {
      await pumpGame(t, location: 'goblin_woods');
      await openArea(t, 'goblin_woods');
      final badges = find.byType(LevelBadge);
      expect(badges, findsWidgets);
      for (final e in badges.evaluate()) {
        final rich = richIn(t, byElement(e));
        // The skull band shows no number.
        if (!rich.text.toPlainText().contains(RegExp(r'\d'))) continue;
        expectSpectralDigits(rich, 'the level badge ${nameOf(e)}');
      }
      await closeSheet(t);

      await openTab(t, 'character');
      for (final stat in [
        'Level',
        'HP',
        'Attack',
        'Defense',
        'Crit',
        'Hit',
        'Dodge',
        'Block',
      ]) {
        expectSpectralDigits(
          richIn(t, find.byKey(ValueKey('stat-$stat'))),
          'the value of $stat',
        );
      }
    });

    testWidgets('the digits of "Level N" on Now, on Professions and on '
        'level-up are in Spectral; the words keep their font', (t) async {
      bool level(String s) => RegExp(r'^Levels? \d+(–\d+)?!?$').hasMatch(s);
      await pumpGame(t);
      expectSpectralDigits(
        richWhere(t, level, within: find.byType(HomeShell)),
        '"Level N" on Now',
        rest: cormorant,
      );

      await openTab(t, 'professions');
      for (final p in game.data.professions.keys) {
        expectSpectralDigits(
          richWhere(
            t,
            level,
            within: find.byKey(ValueKey('profession-button-$p')),
          ),
          '"Level N" on the $p button',
          rest: cormorant,
        );
      }
      await openProfession(t, 'mining');
      expectSpectralDigits(
        richWhere(
          t,
          level,
          within: find.byKey(const ValueKey('profession-mining')),
        ),
        '"Level N" on the Mining screen',
        rest: cormorant,
      );

      await walkAway(t, steps: 5000);
      expectSpectralDigits(
        richWhere(t, level),
        'the title of the level-up card',
        rest: cormorant,
      );
    });

    testWidgets('the numbers of the XP and step bank bars are in Spectral', (
      t,
    ) async {
      await pumpGame(t);
      for (final words in ['XP ', 'Step bank ']) {
        expectSpectralDigits(
          richWhere(t, (s) => s.startsWith(words)),
          'the label of the bar "$words"',
        );
      }
    });

    testWidgets('the step counts on the map are in Spectral', (t) async {
      await pumpGame(t);
      await openTab(t, 'world');
      final map = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is MapPainter,
      );
      final painter = t.widget<CustomPaint>(map).painter! as MapPainter;
      // MapPainter paints the step counts on a canvas, so no widget holds
      // their style. The test reads MapPainter.stepStyle. A recording canvas
      // then shows that each count has the size of that style.
      final style = painter.stepStyle;
      expect(style.fontFamily, spectral);
      final canvas = TestRecordingCanvas();
      painter.paint(canvas, t.getSize(map));
      final drawn = [
        for (final call in canvas.invocations)
          if (call.invocation.memberName == #drawParagraph)
            call.invocation.positionalArguments.first as ui.Paragraph,
      ];
      final counts = [for (final p in painter.paths) ?p.$3];
      expect(drawn, hasLength(counts.length));
      for (final (i, count) in counts.indexed) {
        final expected = TextPainter(
          text: TextSpan(text: count, style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        addTearDown(expected.dispose);
        expect(
          (drawn[i].height, drawn[i].longestLine),
          (expected.height, expected.width),
          reason: count,
        );
      }
    });

    testWidgets('a number in a report line keeps the font of its sentence', (
      t,
    ) async {
      await walkAway(t, steps: 300, toReport: true);
      for (final (text, style) in piecesWith(t, 'You walked 300 steps.')) {
        expect(style.fontFamily, alegreya, reason: '"$text"');
      }
    });

    testWidgets('Settings has a Licences row, and a tap opens the Licences '
        'page', (t) async {
      await pumpGame(t);
      await openSettings(t);
      await t.tap(find.text('Licences'));
      // The page reads from the app bundle, which a widget test does not
      // wait for.
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(find.byType(LicencesScreen), findsOneWidget);
    });

    testWidgets('the Licences page shows the four fonts, each with its '
        'licence text', (t) async {
      await pumpGame(t);
      final bundle = await pushLicences(t);
      final entries = await readPage(t, find.byType(LicencesScreen));
      final at = {
        for (final family in licenceFiles.keys)
          family: entries.indexWhere((e) => e.$2.trim() == family),
      };
      for (final MapEntry(key: family, value: i) in at.entries) {
        expect(i, isNot(-1), reason: 'the name $family on its own');
      }
      final starts = at.values.toList()..sort();
      for (final MapEntry(key: family, value: file) in licenceFiles.entries) {
        final start = at[family]!;
        final end = starts.firstWhere(
          (s) => s > start,
          orElse: () => entries.length,
        );
        final section = squash(
          entries.sublist(start + 1, end).map((e) => e.$2).join('\n'),
        );
        for (final line in File('assets/fonts/$file').readAsLinesSync()) {
          if (line.trim().isEmpty) continue;
          expect(
            section.contains(squash(line)),
            isTrue,
            reason: 'under $family, the licence line "$line"',
          );
        }
        expect(
          bundle.keys,
          contains('assets/fonts/$file'),
          reason: 'the page reads $file from its bundle',
        );
      }
    });
  });
}

void criterion4() {
  group('spec 0014 criterion 4: the 2 dp black border', () {
    testWidgets('the button, segment, chip and switch themes resolve the '
        'border in each state', (t) async {
      await pumpGame(t);
      final theme = Theme.of(t.element(find.byType(HomeShell)));
      final styles = <String, ButtonStyle?>{
        'FilledButton': theme.filledButtonTheme.style,
        'OutlinedButton': theme.outlinedButtonTheme.style,
        'TextButton': theme.textButtonTheme.style,
        'IconButton': theme.iconButtonTheme.style,
        if (theme.elevatedButtonTheme.style != null)
          'ElevatedButton': theme.elevatedButtonTheme.style,
        'SegmentedButton': theme.segmentedButtonTheme.style,
      };
      for (final MapEntry(key: name, value: style) in styles.entries) {
        expectBlackInEachState(
          'the $name theme',
          (s) => style?.side?.resolve(s),
        );
      }
      expectBlackInEachState(
        'the chip theme',
        (s) => WidgetStateProperty.resolveAs(theme.chipTheme.side, s),
      );
      expectBlackInEachState(
        'the switch theme',
        (s) => switchSide(null, theme.switchTheme, s),
      );
    });

    testWidgets('Now, at rest and with a queue; a pressed button keeps its '
        'border', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await c.setTestWalk(true);
      await t.pump();
      expectBordersOnScreen(t, 'Now at rest');

      final open = buttonWith('Open the World map');
      final gesture = await t.startGesture(t.getCenter(open));
      await t.pump(const Duration(milliseconds: 200));
      expectBlackSide(
        sideOf(materialOf(t.element(open))),
        'Open the World map, pressed',
      );
      await gesture.cancel();
      await t.pump();

      await fightGoblin(c);
      await c.addAction(const Activity.fight('goblin_brute'));
      await settle(t, c);
      expectBordersOnScreen(t, 'Now with a queue');
    });

    testWidgets('the sheet of "Until I have N" and its item list', (t) async {
      await pumpGame(
        t,
        level: 5,
        location: 'goblin_woods',
        counters: {'kills.goblin': 3, 'found.goblin.goblin_hide': 1},
      );
      await openArea(t, 'goblin_woods');
      await t.tap(option('fight', 'goblin'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('stop-untilHave')));
      await t.pumpAndSettle();
      expectBordersOnScreen(t, 'the sheet of "Until I have N"');
      final list = find.byType(DropdownButton<String>);
      expect(list, findsOneWidget);
      expectBorderAroundEach(
        {'the item list of "Until I have N"': (t.element(list), [])},
        others: [...find.byType(RawChip).evaluate(), ..._buttons.evaluate()],
      );
    });

    testWidgets('the item cards and their dialogs', (t) async {
      final (c, _) = await pumpGame(
        t,
        inventory: {'bone_sword@rare+crit2+hp10': 1, 'grilled_perch': 1},
      );
      await openItem(t, 'bone_sword@rare+crit2+hp10');
      expectBordersOnScreen(t, 'the card of a rare sword');
      await t.tap(find.byKey(const ValueKey('card-salvage')));
      await t.pumpAndSettle();
      expect(find.text('Keep it'), findsOneWidget);
      expectBordersOnScreen(t, 'the salvage dialog');
      await t.tap(find.text('Keep it'));
      await t.pumpAndSettle();

      c.state.meal = ActiveMeal('venison_skewer', 1240);
      await openItem(t, 'grilled_perch');
      expectBordersOnScreen(t, 'the card of a meal');
      await t.tap(find.byKey(const ValueKey('card-eat')));
      await t.pumpAndSettle();
      expect(find.text('Not now'), findsOneWidget);
      expectBordersOnScreen(t, 'the meal dialog');
    });

    testWidgets('Professions, the six profession buttons and the screens of '
        'Crafting and Mining', (t) async {
      await pumpGame(t);
      await openTab(t, 'professions');
      expectBordersOnScreen(t, 'Professions');
      expectBorderAroundEach({
        for (final p in game.data.professions.values)
          'the profession button ${p.id}': labelled(
            t,
            find.byKey(ValueKey('profession-button-${p.id}')),
            [find.text(p.name)],
          ),
      });
      await openProfession(t, 'crafting');
      expectBordersOnScreen(t, 'the Crafting screen');
      await openProfession(t, 'mining');
      expectBordersOnScreen(t, 'the Mining screen');
    });

    testWidgets('Settings, the name dialog and the options of the gender '
        'dialog', (t) async {
      await pumpGame(t);
      await openSettings(t);
      expect(find.byType(Switch), findsWidgets);
      expectBordersOnScreen(t, 'Settings');
      await t.tap(find.byKey(const ValueKey('settings-name')));
      await t.pumpAndSettle();
      expectBordersOnScreen(t, 'the name dialog');
      await t.tap(find.text('Cancel'));
      await t.pumpAndSettle();

      await t.tap(find.byKey(const ValueKey('settings-gender')));
      await t.pumpAndSettle();
      final options = find.byType(SimpleDialogOption).evaluate().toList();
      expect(options, hasLength(Gender.values.length));
      expectBorderAroundEach({
        for (final option in options)
          'the gender option ${nameOf(option)}': labelled(
            t,
            byElement(option),
            [find.byType(Text)],
          ),
      });
    });

    testWidgets('"Who are you?" and the Character tab', (t) async {
      await pumpGame(t, character: null);
      expect(find.byType(SegmentedButton<Gender>), findsOneWidget);
      expectBordersOnScreen(t, '"Who are you?"');

      await pumpGame(t);
      await openTab(t, 'character');
      expect(find.byType(SegmentedButton<bool>), findsOneWidget);
      expectBordersOnScreen(t, 'Character');
    });

    testWidgets('level-up and the away screen', (t) async {
      await walkAway(t, steps: 5000);
      expectBordersOnScreen(t, 'the first level-up card');
      await t.tap(buttonWith('Next'));
      await t.pumpAndSettle();
      expectBordersOnScreen(t, 'the last level-up card');
      await t.tap(buttonWith('Continue'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('away-continue')), findsOneWidget);
      expectBordersOnScreen(t, 'the away screen');
    });

    testWidgets('the four tabs of the bottom bar, the lit one and the others', (
      t,
    ) async {
      await pumpGame(t);
      for (final lit in ['now', 'world']) {
        await openTab(t, lit);
        expectBorderAroundEach({
          for (final MapEntry(key: id, value: label) in _tabs.entries)
            'the tab $label with ${_tabs[lit]} lit': labelled(
              t,
              find.byKey(ValueKey('tab-$id')),
              [find.text(label), find.byType(Icon)],
            ),
        });
      }
    });

    testWidgets('the three tabs of the Journal', (t) async {
      await pumpGame(t);
      await openJournal(t);
      expectBordersOnScreen(t, 'the Journal');
      expectBorderAroundEach({
        for (final label in ['Log', 'Bestiary', 'Lore'])
          'the Journal tab $label': (
            t.element(
              find.descendant(
                of: find.byType(TabBar),
                matching: find.text(label),
              ),
            ),
            [],
          ),
      });
    });
  });
}

// Each button that the plan's table names has a colour check below. These
// slate buttons have none, because each needs a set-up of its own:
// - Keep new and Keep old: a Legendary with a new stat roll that waits for
//   a choice, which takes a reroll at a forge first.
// - Reroll on one stat: a Legendary at a forge.
// - Unequip, Use, "Swap with <item>" and the buttons of the slot sheet.
// - Go there on Cooking: a camp fire away from the player.
// - The Keep buttons of Auto-eat and the count buttons of the action sheet.
// The tests of criterion 4 check the border of each button on their screens,
// and the count buttons are on one of them.
void criterion5() {
  group('spec 0014 criterion 5: teal, ghost and slate buttons, with '
      "today's words", () {
    testWidgets('teal: Allow step access, Try again and Set out', (t) async {
      final (c, source) = await pumpGame(t, granted: false);
      expectTeal(t, buttonWith('Allow step access'), 'Allow step access');
      source.available = false;
      await c.start();
      await t.pump();
      expectTeal(t, buttonWith('Try again'), 'Try again');

      await pumpGame(t, character: null);
      await t.tap(find.byKey(const ValueKey('origin-coast_fisher')));
      await t.pump();
      expectTeal(t, buttonWith('Set out'), 'Set out');
    });

    // On main the button reads "Start" while nothing runs and "Start now"
    // while something runs (action_sheet.dart).
    testWidgets('teal: Start, Start now and Add to queue', (t) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await openArea(t, 'goblin_woods');
      await t.tap(option('fight', 'goblin'));
      await t.pumpAndSettle();
      expectTeal(t, buttonWith('Start'), 'Start');
      await closeSheet(t);

      await fightGoblin(c);
      await settle(t, c);
      await openArea(t, 'goblin_woods');
      await t.tap(option('fight', 'goblin_brute'));
      await t.pumpAndSettle();
      expectTeal(t, buttonWith('Start now'), 'Start now');
      expectTeal(t, buttonWith('Add to queue'), 'Add to queue');
    });

    testWidgets('teal: each Learn button', (t) async {
      await pumpGame(t, learned: false);
      for (final p in game.data.professions.values) {
        await t.tap(find.byKey(ValueKey('teacher-${p.id}')));
        await t.pumpAndSettle();
        expectTeal(t, buttonWith('Learn ${p.name}'), 'Learn ${p.name}');
        await closeSheet(t);
      }
    });

    testWidgets('teal: Save; ghost: Cancel; slate: Back, on Settings', (
      t,
    ) async {
      await pumpGame(t);
      await openSettings(t);
      expectSlate(t, buttonIn(find.byType(BackButton)), 'Back');
      await t.tap(find.byKey(const ValueKey('settings-name')));
      await t.pumpAndSettle();
      expectTeal(t, buttonWith('Save'), 'Save');
      expectGhost(t, buttonWith('Cancel'), 'Cancel in the name dialog');
    });

    testWidgets('teal: Next and both Continue buttons; ghost: Skip all', (
      t,
    ) async {
      await walkAway(t, steps: 5000);
      expectGhost(t, buttonWith('Skip all'), 'Skip all');
      expectTeal(t, buttonWith('Next'), 'Next');
      await t.tap(buttonWith('Next'));
      await t.pumpAndSettle();
      expectTeal(t, buttonWith('Continue'), 'Continue on level-up');
      await t.tap(buttonWith('Continue'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('away-continue')), findsOneWidget);
      expectTeal(t, buttonWith('Continue'), 'Continue on the away screen');
    });

    testWidgets('ghost: Cancel; slate: Fight anyway, in the deadly dialog', (
      t,
    ) async {
      await pumpGame(t, location: 'goblin_woods');
      await openArea(t, 'goblin_woods');
      await t.tap(option('fight', 'old_bear'));
      await t.pumpAndSettle();
      final dialog = find.byType(Dialog);
      expectGhost(
        t,
        buttonWith('Cancel', within: dialog),
        'Cancel in the deadly dialog',
      );
      expectSlate(
        t,
        buttonWith('Fight anyway', within: dialog),
        'Fight anyway',
      );
    });

    testWidgets('ghost: Not now; slate: Eat, on the meal card and in its '
        'dialog', (t) async {
      final (c, _) = await pumpGame(t, inventory: {'grilled_perch': 1});
      c.state.meal = ActiveMeal('venison_skewer', 1240);
      await openItem(t, 'grilled_perch');
      expectSlate(t, buttonWith('Eat'), 'Eat on the meal card');
      await t.tap(find.byKey(const ValueKey('card-eat')));
      await t.pumpAndSettle();
      final dialog = find.byType(Dialog);
      expectGhost(t, buttonWith('Not now', within: dialog), 'Not now');
      expectSlate(t, buttonWith('Eat', within: dialog), 'Eat in the dialog');
    });

    testWidgets('ghost: Keep it; slate: Equip, Reroll and Salvage on the '
        'gear card, and Salvage in its dialog', (t) async {
      const sword = 'bone_sword@rare+crit2+hp10';
      await pumpGame(t, inventory: {sword: 1});
      await openItem(t, sword);
      expectSlate(t, buttonWith('Equip'), 'Equip');
      expectSlate(
        t,
        buttonIn(find.byKey(const ValueKey('card-reroll'))),
        'Reroll',
      );
      expectSlate(t, buttonWith('Salvage'), 'Salvage on the card');
      await t.tap(find.byKey(const ValueKey('card-salvage')));
      await t.pumpAndSettle();
      final dialog = find.byType(Dialog);
      expectGhost(t, buttonWith('Keep it', within: dialog), 'Keep it');
      expectSlate(
        t,
        buttonWith('Salvage', within: dialog),
        'Salvage in the dialog',
      );
    });

    testWidgets('slate: Swap on a gear card and on a tool card', (t) async {
      final slot = game.slotsFor('bone_sword').single;
      await pumpGame(
        t,
        equipment: {slot: 'copper_sword'},
        inventory: {'bone_sword': 1, 'copper_pickaxe@rare': 1},
      );
      await openItem(t, 'bone_sword');
      expectSlate(t, buttonWith('Swap'), 'Swap on the gear card');
      await closeSheet(t);
      await openItem(t, 'copper_pickaxe@rare');
      expectSlate(t, buttonWith('Swap'), 'Swap on the tool card');
    });

    testWidgets('slate: Hide, OK, Open the World map, the test walk buttons '
        'and the top bar on Now', (t) async {
      final (c, _) = await pumpGame(t);
      await c.setTestWalk(true);
      await t.pump();
      for (final words in [
        'Hide',
        'OK',
        'Open the World map',
        '+100',
        '+1,000',
        '+5,000',
      ]) {
        expectSlate(t, buttonWith(words), words);
      }
      for (final key in _topBar) {
        expectSlate(t, buttonIn(find.byKey(ValueKey(key))), key);
      }
    });

    testWidgets('slate: Stop and Remove on Now while an action runs', (
      t,
    ) async {
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      await fightGoblin(c);
      await settle(t, c);
      expectSlate(t, buttonWith('Stop'), 'Stop');
      await c.addAction(const Activity.fight('goblin_brute'));
      await settle(t, c);
      expectSlate(
        t,
        buttonIn(find.byKey(const ValueKey('remove-1'))),
        'Remove',
      );
    });

    testWidgets('slate: the six profession buttons and Go there', (t) async {
      await pumpGame(t);
      await openTab(t, 'professions');
      for (final p in game.data.professions.values) {
        final button = find.byKey(ValueKey('profession-button-${p.id}'));
        final outer = firstPaint(drawnUnder(t.element(button)));
        expectRgb(
          outer?.fill ?? outer?.gradient,
          slateRgb,
          'the profession button ${p.name}',
        );
        expectRgb(
          styleOf(t, p.name, within: button).color,
          textRgb,
          'the label of the profession button ${p.name}',
        );
      }
      await openProfession(t, 'mining');
      expectSlate(t, buttonWith('Go there'), 'Go there');
    });

    // §2.2: "A pressed button sinks. A focused button gets a teal ring." The
    // slate button is on Now, and the teal one on the sheet of a fight.
    for (final (what, expectLook) in [
      (
        'a pressed teal or slate button sinks: no drop shadow, and its label '
            '1 dp lower',
        expectSinks,
      ),
      (
        'a focused teal or slate button gets a teal ring outside its border',
        expectRing,
      ),
    ]) {
      testWidgets(what, (t) async {
        await pumpGame(t, location: 'goblin_woods');
        await expectLook(t, 'Open the World map');
        await openArea(t, 'goblin_woods');
        await t.tap(option('fight', 'goblin'));
        await t.pumpAndSettle();
        await expectLook(t, 'Start');
      });
    }
  });
}

void criterion6() {
  group('spec 0014 criterion 6: each pushed page shows one Back button', () {
    for (final (page, title, open)
        in <(String, String?, Future<void> Function(WidgetTester))>[
          ('Achievements', 'Achievements', openAchievements),
          ('the Journal', "Ada's journal", openJournal),
          ('Settings', 'Settings', openSettings),
          ('the Mining screen', 'Mining', (t) => openProfession(t, 'mining')),
          // The spec names the row "Licences", not the title of the page.
          ('the Licences page', null, pushLicences),
        ]) {
      testWidgets('$page shows Back with the tooltip "Back", no other '
          'button, and its title', (t) async {
        await pumpGame(t);
        await open(t);
        final bar = find.byType(AppBar);
        expect(bar, findsOneWidget, reason: page);
        Finder inBar(Finder f) => find.descendant(of: bar, matching: f);
        expect(inBar(find.byType(BackButton)), findsOneWidget);
        expect(inBar(find.byTooltip('Back')), findsOneWidget);
        expect(
          inBar(_buttons),
          findsOneWidget,
          reason: 'Back is the only button in the top bar of $page',
        );
        if (title == null) {
          expect(t.widget<AppBar>(bar).title, isNotNull, reason: page);
        } else {
          expect(
            inBar(find.text(title)),
            findsOneWidget,
            reason: 'the title of $page',
          );
        }
      });
    }
  });
}

void criterion7() {
  group('spec 0014 criterion 7: the bottom bar and the top bar', () {
    testWidgets('the bottom bar is a NavigationBar with Now, World, '
        'Professions and Character', (t) async {
      await pumpGame(t);
      final bar = t.widget<NavigationBar>(find.byType(NavigationBar));
      expect([
        for (final d in bar.destinations) (d as NavigationDestination).label,
      ], _tabs.values);
      expect(
        [for (final d in bar.destinations) d.key],
        [for (final id in _tabs.keys) ValueKey('tab-$id')],
      );
    });

    testWidgets('each tab screen has Trophies with its dot, Journal and '
        'Settings in its top bar, and no title', (t) async {
      await pumpGame(t);
      for (final tab in _tabs.keys) {
        await openTab(t, tab);
        final bar = find.byType(AppBar);
        expect(bar, findsOneWidget, reason: tab);
        Finder inBar(String key) =>
            find.descendant(of: bar, matching: find.byKey(ValueKey(key)));
        for (final key in _topBar) {
          expect(inBar(key), findsOneWidget, reason: '$key on $tab');
          expect(t.widget(inBar(key)), isA<IconButton>(), reason: key);
        }
        final dot = find.descendant(
          of: inBar('achievements-button'),
          matching: find.byKey(const ValueKey('achievements-dot')),
        );
        expect(dot, findsOneWidget, reason: 'the dot on Trophies on $tab');
        expect(t.widget(dot), isA<Badge>());
        final x = [for (final key in _topBar) t.getCenter(inBar(key)).dx];
        expect(x[0] < x[1] && x[1] < x[2], isTrue, reason: 'the order on $tab');
        expect(
          find.descendant(of: bar, matching: find.byType(Text)),
          findsNothing,
          reason: 'the top bar of $tab has no title',
        );
      }
    });

    testWidgets('with an unseen achievement, the dot shows on each tab '
        'screen', (t) async {
      final (c, _) = await pumpGame(t);
      c.state.achievements.add(game.data.achievements.keys.first);
      for (final tab in _tabs.keys) {
        await openTab(t, tab);
        expect(
          t
              .widget<Badge>(find.byKey(const ValueKey('achievements-dot')))
              .isLabelVisible,
          isTrue,
          reason: 'the dot on $tab',
        );
      }
    });
  });
}

// Screens.

/// Sets the light or dark mode of the phone for one test.
void setPhone(WidgetTester t, Brightness phone) {
  t.platformDispatcher.platformBrightnessTestValue = phone;
  addTearDown(t.platformDispatcher.clearPlatformBrightnessTestValue);
}

/// Fights the Goblin for [steps] while the app is away, so that the app
/// opens on level-up cards, then on the away report. With [toReport], the
/// test skips the cards.
Future<GameController> walkAway(
  WidgetTester t, {
  required int steps,
  bool toReport = false,
}) async {
  // A new tree: pumpGame keeps the app's state, and with it each pushed
  // page, which would hide the level-up cards.
  await t.pumpWidget(const SizedBox());
  final (c, source) = await pumpGame(t, location: 'goblin_woods');
  await c.startActivity(const Activity.fight('goblin'));
  source.walk(DateTime(2026, 10, 18, 10), steps);
  now = DateTime(2026, 10, 18, 11);
  await c.resume();
  await t.pump();
  if (toReport && c.levelCards.isNotEmpty) {
    c.dismissLevelCards();
    await t.pump();
  }
  return c;
}

/// Fights the Goblin until it is grey. An action that never stops (the
/// default) lets no other action wait after it.
Future<void> fightGoblin(GameController c) => c.startActivity(
  const Activity.fight('goblin'),
  stop: const StopCondition.untilGrey(),
);

Future<void> openJournal(WidgetTester t) async {
  await t.tap(find.byKey(const ValueKey('journal-button')));
  await t.pumpAndSettle();
}

/// Opens the card of [key] from the bag.
Future<void> openItem(WidgetTester t, String key) async {
  await openTab(t, 'character');
  await t.tap(find.byKey(const ValueKey('tab-bag')));
  await t.pumpAndSettle();
  await t.tap(find.byKey(ValueKey('bag-$key')));
  await t.pumpAndSettle();
}

/// Opens the Licences page over Now, with a bundle that reads from disk.
Future<DiskBundle> pushLicences(WidgetTester t) async {
  final bundle = DiskBundle();
  Navigator.of(t.element(find.byType(HomeShell))).push(
    MaterialPageRoute<void>(builder: (_) => LicencesScreen(bundle: bundle)),
  );
  await t.pumpAndSettle();
  return bundle;
}

/// Reads assets from app/ on disk with synchronous reads, so that no real
/// I/O runs in the fake-async zone of a widget test (CLAUDE.md). It keeps
/// each key that it reads.
class DiskBundle extends CachingAssetBundle {
  final keys = <String>[];

  File _file(String key) {
    keys.add(key);
    final file = File(key);
    if (!file.existsSync()) throw FlutterError('Unable to load asset: $key');
    return file;
  }

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(_file(key).readAsBytesSync());

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      _file(key).readAsStringSync();
}

/// Each text of [page] with its distance from the top of the page, top
/// first. The page scrolls to its end, so that a lazy list builds each row.
Future<List<(double, String)>> readPage(WidgetTester t, Finder page) async {
  final texts = <String, (double, String)>{};
  final scrollables = find.descendant(
    of: page,
    matching: find.byType(Scrollable),
  );
  final position = scrollables.evaluate().isEmpty
      ? null
      : t.state<ScrollableState>(scrollables.first).position;
  while (true) {
    final scrolled = position?.pixels ?? 0;
    final shown = find.descendant(
      of: page,
      matching: find.byWidgetPredicate(
        (w) => w is RichText || w is EditableText,
      ),
    );
    for (final e in shown.evaluate()) {
      final text = switch (e.widget) {
        RichText(:final text) => text.toPlainText(),
        EditableText(:final controller) => controller.text,
        _ => '',
      };
      final box = e.renderObject! as RenderBox;
      final y = box.localToGlobal(Offset.zero).dy + scrolled;
      texts['${y.round()} $text'] = (y, text);
    }
    if (position == null || position.pixels >= position.maxScrollExtent) break;
    position.jumpTo(
      math.min(
        position.pixels + position.viewportDimension / 2,
        position.maxScrollExtent,
      ),
    );
    await t.pump();
  }
  return texts.values.toList()..sort((a, b) => a.$1.compareTo(b.$1));
}

String squash(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();

// Colours.

/// Expects [c] to have the RGB [expected], at any alpha above 0.
void expectRgb(Color? c, int expected, String what) {
  expect(c, isNotNull, reason: '$what has no colour');
  expect(hex(rgb(c!)), hex(expected), reason: what);
  expect(c.a, greaterThan(0), reason: '$what is invisible');
}

bool sameRgb(Color? c, int expected) =>
    c != null && c.a > 0 && rgb(c) == expected;

/// Each colour field of [theme] that a widget can paint: the colour
/// scheme, the colours of ThemeData that are not deprecated, and the text
/// colours of the text theme.
Map<String, Color> themeColours(ThemeData theme) {
  final s = theme.colorScheme;
  final text = theme.textTheme;
  return {
    'colorScheme.primary': s.primary,
    'colorScheme.onPrimary': s.onPrimary,
    'colorScheme.primaryContainer': s.primaryContainer,
    'colorScheme.onPrimaryContainer': s.onPrimaryContainer,
    'colorScheme.primaryFixed': s.primaryFixed,
    'colorScheme.primaryFixedDim': s.primaryFixedDim,
    'colorScheme.onPrimaryFixed': s.onPrimaryFixed,
    'colorScheme.onPrimaryFixedVariant': s.onPrimaryFixedVariant,
    'colorScheme.secondary': s.secondary,
    'colorScheme.onSecondary': s.onSecondary,
    'colorScheme.secondaryContainer': s.secondaryContainer,
    'colorScheme.onSecondaryContainer': s.onSecondaryContainer,
    'colorScheme.secondaryFixed': s.secondaryFixed,
    'colorScheme.secondaryFixedDim': s.secondaryFixedDim,
    'colorScheme.onSecondaryFixed': s.onSecondaryFixed,
    'colorScheme.onSecondaryFixedVariant': s.onSecondaryFixedVariant,
    'colorScheme.tertiary': s.tertiary,
    'colorScheme.onTertiary': s.onTertiary,
    'colorScheme.tertiaryContainer': s.tertiaryContainer,
    'colorScheme.onTertiaryContainer': s.onTertiaryContainer,
    'colorScheme.tertiaryFixed': s.tertiaryFixed,
    'colorScheme.tertiaryFixedDim': s.tertiaryFixedDim,
    'colorScheme.onTertiaryFixed': s.onTertiaryFixed,
    'colorScheme.onTertiaryFixedVariant': s.onTertiaryFixedVariant,
    'colorScheme.error': s.error,
    'colorScheme.onError': s.onError,
    'colorScheme.errorContainer': s.errorContainer,
    'colorScheme.onErrorContainer': s.onErrorContainer,
    'colorScheme.surface': s.surface,
    'colorScheme.onSurface': s.onSurface,
    'colorScheme.surfaceDim': s.surfaceDim,
    'colorScheme.surfaceBright': s.surfaceBright,
    'colorScheme.surfaceContainerLowest': s.surfaceContainerLowest,
    'colorScheme.surfaceContainerLow': s.surfaceContainerLow,
    'colorScheme.surfaceContainer': s.surfaceContainer,
    'colorScheme.surfaceContainerHigh': s.surfaceContainerHigh,
    'colorScheme.surfaceContainerHighest': s.surfaceContainerHighest,
    'colorScheme.onSurfaceVariant': s.onSurfaceVariant,
    'colorScheme.outline': s.outline,
    'colorScheme.outlineVariant': s.outlineVariant,
    'colorScheme.shadow': s.shadow,
    'colorScheme.scrim': s.scrim,
    'colorScheme.inverseSurface': s.inverseSurface,
    'colorScheme.onInverseSurface': s.onInverseSurface,
    'colorScheme.inversePrimary': s.inversePrimary,
    'colorScheme.surfaceTint': s.surfaceTint,
    'canvasColor': theme.canvasColor,
    'cardColor': theme.cardColor,
    'disabledColor': theme.disabledColor,
    'dividerColor': theme.dividerColor,
    'focusColor': theme.focusColor,
    'highlightColor': theme.highlightColor,
    'hintColor': theme.hintColor,
    'hoverColor': theme.hoverColor,
    'primaryColor': theme.primaryColor,
    'primaryColorDark': theme.primaryColorDark,
    'primaryColorLight': theme.primaryColorLight,
    'scaffoldBackgroundColor': theme.scaffoldBackgroundColor,
    'secondaryHeaderColor': theme.secondaryHeaderColor,
    'shadowColor': theme.shadowColor,
    'splashColor': theme.splashColor,
    'unselectedWidgetColor': theme.unselectedWidgetColor,
    for (final (role, style) in [
      ('displayLarge', text.displayLarge),
      ('displayMedium', text.displayMedium),
      ('displaySmall', text.displaySmall),
      ('headlineLarge', text.headlineLarge),
      ('headlineMedium', text.headlineMedium),
      ('headlineSmall', text.headlineSmall),
      ('titleLarge', text.titleLarge),
      ('titleMedium', text.titleMedium),
      ('titleSmall', text.titleSmall),
      ('bodyLarge', text.bodyLarge),
      ('bodyMedium', text.bodyMedium),
      ('bodySmall', text.bodySmall),
      ('labelLarge', text.labelLarge),
      ('labelMedium', text.labelMedium),
      ('labelSmall', text.labelSmall),
    ])
      'textTheme.$role.color': ?style?.color,
  };
}

/// The colour that [indicator] paints its value in, as a progress indicator
/// resolves it.
Color barColour(Element indicator) {
  final w = indicator.widget as ProgressIndicator;
  return w.valueColor?.value ??
      w.color ??
      ProgressIndicatorTheme.of(indicator).color ??
      Theme.of(indicator).colorScheme.primary;
}

/// The fill of a chip: the decoration of the Ink that RawChip draws.
Color? chipFill(Element chip) {
  for (final e in withRoot(chip)) {
    if (e.widget case Ink(decoration: final ShapeDecoration d)) return d.color;
    if (e.widget case Ink(decoration: final BoxDecoration d)) return d.color;
  }
  return null;
}

// What widgets paint.

/// What one widget paints: its fill, the first colour of its gradient, the
/// radius of its corners and the sides of its border.
class Drawn {
  Drawn(
    this.what, {
    this.fill,
    this.gradient,
    this.radius,
    this.sides = const [],
  });

  final String what;
  final Color? fill;
  final Color? gradient;
  final BorderRadius? radius;
  final List<BorderSide> sides;

  bool get paints =>
      (fill?.a ?? 0) > 0 ||
      (gradient?.a ?? 0) > 0 ||
      sides.any((s) => s.style != BorderStyle.none && s.width > 0);

  @override
  String toString() =>
      '$what(fill: ${fill == null ? null : hex(rgb(fill!))}, '
      'gradient: ${gradient == null ? null : hex(rgb(gradient!))}, '
      'radius: $radius, sides: '
      '${[for (final s in sides) '${s.width} ${hex(rgb(s.color))}']})';
}

Finder byElement(Element e) => find.byElementPredicate((x) => x == e);

/// [e] and each onstage element below it, depth first.
Iterable<Element> withRoot(Element e) => [
  e,
  ...collectAllElementsFrom(e, skipOffstage: true),
];

/// What [e]'s own widget paints, or null when it paints nothing of note.
Drawn? drawnBy(Element e) {
  final w = e.widget;
  if (w is Material) {
    if (w.type == MaterialType.transparency) return null;
    final theme = Theme.of(e);
    final base =
        w.color ??
        switch (w.type) {
          MaterialType.canvas => theme.canvasColor,
          MaterialType.card => theme.cardColor,
          _ => null,
        };
    final (radius, sides) = _shape(w.shape);
    return Drawn(
      'Material',
      fill: base == null
          ? null
          : ElevationOverlay.applySurfaceTint(
              base,
              w.surfaceTintColor,
              w.elevation,
            ),
      radius: radius ?? w.borderRadius?.resolve(TextDirection.ltr),
      sides: sides,
    );
  }
  final decoration = switch (w) {
    DecoratedBox(:final decoration) => decoration,
    Ink(:final decoration?) => decoration,
    _ => null,
  };
  if (decoration is BoxDecoration) {
    return Drawn(
      w.runtimeType.toString(),
      fill: decoration.color,
      gradient: decoration.gradient?.colors.first,
      radius: decoration.shape == BoxShape.circle
          ? null
          : decoration.borderRadius?.resolve(TextDirection.ltr) ??
                BorderRadius.zero,
      sides: switch (decoration.border) {
        Border(:final top, :final right, :final bottom, :final left) => [
          top,
          right,
          bottom,
          left,
        ],
        BorderDirectional(
          :final top,
          :final end,
          :final bottom,
          :final start,
        ) =>
          [top, end, bottom, start],
        _ => const [],
      },
    );
  }
  if (decoration is ShapeDecoration) {
    final (radius, sides) = _shape(decoration.shape);
    return Drawn(
      w.runtimeType.toString(),
      fill: decoration.color,
      gradient: decoration.gradient?.colors.first,
      radius: radius,
      sides: sides,
    );
  }
  if (w is InputDecorator) {
    final border = w.decoration.enabledBorder ?? w.decoration.border;
    if (border is OutlineInputBorder) {
      return Drawn(
        'InputDecorator',
        radius: border.borderRadius,
        sides: [border.borderSide],
      );
    }
  }
  return null;
}

(BorderRadius?, List<BorderSide>) _shape(ShapeBorder? shape) => switch (shape) {
  RoundedRectangleBorder(:final borderRadius, :final side) ||
  RoundedSuperellipseBorder(
    :final borderRadius,
    :final side,
  ) => (borderRadius.resolve(TextDirection.ltr), [side]),
  OutlinedBorder(:final side) => (null, [side]),
  Border(:final top, :final right, :final bottom, :final left) => (
    null,
    [top, right, bottom, left],
  ),
  _ => (null, const <BorderSide>[]),
};

/// What [e] and the widgets below it paint, the outermost first.
List<Drawn> drawnUnder(Element e) => [for (final x in withRoot(e)) ?drawnBy(x)];

/// What the widgets above [e] paint, up to its Scaffold, the closest first.
List<Drawn> drawnAbove(Element e) {
  final out = <Drawn>[];
  e.visitAncestorElements((a) {
    if (a.widget is Scaffold) return false;
    if (drawnBy(a) case final d?) out.add(d);
    return true;
  });
  return out;
}

Drawn? firstPaint(List<Drawn> drawn) =>
    drawn.where((d) => d.paints).firstOrNull;

String describeAll(List<Drawn> drawn) =>
    drawn.where((d) => d.paints).take(8).join('; ');

/// Whether [d] is a plate: the plate colour, radius 16 and a 1 dp teal
/// hairline. With [top], the bottom corners may be square (a sheet on the
/// bottom edge).
bool isPlate(Drawn d, {bool top = false}) {
  const r = Radius.circular(16);
  final corners = d.radius;
  return sameRgb(d.fill ?? d.gradient, plateRgb) &&
      corners != null &&
      corners.topLeft == r &&
      corners.topRight == r &&
      (top || (corners.bottomLeft == r && corners.bottomRight == r)) &&
      d.sides.isNotEmpty &&
      d.sides.every(
        (s) =>
            s.style == BorderStyle.solid &&
            s.width == 1 &&
            sameRgb(s.color, tealRgb),
      );
}

/// Expects the outermost paint of [finder] to be a plate.
void expectPlate(
  WidgetTester t,
  Finder finder,
  String what, {
  bool top = false,
}) {
  expect(finder, findsOneWidget, reason: what);
  final drawn = drawnUnder(t.element(finder));
  final outer = firstPaint(drawn);
  expect(
    outer != null && isPlate(outer, top: top),
    isTrue,
    reason: '$what is no plate: ${describeAll(drawn)}',
  );
}

bool isBlackBorder(Drawn d) =>
    d.sides.isNotEmpty && d.sides.every((s) => _blackSide(s) == null);

/// Why [side] is not the 2 dp black border, or null when it is.
String? _blackSide(BorderSide? side) {
  if (side == null) return 'no border';
  if (side.style != BorderStyle.solid) return 'the style ${side.style}';
  if (side.width != 2) return 'the width ${side.width}';
  if (rgb(side.color) != 0) return 'the colour ${hex(rgb(side.color))}';
  if (side.color.a == 0) return 'an invisible border';
  return null;
}

void expectBlackSide(BorderSide? side, String what) =>
    expect(_blackSide(side), isNull, reason: what);

/// Expects [sideIn] to give the 2 dp black border in each state.
void expectBlackInEachState(
  String what,
  BorderSide? Function(Set<WidgetState>) sideIn,
) {
  for (final MapEntry(key: state, value: s) in _states.entries) {
    expectBlackSide(sideIn(s), '$what, $state');
  }
}

BorderSide? sideOf(Material m) => switch (m.shape) {
  OutlinedBorder(:final side) => side,
  _ => null,
};

/// The element that draws a 2 dp black border around [item]: a widget in
/// it that holds each of [holds], or a widget above it with none of
/// [others] inside.
Element? borderAround(
  Element item, {
  List<Element> holds = const [],
  Iterable<Element> others = const [],
}) {
  Set<Element> up(Element e) {
    final s = {e};
    e.visitAncestorElements((a) => s.add(a) || true);
    return s;
  }

  final held = [for (final h in holds) up(h)];
  for (final e in withRoot(item)) {
    final d = drawnBy(e);
    if (d != null && isBlackBorder(d) && held.every((h) => h.contains(e))) {
      return e;
    }
  }
  final blocked = {for (final o in others) ...up(o)};
  Element? found;
  item.visitAncestorElements((a) {
    if (blocked.contains(a)) return false;
    if (drawnBy(a) case final d? when isBlackBorder(d)) {
      found = a;
      return false;
    }
    return true;
  });
  return found;
}

/// [item] with the first match of each of [labels] inside it.
(Element, List<Element>) labelled(
  WidgetTester t,
  Finder item,
  List<Finder> labels,
) => (
  t.element(item),
  [
    for (final l in labels)
      t.element(find.descendant(of: item, matching: l).first),
  ],
);

/// Expects a 2 dp black border around each of [items], by name: a border
/// that holds the labels of the item, and no other item and none of
/// [others].
void expectBorderAroundEach(
  Map<String, (Element, List<Element>)> items, {
  List<Element> others = const [],
}) {
  for (final MapEntry(key: name, value: (item, holds)) in items.entries) {
    expect(
      borderAround(
        item,
        holds: holds,
        others: [
          ...others,
          for (final (o, _) in items.values)
            if (o != item) o,
        ],
      ),
      isNotNull,
      reason: name,
    );
  }
}

BorderSide? switchSide(Switch? sw, SwitchThemeData theme, Set<WidgetState> s) {
  final colour =
      sw?.trackOutlineColor?.resolve(s) ?? theme.trackOutlineColor?.resolve(s);
  final width =
      sw?.trackOutlineWidth?.resolve(s) ?? theme.trackOutlineWidth?.resolve(s);
  return colour == null || width == null
      ? null
      : BorderSide(color: colour, width: width);
}

/// Expects the 2 dp black border on each button, chip, segment and switch
/// that the screen shows: as drawn now, and as resolved for each state.
void expectBordersOnScreen(WidgetTester t, String where) {
  final segmented = find.byWidgetPredicate((w) => w is SegmentedButton);
  // SegmentedButton draws the border of its segments itself.
  final inSegments = find
      .descendant(of: segmented, matching: _buttons)
      .evaluate()
      .toSet();
  var buttons = 0;
  for (final e in _buttons.evaluate()) {
    if (inSegments.contains(e)) continue;
    buttons++;
    final style = (e.widget as ButtonStyleButton).style;
    final theme = _themeStyle(e);
    final name = '$where, ${nameOf(e)}';
    expectBlackSide(sideOf(materialOf(e)), '$name as drawn');
    expectBlackInEachState(
      name,
      (s) => style?.side?.resolve(s) ?? theme?.side?.resolve(s),
    );
  }
  expect(buttons, greaterThan(0), reason: '$where shows no button');

  for (final e in find.byType(RawChip).evaluate()) {
    final chip = e.widget as RawChip;
    final name = '$where, the chip ${nameOf(e)}';
    expect(
      drawnUnder(e).any(isBlackBorder),
      isTrue,
      reason: '$name as drawn: ${describeAll(drawnUnder(e))}',
    );
    expectBlackInEachState(
      name,
      (s) =>
          WidgetStateProperty.resolveAs(chip.side, s) ??
          WidgetStateProperty.resolveAs(ChipTheme.of(e).side, s),
    );
  }
  for (final e in segmented.evaluate()) {
    final style = (e.widget as SegmentedButton).style;
    final theme = SegmentedButtonTheme.of(e).style;
    expectBlackInEachState(
      '$where, the segments ${nameOf(e)}',
      (s) => style?.side?.resolve(s) ?? theme?.side?.resolve(s),
    );
  }
  for (final e in find.byType(Switch).evaluate()) {
    expectBlackInEachState(
      '$where, the switch ${nameOf(e)}',
      (s) => switchSide(e.widget as Switch, SwitchTheme.of(e), s),
    );
  }
}

/// The button style of the theme that [button] reads.
ButtonStyle? _themeStyle(Element button) => switch (button.widget) {
  FilledButton() => FilledButtonTheme.of(button).style,
  OutlinedButton() => OutlinedButtonTheme.of(button).style,
  TextButton() => TextButtonTheme.of(button).style,
  ElevatedButton() => ElevatedButtonTheme.of(button).style,
  _ when button.findAncestorWidgetOfExactType<IconButton>() != null =>
    IconButtonTheme.of(button).style,
  _ => null,
};

// Buttons and text.

/// The button with the label [words].
Finder buttonWith(String words, {Finder? within}) => find
    .ancestor(
      of: within == null
          ? find.text(words)
          : find.descendant(of: within, matching: find.text(words)),
      matching: _buttons,
    )
    .first;

/// The button that [finder] is or holds, for an icon button found by its
/// key or type.
Finder buttonIn(Finder finder) =>
    find.descendant(of: finder, matching: _buttons, matchRoot: true).first;

/// The Material that the button [e] renders.
Material materialOf(Element e) =>
    collectAllElementsFrom(
          e,
          skipOffstage: true,
        ).firstWhere((x) => x.widget is Material).widget
        as Material;

/// The colour of [button]'s label: its text, or else its icon.
Color? labelColour(WidgetTester t, Finder button) {
  final text = find.descendant(of: button, matching: find.byType(Text));
  final label = text.evaluate().isNotEmpty
      ? text.first
      : find.descendant(of: button, matching: find.byType(Icon)).first;
  return rootStyle(richIn(t, label)).color;
}

void expectTeal(WidgetTester t, Finder button, String name) {
  expectRgb(materialOf(t.element(button)).color, tealRgb, '$name: background');
  expectRgb(labelColour(t, button), onTealRgb, '$name: label');
}

/// A slate button: #2B333B on its Material (the top of its gradient) and a
/// #E3EAEC label.
void expectSlate(WidgetTester t, Finder button, String name) {
  expectRgb(materialOf(t.element(button)).color, slateRgb, '$name: background');
  expectRgb(labelColour(t, button), textRgb, '$name: label');
}

/// Presses the button with the label [words] and expects it to sink: no
/// drop shadow, and the label 1 dp lower than at rest. Then it lets go
/// without a tap.
Future<void> expectSinks(WidgetTester t, String words) async {
  final button = buttonWith(words);
  final label = find.descendant(of: button, matching: find.text(words));
  final rest = t.getTopLeft(label).dy;
  final gesture = await t.startGesture(t.getCenter(button));
  // A button in a list waits for the press timeout.
  await t.pump(const Duration(milliseconds: 200));
  expect(
    materialOf(t.element(button)).elevation,
    0,
    reason: '"$words", pressed, has a drop shadow',
  );
  expect(
    t.getTopLeft(label).dy - rest,
    moreOrLessEquals(1),
    reason: 'the label of "$words", pressed, is 1 dp lower',
  );
  await gesture.cancel();
  await t.pump();
}

/// Expects no teal ring around the button with the label [words] at rest,
/// and a teal ring outside its black border when it has the focus. The ring
/// is looked for in what the Material of the button paints: its shape, its
/// background and its foreground.
Future<void> expectRing(WidgetTester t, String words) async {
  final button = buttonWith(words);
  final material = t.renderObject<RenderBox>(
    find.descendant(of: button, matching: find.byType(Material)).first,
  );
  // The Material paints its face from its own origin.
  final face = Offset.zero & material.size;
  // A teal line (a stroke, or the band between two rounded rectangles) whose
  // inner edge lies on or outside the face, and so outside the border.
  PaintPattern ring() => paints
    ..something((method, args) {
      final (inner, paint) = switch (method) {
        #drawRRect => (
          (args[0] as RRect).outerRect.deflate(
            (args[1] as Paint).strokeWidth / 2,
          ),
          args[1] as Paint,
        ),
        #drawDRRect => ((args[1] as RRect).outerRect, args[2] as Paint),
        _ => (null, null),
      };
      if (inner == null || paint == null) return false;
      if (method == #drawRRect && paint.style != PaintingStyle.stroke) {
        return false;
      }
      return sameRgb(paint.color, tealRgb) &&
          inner.left <= face.left &&
          inner.top <= face.top &&
          inner.right >= face.right &&
          inner.bottom >= face.bottom;
    });

  expect(material, isNot(ring()), reason: '"$words" at rest has a teal ring');
  Focus.of(t.element(find.descendant(of: button, matching: find.text(words))))
      .requestFocus();
  // The focus changes the state of the button, and the next frame its look.
  await t.pumpAndSettle();
  expect(material, ring(), reason: '"$words" with the focus has no teal ring');
  FocusManager.instance.primaryFocus?.unfocus();
  await t.pumpAndSettle();
}

/// A ghost button: no fill, and the 2 dp black border.
void expectGhost(WidgetTester t, Finder button, String name) {
  final m = materialOf(t.element(button));
  expect(
    m.color == null || m.color!.a == 0,
    isTrue,
    reason: '$name: a ghost button has no fill, not ${m.color}',
  );
  final fills = [
    for (final d in drawnUnder(t.element(button)))
      if ((d.fill?.a ?? 0) > 0 || (d.gradient?.a ?? 0) > 0) d,
  ];
  expect(fills, isEmpty, reason: '$name: a ghost button has no fill');
  expectBlackSide(sideOf(m), '$name: border');
}

/// The first RichText in [finder], [finder] itself included.
RichText richIn(WidgetTester t, Finder finder) => t.widget<RichText>(
  find
      .descendant(of: finder, matching: find.byType(RichText), matchRoot: true)
      .first,
);

/// The style of the text [words], inside [within] if it is given.
TextStyle styleOf(WidgetTester t, String words, {Finder? within}) => rootStyle(
  richIn(
    t,
    within == null
        ? find.text(words)
        : find.descendant(of: within, matching: find.text(words)),
  ),
);

/// The first RichText whose plain text passes [test].
RichText richWhere(
  WidgetTester t,
  bool Function(String) test, {
  Finder? within,
}) {
  final rich = find.byWidgetPredicate(
    (w) => w is RichText && test(w.text.toPlainText()),
  );
  final found = within == null
      ? rich
      : find.descendant(of: within, matching: rich);
  expect(found, findsWidgets);
  return t.widget<RichText>(found.first);
}

/// The pieces that hold [words] in the first RichText that holds them.
List<(String, TextStyle)> piecesWith(
  WidgetTester t,
  String words, {
  Finder? within,
}) => [
  for (final p in piecesOf(
    richWhere(t, (s) => s.contains(words), within: within),
  ))
    if (p.$1.contains(words)) p,
];

/// Each piece of text in [rich] with the style that it is drawn in.
List<(String, TextStyle)> piecesOf(RichText rich) {
  final out = <(String, TextStyle)>[];
  void visit(InlineSpan span, TextStyle parent) {
    final style = parent.merge(span.style);
    if (span is! TextSpan) return;
    if (span.text case final text? when text.isNotEmpty) {
      out.add((text, style));
    }
    for (final child in span.children ?? const <InlineSpan>[]) {
      visit(child, style);
    }
  }

  visit(rich.text, const TextStyle());
  return out;
}

TextStyle rootStyle(RichText rich) => const TextStyle().merge(rich.text.style);

/// Expects each piece of [rich] with a digit in Spectral. With [rest], each
/// piece with letters has no digit and keeps the family [rest].
void expectSpectralDigits(RichText rich, String where, {String? rest}) {
  final pieces = piecesOf(rich);
  expect(
    pieces.any((p) => p.$1.contains(RegExp(r'\d'))),
    isTrue,
    reason: '$where shows no number',
  );
  for (final (text, style) in pieces) {
    final digits = text.contains(RegExp(r'\d'));
    final letters = text.contains(RegExp('[A-Za-z]'));
    if (digits) {
      expect(style.fontFamily, spectral, reason: '$where: "$text"');
    }
    if (rest != null && letters) {
      expect(digits, isFalse, reason: '$where: "$text" mixes words and digits');
      expect(style.fontFamily, rest, reason: '$where: "$text" keeps its font');
    }
  }
}

/// A short name of [e] for a failure: its words, else a key or a tooltip
/// above it, else its type.
String nameOf(Element e) {
  final words = [
    for (final x in withRoot(e))
      if (x.widget case Text(:final data?)) data,
  ];
  if (words.isNotEmpty) return '"${words.join(' ')}"';
  String? name;
  var depth = 0;
  e.visitAncestorElements((a) {
    final w = a.widget;
    if (w.key case ValueKey(:final value)) {
      name = 'key $value';
    } else if (w is Tooltip) {
      name = 'tooltip ${w.message}';
    }
    return name == null && ++depth < 8;
  });
  return name ?? e.widget.runtimeType.toString();
}

/// The colour of the Scaffold in [finder]: the case behind a screen.
Color? scaffoldFill(WidgetTester t, Finder finder) {
  final scaffold = find
      .descendant(of: finder, matching: find.byType(Scaffold), matchRoot: true)
      .first;
  final material = find.descendant(
    of: scaffold,
    matching: find.byType(Material),
  );
  return drawnBy(t.element(material.first))?.fill;
}
