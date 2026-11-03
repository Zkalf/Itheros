import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'labels.dart';
import 'theme.dart';

/// Asks once, then salvages every one of the bag items [keys] and says what
/// it gave (spec 0010 amendment 9, rules 4 and 6). [what] names the batch:
/// "14 Common items", "5 Bone swords". A refusal shows on [host].
Future<void> salvageAll(
  BuildContext host,
  GameController c,
  List<String> keys,
  String what,
) async {
  final messenger = ScaffoldMessenger.of(host);
  final sure = await showDialog<bool>(
    context: host,
    builder: (context) => AlertDialog(
      title: Text('Salvage $what?'),
      content: const Text('They break down into dust for good.'),
      actions: [
        TextButton(
          key: const ValueKey('salvage-all-keep'),
          style: ghostButton,
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep them'),
        ),
        TextButton(
          key: const ValueKey('salvage-all-confirm'),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Salvage'),
        ),
      ],
    ),
  );
  if (sure != true) return;
  try {
    final result = await c.salvageAll(keys);
    // The new message replaces the one on screen (#176).
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(Labels(c.game.data).salvagedAll(result))),
      );
  } on ActivityError catch (e) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(e.message)));
  }
}

/// At a forge, one "Salvage all Common (14)" button for each quality with
/// items for a batch (spec 0010 amendment 9, rule 2). Elsewhere, nothing.
class SalvageAllButtons extends StatelessWidget {
  const SalvageAllButtons({super.key, required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    if (!game.atForge(s)) return const SizedBox.shrink();
    final buttons = [
      for (final q in game.data.qualities)
        if (game.salvageAllOf(s, q.id) case final keys when keys.isNotEmpty)
          (q, keys, keys.fold(0, (n, k) => n + s.inventory[k]!)),
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (q, keys, n) in buttons)
            OutlinedButton(
              key: ValueKey('salvage-all-${q.id}'),
              onPressed: () =>
                  salvageAll(context, c, keys, plural(n, '${q.name} item')),
              child: Text('Salvage all ${q.name} ($n)'),
            ),
        ],
      ),
    );
  }
}
