import 'package:flutter/material.dart';

import 'away_summary_card.dart';
import 'controller_scope.dart';
import 'labels.dart';

const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// "Today 14:05", "Yesterday 18:30" or "Fri 16 Oct 09:12" (spec 0004
/// decision 4).
String journalTime(DateTime t, DateTime now) {
  String two(int n) => n.toString().padLeft(2, '0');
  final time = '${two(t.hour)}:${two(t.minute)}';
  final day = DateTime(t.year, t.month, t.day);
  final today = DateTime(now.year, now.month, now.day);
  if (day == today) return 'Today $time';
  if (day == DateTime(today.year, today.month, today.day - 1)) {
    return 'Yesterday $time';
  }
  return '${_days[t.weekday - 1]} ${t.day} ${_months[t.month - 1]} $time';
}

/// The newest reports, newest first (spec 0004 §2).
class JournalScreen extends StatelessWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final labels = Labels(c.game.data);
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Journal')),
      body: c.journal.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No reports yet. Pick something to do, go for a walk, and '
                'what happened shows up here.',
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final e in c.journal)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${journalTime(e.started, c.now)}'
                            '${e.testWalk ? ' (test walk)' : ''}',
                            style: text.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          ...reportBanners(e.summary, labels),
                          for (final l in reportLines(e.summary, labels))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: reportLine(l, labels),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
