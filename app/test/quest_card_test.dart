// Spec 0024 (quests, chapter 1), plan 0071 M2: the quest card on Now in the
// place of Next goal. Criteria 23-31.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';

import 'ui_test.dart' show game, openSettings, pumpGame;

void main() {
  final card = find.byKey(const ValueKey('quest-card'));
  Finder line(String id) => find.byKey(ValueKey('quest-line-$id'));
  Finder inCard(Finder f) => find.descendant(of: card, matching: f);

  /// [quests] taken now, and [done] handed in.
  void Function(GameState) with_({
    List<String> taken = const [],
    List<String> done = const [],
  }) => (s) {
    for (final q in done) {
      s.quests[q] = const QuestProgress.done();
    }
    for (final q in taken) {
      s.quests[q] = const QuestProgress.taken(0);
    }
  };

  const camp = ['hilde_ore', 'bram_logs', 'sigrun_deer', 'wen_perch'];

  testWidgets('criterion 23: the quest card stands where Next goal stood, '
      'after the status card and before the queue card', (t) async {
    await pumpGame(t);
    expect(card, findsOneWidget);
    final top = t.getTopLeft(card).dy;
    expect(
      top,
      greaterThan(t.getTopLeft(find.byKey(const ValueKey('status-place'))).dy),
    );
    expect(
      top,
      lessThan(t.getTopLeft(find.byKey(const ValueKey('queue-card'))).dy),
    );
    expect(inCard(find.text('Quests')), findsOneWidget);
  });

  testWidgets('criterion 24: up to three taken quests, ready ones first, '
      'with their task words and count', (t) async {
    await pumpGame(
      t,
      counters: {'gathered.copper_ore': 4, 'gathered.oak_log': 25},
      prepare: with_(done: ['odda_goblins'], taken: ['hilde_ore', 'bram_logs']),
    );
    expect(line('bram_logs'), findsOneWidget);
    expect(line('hilde_ore'), findsOneWidget);
    // Bram's quest is ready, so it stands first.
    expect(
      t.getTopLeft(line('bram_logs')).dy,
      lessThan(t.getTopLeft(line('hilde_ore')).dy),
    );
    expect(
      find.descendant(
        of: line('hilde_ore'),
        matching: find.text('Gather 25 copper ore in Copper Hills · 4 of 25'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: line('hilde_ore'),
        matching: find.text('Ore for the forge'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('criterion 25: a ready quest says "Ready: hand it in to <name> '
      'in <place>"', (t) async {
    await pumpGame(
      t,
      counters: {'gathered.goblin_hide': 15},
      inventory: {'goblin_hide': 15},
      prepare: with_(done: ['odda_goblins'], taken: ['pell_hides']),
    );
    expect(
      find.descendant(
        of: line('pell_hides'),
        matching: find.text('Ready: hand it in to Pell in Goblin Woods'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('criterion 26: with more than three taken quests, "+1 more", '
      'and a tap opens the Quests tab', (t) async {
    await pumpGame(
      t,
      prepare: with_(done: ['odda_goblins'], taken: camp),
    );
    expect(
      [for (final q in camp) line(q).evaluate().length].reduce((a, b) => a + b),
      3,
    );
    expect(inCard(find.text('+1 more')), findsOneWidget);
    await t.tap(card);
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('quest-log-wen_perch')), findsOneWidget);
  });

  testWidgets('criterion 27: with no quest taken, the card names the first '
      'person with an offered quest and their place', (t) async {
    await pumpGame(t);
    expect(inCard(find.text('Odda has work for you at Camp')), findsOneWidget);
  });

  testWidgets('criterion 27: Pell, once the Camp quests are done', (t) async {
    await pumpGame(t, prepare: with_(done: ['odda_goblins', ...camp]));
    expect(
      inCard(find.text('Pell has work for you in Goblin Woods')),
      findsOneWidget,
    );
  });

  final allButJory = [
    for (final id in [
      'odda_goblins',
      ...camp,
      'pell_hides',
      'garrow_blade',
      'garrow_vest',
      'marta_skewers',
      'pell_brutes',
      'pell_bear',
      'odda_graveyard',
      'aldous_guard',
      'aldous_cloth',
      'garrow_shield',
      'odda_king',
    ])
      id,
  ];

  testWidgets('criterion 28: a person at a hidden place is not named', (
    t,
  ) async {
    await pumpGame(t, prepare: with_(done: allButJory));
    expect(inCard(find.textContaining('Jory')), findsNothing);
  });

  testWidgets('criterion 28: once the cove is revealed, Jory is named', (
    t,
  ) async {
    await pumpGame(
      t,
      prepare: (s) {
        with_(done: allButJory)(s);
        s.revealed.add('smugglers_cove');
      },
    );
    expect(
      inCard(find.text("Jory Tarr has work for you in Smugglers' Cove")),
      findsOneWidget,
    );
  });

  // Spec 0025 §2.9, criteria 34-36: the end words come from the data.
  testWidgets('criterion 29: with every quest done, the end words', (t) async {
    await pumpGame(t, prepare: with_(done: [...game.data.quests.keys]));
    expect(
      inCard(
        find.text('The dragon is dead, and the lands are quiet. For now.'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('The north will need you'), findsNothing);
  });

  testWidgets('with chapter 1 done, Maud has work in Grey Moor (spec 0025 '
      'criterion 32)', (t) async {
    await pumpGame(t, prepare: with_(done: [...allButJory, 'jory_bass']));
    expect(
      inCard(find.text('Maud has work for you in Grey Moor')),
      findsOneWidget,
    );
  });

  testWidgets('criterion 30: the quest card shows for a save that hid Next '
      'goal, and Settings has no switch for it', (t) async {
    await pumpGame(t, hidNextGoal: true);
    expect(card, findsOneWidget);
    await openSettings(t);
    expect(find.byKey(const ValueKey('show-quest-card')), findsNothing);
    expect(find.text('Show the quest card'), findsNothing);
    expect(find.textContaining('Next goal'), findsNothing);
  });

  testWidgets('criterion 31: nothing on Now shows a Next goal line', (t) async {
    await pumpGame(t, level: 5);
    expect(find.byKey(const ValueKey('next-goal')), findsNothing);
    expect(find.text('Next goal'), findsNothing);
  });
}
