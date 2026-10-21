import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'away_summary_card.dart';
import 'labels.dart';

/// Opens the card for [item] (spec 0008 §3.5). [wornIn] is set when it was
/// tapped on the doll. An item the data no longer has (an old save) has no
/// card.
Future<void> showItemCard(
  BuildContext context,
  GameController c,
  String item, {
  String? wornIn,
}) async {
  if (c.game.data.itemOf(item) == null) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        ItemCard(controller: c, item: item, wornIn: wornIn, host: context),
  );
}

/// The item's name in its quality colour, the quality and kind in words, its
/// stats, how it compares with what is worn, and Equip / Swap / Unequip. A
/// material says where it comes from and what uses it.
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.controller,
    required this.item,
    required this.host,
    this.wornIn,
  });

  final GameController controller;
  final String item;
  final String? wornIn;

  /// The screen behind the sheet, for messages after the sheet closes.
  final BuildContext host;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final game = c.game;
    final data = game.data;
    final s = c.state;
    final labels = Labels(data);
    final text = Theme.of(context).textTheme;
    final def = data.itemOf(item)!;
    final gear = def.slot != null;
    final colour = itemColour(data, item);

    final rows = <Widget>[
      Text(
        labels.plain(item),
        key: const ValueKey('card-name'),
        style: text.titleLarge?.copyWith(color: colour),
      ),
      const SizedBox(height: 4),
      Text(labels.kind(item), key: const ValueKey('card-kind')),
      const SizedBox(height: 8),
      if (gear) ...[
        Text(labels.bonus(data.bonusOf(item)).join(' · ')),
        if (def.twoHanded)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              wornIn == null && s.equipment['offHand'] != null
                  ? 'Uses both hands: your off-hand item goes to the bag.'
                  : 'Uses both hands.',
            ),
          ),
        const SizedBox(height: 12),
        ..._gearActions(context, labels),
      ] else
        ..._materialLines(labels),
    ];
    return SafeArea(
      child: Padding(
        key: const ValueKey('item-card'),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows,
        ),
      ),
    );
  }

  List<Widget> _gearActions(BuildContext context, Labels labels) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    if (wornIn case final slot?) {
      return [
        _button(
          context,
          const ValueKey('card-unequip'),
          'Unequip',
          () => c.unequip(slot),
        ),
      ];
    }
    final slots = game.slotsFor(item);
    final free = slots.where((id) => !s.equipment.containsKey(id)).toList();
    // An empty slot first (spec 0008 decision 11); otherwise a swap with each
    // slot it fits.
    final targets = free.isNotEmpty ? [free.first] : slots;
    return [
      for (final slot in targets) ...[
        // Everything it takes off: the worn item, a two-hander's off hand,
        // or the two-hander an off-hand item replaces.
        Text(switch ([
          for (final id in game.displaced(s, item, slot))
            labels.plain(s.equipment[id]!),
        ]) {
          [] => '${labels.slot(slot)} is empty',
          final off => 'Instead of your ${off.join(' and ')}',
        }, style: Theme.of(context).textTheme.bodySmall),
        // The change counts everything it takes off (a two-hander's shield).
        Text(
          labels.delta(game.compare(s, item, slot)),
          key: ValueKey('compare-$slot'),
        ),
        const SizedBox(height: 8),
        _button(
          context,
          ValueKey(
            free.isNotEmpty
                ? 'card-equip'
                : slots.length == 1
                ? 'card-swap'
                : 'card-swap-$slot',
          ),
          free.isNotEmpty
              ? 'Equip'
              : slots.length == 1
              ? 'Swap'
              : 'Swap with ${labels.plain(s.equipment[slot]!)}',
          () => c.equip(item, slot: slot),
        ),
        const SizedBox(height: 8),
      ],
    ];
  }

  List<Widget> _materialLines(Labels labels) {
    final game = controller.game;
    final (enemies, nodes) = game.itemSources(controller.state, item);
    final uses = game.itemUses(item);
    return [
      if (enemies.isNotEmpty)
        Text('Drops from: ${enemies.map(labels.enemy).join(', ')}'),
      if (nodes.isNotEmpty)
        Text('Mined at: ${nodes.map(labels.node).join(', ')}'),
      if (uses.isNotEmpty)
        Text('Used in: ${uses.map(labels.recipe).join(', ')}'),
    ];
  }

  Widget _button(
    BuildContext context,
    Key key,
    String label,
    Future<void> Function() action,
  ) => sheetButton(context, host, key, label, action);
}

/// The colour an item's name is drawn in: its quality's, or null (the normal
/// text colour) for common gear and materials.
Color? itemColour(GameData data, String key) {
  final q = data.qualityOf(key);
  return data.itemOf(key)?.slot != null && q != data.qualities.first
      ? qualityColour(q)
      : null;
}

/// A button in a bottom sheet that closes it, then runs [action]; a refusal
/// shows on [host], the screen behind the sheet.
Widget sheetButton(
  BuildContext sheet,
  BuildContext host,
  Key key,
  String label,
  Future<void> Function() action,
) => FilledButton.tonal(
  key: key,
  onPressed: () async {
    final messenger = ScaffoldMessenger.of(host);
    Navigator.of(sheet).pop();
    try {
      await action();
    } on ActivityError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  },
  child: Text(label),
);
