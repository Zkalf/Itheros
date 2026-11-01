import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'controller_scope.dart';
import 'item_card.dart';
import 'labels.dart';
import 'theme.dart';

/// The supply chest screen (spec 0013 §3.2): today's steps into actions
/// toward the goal, and the waiting chests with Open and Open all.
class SupplyChestScreen extends StatelessWidget {
  const SupplyChestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final text = Theme.of(context).textTheme;
    final goal = c.game.data.supplyChest.goal;
    final today = c.supplyToday;
    final waiting = c.state.supplyChests.length;
    return Scaffold(
      appBar: AppBar(
        leading: const BackPlate(),
        // The sheet of one chest reads "Supply chest" (spec 0013 §3.3).
        title: const Text('Supply chests'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(gutter),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      today.paid
                          ? 'Today: earned'
                          : 'Today: ${fmt(today.steps)} / ${fmt(goal)} steps',
                      style: text.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: today.paid
                          ? 1
                          : (today.steps / goal).clamp(0, 1).toDouble(),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(switch (waiting) {
                      0 => 'No chest waiting',
                      1 => '1 supply chest',
                      final n => '$n supply chests',
                    }, style: text.titleMedium),
                    if (waiting > 0) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          FilledButton(
                            key: const ValueKey('supply-open'),
                            onPressed: () => _open(context, c, all: false),
                            child: const Text('Open'),
                          ),
                          if (waiting > 1)
                            FilledButton(
                              key: const ValueKey('supply-open-all'),
                              onPressed: () => _open(context, c, all: true),
                              child: const Text('Open all'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(
    BuildContext context,
    GameController c, {
    required bool all,
  }) async {
    final ({int count, Map<String, int> items}) opened;
    try {
      opened = all ? await c.openAllSupplyChests() : await c.openSupplyChest();
    } on ActivityError {
      // A second tap after the first open took the last chest.
      return;
    }
    final (:count, :items) = opened;
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ChestSheet(
        controller: c,
        title: count == 1 ? 'Supply chest' : '$count supply chests',
        items: items,
        host: context,
      ),
    );
  }
}

/// What came out of the chests (spec 0013 §3.3): each item with its count,
/// gear in its quality colour; a tap on gear opens its item card.
class _ChestSheet extends StatelessWidget {
  const _ChestSheet({
    required this.controller,
    required this.title,
    required this.items,
    required this.host,
  });

  final GameController controller;
  final String title;
  final Map<String, int> items;

  /// The screen's context: the item card opens from it.
  final BuildContext host;

  @override
  Widget build(BuildContext context) {
    final data = controller.game.data;
    final labels = Labels(data);
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(8, 16, 8, 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          for (final MapEntry(key: key, value: n) in items.entries)
            if (data.itemOf(key)?.slot != null)
              ListTile(
                title: Text(
                  '${labels.item(key)} ×$n',
                  // As on the item card: Common in the normal text colour.
                  style: TextStyle(color: itemColour(data, key)),
                ),
                onTap: () => showItemCard(host, controller, key),
              )
            else
              ListTile(title: Text('${labels.item(key)} ×$n')),
        ],
      ),
    );
  }
}
