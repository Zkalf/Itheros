import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../sync/away_summary.dart';
import 'labels.dart';

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

/// The lines of one report, as the card and the journal show them.
List<String> reportLines(AwaySummary s, Labels labels) => [
  'You walked ${plural(s.walked, 'step')}.',
  if (s.boostUsed > 0)
    'Your step bank added ${plural(s.boostUsed, 'extra step')}.',
  for (final a in s.actions) ...labels.actionLines(a),
  for (final l in s.levelsReached) 'Reached level $l!',
  for (final a in s.achievements) 'Achievement: ${labels.achievement(a)}.',
  if (s.banked > 0) 'Saved ${plural(s.banked, 'step')} in your step bank.',
  if (s.lost > 0)
    'Your step bank was full, so ${plural(s.lost, 'step')} '
        'could not be saved.',
];

class AwaySummaryCard extends StatelessWidget {
  const AwaySummaryCard({
    super.key,
    required this.summary,
    required this.labels,
    required this.onDismiss,
  });

  final AwaySummary summary;
  final Labels labels;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final lines = reportLines(summary, labels);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'While you were away',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final l in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: reportLine(l, labels),
              ),
            const SizedBox(height: 4),
            Text(
              'Steps can reach Health Connect a minute late, so this report '
              'keeps updating for a couple of minutes.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onDismiss, child: const Text('OK')),
            ),
          ],
        ),
      ),
    );
  }
}
