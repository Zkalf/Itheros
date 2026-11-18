import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'images.dart';
import 'labels.dart';
import 'theme.dart';

/// The quests of [giver] on their sheet (spec 0024 §3.3), in data order: an
/// offered quest with its ask, task, reward and Take; a taken quest with its
/// count; a ready one with Hand in. A quest handed in while the sheet is open
/// shows its thanks and reward in its place until the sheet closes.
class QuestPart extends StatefulWidget {
  const QuestPart({super.key, required this.controller, required this.giver});

  final GameController controller;

  /// A person's id, or a teacher's profession id.
  final String giver;

  @override
  State<QuestPart> createState() => _QuestPartState();
}

class _QuestPartState extends State<QuestPart> {
  /// Handed in while this sheet is open.
  final _handedIn = <String>[];

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final game = c.game;
      final s = c.state;
      final labels = Labels(game.data, s.character);
      final shown = [
        for (final q in game.questsOf(widget.giver))
          if (_handedIn.contains(q.id) ||
              switch (game.questState(s, q.id)) {
                QuestState.offered || QuestState.taken => true,
                QuestState.closed || QuestState.done => false,
              })
            q,
      ];
      if (shown.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [for (final q in shown) _quest(context, q, labels)],
      );
    },
  );

  Widget _quest(BuildContext context, QuestDef q, Labels labels) {
    final c = widget.controller;
    final game = c.game;
    final s = c.state;
    final text = Theme.of(context).textTheme;
    const italic = TextStyle(fontStyle: FontStyle.italic);
    final state = game.questState(s, q.id);
    final ready = game.questReady(s, q.id);
    final children = <Widget>[
      Row(
        children: [
          if (ready || state == QuestState.offered)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: QuestMarkIcon(
                ready ? QuestMark.ready : QuestMark.offer,
                size: 20,
              ),
            ),
          Expanded(child: Text(q.title, style: text.titleMedium)),
        ],
      ),
      const SizedBox(height: 8),
      if (_handedIn.contains(q.id)) ...[
        Text(
          '"${labels.fill(q.thanks)}"',
          key: ValueKey('quest-thanks-${q.id}'),
          style: italic,
        ),
        const SizedBox(height: 8),
        Text(labels.questReward(q.id, plus: true), style: text.titleSmall),
      ] else if (state == QuestState.offered) ...[
        Text('"${labels.fill(q.ask)}"', style: italic),
        const SizedBox(height: 8),
        Text(q.task.words),
        Text(
          labels.questReward(q.id),
          key: ValueKey('quest-reward-${q.id}'),
          style: text.bodySmall,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            key: ValueKey('quest-take-${q.id}'),
            onPressed: () => c.takeQuest(q.id),
            child: const Text('Take'),
          ),
        ),
      ] else if (ready) ...[
        Text(q.task.words),
        if (q.task.kind == TaskKind.bring)
          Text(_gives(q), style: text.bodySmall),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton(
            key: ValueKey('quest-hand-in-${q.id}'),
            onPressed: () async {
              if (await c.handIn(q.id) && mounted) {
                setState(() => _handedIn.add(q.id));
              }
            },
            child: const Text('Hand in'),
          ),
        ),
      ] else ...[
        Text(q.task.words),
        Text(
          '${game.questCount(s, q.id)} of ${q.task.count}',
          key: ValueKey('quest-count-${q.id}'),
          style: text.bodySmall,
        ),
      ],
    ];
    return Card(
      key: ValueKey('quest-${q.id}'),
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  /// "Gives 15 goblin hides": the task words from the count on.
  String _gives(QuestDef q) {
    final words = q.task.words;
    final at = words.indexOf(RegExp(r'\d'));
    return 'Gives ${at < 0 ? words : words.substring(at)}';
  }
}

/// The gold "!" (a quest to take) or "?" (a quest to hand in): flat icons
/// that Claude draws (spec 0024 §3.2, §3.6).
class QuestMarkIcon extends StatelessWidget {
  const QuestMarkIcon(this.mark, {super.key, this.size = 24});

  final QuestMark mark;
  final double size;

  @override
  Widget build(BuildContext context) => switch (mark) {
    QuestMark.offer => DrawnIcon(
      'quest_offer',
      fallback: Icons.priority_high,
      size: size,
      color: Quiet.gold,
    ),
    QuestMark.ready => DrawnIcon(
      'quest_ready',
      fallback: Icons.question_mark,
      size: size,
      color: Quiet.gold,
    ),
  };
}
