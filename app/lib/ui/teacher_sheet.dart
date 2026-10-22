import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'labels.dart';

/// Opens [profession]'s teacher (spec 0010 §6). Talking to a teacher tells
/// the tips waiting, so they are told as the sheet opens.
Future<void> showTeacher(
  BuildContext context,
  GameController c,
  String profession,
) async {
  if (c.game.tipsWaiting(c.state, profession).isNotEmpty) {
    await c.talk(profession);
  }
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        TeacherSheet(controller: c, profession: profession, host: context),
  );
}

/// "Hilde, the miner".
String teacherName(ProfessionDef p) => '${p.teacher.name}, ${p.teacher.title}';

/// A teacher's line and Learn, or once learned their line, a line that
/// follows the profession level, and the tips told so far (spec 0010 §6).
class TeacherSheet extends StatelessWidget {
  const TeacherSheet({
    super.key,
    required this.controller,
    required this.profession,
    required this.host,
  });

  final GameController controller;
  final String profession;

  /// The screen behind the sheet, for messages.
  final BuildContext host;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final c = controller;
      final game = c.game;
      final s = c.state;
      final p = game.data.professions[profession]!;
      final labels = Labels(game.data);
      final text = Theme.of(context).textTheme;
      final learned = s.learned.contains(profession);
      final level = game.professionLevel(s, profession);
      final next = p.tips.where((t) => t.level > level).firstOrNull;
      return SafeArea(
        child: SingleChildScrollView(
          key: const ValueKey('teacher-sheet'),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(teacherName(p), style: text.titleLarge),
              const SizedBox(height: 8),
              if (!learned) ...[
                Text('${p.teacher.name} teaches ${p.name}.'),
                const SizedBox(height: 12),
                FilledButton(
                  key: ValueKey('learn-$profession'),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(host);
                    try {
                      await c.learn(profession);
                    } on ActivityError catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.message)),
                      );
                    }
                  },
                  child: Text('Learn ${p.name}'),
                ),
              ] else ...[
                Text(
                  '"${p.teacher.learnLine}"',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 8),
                Text(
                  '${p.name} $level · ${p.tierAt(level).name}. '
                  '${next == null ? "You've heard all my tips." : 'Next tip at ${p.name} ${next.level}.'}',
                ),
                for (final t in p.tips)
                  if (s.tips.contains(t.id)) TipCard(tip: t, labels: labels),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// A tip as the sheet and the Lore tab show it.
class TipCard extends StatelessWidget {
  const TipCard({super.key, required this.tip, required this.labels});

  final TipDef tip;
  final Labels labels;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(top: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tip.title, style: text.titleMedium),
            Text('About the ${labels.enemy(tip.enemy)}', style: text.bodySmall),
            const SizedBox(height: 8),
            Text(tip.text),
          ],
        ),
      ),
    );
  }
}
