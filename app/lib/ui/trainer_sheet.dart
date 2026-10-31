import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'labels.dart';
import 'theme.dart';

/// "Ysolde, the Guild trainer".
String trainerName(TrainerDef t) => '${t.name}, ${t.title}';

/// Opens the Guild trainer (spec 0015 §2.7).
Future<void> showTrainer(BuildContext context, GameController c) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TrainerSheet(controller: c, host: context),
    );

/// The trainer's greeting, the points left and the reset, with its price
/// (spec 0015 §2.6, §2.7).
class TrainerSheet extends StatefulWidget {
  const TrainerSheet({super.key, required this.controller, required this.host});

  final GameController controller;

  /// The screen behind the sheet, for messages.
  final BuildContext host;

  @override
  State<TrainerSheet> createState() => _TrainerSheetState();
}

class _TrainerSheetState extends State<TrainerSheet> {
  /// Set after a reset: the trainer's line for it.
  var _done = false;

  Future<void> _reset(TrainerDef trainer) async {
    final c = widget.controller;
    final messenger = ScaffoldMessenger.of(widget.host);
    final go = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(trainer.confirm),
        actions: [
          TextButton(
            style: ghostButton,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Forget'),
          ),
        ],
      ),
    );
    if (go != true) return;
    try {
      await c.resetTalents();
      if (mounted) setState(() => _done = true);
    } on ActivityError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final game = c.game;
      final s = c.state;
      final trainer = game.data.trainer;
      final labels = Labels(game.data, s.character);
      final text = Theme.of(context).textTheme;
      const italic = TextStyle(fontStyle: FontStyle.italic);
      final early = game.level(s) < game.data.talentPointsFrom;
      final left = game.talentPointsLeft(s);
      final price = game.resetPriceNow(s);
      final ranks = s.talents.values.any((r) => r > 0);
      return SafeArea(
        child: SingleChildScrollView(
          key: const ValueKey('trainer-sheet'),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trainerName(trainer), style: text.titleLarge),
              const SizedBox(height: 8),
              Text(
                '"${labels.fill(_done ? trainer.done : trainer.greeting)}"',
                style: italic,
              ),
              const SizedBox(height: 8),
              if (early)
                Text('"${labels.fill(trainer.early)}"', style: italic)
              else ...[
                Text(switch (left) {
                  0 => 'No talent points left.',
                  1 => '1 talent point left.',
                  _ => '$left talent points left.',
                }),
                if (ranks) ...[
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const ValueKey('reset-talents'),
                    style: slateButton,
                    onPressed: () => _reset(trainer),
                    child: Text(
                      price == 0
                          ? 'Forget my talents'
                          : 'Forget my talents · ${_grouped(price)} steps',
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      );
    },
  );
}

String _grouped(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');
