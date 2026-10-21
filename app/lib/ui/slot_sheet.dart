import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'away_summary_card.dart';
import 'item_card.dart';
import 'labels.dart';

/// Opens the sheet for doll slot [slot] (spec 0008 amendment 3).
Future<void> showSlotSheet(
  BuildContext context,
  GameController c,
  String slot,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => SlotSheet(controller: c, slot: slot, host: context),
);

/// One slot, empty or not: what's worn there with Unequip, and every bag item
/// that fits with its stat change and Equip or Swap into this slot.
class SlotSheet extends StatelessWidget {
  const SlotSheet({
    super.key,
    required this.controller,
    required this.slot,
    required this.host,
  });

  final GameController controller;
  final String slot;

  /// The screen behind the sheet, for messages and the item card.
  final BuildContext host;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final game = c.game;
    final data = game.data;
    final s = c.state;
    final labels = Labels(data);
    final text = Theme.of(context).textTheme;
    final worn = s.equipment[slot];
    final kind = data.gearSlots.firstWhere((g) => g.id == slot).kind;
    final shared = data.slotsOfKind(kind).length > 1;
    final fits =
        [
          for (final key in s.inventory.keys)
            if (game.slotsFor(key).contains(slot)) key,
        ]..sort((a, b) {
          final byScore = data.scoreOf(b).compareTo(data.scoreOf(a));
          return byScore != 0 ? byScore : a.compareTo(b);
        });

    Text name(String key) {
      final q = data.qualityOf(key);
      return Text(
        labels.plain(key),
        style: TextStyle(
          color: q == data.qualities.first ? null : qualityColour(q),
        ),
      );
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.8,
        ),
        child: ListView(
          key: const ValueKey('slot-sheet'),
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          children: [
            ListTile(
              // "Ring 1" where a kind has several slots, else "Head".
              title: Text(
                shared
                    ? '${labels.slot(slot)} ${slot.replaceAll(RegExp(r'\D'), '')}'
                    : labels.slot(slot),
                key: const ValueKey('sheet-title'),
                style: text.titleLarge,
              ),
              subtitle: shared ? Text('${labels.slot(kind)}s fit here') : null,
            ),
            if (worn != null)
              ListTile(
                title: name(worn),
                subtitle: Text(labels.bonus(data.bonusOf(worn)).join(' · ')),
                onTap: () {
                  Navigator.of(context).pop();
                  showItemCard(host, c, worn, wornIn: slot);
                },
                trailing: _button(
                  context,
                  const ValueKey('sheet-unequip'),
                  'Unequip',
                  () => c.unequip(slot),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('From your bag', style: text.titleSmall),
            ),
            if (fits.isEmpty)
              const ListTile(
                key: ValueKey('sheet-none'),
                title: Text('Nothing in your bag fits here yet.'),
              ),
            for (final key in fits)
              ListTile(
                title: name(key),
                subtitle: Text(
                  labels.delta(game.compare(s, key, slot)),
                  key: ValueKey('sheet-delta-$key'),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  showItemCard(host, c, key);
                },
                trailing: _button(
                  context,
                  ValueKey('sheet-equip-$key'),
                  worn == null ? 'Equip' : 'Swap',
                  () => c.equip(key, slot: slot),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _button(
    BuildContext context,
    Key key,
    String label,
    Future<void> Function() action,
  ) => FilledButton.tonal(
    key: key,
    onPressed: () async {
      final messenger = ScaffoldMessenger.of(host);
      Navigator.of(context).pop();
      try {
        await action();
      } on ActivityError catch (e) {
        messenger.showSnackBar(SnackBar(content: Text(e.message)));
      }
    },
    child: Text(label),
  );
}
