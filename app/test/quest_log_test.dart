// Spec 0024 (quests, chapter 1), plan 0071 M2: the Quests tab of the Journal
// and the report. Criteria 39-43.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/sync/away_summary.dart';
import 'package:walkingrpg/ui/labels.dart';
import 'package:walkingrpg/ui/socket.dart';

import 'images_test.dart' show diskImages;
import 'ui_test.dart' show game, pumpGame;

void main() {
  Finder entry(String id) => find.byKey(ValueKey('quest-log-$id'));

  Future<void> openQuests(WidgetTester t) async {
    await t.tap(find.byKey(const ValueKey('journal-button')));
    await t.pumpAndSettle();
    await t.tap(find.text('Quests'));
    await t.pumpAndSettle();
  }

  testWidgets('criterion 39: the Journal has the tabs Log, Bestiary, Lore '
      'and Quests', (t) async {
    await pumpGame(t);
    await t.tap(find.byKey(const ValueKey('journal-button')));
    await t.pumpAndSettle();
    for (final tab in ['Log', 'Bestiary', 'Lore', 'Quests']) {
      expect(find.text(tab), findsOneWidget, reason: tab);
    }
  });

  testWidgets('criterion 40: the taken quests, ready ones first, then the '
      'done quests, newest first', (t) async {
    await pumpGame(
      t,
      counters: {'gathered.oak_log': 25},
      prepare: (s) {
        // Handed in: odda_goblins first, then sigrun_deer.
        s.quests['odda_goblins'] = const QuestProgress.done();
        s.quests['sigrun_deer'] = const QuestProgress.done();
        s.quests['hilde_ore'] = const QuestProgress.taken(0);
        s.quests['bram_logs'] = const QuestProgress.taken(0);
      },
    );
    await openQuests(t);
    double top(String id) => t.getTopLeft(entry(id)).dy;
    // bram_logs is ready.
    expect(top('bram_logs'), lessThan(top('hilde_ore')));
    expect(top('hilde_ore'), lessThan(top('sigrun_deer')));
    expect(top('sigrun_deer'), lessThan(top('odda_goblins')));
  });

  testWidgets('a taken quest shows its giver, place, task words and count; '
      'a done quest its ask and thanks', (t) async {
    await pumpGame(
      t,
      counters: {'gathered.copper_ore': 7},
      prepare: (s) {
        s.quests['odda_goblins'] = const QuestProgress.done();
        s.quests['hilde_ore'] = const QuestProgress.taken(0);
      },
    );
    await openQuests(t);
    Finder inEntry(String id, Finder f) =>
        find.descendant(of: entry(id), matching: f);
    expect(inEntry('hilde_ore', find.text('Hilde · Camp')), findsOneWidget);
    expect(
      inEntry(
        'hilde_ore',
        find.text('Gather 25 copper ore in Copper Hills · 7 of 25'),
      ),
      findsOneWidget,
    );
    expect(
      inEntry('odda_goblins', find.textContaining('Ten? That')),
      findsOneWidget,
    );
    expect(
      inEntry('odda_goblins', find.textContaining('Goblins took a crate')),
      findsOneWidget,
    );
  });

  testWidgets("criterion 41: each entry shows its giver's portrait", (t) async {
    await pumpGame(
      t,
      images: diskImages,
      prepare: (s) {
        s.quests['odda_goblins'] = const QuestProgress.done();
        s.quests['hilde_ore'] = const QuestProgress.taken(0);
      },
    );
    await openQuests(t);
    for (final (id, portrait) in [
      ('odda_goblins', 'portraits/odda'),
      ('hilde_ore', 'portraits/hilde'),
    ]) {
      final socket = t.widget<PictureSocket>(
        find.descendant(of: entry(id), matching: find.byType(PictureSocket)),
      );
      expect(socket.picture.key, portrait, reason: id);
    }
  });

  test('criterion 42: the report shows "Quest ready: <title>. Hand it in to '
      '<name>."', () {
    final labels = Labels(game.data);
    expect(
      labels.questReady('odda_goblins'),
      'Quest ready: Goblins at the door. Hand it in to Odda.',
    );
    var s = game.newGame(seed: 1)
      ..location = 'camp'
      ..xp = game.data.xpForLevel(5);
    s = game.takeQuest(s, 'odda_goblins')..location = 'goblin_woods';
    s = game.startActivity(s, const Activity.fight('goblin'));
    final summary = AwaySummary.fromReports([game.applySteps(s, 20000)]);
    expect(summary.questsReady, ['odda_goblins']);
    expect(summary.isEventful, isTrue);
  });

  test('criterion 43: the Journal shows "Quest done: <title>. +N XP and a '
      'supply chest."', () {
    final labels = Labels(game.data);
    expect(
      labels.questDone('odda_goblins'),
      'Quest done: Goblins at the door. +60 XP and a supply chest.',
    );
    const summary = AwaySummary(questsDone: ['odda_goblins']);
    final back = AwaySummary.fromJson(summary.toJson());
    expect(back.questsDone, ['odda_goblins']);
    expect(back.isEventful, isTrue);
  });
}
