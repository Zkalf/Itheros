import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'away_summary_card.dart';
import 'labels.dart';
import 'theme.dart';

/// Opens the card for [item] (spec 0008 §3.5). [wornIn] is set when it was
/// tapped on the doll, [toolWorn] when it is the tool in use (spec 0010
/// §3). An item the data no longer has (an old save) has no card.
Future<void> showItemCard(
  BuildContext context,
  GameController c,
  String item, {
  String? wornIn,
  bool toolWorn = false,
}) async {
  if (c.game.data.itemOf(item) == null) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => ItemCard(
      controller: c,
      item: item,
      wornIn: wornIn,
      toolWorn: toolWorn,
      host: context,
    ),
  );
}

/// The item's name in its quality colour, the quality and kind in words, its
/// stats, how it compares with what is worn, and Equip / Swap / Unequip. A
/// tool says what it serves and costs; at a forge gear and tools salvage
/// and gear rerolls (spec 0010 §8.3). A meal says its buff and length, with
/// Eat and Auto-eat (spec 0011 §8.3). A material says where it comes from
/// and what uses it.
class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.controller,
    required this.item,
    required this.host,
    this.wornIn,
    this.toolWorn = false,
  });

  final GameController controller;
  final String item;
  final String? wornIn;
  final bool toolWorn;

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
    final legendary = data.qualityOf(item) == data.qualities.last;
    final pending = data.pendingRoll(item);
    // A Legendary's bonus stats reroll one at a time at a forge (§7.3).
    final statRerolls = gear && legendary && pending == null && game.atForge(s);

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
        // Base stats, then type and hands (or armour), then each bonus stat
        // on its own line (spec 0009 §8.2).
        Text(labels.bonus(data.baseStatsOf(item)).join(' · ')),
        if (labels.typeLine(item) case final type?) Text(type),
        for (final (i, r) in data.bonusRolls(item).indexed)
          if (statRerolls)
            Row(
              children: [
                Expanded(
                  child: Text(
                    labels.bonusRoll(r),
                    style: TextStyle(color: colour),
                  ),
                ),
                TextButton(
                  key: ValueKey('card-reroll-stat-$i'),
                  onPressed: () => _close(
                    context,
                    () => c.addAction(Activity.rerollStat(item, i)),
                  ),
                  child: Text('Reroll (${_dust(item)})'),
                ),
              ],
            )
          else
            Text(labels.bonusRoll(r), style: TextStyle(color: colour)),
        if (pending case final p?) ...[
          const SizedBox(height: 8),
          Text(
            'New roll: ${labels.bonusRoll(p.roll)} '
            '(was ${labels.bonusRoll(data.bonusRolls(item)[p.index])})',
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _button(
                context,
                const ValueKey('card-keep-new'),
                'Keep new',
                () => c.keepRoll(item, keepNew: true),
              ),
              const SizedBox(width: 8),
              _button(
                context,
                const ValueKey('card-keep-old'),
                'Keep old',
                () => c.keepRoll(item, keepNew: false),
              ),
            ],
          ),
        ],
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
        ..._forgeActions(context, labels),
      ] else if (def.tool != null) ...[
        Text(labels.toolLine(item)),
        const SizedBox(height: 12),
        ..._toolActions(context, labels),
        ..._forgeActions(context, labels),
      ] else if (def.meal != null) ...[
        Text(labels.mealLength(item), key: const ValueKey('card-buff')),
        const SizedBox(height: 12),
        ..._mealActions(context, labels),
      ] else
        ..._materialLines(labels),
    ];
    return SafeArea(
      child: SingleChildScrollView(
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

  /// Use or Swap for a tool in the bag (spec 0010 §3.2).
  List<Widget> _toolActions(BuildContext context, Labels labels) {
    final c = controller;
    if (toolWorn) return [const Text('In use')];
    final worn = c.state.tools[c.game.data.toolProfession(item)];
    return [
      if (worn != null)
        Text(
          'Instead of ${labels.plain(worn)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      const SizedBox(height: 8),
      _button(
        context,
        const ValueKey('card-tool'),
        worn == null ? 'Use' : 'Swap',
        () => c.useTool(item),
      ),
      const SizedBox(height: 8),
    ];
  }

  /// Eat, asking first while a meal runs, and the auto-eat choice (spec
  /// 0011 §5.4).
  List<Widget> _mealActions(BuildContext context, Labels labels) {
    final c = controller;
    final s = c.state;
    final running = s.meal;
    final small = Theme.of(context).textTheme.bodySmall;
    return [
      if (running != null)
        Text(
          'Replaces ${labels.item(running.key)} '
          '(${fmt(running.left)} steps left)',
          style: small,
        ),
      const SizedBox(height: 8),
      FilledButton.tonal(
        key: const ValueKey('card-eat'),
        style: slateButton,
        onPressed: () => _close(context, () => _eat(labels)),
        child: const Text('Eat'),
      ),
      const SizedBox(height: 16),
      Text('Auto-eat', style: headingStyle(context)),
      if (s.autoEat case final auto?
          when auto.meal != c.game.data.itemOf(item)!.id)
        Text(
          'Replaces ${labels.item(auto.meal)} as the auto-eat meal',
          style: small,
        ),
      const SizedBox(height: 4),
      _AutoEat(controller: c, meal: c.game.data.itemOf(item)!.id),
    ];
  }

  /// Eats the meal; with one running, asks first.
  Future<void> _eat(Labels labels) async {
    final running = controller.state.meal;
    if (running != null) {
      final sure = await showDialog<bool>(
        context: host,
        builder: (context) => AlertDialog(
          title: Text('Eat the ${labels.item(item)}?'),
          content: Text(
            'It replaces your ${labels.item(running.key)} '
            '(${fmt(running.left)} steps left).',
          ),
          actions: [
            TextButton(
              style: ghostButton,
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Not now'),
            ),
            TextButton(
              key: const ValueKey('eat-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eat'),
            ),
          ],
        ),
      );
      if (sure != true) return;
    }
    await controller.eat(item);
  }

  /// Salvage for a bag item, Reroll for gear below Legendary, both at a
  /// forge (spec 0010 §7.1-7.2); elsewhere, where to go.
  List<Widget> _forgeActions(BuildContext context, Labels labels) {
    final c = controller;
    final game = c.game;
    final data = game.data;
    final def = data.itemOf(item)!;
    final inBag = wornIn == null && !toolWorn;
    final salvage = inBag && !(def.tool?.starter ?? false);
    final reroll =
        def.slot != null &&
        data.qualityOf(item) != data.qualities.last &&
        data.pendingRoll(item) == null;
    if (!salvage && !reroll) return const [];
    if (!game.atForge(c.state)) {
      return [
        Text(
          'Salvage and reroll at a forge',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ];
    }
    return [
      Wrap(
        spacing: 8,
        children: [
          if (reroll)
            _button(
              context,
              const ValueKey('card-reroll'),
              'Reroll (${_dust(item)})',
              // One roll: no stop condition to pick.
              () => c.addAction(Activity.reroll(item)),
            ),
          if (salvage)
            OutlinedButton(
              key: const ValueKey('card-salvage'),
              onPressed: () => _close(context, () => _salvage(labels)),
              child: const Text('Salvage'),
            ),
        ],
      ),
    ];
  }

  /// Salvages the item, asking first from Rare up, and says what it gave.
  Future<void> _salvage(Labels labels) async {
    final data = controller.game.data;
    final messenger = ScaffoldMessenger.of(host);
    if (data.qualities.indexOf(data.qualityOf(item)) >= 2) {
      final sure = await showDialog<bool>(
        context: host,
        builder: (context) => AlertDialog(
          title: Text('Salvage the ${labels.owned(item)}?'),
          content: const Text('It breaks down into dust for good.'),
          actions: [
            TextButton(
              style: ghostButton,
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep it'),
            ),
            TextButton(
              key: const ValueKey('salvage-confirm'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Salvage'),
            ),
          ],
        ),
      );
      if (sure != true) return;
    }
    final result = await controller.salvage(item);
    messenger.showSnackBar(
      SnackBar(content: Text(labels.salvaged(item, result))),
    );
  }

  /// What a reroll of [key] takes: "3 Rare dust".
  String _dust(String key) {
    final data = controller.game.data;
    return '${data.rerollDust} ${data.qualityOf(key).name} dust';
  }

  /// Closes the card, then runs [action]; a refusal shows on [host].
  Future<void> _close(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(host);
    Navigator.of(context).pop();
    try {
      await action();
    } on ActivityError catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  List<Widget> _materialLines(Labels labels) {
    final game = controller.game;
    final (enemies, nodes) = game.itemSources(controller.state, item);
    final uses = game.itemUses(item);
    return [
      if (enemies.isNotEmpty)
        Text('Drops from: ${enemies.map(labels.enemy).join(', ')}'),
      for (final (verb, profession) in const [
        ('Mined', 'mining'),
        ('Chopped', 'woodcutting'),
        ('Fished', 'fishing'),
        ('Hunted', 'hunting'),
      ])
        if (nodes.where((n) => game.data.nodes[n]?.profession == profession)
            case final at when at.isNotEmpty)
          Text('$verb at: ${at.map(labels.node).join(', ')}'),
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

/// Auto-eat for one meal kind (spec 0011 §5.4): off, until out, or only
/// N, keeping N in the bag. It keeps its own choice, since the card doesn't
/// redraw on the controller's changes.
class _AutoEat extends StatefulWidget {
  const _AutoEat({required this.controller, required this.meal});

  final GameController controller;
  final String meal;

  @override
  State<_AutoEat> createState() => _AutoEatState();
}

class _AutoEatState extends State<_AutoEat> {
  /// null: off; 0: until out; N: keep N.
  int? _keep;

  @override
  void initState() {
    super.initState();
    final auto = widget.controller.state.autoEat;
    _keep = auto?.meal == widget.meal ? auto!.keep : null;
  }

  void _set(int? keep) {
    setState(() => _keep = keep);
    widget.controller.setAutoEat(
      keep == null ? null : widget.meal,
      keep: keep ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final keep = _keep;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          children: [
            for (final (key, label, value, on) in [
              ('auto-eat-off', 'Off', null, keep == null),
              ('auto-eat-out', 'Until out', 0, keep == 0),
              ('auto-eat-keep', 'Only N', 1, keep != null && keep > 0),
            ])
              ChoiceChip(
                key: ValueKey(key),
                label: Text(label),
                selected: on,
                onSelected: on ? null : (_) => _set(value),
              ),
          ],
        ),
        if (keep != null && keep > 0)
          Row(
            spacing: 8,
            children: [
              IconButton(
                key: const ValueKey('keep-down'),
                icon: const Icon(Icons.remove),
                onPressed: keep > 1 ? () => _set(keep - 1) : null,
              ),
              Text.rich(
                numberSpan('Keep $keep'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                key: const ValueKey('keep-up'),
                icon: const Icon(Icons.add),
                onPressed: () => _set(keep + 1),
              ),
              const Expanded(child: Text('in the bag; eat the rest')),
            ],
          ),
      ],
    );
  }
}

/// The colour an item's name is drawn in: its quality's, or null (the normal
/// text colour) for common gear and materials.
Color? itemColour(GameData data, String key) {
  final q = data.qualityOf(key);
  final item = data.itemOf(key);
  return (item?.slot != null || item?.tool != null) && q != data.qualities.first
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
  // A tonal button is slate (plan 0017, choice 6).
  style: slateButton,
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
