// Spec 0017 (achievements rework), plan 0021 M3: the tests of criteria
// 26-30, the goal texts of amendments 2 and 3, and the report of lost
// achievements (§5, criterion 22 on the screen).
// - The view is tall, so the list builds each card of the 30.
// - A save that loads with an earned achievement whose criterion it does not
//   meet loses that achievement in Game.load (M1). These tests check that the
//   report of the open shows it.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:walkingrpg/sync/away_summary.dart';
import 'package:walkingrpg/ui/labels.dart';

import 'images_test.dart' show assetOf, diskImages, imagesIn;
import 'ui_test.dart' show game, now, openAchievements, pumpGame;

Finder card(String id) => find.byKey(ValueKey('achievement-$id'));

Finder inCard(String id, Finder f) =>
    find.descendant(of: card(id), matching: f);

Future<void> tallView(WidgetTester t) async {
  t.view.physicalSize = const Size(1080, 14000);
  await t.pumpAndSettle();
}

void main() {
  final data = game.data;
  final labels = Labels(data);

  group('spec 0017 §6: the Achievements screen', () {
    testWidgets('criterion 26: the headings Early, Mid and Late, in this '
        'order, each above the cards of its stage', (t) async {
      await pumpGame(t);
      await openAchievements(t);
      await tallView(t);
      double top(Finder f) => t.getTopLeft(f).dy;
      final heading = {
        for (final s in AchievementStage.values)
          s: find.byKey(ValueKey('achievement-stage-${s.name}')),
      };
      for (final MapEntry(key: s, value: f) in heading.entries) {
        expect(f, findsOneWidget, reason: s.name);
        expect(
          find.descendant(
            of: f,
            matching: find.text(switch (s) {
              AchievementStage.early => 'Early',
              AchievementStage.mid => 'Mid',
              AchievementStage.late => 'Late',
            }),
          ),
          findsOneWidget,
        );
      }
      final early = top(heading[AchievementStage.early]!);
      final mid = top(heading[AchievementStage.mid]!);
      final late = top(heading[AchievementStage.late]!);
      expect(early, lessThan(mid));
      expect(mid, lessThan(late));
      for (final a in data.achievements.values) {
        final y = top(card(a.id));
        final (from, to) = switch (a.stage) {
          AchievementStage.early => (early, mid),
          AchievementStage.mid => (mid, late),
          AchievementStage.late => (late, double.infinity),
        };
        expect(y, greaterThan(from), reason: '${a.id} under ${a.stage.name}');
        expect(y, lessThan(to), reason: '${a.id} under ${a.stage.name}');
      }
    });

    testWidgets('criterion 27: each card shows "Reward: …", for each kind of '
        'reward', (t) async {
      await pumpGame(t);
      await openAchievements(t);
      await tallView(t);
      for (final a in data.achievements.values) {
        expect(
          inCard(a.id, find.textContaining(RegExp(r'^Reward: .+'))),
          findsOneWidget,
          reason: a.id,
        );
      }
      for (final (id, reward) in [
        ('first_steps', 'Reward: +250 step bank cap'),
        ('the_long_road', 'Reward: +1,500 step bank cap'),
        ('master_smith', 'Reward: Mithril helm (Rare)'),
        ('champion', 'Reward: Star-diamond ring (Epic)'),
        ('goblin_slayer_1', 'Reward: +4 Attack'),
        ('wyvern_hunter', 'Reward: +130 HP'),
        ('bear_hunter', 'Reward: +4% Crit'),
        ('chieftains_bane', 'Reward: +1 queue slot'),
      ]) {
        expect(inCard(id, find.text(reward)), findsOneWidget, reason: id);
      }
    });

    testWidgets('criterion 28: a feat card shows the word "Feat"; a milestone '
        'card does not', (t) async {
      await pumpGame(t);
      await openAchievements(t);
      await tallView(t);
      for (final a in data.achievements.values) {
        expect(
          inCard(a.id, find.text('Feat')),
          a.kind == AchievementKind.feat ? findsOneWidget : findsNothing,
          reason: a.id,
        );
      }
    });

    testWidgets('criterion 29: an earned achievement without a picture shows '
        'its placeholder; one with a picture shows the picture', (t) async {
      final (c, _) = await pumpGame(t, images: diskImages);
      // Earned after the load, so the load does not check them.
      c.state.achievements.addAll(['lucky_find', 'first_steps']);
      await t.pump();
      expect(diskImages.has('achievements/lucky_find'), isFalse);
      expect(diskImages.has('achievements/first_steps'), isTrue);
      await openAchievements(t);
      await tallView(t);
      expect(imagesIn(t, card('lucky_find')), [
        assetOf('placeholders/generic'),
      ]);
      expect(imagesIn(t, card('first_steps')), [
        assetOf('achievements/first_steps'),
      ]);
    });

    testWidgets('amendments 2 and 3: catches name the fishing spot', (t) async {
      await pumpGame(t);
      await openAchievements(t);
      await tallView(t);
      expect(
        inCard('deep_waters', find.text('Catch 500 fish at Cold tarn')),
        findsOneWidget,
      );
      expect(
        inCard('angler', find.text('Catch 5 fish at Lake shore')),
        findsOneWidget,
      );
      // Ores are not catches.
      expect(
        inCard('prospector', find.text('Gather 30 × Copper ore')),
        findsOneWidget,
      );
    });
  });

  group('spec 0017 criterion 30: the banner names the reward', () {
    test('one text for each kind of reward', () {
      expect(
        labels.achievementUnlocked('first_steps'),
        'Achievement unlocked: First Steps. Reward: +250 step bank cap',
      );
      expect(
        labels.achievementUnlocked('champion'),
        'Achievement unlocked: Champion. Reward: Star-diamond ring (Epic)',
      );
      expect(
        labels.achievementUnlocked('goblin_slayer_1'),
        'Achievement unlocked: Goblin Slayer I. Reward: +4 Attack',
      );
      expect(
        labels.achievementUnlocked('chieftains_bane'),
        "Achievement unlocked: Chieftain's Bane. Reward: +1 queue slot",
      );
    });
  });

  group('spec 0017 §5: the report names each lost achievement', () {
    test('what the player lost, for each kind of reward', () {
      final ring = data.keyFor('star_diamond_ring', 'epic');
      for (final (event, text) in [
        (
          const AchievementLost('smith'),
          'Achievement lost: Smith. Lost: +500 step bank cap.',
        ),
        (
          const AchievementLost('smith', bankSteps: 1200),
          'Achievement lost: Smith. Lost: +500 step bank cap and 1,200 steps '
              'from your step bank.',
        ),
        (
          AchievementLost('champion', item: ring),
          'Achievement lost: Champion. Lost: Star-diamond ring (Epic).',
        ),
        (
          const AchievementLost('champion'),
          'Achievement lost: Champion. Lost: nothing more, the Star-diamond '
              'ring (Epic) was gone already.',
        ),
        (
          const AchievementLost('goblin_slayer_1'),
          'Achievement lost: Goblin Slayer I. Lost: +4 Attack.',
        ),
        (
          const AchievementLost('chieftains_bane'),
          "Achievement lost: Chieftain's Bane. Lost: +1 queue slot.",
        ),
        (
          const AchievementLost('chieftains_bane', actions: 1),
          "Achievement lost: Chieftain's Bane. Lost: +1 queue slot and 1 "
              'waiting action.',
        ),
        (
          const AchievementLost('chieftains_bane', actions: 2),
          "Achievement lost: Chieftain's Bane. Lost: +1 queue slot and 2 "
              'waiting actions.',
        ),
      ]) {
        expect(labels.achievementLost(event), text);
      }
    });

    test('the journal keeps the lost achievements', () {
      final ring = data.keyFor('star_diamond_ring', 'epic');
      final s = AwaySummary(
        lostAchievements: [
          const AchievementLost('smith', bankSteps: 40),
          AchievementLost('champion', item: ring),
          const AchievementLost('chieftains_bane', actions: 2),
        ],
      );
      expect(s.isEmpty, isFalse, reason: 'no steps, but news');
      expect(s.isEventful, isTrue);
      final back = AwaySummary.fromJson(s.toJson());
      expect(
        [for (final l in back.lostAchievements) labels.achievementLost(l)],
        [for (final l in s.lostAchievements) labels.achievementLost(l)],
      );
      // Entries from before spec 0017 have none.
      final old = s.toJson()..remove('lostAchievements');
      expect(AwaySummary.fromJson(old).lostAchievements, isEmpty);
      // Two reports add up.
      expect((s + s).lostAchievements, hasLength(6));
    });

    testWidgets('the load loses them, and the away screen and the journal '
        'name them, with no steps walked', (t) async {
      final ring = data.keyFor('star_diamond_ring', 'epic');
      late int over;
      final (c, _) = await pumpGame(
        t,
        prepare: (s) {
          // Earned, but the save meets none of these criteria.
          s
            ..achievements.addAll(['smith', 'goblin_slayer_1', 'champion'])
            ..inventory[ring] = 1;
          s.bank = game.bankCap(s);
          over = game
              .load(s)
              .events
              .whereType<AchievementLost>()
              .firstWhere((e) => e.id == 'smith')
              .bankSteps;
        },
      );
      expect(over, greaterThan(0), reason: 'the test needs lost bank steps');
      await t.pump();
      expect(c.state.achievements, isNot(contains('smith')));
      final texts = [
        'Achievement lost: Smith. Lost: +500 step bank cap and '
            '${fmt(over)} steps from your step bank.',
        'Achievement lost: Goblin Slayer I. Lost: +4 Attack.',
        'Achievement lost: Champion. Lost: Star-diamond ring (Epic).',
      ];
      final banners = find.byKey(const ValueKey('report-banner'));
      Finder banner(String text) =>
          find.descendant(of: banners, matching: find.text(text));
      expect(c.awaySummary, isNotNull, reason: 'the away screen opens');
      for (final text in texts) {
        expect(banner(text), findsOneWidget, reason: text);
      }

      await t.tap(find.byKey(const ValueKey('away-continue')));
      await t.pump();
      await t.tap(find.byKey(const ValueKey('journal-button')));
      await t.pumpAndSettle();
      for (final text in texts) {
        expect(banner(text), findsOneWidget, reason: 'journal: $text');
      }
    });

    testWidgets('the lost achievements join the report of the steps of the '
        'open, and come once', (t) async {
      final (c, source) = await pumpGame(
        t,
        location: 'goblin_woods',
        prepare: (s) => s.achievements.add('goblin_slayer_1'),
      );
      const text = 'Achievement lost: Goblin Slayer I. Lost: +4 Attack.';
      expect(c.awaySummary!.lostAchievements.map((e) => e.id), [
        'goblin_slayer_1',
      ]);
      await t.tap(find.byKey(const ValueKey('away-continue')));
      await t.pump();

      c.pause();
      source.walk(DateTime(2026, 10, 18, 10), 300);
      now = DateTime(2026, 10, 18, 11);
      await c.resume();
      await t.pump();
      expect(c.journal.first.summary.walked, 300);
      expect(
        c.journal.first.summary.lostAchievements,
        isEmpty,
        reason: 'the next return does not name them again',
      );
      expect(find.text(text), findsNothing);
    });

    testWidgets('when the sync of the open fails, the next sync that works '
        'names them, also the sync of an action', (t) async {
      final (c, _) = await pumpGame(
        t,
        location: 'goblin_woods',
        failFirstSync: true,
        prepare: (s) => s.achievements.add('goblin_slayer_1'),
      );
      expect(c.syncError, isNotNull, reason: 'the test needs a failed sync');
      expect(c.state.achievements, isNot(contains('goblin_slayer_1')));
      expect(c.awaySummary, isNull);

      await c.startActivity(const Activity.fight('goblin'));
      await t.pump();
      expect(c.awaySummary?.lostAchievements.map((e) => e.id), [
        'goblin_slayer_1',
      ]);
      expect(c.journal.first.summary.lostAchievements.map((e) => e.id), [
        'goblin_slayer_1',
      ]);
    });
  });
}
