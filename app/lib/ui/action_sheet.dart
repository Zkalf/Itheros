import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'bestiary_card.dart';
import 'labels.dart';
import 'theme.dart';

/// Picks a stop condition for [activity] and whether to start it now or add
/// it to the queue (spec 0003 §8). Pops `(StopCondition, bool now)`. For a
/// fight, the monster's bestiary card sits on top (spec 0009 decision 11).
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
  var _quality = 'rare';

  Game get _game => widget.controller.game;

  @override
  void initState() {
    super.initState();
    final s = widget.controller.state;
    final a = widget.activity;
    _kind = StopCondition.defaultFor(a).kind;
    // "Until grey" can't start on a monster that is already grey.
    if (_kind == StopKind.untilGrey &&
        _game.enemyBand(s, a.target).colour == LevelColour.grey) {
      _kind = _kinds.contains(StopKind.untilHave)
          ? StopKind.untilHave
          : StopKind.never;
    }
    final items = _items;
    if (items.isNotEmpty) _pick(items.first);
  }

  /// Counts "Until I have N" for [item]: what the player has of it, plus 5
  /// (#113).
  void _pick(String item) {
    _item = item;
    _count = _game.owned(widget.controller.state, item) + 5;
  }

  Future<void> _typeCount() async {
    final n = await showDialog<int>(
      context: context,
      builder: (_) => _CountDialog(_count),
    );
    if (n != null && mounted) setState(() => _count = n);
  }

  /// Items "until I have N" may count: a monster's drops only once found,
  /// so the picker never names a "???" drop (spec 0006 criterion 6), and a
  /// spot's catches the same way (#114).
  List<String> get _items {
    final a = widget.activity;
    final s = widget.controller.state;
    if (a.kind == ActivityKind.gather) return _game.foundCatches(s, a.target);
    final items = _game.countableItems(a);
    if (a.kind != ActivityKind.fight) return items;
    final found = _game.foundDrops(s, a.target);
    return [
      for (final i in items)
        if (found.contains(i)) i,
    ];
  }

  List<StopKind> get _kinds => [
    for (final k in _game.stopKindsFor(
      widget.controller.state,
      widget.activity,
    ))
      if (k != StopKind.untilHave || _items.isNotEmpty) k,
  ];

  StopCondition get _stop => switch (_kind) {
    StopKind.untilGrey => const StopCondition.untilGrey(),
    StopKind.untilHave => StopCondition.untilHave(_item!, _count),
    StopKind.untilCrafted => StopCondition.untilCrafted(_count),
    StopKind.untilQuality => StopCondition.untilQuality(_quality),
    StopKind.never => const StopCondition.never(),
  };

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final s = c.state;
    final a = widget.activity;
    final labels = Labels(_game.data);
    final text = Theme.of(context).textTheme;
    final kinds = _kinds;
    final blocked = s.activity != null && _game.lastNeverStops(s);
    // Why "Add to queue" can't take it (spec 0016 §7.2), or null.
    String? refusal;
    if (s.activity != null && !blocked) {
      try {
        _game.addAction(s, a, stop: _stop);
      } on ActivityError catch (e) {
        refusal = e.message;
      }
    }
    final room = s.activity != null && !blocked && refusal == null;
    final walk = _game.walkFirst(s, a);

    String kindName(StopKind k) => switch (k) {
      StopKind.untilGrey => 'Until grey',
      StopKind.untilHave => 'Until I have N',
      StopKind.untilCrafted => 'Until N crafted',
      StopKind.untilQuality => 'Until a quality',
      StopKind.never => 'Never stop',
    };

    return SafeArea(
      child: SingleChildScrollView(
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
            if (a.kind == ActivityKind.fight) ...[
              BestiaryCard(controller: c, enemy: a.target),
              const Divider(height: 24),
            ] else ...[
              Text(labels.short(a), style: text.titleLarge),
              const SizedBox(height: 12),
            ],
            Text('Stop when', style: headingStyle(context)),
            const SizedBox(height: 6),
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
                      if (k == StopKind.untilHave && _item != null) {
                        _pick(_item!);
                      }
                    }),
                  ),
              ],
            ),
            if (_kind == StopKind.untilHave) ...[
              const SizedBox(height: 8),
              // The item list in a slate box with the border (spec 0014
              // §2.2); the list stays a DropdownButton.
              ControlBox(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _item,
                      style: text.bodyLarge,
                      dropdownColor: Quiet.slate,
                      borderRadius: BorderRadius.circular(11),
                      items: [
                        for (final i in _items)
                          DropdownMenuItem(
                            value: i,
                            child: Text(labels.item(i)),
                          ),
                      ],
                      onChanged: (i) => setState(() => _pick(i!)),
                    ),
                  ),
                ),
              ),
            ],
            if (_kind == StopKind.untilQuality) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final q in _game.data.qualities.skip(1))
                    ChoiceChip(
                      key: ValueKey('quality-${q.id}'),
                      label: Text('${q.name} or better'),
                      selected: _quality == q.id,
                      onSelected: (_) => setState(() => _quality = q.id),
                    ),
                ],
              ),
            ],
            if (_kind == StopKind.untilHave ||
                _kind == StopKind.untilCrafted) ...[
              Row(
                spacing: 8,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _count > 1
                        ? () => setState(() => _count--)
                        : null,
                  ),
                  // A tap types the number (#115).
                  TextButton(
                    key: const ValueKey('count'),
                    style: ghostButton,
                    onPressed: _typeCount,
                    child: Text(
                      '$_count',
                      style: text.titleMedium?.copyWith(
                        fontFamily: Fonts.number,
                      ),
                    ),
                  ),
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
            if (a.kind == ActivityKind.craft &&
                _game.data.recipes[a.target]!.inputs.isNotEmpty) ...[
              const SizedBox(height: 12),
              _MaterialsTable(
                game: _game,
                state: s,
                recipe: a.target,
                stop: _stop,
              ),
            ],
            if (walk != null) ...[
              const SizedBox(height: 8),
              Text(
                'Walk to ${labels.location(walk.place)} first: '
                '${fmt(walk.steps)} steps, one more slot.',
              ),
            ],
            if (refusal != null) ...[
              const SizedBox(height: 8),
              Text(refusal, style: text.bodySmall),
            ],
            if (blocked) ...[
              const SizedBox(height: 8),
              Text(
                'Your current plan never stops, so nothing can wait after '
                'it. Start this now instead, or stop that one first.',
                style: text.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            // Two equal buttons in the middle: Start now left, Add to queue
            // right. A Wrap, so big system text stacks them instead of
            // overflowing.
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('start-now'),
                    onPressed: () => Navigator.pop(context, (_stop, true)),
                    icon: const Icon(Icons.play_arrow),
                    // Start now clears the queue (spec 0016 §5).
                    label: Text(switch (s) {
                      GameState(activity: null) => 'Start',
                      GameState(queue: []) => 'Start now',
                      _ => 'Start now, clear queue',
                    }),
                  ),
                  if (room)
                    FilledButton.icon(
                      key: const ValueKey('add-to-queue'),
                      onPressed: () => Navigator.pop(context, (_stop, false)),
                      icon: const Icon(Icons.playlist_add),
                      label: const Text('Add to queue'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Each material of [recipe]: what the player has where the action will
/// stand in the queue, what [stop] uses and what is left (spec 0010
/// amendment 5 §2.2-2.3).
class _MaterialsTable extends StatelessWidget {
  const _MaterialsTable({
    required this.game,
    required this.state,
    required this.recipe,
    required this.stop,
  });

  final Game game;
  final GameState state;
  final String recipe;
  final StopCondition stop;

  @override
  Widget build(BuildContext context) {
    final labels = Labels(game.data);
    final text = Theme.of(context).textTheme;
    // With an action running, the new one waits after the queue.
    final queued = state.activity != null;
    final bag = game.bagAfterQueue(state);
    final crafts = game.craftsFor(Activity.craft(recipe), stop, bag);
    final allowed = game.craftsAllowed(bag, recipe)!;
    final number = text.bodyMedium?.copyWith(fontFamily: Fonts.number);

    Widget cell(
      String key,
      String value, {
      TextStyle? style,
      bool end = true,
    }) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: Text(
        value,
        key: ValueKey(key),
        textAlign: end ? TextAlign.end : TextAlign.start,
        style: style,
      ),
    );

    final heading = text.bodySmall?.copyWith(color: Quiet.muted);
    return Column(
      key: const ValueKey('materials'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (queued)
          Text(
            'After your queue',
            key: const ValueKey('materials-after-queue'),
            style: text.bodySmall,
          ),
        Table(
          // Shares, not the width of the numbers: at a large text size the
          // numbers would take the width and leave the names none.
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(),
            2: FlexColumnWidth(),
            3: FlexColumnWidth(),
          },
          defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            TableRow(
              children: [
                cell(
                  'materials-head-name',
                  'Material',
                  style: heading,
                  end: false,
                ),
                cell('materials-head-have', 'Have', style: heading),
                cell('materials-head-uses', 'Uses', style: heading),
                cell('materials-head-left', 'Left', style: heading),
              ],
            ),
            for (final MapEntry(key: item, value: need)
                in game.data.recipes[recipe]!.inputs.entries)
              _row(item, need, bag[item] ?? 0, crafts, labels, number, cell),
          ],
        ),
        if (crafts == null || allowed < crafts)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Enough for $allowed',
              key: const ValueKey('materials-enough'),
              style: text.bodySmall?.copyWith(color: Quiet.short),
            ),
          ),
      ],
    );
  }

  TableRow _row(
    String item,
    int need,
    int have,
    int? crafts,
    Labels labels,
    TextStyle? number,
    Widget Function(String, String, {TextStyle? style, bool end}) cell,
  ) {
    final uses = crafts == null ? null : need * crafts;
    final short = uses != null && have < uses;
    TextStyle? colour(TextStyle? s) =>
        short ? (s ?? const TextStyle()).copyWith(color: Quiet.short) : s;
    return TableRow(
      children: [
        cell(
          'material-$item-name',
          labels.item(item),
          style: colour(null),
          end: false,
        ),
        cell('material-$item-have', '$have', style: colour(number)),
        cell(
          'material-$item-uses',
          uses == null ? '–' : '$uses',
          style: colour(number),
        ),
        cell(
          'material-$item-left',
          uses == null ? '–' : '${have - uses < 0 ? 0 : have - uses}',
          style: colour(number),
        ),
      ],
    );
  }
}

/// Types the number of "Until I have N" or "Until N crafted" (#115). Pops the
/// number, at least 1, or null on Cancel.
class _CountDialog extends StatefulWidget {
  const _CountDialog(this.count);

  final int count;

  @override
  State<_CountDialog> createState() => _CountDialogState();
}

class _CountDialogState extends State<_CountDialog> {
  late final _field = TextEditingController(text: '${widget.count}')
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: '${widget.count}'.length,
    );

  int? get _value => switch (int.tryParse(_field.text)) {
    final n? when n >= 1 => n,
    _ => null,
  };

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('How many?'),
      content: TextField(
        key: const ValueKey('count-field'),
        controller: _field,
        autofocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 5,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) {
          if (_value case final n?) Navigator.pop(context, n);
        },
      ),
      actions: [
        TextButton(
          style: ghostButton,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _value == null
              ? null
              : () => Navigator.pop(context, _value),
          child: const Text('Set'),
        ),
      ],
    );
  }
}
