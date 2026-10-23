// Spec 0014 (Quiet Teal), plan 0017 M4: the tests of criteria 10, 19, 20,
// 21 and 22, and what M4 adds to criteria 3, 4 and 11. Each test reads
// what the player sees: the sockets on Now, on Professions, on the monster
// rows and sheets, on the banners and on level-up, by the asset of their
// Image; the order of the parts of a row; the texts that §4.1 keeps; the
// skull band and its semantics.
// - The index of the image files comes from the files on disk, with
//   synchronous reads before the pump (images_test.dart). The skull picture
//   has no file until the code of M4 adds it, so each test that shows the
//   skull band fails until then.
// - A "What's new" row of a recipe or a gathering spot does not show on a
//   level-up card today (spec 0010 §2.2 moved them to profession levels). So
//   the test of those rows shows NewsTile alone.
// - The World row of §4.1 (the teal ring) is the test of criterion 18, in M3.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/game_controller.dart';
import 'package:walkingrpg/persistence/save_data.dart';
import 'package:walkingrpg/persistence/save_store.dart';
import 'package:walkingrpg/steps/fake_step_source.dart';
import 'package:walkingrpg/sync/away_summary.dart';
import 'package:walkingrpg/sync/day_key.dart';
import 'package:walkingrpg/ui/app.dart';
import 'package:walkingrpg/ui/bestiary_card.dart';
import 'package:walkingrpg/ui/controller_scope.dart';
import 'package:walkingrpg/ui/home_shell.dart';
import 'package:walkingrpg/ui/images.dart';
import 'package:walkingrpg/ui/labels.dart';
import 'package:walkingrpg/ui/level_badge.dart';
import 'package:walkingrpg/ui/level_up_screen.dart';
import 'package:walkingrpg/ui/socket.dart';
import 'package:walkingrpg/ui/theme.dart' show quietTheme;

import 'images_test.dart'
    show
        assetName,
        diskImages,
        expectRing,
        expectShows,
        imagesIn,
        loadFonts,
        markIn,
        qualityRgb,
        ringIn,
        socketIn;
import 'quiet_teal_files_test.dart' show alegreyaSc, rgb, tealRgb;
import 'quiet_teal_test.dart'
    show
        byElement,
        drawnUnder,
        expectBordersOnScreen,
        expectRgb,
        firstPaint,
        isPlate,
        nameOf,
        openItem,
        openJournal,
        piecesOf,
        richIn;
import 'ui_test.dart'
    show
        ada,
        closeSheet,
        game,
        now,
        openAchievements,
        openArea,
        openProfession,
        openTab,
        option,
        pumpGame;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadFonts);
  criterion10();
  criterion11();
  criterion19();
  criterion20();
  criterion21();
  criterion22();
  criteria3and4();
}

const skullAsset = 'assets/images/pictures/skull.webp';

/// The heading above the monster rows (spec 0014 §4.1).
String get monstersHeading =>
    'Monsters · ${game.data.combatRoundSteps} steps per round';

Finder get hereList => find.byKey(const ValueKey('here'));

/// The status card on Now: the card with "Walked today".
Finder get statusCard => find
    .ancestor(
      of: find.byKey(const ValueKey('walked-today')),
      matching: find.byType(Card),
    )
    .first;

Finder get monsterCard => find.byKey(const ValueKey('bestiary-card'));

Finder inSheet(Finder f) =>
    find.descendant(of: find.byType(BottomSheet), matching: f);

Finder inside(Finder within, Finder f) =>
    find.descendant(of: within, matching: f);

// Where the parts of a row lie.

/// Expects [first] to come first in [within] (spec 0014 §4.2: "starts
/// with"): each text and image of [within] outside [first] lies to the right
/// of it or below it, and none lies above it.
void expectFirst(WidgetTester t, Finder within, Finder first, String what) {
  final head = t.getRect(first);
  final own = find
      .descendant(
        of: first,
        matching: find.byWidgetPredicate((_) => true),
        matchRoot: true,
      )
      .evaluate()
      .toSet();
  for (final e in inside(
    within,
    find.byWidgetPredicate((w) => w is RichText || w is Image),
  ).evaluate()) {
    if (own.contains(e)) continue;
    final r = t.getRect(byElement(e));
    if (r.isEmpty) continue;
    final beside = r.left >= head.right - .5;
    final below = r.top >= head.bottom - .5;
    expect(
      r.bottom > head.top + .5 && (beside || below),
      isTrue,
      reason: '$what: ${nameOf(e)} at $r comes before the picture at $head',
    );
  }
}

/// Expects [where] to start with one socket of [size] dp that shows the
/// picture of [thing] with the image files on disk.
Finder expectSocketFirst(
  WidgetTester t,
  Finder where,
  Thing thing,
  double size,
  String what,
) {
  final socket = socketIn(where);
  expect(t.getSize(socket), Size(size, size), reason: '$what: $size dp');
  expectShows(t, socket, thing, what);
  expectFirst(t, where, socket, what);
  return socket;
}

/// Expects the monster card in view to start with the picture of the boss
/// [id] with [images]: one Image as wide as the card and at most 200 dp
/// tall, and no socket of 72 dp (spec 0014 §4.2).
void expectBossImage(
  WidgetTester t,
  String id,
  ImageIndex images,
  String what,
) {
  final picture = images.pictureOf(game.data, MonsterThing(id));
  final image = inside(
    monsterCard,
    find.byWidgetPredicate(
      (w) => w is Image && assetName(w.image) == picture.asset,
    ),
  );
  expect(image, findsOneWidget, reason: '$what: the image ${picture.key}');
  final rect = t.getRect(image);
  final width = t.getSize(monsterCard).width;
  expect(
    rect.width,
    moreOrLessEquals(width, epsilon: .5),
    reason: '$what: the image $rect across the card, $width dp wide',
  );
  expect(
    rect.height,
    allOf(greaterThan(0), lessThanOrEqualTo(200.5)),
    reason: '$what: the image $rect is at most 200 dp tall',
  );
  expect(
    [
      for (final s in t.widgetList<PictureSocket>(
        inside(monsterCard, find.byType(PictureSocket)),
      ))
        if (s.size == 72) s,
    ],
    isEmpty,
    reason: '$what: a boss has no 72 dp socket',
  );
  expectFirst(t, monsterCard, image, what);
  expect(
    markIn(monsterCard),
    picture.placeholder ? findsOneWidget : findsNothing,
    reason: '$what: a PH mark only on a placeholder',
  );
}

// Screens.

/// Shows [child] alone, in the theme and the scopes of the app.
Future<void> pumpAlone(
  WidgetTester t,
  GameController c,
  Widget child, {
  ImageIndex images = ImageIndex.empty,
}) => t.pumpWidget(
  ControllerScope(
    controller: c,
    child: ImageScope(
      images: images,
      child: MaterialApp(
        theme: quietTheme,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  ),
);

/// Starts the app at Camp, with the image files on disk and one journal
/// entry that holds [summary], as the save keeps it.
Future<GameController> pumpReport(WidgetTester t, AwaySummary summary) async {
  t.view.physicalSize = const Size(1080, 4000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  now = DateTime(2026, 10, 18, 9);
  final source = FakeStepSource();
  final c = GameController(
    game: game,
    source: source,
    permissions: source,
    store: MemorySaveStore(
      SaveData(
        game: game.newGame(seed: 1)..character = ada,
        firstDay: dayKey(now),
        credited: const {},
        journal: [JournalEntry(started: now, summary: summary)],
      ).toJson(),
    ),
    clock: () => now,
    syncInterval: null,
    newSeed: () => 1,
  );
  addTearDown(c.dispose);
  await t.pumpWidget(WalkingRpgApp(controller: c, images: diskImages));
  await c.start();
  await t.pump();
  return c;
}

/// Fights [enemy] while the app is away, so that the app opens on the
/// level-up card of [level], with the image files on disk.
Future<GameController> reachLevel(
  WidgetTester t,
  int level, {
  required String location,
  required String enemy,
}) async {
  final (c, source) = await pumpGame(
    t,
    images: diskImages,
    level: level - 1,
    xp: game.data.xpForLevel(level) - 1,
    location: location,
  );
  await c.startActivity(Activity.fight(enemy));
  source.walk(DateTime(2026, 10, 18, 10), 200);
  now = DateTime(2026, 10, 18, 11);
  await c.resume();
  await t.pump();
  return c;
}

/// A report with one piece of news of each kind (spec 0014 §4.2), and its
/// banners in today's order: each text with the thing that it names, or
/// null for a banner of text only.
(AwaySummary, List<(String, Thing?)>) everyBanner() {
  final data = game.data;
  final labels = Labels(data);
  final lore = data.loreNotes.first.id;
  final before = data.keyFor('hide_vest', 'uncommon');
  final after = data.keyFor('hide_vest', 'rare');
  final chest = data.keyFor('drowned_captains_ring', 'rare');
  return (
    AwaySummary(
      walked: 300,
      levelsReached: const [2],
      achievements: const ['first_steps'],
      lore: [lore],
      learned: const ['goblin'],
      slayers: const ['goblin_brute'],
      professionLevels: const [('mining', 2)],
      finds: const ['garnet'],
      trophyFish: const [('old_mossback', 142)],
      rerolls: [(before, after)],
      charts: const ['smugglers_cove'],
      bottleItems: const ['rare_dust'],
      chests: [chest],
    ),
    <(String, Thing?)>[
      ('Reached level 2!', null),
      (
        'Achievement unlocked: ${labels.achievement('first_steps')}',
        const AchievementThing('first_steps', earned: true),
      ),
      (labels.loreFound(lore), null),
      (labels.weaknessLearned('goblin'), const MonsterThing('goblin')),
      (labels.slayerEarned('goblin_brute'), const MonsterThing('goblin_brute')),
      (labels.professionLevel('mining', 2), null),
      (labels.rareFound('garnet'), const ItemThing('garnet')),
      (
        labels.rareFound('old_mossback', weight: 142),
        const ItemThing('old_mossback'),
      ),
      (labels.rerollNews(before, after), ItemThing(after)),
      (labels.bottle(revealed: 'smugglers_cove'), null),
      (labels.bottle(item: 'rare_dust'), const ItemThing('rare_dust')),
      (labels.chest(chest), ItemThing(chest)),
    ],
  );
}

// The criteria.

void criterion10() {
  group('spec 0014 criterion 10: each fact of §4.1 shows once', () {
    final labels = Labels(game.data);
    Finder card(Finder f) => inside(find.byKey(const ValueKey('item-card')), f);

    testWidgets('tab screens: the name of each tab screen shows once, on its '
        'tab', (t) async {
      await pumpGame(t);
      for (final (tab, label) in const [
        ('now', 'Now'),
        ('world', 'World'),
        ('professions', 'Professions'),
        ('character', 'Character'),
      ]) {
        await openTab(t, tab);
        expect(
          inside(find.byType(HomeShell), find.text(label)),
          findsOneWidget,
          reason: '"$label" on $tab',
        );
        expect(
          inside(find.byKey(ValueKey('tab-$tab')), find.text(label)),
          findsOneWidget,
          reason: '"$label" on its tab',
        );
      }
    });

    testWidgets('Now: the place shows once, in the status card, and the list '
        'heading is "Here"', (t) async {
      for (final place in ['camp', 'goblin_woods']) {
        await t.pumpWidget(const SizedBox());
        await pumpGame(t, location: place);
        final name = game.data.locations[place]!.name;
        expect(
          inside(find.byType(HomeShell), find.text(name)),
          findsOneWidget,
          reason: '"$name" once on Now',
        );
        expect(inside(statusCard, find.text(name)), findsOneWidget);
        expect(find.textContaining('Here:'), findsNothing, reason: place);
        final heading = inside(hereList, find.text('Here'));
        expect(heading, findsOneWidget, reason: 'the list heading at $place');
        for (final e in inside(hereList, find.byType(ListTile)).evaluate()) {
          expect(
            t.getRect(byElement(e)).top,
            greaterThanOrEqualTo(t.getRect(heading).bottom - .5),
            reason: 'at $place, "Here" stands above ${nameOf(e)}',
          );
        }
        // Camp has no monsters, so it has no heading of monsters.
        if (game.data.locations[place]!.enemies.isEmpty) {
          expect(find.text(monstersHeading), findsNothing, reason: place);
        }
      }
    });

    testWidgets('monster rows: one heading "Monsters · 10 steps per round" '
        'stands above them on Now and on the area sheet, and no row says '
        '"steps per round"', (t) async {
      await pumpGame(t, location: 'goblin_woods');
      final enemies = game.data.locations['goblin_woods']!.enemies;
      void expectHeading(Finder within, Finder above, String where) {
        final heading = inside(within, find.text(monstersHeading));
        expect(heading, findsOneWidget, reason: where);
        final h = t.getRect(heading);
        expect(
          h.top,
          greaterThanOrEqualTo(t.getRect(above).bottom - .5),
          reason: '$where: the heading $h below $above',
        );
        for (final id in enemies) {
          final row = inside(within, option('fight', id));
          expect(
            t.getRect(row).top,
            greaterThanOrEqualTo(h.bottom - .5),
            reason: '$where: the heading above the row of $id',
          );
          expect(
            inside(row, find.textContaining('steps per round')),
            findsNothing,
            reason: '$where: the row of $id',
          );
          expect(
            inside(row, find.textContaining(' XP')),
            findsOneWidget,
            reason: '$where: the row of $id keeps its XP',
          );
        }
      }

      expectHeading(hereList, inside(hereList, find.text('Here')), 'Now');
      await openArea(t, 'goblin_woods');
      expectHeading(
        find.byType(BottomSheet),
        inSheet(find.text(game.data.locations['goblin_woods']!.name)),
        'the sheet of Goblin Woods',
      );
      await closeSheet(t);
      await openArea(t, 'camp');
      expect(find.text(monstersHeading), findsNothing, reason: 'Camp');
    });

    testWidgets('the card for an empty slot shows the stats once and drops '
        'the change line that repeats them', (t) async {
      const vest = 'hide_vest@rare';
      const sword = 'bone_sword@rare+crit2+hp10';
      const pike = 'iron_pike';
      await pumpGame(t, inventory: {vest: 1, sword: 1, pike: 1});
      for (final (key, slot) in const [
        (vest, 'chest'),
        (sword, 'mainHand'),
        (pike, 'mainHand'),
      ]) {
        await openItem(t, key);
        final stats = labels.bonus(game.data.baseStatsOf(key)).join(' · ');
        expect(card(find.text(stats)), findsOneWidget, reason: '$key: $stats');
        for (final r in game.data.bonusRolls(key)) {
          expect(card(find.text(labels.bonusRoll(r))), findsOneWidget);
        }
        expect(
          card(find.text('${labels.slot(slot)} is empty')),
          findsOneWidget,
          reason: key,
        );
        expect(
          card(find.byKey(ValueKey('compare-$slot'))),
          findsNothing,
          reason: '$key: the change repeats the stats',
        );
        expect(card(find.byKey(const ValueKey('card-equip'))), findsOneWidget);
        await closeSheet(t);
      }
    });

    testWidgets('the card for an empty slot keeps the change line when it '
        'differs from the stats: a two-hander removes the shield', (t) async {
      final (c, _) = await pumpGame(
        t,
        inventory: {'iron_pike': 1},
        equipment: {'offHand': 'bone_shield'},
      );
      await openItem(t, 'iron_pike');
      final change = labels.delta(
        game.compare(c.state, 'iron_pike', 'mainHand'),
      );
      expect(
        change,
        isNot(labels.bonus(game.data.baseStatsOf('iron_pike')).join(' · ')),
      );
      expect(
        card(find.text('Instead of your ${labels.plain('bone_shield')}')),
        findsOneWidget,
      );
      expect(
        t
            .widget<Text>(card(find.byKey(const ValueKey('compare-mainHand'))))
            .data,
        change,
      );
      expect(card(find.byKey(const ValueKey('card-equip'))), findsOneWidget);
    });

    // A teal rim is the teal of §2.1 for "earned things" (criterion 2).
    testWidgets('an earned achievement shows its goal and a teal rim, with no '
        'bar and no count; an unearned one keeps its bar and its count', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        counters: {'steps.walked': 150, 'kills.goblin': 3},
      );
      c.state.achievements.add('first_steps');
      await openAchievements(t);
      final count = RegExp(r'^[\d,]+ / [\d,]+$');
      for (final (id, earned, goal, counts) in const [
        ('first_steps', true, 'Walk 100 steps', <String>[]),
        ('goblin_slayer_1', false, 'Defeat 10 × Goblin', ['3 / 10']),
      ]) {
        final row = find
            .ancestor(
              of: find.text(game.data.achievements[id]!.name),
              matching: find.byType(Card),
            )
            .first;
        expect(inside(row, find.text(goal)), findsOneWidget, reason: id);
        expect(
          inside(row, find.byType(LinearProgressIndicator)),
          earned ? findsNothing : findsOneWidget,
          reason: '$id: the bar',
        );
        expect(
          [
            for (final r in t.widgetList<RichText>(
              inside(row, find.byType(RichText)),
            ))
              if (count.hasMatch(r.text.toPlainText().trim()))
                r.text.toPlainText().trim(),
          ],
          counts,
          reason: '$id: the count',
        );
        final plate = firstPaint(drawnUnder(t.element(row)));
        expect(plate, isNotNull, reason: id);
        final rim =
            plate!.sides.isNotEmpty &&
            plate.sides.every(
              (s) =>
                  s.style == BorderStyle.solid &&
                  s.width >= 1 &&
                  rgb(s.color) == tealRgb &&
                  s.color.a > .99,
            );
        expect(rim, earned, reason: '$id: a teal rim: $plate');
        if (!earned) expect(isPlate(plate), isTrue, reason: '$id: a plate');
      }
    });

    testWidgets('a Bestiary row keeps the word "Slayer" and shows no Slayer '
        'icon', (t) async {
      final (c, _) = await pumpGame(t, counters: {'kills.goblin': 50});
      expect(game.knowledge(c.state, 'goblin').slayer, isTrue);
      await openJournal(t);
      await t.tap(find.text('Bestiary'));
      await t.pumpAndSettle();
      for (final (id, slayer) in const [
        ('goblin', true),
        ('goblin_brute', false),
      ]) {
        final row = find.byKey(ValueKey('bestiary-$id'));
        expect(
          inside(row, find.textContaining(RegExp(r'\bSlayer\b'))),
          slayer ? findsOneWidget : findsNothing,
          reason: id,
        );
        expect(inside(row, find.byType(Icon)), findsNothing, reason: id);
      }
    });
  });
}

void criterion11() {
  group('spec 0014 criterion 11: the screens of M4 show the picture of each '
      'thing', () {
    // The monster sheet, the banners and level-up show their pictures in the
    // tests of criteria 19, 21 and 22, by the same check.
    testWidgets('the status card on Now shows the marker of the place in a '
        '48 dp socket, next to its name', (t) async {
      for (final place in ['camp', 'goblin_woods', 'mirror_lake']) {
        await t.pumpWidget(const SizedBox());
        await pumpGame(t, images: diskImages, location: place);
        final socket = find.byKey(const ValueKey('status-place'));
        expect(inside(statusCard, socket), findsOneWidget, reason: place);
        expect(t.widget(socket), isA<PictureSocket>(), reason: place);
        expect(t.getSize(socket), const Size(48, 48), reason: place);
        expectShows(
          t,
          socket,
          PlaceThing(place, fogged: false),
          'the marker of $place',
        );
        expect(inside(statusCard, find.byIcon(Icons.place)), findsNothing);
        // Next to the name: on its line, before it, and at most 24 dp away.
        final p = t.getRect(socket);
        final name = t.getRect(
          inside(statusCard, find.text(game.data.locations[place]!.name)),
        );
        expect(
          p.top < name.center.dy && name.center.dy < p.bottom,
          isTrue,
          reason: '$place: the name $name on the line of the marker $p',
        );
        expect(
          name.left - p.right,
          inInclusiveRange(0, 24),
          reason: '$place: the name $name beside the marker $p',
        );
      }
    });

    // The meal line, the tool line and the meal row of Cooking are single
    // lines. Their sockets are 32 dp, the size of §2.3 for banners, as the
    // design phones 11 and 25 show.
    testWidgets('the meal line on Now starts with the image of the meal in a '
        '32 dp socket, with no ring', (t) async {
      final (c, _) = await pumpGame(t, images: diskImages);
      c.state.meal = ActiveMeal('venison_skewer', 1850);
      await openTab(t, 'world');
      await openTab(t, 'now');
      final line = find.byKey(const ValueKey('meal-line'));
      expectSocketFirst(
        t,
        line,
        const ItemThing('venison_skewer'),
        32,
        'the meal line',
      );
      expect(ringIn(t, line), isNull, reason: 'a meal has no ring');
      expect(inside(line, find.byIcon(Icons.restaurant)), findsNothing);
    });

    testWidgets('each monster row on Now and on the area sheet starts with '
        'the image of the monster in a 48 dp socket, and keeps its level '
        'badge', (t) async {
      await pumpGame(t, images: diskImages, location: 'goblin_woods');
      for (final (where, within) in [
        ('Now', hereList),
        ('the area sheet', find.byType(BottomSheet)),
      ]) {
        if (where != 'Now') await openArea(t, 'goblin_woods');
        for (final id in game.data.locations['goblin_woods']!.enemies) {
          final row = inside(within, option('fight', id));
          expectSocketFirst(t, row, MonsterThing(id), 48, '$id on $where');
          expect(
            inside(row, find.byType(LevelBadge)),
            findsOneWidget,
            reason: '$id on $where keeps its level badge',
          );
        }
      }
    });

    testWidgets('on each profession screen the tool line starts with the '
        'image of the tool in a 32 dp socket with the ring of its quality; '
        "Cooking's meal row starts with the meal in a 32 dp socket; recipe "
        'rows stay as today', (t) async {
      final (c, _) = await pumpGame(t, images: diskImages);
      await openProfession(t, 'cooking');
      expect(
        inside(
          find.byKey(const ValueKey('cooking-meal')),
          find.byType(PictureSocket),
        ),
        findsNothing,
        reason: 'no meal runs',
      );
      c.state.tools['mining'] = game.data.keyFor('copper_pickaxe', 'rare');
      c.state.meal = ActiveMeal('venison_skewer', 1850);
      var recipes = 0;
      for (final p in game.data.professions.keys) {
        await openProfession(t, p);
        final tool = c.state.tools[p]!;
        final line = find.byKey(ValueKey('tool-$p'));
        expectSocketFirst(t, line, ItemThing(tool), 32, 'the tool line of $p');
        expectRing(
          t,
          line,
          qualityRgb(game.data.qualityOf(tool).id),
          'the tool of $p',
        );
        for (final e
            in find
                .byWidgetPredicate(
                  (w) => switch (w.key) {
                    ValueKey<String>(:final value) => value.startsWith(
                      'option-craft-',
                    ),
                    _ => false,
                  },
                )
                .evaluate()) {
          recipes++;
          expect(
            inside(byElement(e), find.byType(PictureSocket)),
            findsNothing,
            reason: 'the recipe row ${nameOf(e)} on $p',
          );
        }
      }
      expect(recipes, greaterThan(0), reason: 'no recipe row was checked');
      await openProfession(t, 'cooking');
      final meal = find.byKey(const ValueKey('cooking-meal'));
      expectSocketFirst(
        t,
        meal,
        const ItemThing('venison_skewer'),
        32,
        "Cooking's meal row",
      );
      expect(ringIn(t, meal), isNull, reason: 'a meal has no ring');
    });
  });
}

void criterion19() {
  group('spec 0014 criterion 19: one sheet for each monster, with its '
      'image', () {
    testWidgets('a tap on a monster on Now, on the area sheet or in the '
        'Bestiary opens one sheet that starts with its image in a 72 dp '
        'socket', (t) async {
      await pumpGame(t, images: diskImages, location: 'goblin_woods');
      Future<void> expectSheet(String from) async {
        await t.pumpAndSettle();
        expect(find.byType(BottomSheet), findsOneWidget, reason: from);
        expect(monsterCard, findsOneWidget, reason: from);
        expect(find.byType(BackButton), findsNothing, reason: 'no page');
        expectSocketFirst(
          t,
          monsterCard,
          const MonsterThing('goblin'),
          72,
          'the sheet of the Goblin from $from',
        );
        await closeSheet(t);
      }

      await t.tap(inside(hereList, option('fight', 'goblin')));
      await expectSheet('Now');
      await openArea(t, 'goblin_woods');
      await t.tap(inSheet(option('fight', 'goblin')));
      await expectSheet('the area sheet');
      await openJournal(t);
      await t.tap(find.text('Bestiary'));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('bestiary-goblin')));
      await t.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expectSocketFirst(
        t,
        monsterCard,
        const MonsterThing('goblin'),
        72,
        'the sheet of the Goblin from the Bestiary',
      );
    });

    testWidgets('a boss, a monster with first-kill drops, opens the same '
        'sheet, which starts with its image across the full width, at most '
        '200 dp tall, also at 360 dp', (t) async {
      const king = 'graveyard_king';
      expect(game.data.enemies[king]!.firstKillDrops, isNotEmpty);
      await pumpGame(
        t,
        images: diskImages,
        level: 10,
        location: 'old_graveyard',
      );
      await t.tap(inside(hereList, option('fight', king)));
      await t.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(BackButton), findsNothing, reason: 'no boss page');
      for (final size in const [Size(1080, 4000), Size(360, 780)]) {
        t.view.physicalSize = size;
        await t.pumpAndSettle();
        expectBossImage(t, king, diskImages, 'at ${size.width} dp');
        expect(
          t.getSize(find.byType(BottomSheet)).width -
              t.getSize(monsterCard).width,
          inInclusiveRange(0, 48.5),
          reason: 'at ${size.width} dp, the card spans its sheet',
        );
      }
    });

    testWidgets('each monster card of the data: a boss starts with its image '
        'across the card, each other monster with a 72 dp socket; a boss '
        'with no image file shows its placeholder across the card', (t) async {
      final (c, _) = await pumpGame(t);
      for (final e in game.data.enemies.values) {
        await pumpAlone(
          t,
          c,
          BestiaryCard(controller: c, enemy: e.id),
          images: diskImages,
        );
        if (e.firstKillDrops.isEmpty) {
          expectSocketFirst(t, monsterCard, MonsterThing(e.id), 72, e.id);
        } else {
          expectBossImage(t, e.id, diskImages, e.id);
        }
      }
      await pumpAlone(
        t,
        c,
        BestiaryCard(controller: c, enemy: 'graveyard_king'),
      );
      expectBossImage(
        t,
        'graveyard_king',
        ImageIndex.empty,
        'the Graveyard King with no image file',
      );
    });

    testWidgets('stats stay unknown until 10 kills, on the sheet of a boss and '
        'with a lore note too', (t) async {
      final (c, _) = await pumpGame(
        t,
        images: diskImages,
        level: 10,
        location: 'old_graveyard',
        counters: {'kills.skeleton': 9, 'kills.zombie': 10},
      );
      final note = game.data.loreNotes.firstWhere(
        (n) => n.about == 'graveyard_king',
      );
      c.state.lore.add(note.id);
      for (final (id, known) in const [
        ('skeleton', false),
        ('zombie', true),
        ('graveyard_king', false),
      ]) {
        final hp = 'HP ${game.data.enemies[id]!.stats.hp}';
        final row = inside(hereList, option('fight', id));
        expect(
          inside(row, find.textContaining('Stats unknown')),
          known ? findsNothing : findsOneWidget,
          reason: 'the row of $id',
        );
        await t.tap(row);
        await t.pumpAndSettle();
        expect(
          inside(monsterCard, find.text('Stats: ???')),
          known ? findsNothing : findsOneWidget,
          reason: 'the sheet of $id',
        );
        expect(
          inside(monsterCard, find.textContaining(hp)),
          known ? findsOneWidget : findsNothing,
          reason: 'the sheet of $id: "$hp"',
        );
        // The lore note tells the weakness of the King, not his stats.
        if (id == note.about) {
          expect(inside(monsterCard, find.textContaining('Weak to')), findsOne);
        }
        await closeSheet(t);
      }
    });
  });
}

void criterion20() {
  group('spec 0014 criterion 20: the skull band', () {
    testWidgets('the skull band shows the skull image in place of 💀, with no '
        'PH mark, and screen readers say "Level: far too strong"; a red band '
        'keeps its number', (t) async {
      final semantics = t.ensureSemantics();
      for (final colour in const [LevelColour.skull, LevelColour.red]) {
        await t.pumpWidget(
          MaterialApp(
            theme: quietTheme,
            home: Scaffold(
              body: Center(child: LevelBadge(level: 16, colour: colour)),
            ),
          ),
        );
        final skull = colour == LevelColour.skull;
        final badge = find.byType(LevelBadge);
        expect(imagesIn(t, badge), skull ? [skullAsset] : isEmpty);
        expect(find.textContaining('💀'), findsNothing);
        expect(markIn(badge), findsNothing, reason: 'the skull is a picture');
        expect(
          find.bySemanticsLabel(skull ? 'Level: far too strong' : 'Level 16'),
          findsOneWidget,
          reason: colour.name,
        );
        expect(
          find.bySemanticsLabel(RegExp('placeholder picture|💀')),
          findsNothing,
        );
        expectRgb(
          firstPaint(drawnUnder(t.element(badge)))?.fill,
          rgb(LevelBadge.colorOf(colour)),
          'the band of ${colour.name}',
        );
        if (skull) {
          final image = inside(badge, find.byType(Image));
          expect(
            t.getRect(badge).inflate(.5).contains(t.getRect(image).topLeft) &&
                t
                    .getRect(badge)
                    .inflate(.5)
                    .contains(t.getRect(image).bottomRight),
            isTrue,
            reason: 'the skull lies inside its band',
          );
        } else {
          expect(inside(badge, find.text('16')), findsOneWidget);
        }
      }
      semantics.dispose();
    });

    testWidgets("on Now and on the area sheet, the Old Bear's row shows the "
        'skull image, and screen readers still say "Level: far too '
        'strong"', (t) async {
      final semantics = t.ensureSemantics();
      final (c, _) = await pumpGame(t, location: 'goblin_woods');
      expect(game.enemyBand(c.state, 'old_bear').colour, LevelColour.skull);
      for (final (where, within) in [
        ('Now', hereList),
        ('the area sheet', find.byType(BottomSheet)),
      ]) {
        if (where != 'Now') await openArea(t, 'goblin_woods');
        expect(
          imagesIn(t, inside(within, option('fight', 'old_bear'))),
          contains(skullAsset),
          reason: where,
        );
        expect(find.textContaining('💀'), findsNothing, reason: where);
        expect(
          find.bySemanticsLabel(RegExp('Level: far too strong')),
          findsWidgets,
          reason: where,
        );
        expect(find.bySemanticsLabel(RegExp('💀')), findsNothing);
      }
      semantics.dispose();
    });
  });
}

void criterion21() {
  group('spec 0014 criterion 21: each banner shows text or an image', () {
    for (final (where, open)
        in <(String, Future<void> Function(WidgetTester, GameController))>[
          (
            'the away screen',
            (t, c) async {
              c.showLastAwaySummary();
              await t.pumpAndSettle();
            },
          ),
          ('the journal entry', (t, c) => openJournal(t)),
        ]) {
      testWidgets('on $where, the banners of levels, lore notes, profession '
          'levels and the sea chart show text only; each other banner starts '
          'with the image of the thing that it names, in a 32 dp socket', (
        t,
      ) async {
        final (summary, expected) = everyBanner();
        final c = await pumpReport(t, summary);
        await open(t, c);
        final banners = find
            .byKey(const ValueKey('report-banner'))
            .evaluate()
            .toList();
        expect(banners, hasLength(expected.length));
        for (final (i, (text, thing)) in expected.indexed) {
          final banner = byElement(banners[i]);
          expect(
            inside(banner, find.text(text)),
            findsOneWidget,
            reason: 'banner ${i + 1} says "$text", in the order of today',
          );
          if (thing == null) {
            for (final type in [PictureSocket, Image, Icon]) {
              expect(
                inside(banner, find.byType(type)),
                findsNothing,
                reason: '"$text" shows text only: no $type',
              );
            }
            continue;
          }
          expectSocketFirst(t, banner, thing, 32, '"$text" on $where');
          // Gear shows the ring of its quality; the other things have none
          // (§2.3).
          final key = thing is ItemThing ? thing.key : null;
          final item = key == null ? null : game.data.itemOf(key);
          if (item?.slot != null || item?.tool != null) {
            expectRing(
              t,
              banner,
              qualityRgb(game.data.qualityOf(key!).id),
              '"$text"',
            );
          } else {
            expect(ringIn(t, banner), isNull, reason: '"$text" has no ring');
          }
        }
      });
    }
  });
}

void criterion22() {
  group("spec 0014 criterion 22: level-up shows the rank image and the images "
      'of "What\'s new"', () {
    Finder sockets72(Finder within) => inside(
      within,
      find.byWidgetPredicate((w) => w is PictureSocket && w.size == 72),
    );

    testWidgets('a card with a new rank shows the rank image in a 72 dp '
        'socket in place of its icon; its monster rows start with the '
        'monster, and the talent point row keeps its icon', (t) async {
      final c = await reachLevel(
        t,
        10,
        location: 'old_graveyard',
        enemy: 'skeleton',
      );
      final screen = find.byType(LevelUpScreen);
      final title = find.text('Level 10!');
      expect(title, findsOneWidget);
      final rank = game.rank(10).name;
      final socket = sockets72(screen);
      expect(socket, findsOneWidget, reason: 'the rank $rank');
      expectShows(t, socket, RankThing(rank), 'the rank $rank');
      expect(inside(screen, find.byIcon(Icons.military_tech)), findsNothing);
      expect(
        t.getRect(socket).bottom,
        lessThanOrEqualTo(t.getRect(title).top + .5),
        reason: 'the rank image stands where the icon stood, above the title',
      );

      final labels = Labels(game.data, c.state.character);
      Finder row(LevelNews n) => find
          .ancestor(
            of: find.text(labels.news(n)),
            matching: find.byType(ListTile),
          )
          .first;
      final monsters = [
        for (final n in game.levelNews(10, c.state))
          if (n.kind == NewsKind.yourLevel || n.kind == NewsKind.turnedGrey) n,
      ];
      expect(monsters, isNotEmpty);
      for (final n in monsters) {
        expectSocketFirst(t, row(n), MonsterThing(n.id), 48, labels.news(n));
      }
      final point = row(const LevelNews(NewsKind.talentPoint, ''));
      expect(inside(point, find.byIcon(Icons.auto_awesome)), findsOneWidget);
      expect(inside(point, find.byType(PictureSocket)), findsNothing);
    });

    testWidgets('a card with no new rank shows no rank image and keeps its '
        'icon', (t) async {
      await reachLevel(t, 2, location: 'goblin_woods', enemy: 'goblin');
      final screen = find.byType(LevelUpScreen);
      expect(find.text('Level 2!'), findsOneWidget);
      expect(sockets72(screen), findsNothing);
      expect(
        inside(screen, find.byIcon(Icons.arrow_circle_up)),
        findsOneWidget,
      );
    });

    testWidgets('a "What\'s new" row of a monster or a recipe starts with its '
        'image in a 48 dp socket; a row of a gathering spot or a talent '
        'point keeps its icon', (t) async {
      final (c, _) = await pumpGame(t);
      final labels = Labels(game.data, ada);
      final recipes = game.data.recipes;
      for (final (news, thing, icon) in <(LevelNews, Thing?, IconData?)>[
        (
          const LevelNews(NewsKind.recipe, 'copper_sword'),
          ItemThing(recipes['copper_sword']!.output),
          null,
        ),
        (
          const LevelNews(NewsKind.recipe, 'garnet_ring'),
          ItemThing(recipes['garnet_ring']!.output),
          null,
        ),
        (
          const LevelNews(NewsKind.recipe, 'grilled_perch'),
          ItemThing(recipes['grilled_perch']!.output),
          null,
        ),
        (
          const LevelNews(NewsKind.yourLevel, 'goblin'),
          const MonsterThing('goblin'),
          null,
        ),
        (
          const LevelNews(NewsKind.turnedGrey, 'goblin_brute'),
          const MonsterThing('goblin_brute'),
          null,
        ),
        (
          const LevelNews(NewsKind.gatheringSpot, 'iron_vein'),
          null,
          Icons.landscape,
        ),
        (const LevelNews(NewsKind.talentPoint, ''), null, Icons.auto_awesome),
      ]) {
        await pumpAlone(t, c, NewsTile(news: news), images: diskImages);
        final row = find.byType(NewsTile);
        final what = '"${labels.news(news)}"';
        expect(inside(row, find.text(labels.news(news))), findsOneWidget);
        if (thing != null) {
          expectSocketFirst(t, row, thing, 48, what);
        } else {
          expect(inside(row, find.byIcon(icon!)), findsOneWidget, reason: what);
          expect(inside(row, find.byType(PictureSocket)), findsNothing);
        }
      }
    });
  });
}

// Criterion 2 gets no test here: M4 brings no new colour. The teal rim of
// an earned achievement (§2.1, "earned things") is in the test of criterion
// 10, the band of the skull in the test of criterion 20, and the scan of
// lib/ in quiet_teal_files_test.dart reads each colour of the code.
void criteria3and4() {
  group('spec 0014 criterion 3: the fonts of the parts of M4', () {
    // The heading "Here" is the first Heading on Now, which the test of M1
    // reads.
    testWidgets('"Monsters · 10 steps per round" is a list heading in '
        'Alegreya Sans SC 700, its number too, on Now and on the area '
        'sheet', (t) async {
      await pumpGame(t, location: 'goblin_woods');
      for (final where in ['Now', 'the area sheet']) {
        if (where != 'Now') await openArea(t, 'goblin_woods');
        final heading = find.text(monstersHeading);
        expect(heading, findsOneWidget, reason: where);
        final pieces = piecesOf(richIn(t, heading));
        expect(pieces, isNotEmpty, reason: where);
        for (final (text, style) in pieces) {
          expect(
            (style.fontFamily, style.fontWeight),
            (alegreyaSc, FontWeight.w700),
            reason: '"$text" on $where',
          );
        }
      }
    });
  });

  group('spec 0014 criterion 4: the controls of the screens of M4', () {
    // The tests of M1 check Now, the sheet of a monster, level-up, the away
    // screen, the Journal and the screens of Crafting and Mining.
    testWidgets('the sheet of a boss, Achievements with an earned '
        'achievement, and Cooking with a meal keep the 2 dp black border', (
      t,
    ) async {
      final (c, _) = await pumpGame(
        t,
        images: diskImages,
        level: 10,
        location: 'old_graveyard',
        counters: {'steps.walked': 150},
      );
      await t.tap(inside(hereList, option('fight', 'graveyard_king')));
      await t.pumpAndSettle();
      expectBordersOnScreen(t, 'the sheet of the Graveyard King');
      await closeSheet(t);
      c.state.achievements.add('first_steps');
      await openAchievements(t);
      expect(find.text('New'), findsOneWidget, reason: 'the earned one');
      expectBordersOnScreen(t, 'Achievements with an earned achievement');
      await t.pageBack();
      await t.pumpAndSettle();
      c.state.meal = ActiveMeal('venison_skewer', 1850);
      await openProfession(t, 'cooking');
      expectBordersOnScreen(t, 'Cooking with a meal');
    });
  });
}
