import 'package:flutter/material.dart';

import '../sync/away_summary.dart';
import 'labels.dart';

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
    final s = summary;
    final lines = <String>[
      'You walked ${fmt(s.walked)} steps.',
      if (s.boostUsed > 0) '${fmt(s.boostUsed)} banked steps boosted them.',
      if (s.fightsWon.isNotEmpty)
        'Won: ${labels.counts(s.fightsWon, labels.enemy)}.',
      if (s.fightsLost > 0) 'Lost ${s.fightsLost} fight(s).',
      if (s.itemsGained.isNotEmpty)
        'Gained: ${labels.counts(s.itemsGained, labels.item)}.',
      for (final l in s.levelsReached) 'Reached level $l!',
      for (final a in s.achievements) 'Achievement: ${labels.achievement(a)}.',
      for (final e in s.activitiesEnded) '${labels.endReason(e)}.',
      if (s.banked > 0) '${fmt(s.banked)} steps went to the bank.',
      if (s.lost > 0) '${fmt(s.lost)} steps were lost: the bank was full.',
    ];
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
                child: Text(l),
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
