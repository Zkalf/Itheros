import 'package:flutter/material.dart';

import '../game_controller.dart';
import 'item_card.dart';
import 'labels.dart';
import 'theme.dart';

/// Opens the sheet for doll slot [slot] (spec 0008 amendment 3).
Future<void> showSlotSheet(
  BuildContext context,
  GameController c,
  String slot,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => ListenableBuilder(
    // Stays current if steps sync while it is open.
    listenable: c,
    builder: (sheet, _) => SlotSheet(controller: c, slot: slot, host: context),
  ),
);

/// One slot, empty or not: what's worn there with its stats and Unequip, and
/// every bag item that fits with its stat change and Equip or Swap into this
/// slot.
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
    final fits =
        [
          for (final key in s.inventory.keys)
            if (game.slotsFor(key).contains(slot)) key,
        ]..sort((a, b) {
          final byScore = data.scoreOf(b).compareTo(data.scoreOf(a));
          return byScore != 0 ? byScore : a.compareTo(b);
        });

    // An item's name, in the style of a name (spec 0014 §2.2).
    Text name(String key) => Text(
      labels.plain(key),
      style: nameStyle(context)?.copyWith(color: itemColour(data, key)),
    );

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
              title: Text(
                _heading(labels, kind),
                key: const ValueKey('sheet-title'),
                style: text.titleLarge,
              ),
            ),
            if (worn != null)
              ListTile(
                key: const ValueKey('sheet-worn'),
                title: name(worn),
                // The base stats, then each bonus stat on its own line, as
                // on the item card (spec 0009 amendment 2).
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(labels.bonus(data.baseStatsOf(worn)).join(' · ')),
                    for (final r in data.bonusRolls(worn))
                      Text(
                        labels.bonusRoll(r),
                        style: TextStyle(color: itemColour(data, worn)),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  showItemCard(host, c, worn, wornIn: slot);
                },
                trailing: sheetButton(
                  context,
                  host,
                  const ValueKey('sheet-unequip'),
                  'Unequip',
                  () => c.unequip(slot),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('From your bag', style: headingStyle(context)),
            ),
            if (fits.isEmpty)
              const ListTile(
                key: ValueKey('sheet-none'),
                title: Text('Nothing in your bag fits here yet.'),
              ),
            for (final key in fits) _option(context, labels, key, name(key)),
          ],
        ),
      ),
    );
  }

  /// "Head"; where several slots share a kind, "Ring 1 · rings fit here".
  String _heading(Labels labels, String kind) {
    final shared = controller.game.data.slotsOfKind(kind).length > 1;
    final number = slot.replaceAll(RegExp(r'\D'), '');
    final name = number.isEmpty
        ? labels.slot(slot)
        : '${labels.slot(slot)} $number';
    return shared
        ? '$name · ${labels.slot(kind).toLowerCase()}s fit here'
        : name;
  }

  /// A bag item that fits: its change in stats, what else it takes off (a
  /// two-hander, a shield), and Equip or Swap into this slot.
  Widget _option(BuildContext context, Labels labels, String key, Text name) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    final off = [
      for (final id in game.displaced(s, key, slot))
        labels.plain(s.equipment[id]!),
    ];
    return ListTile(
      title: name,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labels.delta(game.compare(s, key, slot)),
            key: ValueKey('sheet-delta-$key'),
          ),
          if (off.isNotEmpty)
            Text(
              'Takes off your ${off.join(' and ')}',
              key: ValueKey('sheet-off-$key'),
            ),
        ],
      ),
      onTap: () {
        Navigator.of(context).pop();
        showItemCard(host, c, key);
      },
      trailing: sheetButton(
        context,
        host,
        ValueKey('sheet-equip-$key'),
        off.isEmpty ? 'Equip' : 'Swap',
        () => c.equip(key, slot: slot),
      ),
    );
  }
}
