import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'labels.dart' show fmt;
import 'theme.dart';

/// Character's Talents tab (spec 0015 §3.1 and amendment 3): the points
/// left, then one tree at a time, as a grid of icons.
class TalentsTab extends StatefulWidget {
  const TalentsTab({super.key, required this.controller});

  final GameController controller;

  @override
  State<TalentsTab> createState() => _TalentsTabState();
}

class _TalentsTabState extends State<TalentsTab> {
  String? _tree;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final game = c.game;
    final s = c.state;
    final data = game.data;
    final tree = _tree ?? data.talentTrees.keys.first;
    final text = Theme.of(context).textTheme;
    final left = game.talentPointsLeft(s);
    final heading = game.level(s) < data.talentPointsFrom
        ? 'Talents open at level ${data.talentPointsFrom}.'
        : switch (left) {
            0 => 'No points left',
            1 => '1 point left',
            _ => '$left points left',
          };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          heading,
          key: const ValueKey('talents-heading'),
          style: text.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          expandedInsets: EdgeInsets.zero,
          segments: [
            for (final t in data.talentTrees.values)
              ButtonSegment(
                value: t.id,
                label: Text(
                  '${t.name} · ${game.ranksIn(s, t.id)}',
                  key: ValueKey('tree-${t.id}'),
                ),
              ),
          ],
          selected: {tree},
          showSelectedIcon: false,
          onSelectionChanged: (v) => setState(() => _tree = v.single),
        ),
        const SizedBox(height: 8),
        Text(data.talentTrees[tree]!.line, style: text.bodySmall),
        const SizedBox(height: 16),
        TalentGrid(controller: c, tree: tree),
      ],
    );
  }
}

/// One tree as a grid of 3 columns, row 1 at the top (spec 0015 amendment 3):
/// an icon per talent, a line from each talent to the one it needs, and the
/// "Opens at" line above the first closed row.
class TalentGrid extends StatelessWidget {
  const TalentGrid({super.key, required this.controller, required this.tree});

  final GameController controller;
  final String tree;

  /// The socket of an icon.
  static const socket = 56.0;

  /// The space between the name of one row and the icons of the next.
  static const gap = 18.0;

  /// The height of the "Opens at" line.
  static const band = 30.0;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    final data = game.data;
    final text = Theme.of(context).textTheme;
    final talents = [
      for (final t in data.talents.values)
        if (t.tree == tree) t,
    ];
    final lastRow = talents.fold(1, (n, t) => math.max(n, t.row));
    final ranks = game.ranksIn(s, tree);
    final closedFrom = [
      for (var r = 1; r <= lastRow; r++)
        if (ranks < game.rowOpensAt(r)) r,
    ].firstOrNull;
    // The name under an icon takes at most 2 lines, at the phone's text size.
    final nameStyle = text.bodySmall!.copyWith(color: Quiet.muted);
    final nameHeight =
        MediaQuery.textScalerOf(context).scale(nameStyle.fontSize!) *
            (nameStyle.height ?? 1.4) *
            2 +
        6;
    final rowHeight = socket + nameHeight + gap;
    double top(int row) =>
        (row - 1) * rowHeight +
        (closedFrom != null && row >= closedFrom ? band : 0);
    final height = top(lastRow) + rowHeight - gap;

    return LayoutBuilder(
      builder: (context, box) {
        final cell = box.maxWidth / 3;
        double centre(int column) => (column - .5) * cell;
        final lines = [
          for (final t in talents)
            if (t.needs case final n?)
              (
                need: data.talents[n]!,
                talent: t,
                teal: (s.talents[n] ?? 0) >= data.talents[n]!.ranks,
              ),
        ];
        return SizedBox(
          key: const ValueKey('talent-grid'),
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // The lines first: the sockets cover their ends.
              Positioned.fill(
                child: CustomPaint(
                  painter: _Lines([
                    for (final l in lines)
                      (
                        x: centre(l.talent.column),
                        from: top(l.need.row) + socket,
                        to: top(l.talent.row),
                        teal: l.teal,
                      ),
                  ]),
                ),
              ),
              for (final l in lines)
                Positioned(
                  left: centre(l.talent.column) - 1,
                  top: top(l.need.row) + socket,
                  width: 2,
                  height: top(l.talent.row) - top(l.need.row) - socket,
                  child: ExcludeSemantics(
                    child: SizedBox(
                      key: ValueKey(
                        'line-${l.need.id}-${l.talent.id}-'
                        '${l.teal ? 'teal' : 'faint'}',
                      ),
                    ),
                  ),
                ),
              if (closedFrom != null)
                Positioned(
                  key: const ValueKey('opens-at'),
                  left: 0,
                  right: 0,
                  top: top(closedFrom) - band,
                  height: band,
                  child: Center(
                    child: Text(
                      'Opens at ${game.rowOpensAt(closedFrom)} points in '
                      '${data.talentTrees[tree]!.name}',
                      style: text.bodySmall?.copyWith(color: Quiet.faint),
                    ),
                  ),
                ),
              for (final t in talents)
                Positioned(
                  left: (t.column - 1) * cell,
                  top: top(t.row),
                  width: cell,
                  child: TalentNode(controller: c, talent: t),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The lines between talents: plain 2 dp strokes, no blur (#121).
class _Lines extends CustomPainter {
  _Lines(this.lines);

  final List<({double x, double from, double to, bool teal})> lines;

  @override
  void paint(Canvas canvas, Size size) {
    for (final l in lines) {
      canvas.drawLine(
        Offset(l.x, l.from),
        Offset(l.x, l.to),
        Paint()
          ..color = l.teal ? Quiet.teal : Quiet.faint
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_Lines old) => !listEquals(old.lines, lines);
}

/// The state of a talent's icon (spec 0015 amendment 3, change 3).
enum NodeState { closed, open, learn, full }

/// One talent on the grid: its image in a 56 dp socket, the ranks badge, and
/// its name under it. A tap opens the talent sheet.
class TalentNode extends StatelessWidget {
  const TalentNode({super.key, required this.controller, required this.talent});

  final GameController controller;
  final TalentDef talent;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    final t = talent;
    final taken = s.talents[t.id] ?? 0;
    final need = t.needs == null ? null : game.data.talents[t.needs]!;
    final closed =
        game.ranksIn(s, t.tree) < game.rowOpensAt(t.row) ||
        (need != null && (s.talents[need.id] ?? 0) < need.ranks);
    final state = closed
        ? NodeState.closed
        : taken >= t.ranks
        ? NodeState.full
        : game.whyNotRank(s, t.id) == null
        ? NodeState.learn
        : NodeState.open;
    final ring = switch (state) {
      NodeState.learn => Border.all(color: Quiet.teal),
      NodeState.full => Border.all(color: Quiet.teal, width: 2),
      _ => null,
    };
    return InkWell(
      key: ValueKey('talent-${t.id}'),
      borderRadius: BorderRadius.circular(12),
      onTap: () => showTalent(context, c, t.id),
      child: Opacity(
        opacity: closed ? .4 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  key: ValueKey('node-${state.name}-${t.id}'),
                  width: TalentGrid.socket,
                  height: TalentGrid.socket,
                  decoration: BoxDecoration(
                    color: Quiet.socket,
                    borderRadius: BorderRadius.circular(12),
                    border: ring,
                  ),
                  child: Icon(talentIcon(t.image), size: 32, color: Quiet.teal),
                ),
                Positioned(
                  right: -12,
                  bottom: -8,
                  child: _RankBadge(
                    key: ValueKey('badge-${t.id}'),
                    taken: taken,
                    of: t.ranks,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              t.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: Quiet.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// The ranks "2/5" in the style of the count badge (spec 0014 §2.3), the
/// number in teal once a rank is taken.
class _RankBadge extends StatelessWidget {
  const _RankBadge({super.key, required this.taken, required this.of});

  final int taken;
  final int of;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: 30, minHeight: 21),
    padding: const EdgeInsets.symmetric(horizontal: 6),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Quiet.slate, Quiet.slateLow],
      ),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(width: 2),
    ),
    child: Text(
      '$taken/$of',
      maxLines: 1,
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        fontFamily: Fonts.number,
        fontWeight: FontWeight.w700,
        fontSize: 12.5,
        height: 17 / 12.5,
        leadingDistribution: TextLeadingDistribution.even,
        letterSpacing: 0,
        color: taken > 0 ? Quiet.teal : Quiet.text,
        fontFeatures: const [
          FontFeature.liningFigures(),
          FontFeature.tabularFigures(),
        ],
      ),
    ),
  );
}

/// A talent's icon in a 48 dp dark socket (spec 0014 §2.3) on the talent
/// sheet, until art comes (spec 0015 §6).
class TalentSocket extends StatelessWidget {
  const TalentSocket(this.image, {super.key});

  final String image;

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: Quiet.socket,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(talentIcon(image), size: 28, color: Quiet.teal),
  );
}

/// The icon of a talent's `image` in `talents.json`, from the app's icon
/// set until art comes (spec 0015 §6).
IconData talentIcon(String image) => switch (image) {
  'attack' => Icons.sports_martial_arts,
  'hp' => Icons.favorite,
  'defense' => Icons.shield,
  'crit' => Icons.flash_on,
  'steps' => Icons.directions_run,
  'hit' => Icons.gps_fixed,
  'dodge' => Icons.air,
  'quality' => Icons.diamond,
  'bank' => Icons.savings,
  'profession' => Icons.handyman,
  'material' => Icons.inventory_2,
  'warning' => Icons.warning_amber,
  'anvil' => Icons.hardware,
  'queue' => Icons.playlist_add,
  'travel' => Icons.hiking,
  'reroll' => Icons.casino,
  _ => Icons.auto_awesome,
};

/// What [talent] gives at [rank], in words: "+1.6% Attack".
String talentEffect(GameData data, TalentDef talent, int rank) {
  final v = talent.value * rank;
  String pct(double x) => '${_trim(x * 100)}%';
  return switch (talent.effect!) {
    TalentEffect.attackPercent => '+${pct(v)} Attack',
    TalentEffect.hpPercent => '+${pct(v)} HP',
    TalentEffect.defensePercent => '+${pct(v)} Defense',
    TalentEffect.crit => '+${v.round()} Crit',
    TalentEffect.hit => '+${v.round()} Hit',
    TalentEffect.dodge => '+${v.round()} Dodge',
    TalentEffect.fightSteps => '${pct(v)} of a fight\'s steps back',
    TalentEffect.dropQuality => '+${pct(v)} better drops',
    TalentEffect.critDamage =>
      'Crits deal ${_trim(data.combat.critDamage + v)}×',
    TalentEffect.bankCap => '+${fmt(v.round())} bank cap',
    TalentEffect.professionSteps => '${pct(v)} fewer steps to gather and craft',
    TalentEffect.extraGather => '${pct(v)} chance of one more',
    TalentEffect.lossXpShare =>
      'A lost fight pays ${pct(data.lossXpShare + v)} of the XP for the '
          'health knocked off',
    TalentEffect.craftQuality => '+${pct(v)} better crafts',
    TalentEffect.queueSlot => '+${v.round()} queue slot',
    TalentEffect.travelSteps => '${pct(v)} fewer travel steps',
    TalentEffect.rerollQuality => '+${pct(v)} better rerolls',
    TalentEffect.professionXp => '+${pct(v)} profession XP',
  };
}

/// [v] with at most one decimal, without a trailing ".0": 1.6, 4, 2.5.
String _trim(double v) {
  final r = (v * 10).round() / 10;
  return r == r.roundToDouble() ? '${r.round()}' : r.toStringAsFixed(1);
}

/// Opens the sheet of [talent] (spec 0015 §3.1).
Future<void> showTalent(
  BuildContext context,
  GameController c,
  String talent,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => TalentSheet(controller: c, talent: talent, host: context),
);

/// A talent's name, line and rank, what it gives now and next, and Learn,
/// or why not.
class TalentSheet extends StatefulWidget {
  const TalentSheet({
    super.key,
    required this.controller,
    required this.talent,
    required this.host,
  });

  final GameController controller;
  final String talent;

  /// The screen behind the sheet, for messages.
  final BuildContext host;

  @override
  State<TalentSheet> createState() => _TalentSheetState();
}

class _TalentSheetState extends State<TalentSheet> {
  /// A rank is on its way: Learn waits, so a double tap spends one point.
  var _busy = false;

  String get talent => widget.talent;
  BuildContext get host => widget.host;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final game = c.game;
      final s = c.state;
      final t = game.data.talents[talent]!;
      final text = Theme.of(context).textTheme;
      final taken = s.talents[talent] ?? 0;
      final why = game.whyNotRank(s, talent);
      final now = taken == 0 ? null : talentEffect(game.data, t, taken);
      final next = taken >= t.ranks
          ? null
          : talentEffect(game.data, t, taken + 1);
      return SafeArea(
        child: SingleChildScrollView(
          key: const ValueKey('talent-sheet'),
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TalentSocket(t.image),
                  const SizedBox(width: 12),
                  Expanded(child: Text(t.name, style: text.titleLarge)),
                ],
              ),
              const SizedBox(height: 8),
              Text(t.line),
              const SizedBox(height: 8),
              Text('Rank $taken of ${t.ranks}', style: text.titleMedium),
              const SizedBox(height: 4),
              Text(
                [
                  if (now != null) 'Now: $now',
                  if (next != null) 'Next: $next',
                ].join(' · '),
              ),
              const SizedBox(height: 12),
              if (why == null)
                FilledButton(
                  key: const ValueKey('learn-talent'),
                  style: slateButton,
                  onPressed: _busy
                      ? null
                      : () async {
                          // A second tap in the same frame finds it busy.
                          if (_busy) return;
                          final messenger = ScaffoldMessenger.of(host);
                          setState(() => _busy = true);
                          try {
                            await c.takeRank(talent);
                          } on ActivityError catch (e) {
                            messenger.showSnackBar(
                              SnackBar(content: Text(e.message)),
                            );
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  child: const Text('Learn · 1 point'),
                )
              else
                Text(why, style: text.bodySmall),
            ],
          ),
        ),
      );
    },
  );
}
