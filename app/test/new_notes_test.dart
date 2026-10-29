// The "New in Itheros" card at open and the notes in Settings (spec 0018
// §3, its amendment 1, plan 0029 M1). In-memory storage keeps real I/O out of
// the fake-async test zone.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/game_controller.dart';
import 'package:walkingrpg/persistence/save_data.dart';
import 'package:walkingrpg/persistence/save_store.dart';
import 'package:walkingrpg/release_notes.dart';
import 'package:walkingrpg/steps/fake_step_source.dart';
import 'package:walkingrpg/sync/day_key.dart';
import 'package:walkingrpg/ui/app.dart';
import 'package:walkingrpg/ui/away_summary_card.dart';
import 'package:walkingrpg/ui/level_up_screen.dart';

import 'images_test.dart' show loadFonts;
import 'ui_test.dart' show ada, game, openSettings;

const _title = 'New in Itheros';
final _continue = find.byKey(const ValueKey('new-notes-continue'));

/// Notes for 0.4.0 to 0.6.0, and a next.md. 0.6.0 has an item with a list
/// inside it (amendment 1).
const _notes = ReleaseNotes({
  '0.4.0': 'Notes of 0.4.0.',
  '0.5.0': 'Notes of 0.5.0.',
  '0.6.0':
      'Small fixes.\n'
      '\n'
      '- **Fixed:** a meal card.\n'
      '- **Top item:** the first\n'
      '  line goes on.\n'
      '  - **Inner item** comes inside.\n',
}, next: 'Notes of the next release.');

/// The real notes of `releases/`, read before the fake-async zone.
final _realNotes = ReleaseNotes.fromFiles({
  for (final f in Directory('../releases').listSync().whereType<File>())
    f.uri.pathSegments.last: f.readAsStringSync(),
});

/// A save at Camp with Ada and [lastVersion], as JSON.
Map<String, Object?> _save(String? lastVersion, {Character? character = ada}) =>
    SaveData(
      game: game.newGame(seed: 1)..character = character,
      firstDay: dayKey(DateTime(2026, 10, 18)),
      credited: const {},
      lastVersion: lastVersion,
    ).toJson();

/// Starts the app in [version] on [store].
Future<GameController> _open(
  WidgetTester t,
  MemorySaveStore store, {
  String version = '0.6.0',
  ReleaseNotes notes = _notes,
  FakeStepSource? source,
  DateTime? at,
  bool testWalkAllowed = true,
}) async {
  final steps = source ?? FakeStepSource();
  final now = at ?? DateTime(2026, 10, 18, 9);
  final c = GameController(
    game: game,
    source: steps,
    permissions: steps,
    store: store,
    clock: () => now,
    syncInterval: null,
    newSeed: () => 1,
    testWalkAllowed: testWalkAllowed,
    notes: notes,
    version: version,
  );
  addTearDown(c.dispose);
  await t.pumpWidget(WalkingRpgApp(controller: c));
  await c.start();
  await t.pumpAndSettle();
  return c;
}

void _tall(WidgetTester t) {
  t.view.physicalSize = const Size(1080, 4000);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

Future<String?> _lastVersion(MemorySaveStore store) async =>
    (await store.load())!.lastVersion;

void main() {
  group('when the card shows (spec 0018 §2.3)', () {
    testWidgets('a skip from 0.4.0 to 0.6.0 shows 0.6.0, then 0.5.0 '
        '(criterion 5)', (t) async {
      _tall(t);
      await _open(t, MemorySaveStore(_save('0.4.0')));
      expect(find.text(_title), findsOneWidget);
      expect(find.text('Itheros 0.6.0'), findsOneWidget);
      expect(find.text('Itheros 0.5.0'), findsOneWidget);
      expect(find.text('Itheros 0.4.0'), findsNothing);
      expect(
        t.getTopLeft(find.text('Itheros 0.6.0')).dy,
        lessThan(t.getTopLeft(find.text('Itheros 0.5.0')).dy),
      );
    });

    testWidgets('the last version equal to the app version shows no card '
        '(criterion 6)', (t) async {
      _tall(t);
      await _open(t, MemorySaveStore(_save('0.6.0')));
      expect(find.text(_title), findsNothing);
    });

    testWidgets('an old save shows only the notes of the app version '
        '(criterion 7)', (t) async {
      _tall(t);
      await _open(t, MemorySaveStore(_save(null)));
      expect(find.text('Itheros 0.6.0'), findsOneWidget);
      expect(find.text('Itheros 0.5.0'), findsNothing);
    });

    testWidgets('a new save shows no card and records the app version '
        '(criterion 8)', (t) async {
      _tall(t);
      final store = MemorySaveStore();
      await _open(t, store);
      expect(find.text(_title), findsNothing);
      expect(await _lastVersion(store), '0.6.0');
    });

    testWidgets('a last version after the app version shows no card and '
        'stays (criteria 9-10)', (t) async {
      _tall(t);
      final store = MemorySaveStore(_save('0.7.0'));
      await _open(t, store);
      expect(find.text(_title), findsNothing);
      expect(await _lastVersion(store), '0.7.0');
    });

    testWidgets('"Continue" saves the app version, and the next open shows '
        'no card (criteria 11-12)', (t) async {
      _tall(t);
      final store = MemorySaveStore(_save('0.5.0'));
      await _open(t, store);
      await t.tap(_continue);
      await t.pumpAndSettle();
      expect(find.text(_title), findsNothing);
      expect(await _lastVersion(store), '0.6.0');
      await _open(t, store);
      expect(find.text(_title), findsNothing);
    });

    testWidgets('next.md never shows on the card (criterion 13)', (t) async {
      _tall(t);
      await _open(t, MemorySaveStore(_save('0.4.0')));
      expect(find.text('Next release (test build)'), findsNothing);
      expect(
        find.textContaining('Notes of the next release', findRichText: true),
        findsNothing,
      );
    });
  });

  group('the order at open (spec 0018 §3.1)', () {
    testWidgets('the card shows first, then the level-up cards, then the away '
        'report (criteria 14-15)', (t) async {
      _tall(t);
      final source = FakeStepSource();
      final store = MemorySaveStore(
        SaveData(
          game: game.newGame(seed: 1)
            ..character = ada
            ..xp = game.data.xpForLevel(10) - 1
            ..location = 'old_graveyard'
            ..explored.add('old_graveyard'),
          firstDay: dayKey(DateTime(2026, 10, 18)),
          credited: const {},
          lastVersion: '0.5.0',
        ).toJson(),
      );
      // The player starts a fight in 0.5.0, walks, and opens 0.6.0.
      final before = await _open(t, store, version: '0.5.0', source: source);
      expect(find.text(_title), findsNothing);
      await before.startActivity(Activity.fight('skeleton'));
      source.walk(DateTime(2026, 10, 18, 10), 200);
      await _open(t, store, source: source, at: DateTime(2026, 10, 18, 11));

      expect(find.text(_title), findsOneWidget);
      expect(find.byType(LevelUpScreen), findsNothing);
      expect(find.byType(AwayScreen), findsNothing);

      await t.tap(_continue);
      await t.pumpAndSettle();
      expect(find.byType(LevelUpScreen), findsOneWidget);

      await t.tap(find.text('Continue'));
      await t.pumpAndSettle();
      expect(find.byType(AwayScreen), findsOneWidget);
    });

    testWidgets('a player with no character sees character creation, not the '
        'card (criterion 16)', (t) async {
      _tall(t);
      await _open(t, MemorySaveStore(_save(null, character: null)));
      expect(find.text(_title), findsNothing);
      expect(find.byKey(const ValueKey('set-out')), findsOneWidget);
    });
  });

  group('the card (spec 0018 §3.2, §3.3, amendment 1)', () {
    testWidgets('the title, the headings, bullets and bold text '
        '(criteria 17-20)', (t) async {
      _tall(t);
      await _open(t, MemorySaveStore(_save('0.5.0')));
      expect(find.text(_title), findsOneWidget);
      expect(find.text('Itheros 0.6.0'), findsOneWidget);
      expect(find.text('•'), findsNWidgets(3));
      expect(find.textContaining('**', findRichText: true), findsNothing);
      final fixed = find.textContaining('Fixed:', findRichText: true);
      final spans = <TextSpan>[];
      (t.widget<RichText>(fixed).text as TextSpan).visitChildren((s) {
        if (s is TextSpan && s.text != null) spans.add(s);
        return true;
      });
      expect(
        spans.firstWhere((s) => s.text == 'Fixed:').style?.fontWeight,
        FontWeight.bold,
      );
      // A line with two spaces joins its item.
      expect(
        find.textContaining('the first line goes on.', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('an item of the second list stands further in '
        '(amendment criterion 1)', (t) async {
      _tall(t);
      await _open(t, MemorySaveStore(_save('0.5.0')));
      final top = find.textContaining('Top item:', findRichText: true);
      final inner = find.textContaining('Inner item', findRichText: true);
      expect(t.getTopLeft(inner).dx, greaterThan(t.getTopLeft(top).dx));
    });

    testWidgets('the back gesture does not close the card (criterion 23)', (
      t,
    ) async {
      _tall(t);
      final store = MemorySaveStore(_save('0.5.0'));
      await _open(t, store);
      expect(
        find.byWidgetPredicate((w) => w is PopScope && !w.canPop),
        findsOneWidget,
      );
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(find.text(_title), findsOneWidget);
      expect(await _lastVersion(store), '0.5.0');
    });

    testWidgets('at the text size 2.0 the real notes fit, and a scroll '
        'reaches "Continue" (criteria 21-22)', (t) async {
      await loadFonts();
      t.view.physicalSize = const Size(360, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      t.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final store = MemorySaveStore(_save('0.2.0'));
      await _open(t, store, version: '0.5.0', notes: _realNotes);
      expect(find.text('Itheros 0.3.0'), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.ensureVisible(_continue);
      await t.pumpAndSettle();
      await t.tap(_continue);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(await _lastVersion(store), '0.5.0');
    });
  });

  group('Settings (spec 0018 §3.4)', () {
    final row = find.byKey(const ValueKey('settings-notes'));

    Future<void> openNotes(WidgetTester t) async {
      await t.tap(row);
      await t.pumpAndSettle();
    }

    testWidgets('the row stands above the version number (criterion 24)', (
      t,
    ) async {
      _tall(t);
      await _open(t, MemorySaveStore(_save('0.6.0')));
      await openSettings(t);
      expect(
        find.descendant(of: row, matching: find.text(_title)),
        findsOneWidget,
      );
      expect(
        t.getTopLeft(row).dy,
        lessThan(t.getTopLeft(find.byKey(const ValueKey('version'))).dy),
      );
    });

    testWidgets('the row opens each version up to the app version, newest '
        'first (criterion 25)', (t) async {
      _tall(t);
      await _open(
        t,
        MemorySaveStore(_save('0.5.0')),
        version: '0.5.0',
        testWalkAllowed: false,
      );
      await openSettings(t);
      await openNotes(t);
      expect(find.text(_title), findsOneWidget);
      expect(find.text('Itheros 0.6.0'), findsNothing);
      final five = t.getTopLeft(find.text('Itheros 0.5.0')).dy;
      final four = t.getTopLeft(find.text('Itheros 0.4.0')).dy;
      expect(five, lessThan(four));
    });

    testWidgets("the owner's build starts with next.md (criterion 26)", (
      t,
    ) async {
      _tall(t);
      await _open(t, MemorySaveStore(_save('0.6.0')));
      await openSettings(t);
      await openNotes(t);
      final next = find.text('Next release (test build)');
      expect(next, findsOneWidget);
      expect(
        t.getTopLeft(next).dy,
        lessThan(t.getTopLeft(find.text('Itheros 0.6.0')).dy),
      );
      expect(
        find.textContaining('Notes of the next release', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets("a friend's build does not show next.md (criterion 27)", (
      t,
    ) async {
      _tall(t);
      await _open(t, MemorySaveStore(_save('0.6.0')), testWalkAllowed: false);
      await openSettings(t);
      await openNotes(t);
      expect(find.text('Next release (test build)'), findsNothing);
      expect(
        find.textContaining('Notes of the next release', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('the notes in Settings do not change the last version '
        '(criterion 28)', (t) async {
      _tall(t);
      final store = MemorySaveStore(_save('0.7.0'));
      await _open(t, store);
      await openSettings(t);
      await openNotes(t);
      await t.pageBack();
      await t.pumpAndSettle();
      expect(await _lastVersion(store), '0.7.0');
    });
  });
}
