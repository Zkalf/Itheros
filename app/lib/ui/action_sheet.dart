import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'labels.dart';

/// Picks a stop condition for [activity] and whether to start it now or add
/// it to the queue (spec 0003 §8). Pops `(StopCondition, bool now)`.
class ActionSheet extends StatefulWidget {
  const ActionSheet({
    super.key,
    required this.controller,
    required this.activity,
  });

  final GameController controller;
  final Activity activity;

  @override
  State<ActionSheet> createState() => _ActionSheetState();
}

class _ActionSheetState extends State<ActionSheet> {
  late StopKind _kind;
  String? _item;
  var _count = 1;

  Game get _game => widget.controller.game;

  @override
  void initState() {
    super.initState();
    final s = widget.controller.state;
    final a = widget.activity;
    _kind = StopCondition.defaultFor(a).kind;
    final items = _game.countableItems(a);
    if (items.isNotEmpty) {
      _item = items.first;
      _count = _game.owned(s, items.first) + 5;
    }
  }

  StopCondition get _stop => switch (_kind) {
    StopKind.untilGrey => const StopCondition.untilGrey(),
    StopKind.untilHave => StopCondition.untilHave(_item!, _count),
    StopKind.untilCrafted => StopCondition.untilCrafted(_count),
    StopKind.never => const StopCondition.never(),
  };

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final s = c.state;
    final a = widget.activity;
    final labels = Labels(_game.data);
    final text = Theme.of(context).textTheme;
    final kinds = _game.stopKindsFor(s, a);
    final room = s.activity != null && 1 + s.queue.length < _game.queueSlots(s);

    String kindName(StopKind k) => switch (k) {
      StopKind.untilGrey => 'Until grey',
      StopKind.untilHave => 'Until I have N',
      StopKind.untilCrafted => 'Until N crafted',
      StopKind.never => 'Never stop',
    };

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(labels.short(a), style: text.titleLarge),
            const SizedBox(height: 12),
            Text('Stop when', style: text.titleSmall),
            Wrap(
              spacing: 8,
              children: [
                for (final k in kinds)
                  ChoiceChip(
                    key: ValueKey('stop-${k.name}'),
                    label: Text(kindName(k)),
                    selected: _kind == k,
                    onSelected: (_) => setState(() {
                      _kind = k;
                      if (k == StopKind.untilCrafted) _count = 1;
                    }),
                  ),
              ],
            ),
            if (_kind == StopKind.untilHave) ...[
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: _item,
                items: [
                  for (final i in _game.countableItems(a))
                    DropdownMenuItem(value: i, child: Text(labels.item(i))),
                ],
                onChanged: (i) => setState(() => _item = i),
              ),
            ],
            if (_kind == StopKind.untilHave ||
                _kind == StopKind.untilCrafted) ...[
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _count > 1
                        ? () => setState(() => _count--)
                        : null,
                  ),
                  Text('$_count', style: text.titleMedium),
                  IconButton(
                    key: const ValueKey('count-up'),
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => _count++),
                  ),
                  if (_kind == StopKind.untilHave)
                    Text(
                      'you have ${_game.owned(s, _item!)}',
                      style: text.bodySmall,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  key: const ValueKey('start-now'),
                  onPressed: () => Navigator.pop(context, (_stop, true)),
                  child: Text(s.activity == null ? 'Start' : 'Start now'),
                ),
                if (room) ...[
                  const SizedBox(width: 8),
                  FilledButton(
                    key: const ValueKey('add-to-queue'),
                    onPressed: () => Navigator.pop(context, (_stop, false)),
                    child: const Text('Add to queue'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
