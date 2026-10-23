import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../sync/away_summary.dart';
import 'controller_scope.dart';
import 'images.dart';
import 'journal_screen.dart';
import 'labels.dart';
import 'socket.dart';
import 'theme.dart';

/// The colour of [q] (`#rrggbb` in the data).
Color qualityColour(QualityDef q) =>
    Color(0xff000000 | int.parse(q.colour.substring(1), radix: 16));

/// [line] split so that gear better than common, "Hide vest (Rare)", is in
/// its quality colour (spec 0005 amendment 3).
List<TextSpan> reportSpans(String line, GameData data) {
  final better = {for (final q in data.qualities.skip(1)) q.name: q};
  if (better.isEmpty) return [TextSpan(text: line)];
  final names = better.keys.map(RegExp.escape).join('|');
  // An item name runs from the last ",", ":" or "." up to its quality.
  final pattern = RegExp(r'([^,:.]+?) \((' + names + r')\)');
  final spans = <TextSpan>[];
  var at = 0;
  for (final m in pattern.allMatches(line)) {
    final name = m.group(1)!;
    final start = m.start + name.length - name.trimLeft().length;
    if (start > at) spans.add(TextSpan(text: line.substring(at, start)));
    spans.add(
      TextSpan(
        text: line.substring(start, m.end),
        style: TextStyle(color: qualityColour(better[m.group(2)]!)),
      ),
    );
    at = m.end;
  }
  if (at < line.length) spans.add(TextSpan(text: line.substring(at)));
  return spans;
}

/// One report line, with quality colours.
Widget reportLine(String line, Labels labels) =>
    Text.rich(TextSpan(children: reportSpans(line, labels.data)));

/// The big moments of a report, shown as banners above its lines (spec 0004
/// amendment 3): levels reached, achievements, what was learned about
/// monsters (spec 0009 §7), then profession news and the lake's (spec 0011
/// §3.2, §4, §6). Each comes with the thing that it names, or null for news
/// of text only: levels, lore notes, profession levels and the sea chart
/// (spec 0014 §4.2).
List<(Thing?, String)> reportNews(AwaySummary s, Labels labels) => [
  for (final l in s.levelsReached) (null, 'Reached level $l!'),
  for (final a in s.achievements)
    (
      AchievementThing(a, earned: true),
      'Achievement unlocked: ${labels.achievement(a)}',
    ),
  for (final n in s.lore) (null, labels.loreFound(n)),
  for (final e in s.learned) (MonsterThing(e), labels.weaknessLearned(e)),
  for (final e in s.slayers) (MonsterThing(e), labels.slayerEarned(e)),
  // Profession news (spec 0010 §2.2, §5.1, §7.2-7.3).
  for (final (p, l) in s.professionLevels) (null, labels.professionLevel(p, l)),
  for (final f in s.finds) (ItemThing(f), labels.rareFound(f)),
  for (final (f, weight) in s.trophyFish)
    (ItemThing(f), labels.rareFound(f, weight: weight)),
  // A reroll shows the item as it is now.
  for (final (a, b) in s.rerolls) (ItemThing(b), labels.rerollNews(a, b)),
  for (final area in s.charts) (null, labels.bottle(revealed: area)),
  for (final item in s.bottleItems)
    (ItemThing(item), labels.bottle(item: item)),
  for (final key in s.chests) (ItemThing(key), labels.chest(key)),
];

List<Widget> reportBanners(AwaySummary s, Labels labels) => [
  for (final (thing, text) in reportNews(s, labels))
    ReportBanner(text: text, thing: thing),
];

/// A highlighted line on deep teal (spec 0014 §2.1). With a [thing], it
/// starts with its picture in a 32 dp socket (§2.3, §4.2); gear keeps the
/// ring of its quality.
class ReportBanner extends StatelessWidget {
  const ReportBanner({super.key, required this.text, this.thing});

  final String text;
  final Thing? thing;

  @override
  Widget build(BuildContext context) {
    final data = ControllerScope.of(context).game.data;
    final thing = this.thing;
    final picture = thing == null
        ? null
        : ImageScope.of(context).pictureOf(data, thing);
    return Container(
      key: const ValueKey('report-banner'),
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.fromLTRB(picture == null ? 12 : 6, 6, 12, 6),
      decoration: BoxDecoration(
        color: Quiet.deepTeal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Quiet.teal.withValues(alpha: .4)),
      ),
      child: ConstrainedBox(
        // A banner of text only is as tall as a banner with a socket.
        constraints: const BoxConstraints(minHeight: 32),
        child: Row(
          children: [
            if (picture != null) ...[
              if (thing case ItemThing(key: final item))
                PictureSocket.item(data, item, picture: picture, size: 32)
              else
                PictureSocket(picture: picture, size: 32),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The lines of one report, as the card and the journal show them.
List<String> reportLines(AwaySummary s, Labels labels) => [
  'You walked ${plural(s.walked, 'step')}.',
  if (s.boostUsed > 0)
    'Used ${plural(s.boostUsed, 'step')} from your step bank.',
  for (final a in s.actions) ...labels.actionLines(a),
  // Spec 0011 §3.4, §5.4.
  for (final (item, weight, was) in s.records) labels.record(item, weight, was),
  for (final (key, left) in s.mealsEaten) labels.mealEaten(key, left),
  for (final meal in s.mealsOut) labels.mealsOut(meal),
  if (s.banked > 0) 'Saved ${plural(s.banked, 'step')} in your step bank.',
  if (s.lost > 0)
    'Your step bank was full, so ${plural(s.lost, 'step')} '
        'could not be saved.',
];

/// "While you were away": opens by itself when something happened, after
/// any level-up cards, and looks like a journal entry (spec 0004 amendment 2).
class AwayScreen extends StatelessWidget {
  const AwayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final labels = Labels(c.game.data);
    final text = Theme.of(context).textTheme;
    final summary = c.awaySummary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('While you were away'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(gutter),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.journal.isNotEmpty)
                      Text.rich(
                        numberSpan(journalTime(c.journal.first.started, c.now)),
                        style: text.titleMedium,
                      ),
                    const SizedBox(height: 8),
                    if (summary != null) ...reportBanners(summary, labels),
                    if (summary != null)
                      for (final l in reportLines(summary, labels))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: reportLine(l, labels),
                        ),
                  ],
                ),
              ),
            ),
            // The footnote and Continue stand on a plate (spec 0014 §2.2).
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Steps can reach Health Connect a minute late, so this '
                      'report keeps updating for a couple of minutes. It '
                      'stays in your journal.',
                      style: text.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('away-continue'),
                      onPressed: c.dismissAwaySummary,
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
