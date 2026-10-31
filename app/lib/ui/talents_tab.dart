import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'theme.dart';

/// Character's Talents tab (spec 0015 §3.1, the look of spec 0014 §4.3): the
/// points left, then one tree at a time, row by row. Each talent is a plate
/// with its image, name, line and one teal pip per rank.
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
    final rows = {
      for (final t in data.talents.values)
        if (t.tree == tree) t.row,
    }.toList()..sort();
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
        for (final row in rows) _row(context, tree, row),
      ],
    );
  }

  Widget _row(BuildContext context, String tree, int row) {
    final c = widget.controller;
    final game = c.game;
    final opensAt = game.rowOpensAt(row);
    final open = game.ranksIn(c.state, tree) >= opensAt;
    return Opacity(
      key: ValueKey('row-$tree-$row'),
      opacity: open ? 1 : .5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          if (!open)
            Text(
              'Opens at $opensAt points in ${game.data.talentTrees[tree]!.name}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          for (final t in game.data.talents.values)
            if (t.tree == tree && t.row == row) _TalentPlate(c, t),
        ],
      ),
    );
  }
}

/// One talent: image, name, line, pips, and what it needs (spec 0015 §3.1).
class _TalentPlate extends StatelessWidget {
  const _TalentPlate(this.c, this.talent);

  final GameController c;
  final TalentDef talent;

  @override
  Widget build(BuildContext context) {
    final game = c.game;
    final s = c.state;
    final text = Theme.of(context).textTheme;
    final taken = s.talents[talent.id] ?? 0;
    final need = talent.needs == null ? null : game.data.talents[talent.needs]!;
    final needs = need != null && (s.talents[need.id] ?? 0) < need.ranks;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: Quiet.slateLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          key: ValueKey('talent-${talent.id}'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => showTalent(context, c, talent.id),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(talentIcon(talent.image), size: 32, color: Quiet.teal),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(talent.name, style: text.titleMedium),
                      Text(talent.line, style: text.bodySmall),
                      if (needs)
                        Text(
                          'Needs ${need.name} ${need.ranks}/${need.ranks}',
                          style: text.bodySmall?.copyWith(color: Quiet.risky),
                        ),
                      const SizedBox(height: 6),
                      Pips(taken: taken, of: talent.ranks),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One teal pip per rank; a taken rank is filled (spec 0014 §4.3).
class Pips extends StatelessWidget {
  const Pips({super.key, required this.taken, required this.of});

  final int taken;
  final int of;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    children: [
      for (var i = 0; i < of; i++)
        KeyedSubtree(
          key: ValueKey(i),
          child: Container(
            key: ValueKey(i < taken ? 'pip-on' : 'pip-off'),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < taken ? Quiet.teal : Quiet.transparent,
              border: Border.all(color: Quiet.teal, width: 1.5),
            ),
          ),
        ),
    ],
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
    TalentEffect.bankCap => '+${_grouped(v.round())} bank cap',
    TalentEffect.professionSteps => '${pct(v)} fewer steps to gather and craft',
    TalentEffect.extraGather => '${pct(v)} chance of one more',
    TalentEffect.lossXpShare =>
      'A lost fight pays ${pct(data.lossXpShare + v)} of its XP',
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

String _grouped(int n) =>
    n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',');

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
class TalentSheet extends StatelessWidget {
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
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final c = controller;
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
                  Icon(talentIcon(t.image), size: 32, color: Quiet.teal),
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
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(host);
                    try {
                      await c.takeRank(talent);
                    } on ActivityError catch (e) {
                      messenger.showSnackBar(
                        SnackBar(content: Text(e.message)),
                      );
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
