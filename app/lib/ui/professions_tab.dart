import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'actions.dart';
import 'controller_scope.dart';
import 'item_card.dart';
import 'item_square.dart';
import 'labels.dart';
import 'level_badge.dart';
import 'meals.dart';

/// Professions (spec 0010 §8.1, spec 0011 §8.1): one card per profession
/// with its level, progress, tier, tool and where to practise. Crafting's
/// card holds the forge and every recipe, in tier order; Cooking's the camp
/// fire, the meal running, auto-eat and the meal recipes; Fishing's the
/// records.
class ProfessionsTab extends StatefulWidget {
  const ProfessionsTab({super.key, this.focus});

  /// The profession whose card is scrolled into view on opening.
  final String? focus;

  @override
  State<ProfessionsTab> createState() => _ProfessionsTabState();
}

class _ProfessionsTabState extends State<ProfessionsTab> {
  /// Each card's key, to scroll it into view.
  final _cards = <String, GlobalKey>{};

  /// The recipe filters (spec 0010 amendment 3): a view setting, not saved.
  var _mats = false;
  _LevelFilter? _level;

  GlobalKey _card(String id) => _cards.putIfAbsent(id, GlobalKey.new);

  void _show(String id) {
    final at = _cards[id]?.currentContext;
    if (at != null && at.mounted) Scrollable.ensureVisible(at);
  }

  @override
  void initState() {
    super.initState();
    if (widget.focus case final focus?) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _show(focus));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final game = c.game;
    final s = c.state;
    final professions = game.data.professions.values;
    // The running craft always shows, filter or not.
    bool shows(String id) {
      if (s.activity?.activity == Activity.craft(id)) return true;
      if (_mats && !game.hasMaterials(s, id)) return false;
      final r = game.data.recipes[id]!;
      return switch (_level) {
        null => true,
        _LevelFilter.level => game.recipeLevelMet(s, id),
        _LevelFilter.ahead =>
          r.craftingLevel <= game.professionLevel(s, r.profession) + 5,
      };
    }

    // Every card is built, so a card far down (Cooking, under Crafting's
    // recipes) can be scrolled to.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Six buttons share the width, so they fit a narrow phone.
          Row(
            children: [
              for (final p in professions)
                Expanded(
                  child: Tooltip(
                    message: p.name,
                    child: TextButton(
                      key: ValueKey('jump-${p.id}'),
                      onPressed: () => _show(p.id),
                      child: Column(
                        children: [
                          Icon(professionIcon(p.icon)),
                          Text(
                            s.learned.contains(p.id)
                                ? '${game.professionLevel(s, p.id)}'
                                : '–',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                key: const ValueKey('filter-mats'),
                label: const Text('Have mats'),
                selected: _mats,
                onSelected: (on) => setState(() => _mats = on),
              ),
              for (final (f, label) in const [
                (_LevelFilter.level, 'Have level'),
                (_LevelFilter.ahead, 'Up to 5 levels ahead'),
              ])
                FilterChip(
                  key: ValueKey('filter-${f.name}'),
                  label: Text(label),
                  selected: _level == f,
                  onSelected: (on) => setState(() => _level = on ? f : null),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final p in professions)
            KeyedSubtree(
              key: _card(p.id),
              child: _ProfessionCard(
                controller: c,
                profession: p,
                shows: shows,
              ),
            ),
        ],
      ),
    );
  }
}

/// "Have level" or "Up to 5 levels ahead": never both (spec 0010
/// amendment 3).
enum _LevelFilter { level, ahead }

class _ProfessionCard extends StatelessWidget {
  const _ProfessionCard({
    required this.controller,
    required this.profession,
    required this.shows,
  });

  final GameController controller;
  final ProfessionDef profession;

  /// Whether a recipe passes the filters.
  final bool Function(String recipe) shows;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final game = c.game;
    final data = game.data;
    final s = c.state;
    final p = profession;
    final text = Theme.of(context).textTheme;
    final learned = s.learned.contains(p.id);
    final level = game.professionLevel(s, p.id);
    final xp = s.professions[p.id] ?? 0;
    final floor = data.professionXpForLevel(level);
    final next = data.professionXpForLevel(level + 1);

    final rows = <Widget>[
      Row(
        children: [
          Icon(professionIcon(p.icon)),
          const SizedBox(width: 8),
          Text(p.name, style: text.titleLarge),
          const Spacer(),
          if (learned) Text('Level $level', style: text.titleMedium),
        ],
      ),
      const SizedBox(height: 8),
      if (!learned)
        Text('Learn from ${p.teacher.name} in camp')
      else ...[
        Row(
          children: [
            Text(p.tierAt(level).name, style: text.titleSmall),
            const Spacer(),
            Text('${fmt(xp)} / ${fmt(next)} XP', style: text.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: ((xp - floor) / (next - floor)).clamp(0, 1).toDouble(),
        ),
        const SizedBox(height: 8),
        _toolRow(context),
        ..._practise(context),
        if (p.id == 'fishing') ..._records(context),
      ],
    ];
    return Card(
      key: ValueKey('profession-${p.id}'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        ),
      ),
    );
  }

  /// The worn tool in its quality colour and its step cost; tap for its
  /// card.
  Widget _toolRow(BuildContext context) {
    final c = controller;
    final labels = Labels(c.game.data);
    final tool = c.state.tools[profession.id];
    if (tool == null) {
      return Text('No ${profession.toolName.toLowerCase()}');
    }
    return InkWell(
      onTap: () => showItemCard(context, c, tool, toolWorn: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          '${labels.plain(tool)} · ${labels.stepShare(tool)}% steps',
          style: TextStyle(color: itemColour(c.game.data, tool)),
        ),
      ),
    );
  }

  /// Where to practise: the best open spot for the level, with Go there;
  /// for Crafting the nearest forge and the recipes; for Cooking the camp
  /// fire, the meal and the meal recipes.
  List<Widget> _practise(BuildContext context) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    final labels = Labels(game.data);
    final recipes =
        game
            .allRecipes()
            .where((id) => game.data.recipes[id]!.profession == profession.id)
            .toList()
          ..sort(
            (a, b) => game.data.recipes[a]!.craftingLevel.compareTo(
              game.data.recipes[b]!.craftingLevel,
            ),
          );
    final shown = recipes.where(shows).toList();
    final list = [
      for (final id in shown) _RecipeTile(controller: c, recipe: id),
      if (shown.isEmpty && recipes.isNotEmpty)
        Text(
          'Nothing matches the filter',
          key: ValueKey('no-match-${profession.id}'),
        ),
    ];
    if (profession.id == 'cooking') {
      return [_fireRow(context), ..._mealRows(context), ...list];
    }
    if (profession.id == 'crafting') {
      final forge = game.nearestForge(s);
      return [
        ListTile(
          key: const ValueKey('forge'),
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.local_fire_department),
          title: Text(switch (forge) {
            (final at, 0) => 'At the forge (${labels.location(at)})',
            (final at, final d) =>
              'Nearest forge: ${labels.location(at)} · '
                  '${fmt(d)} steps away',
            null => 'No forge within reach',
          }),
          subtitle: forge == null || forge.$2 == 0
              ? null
              : const Text('Crafting walks you there first.'),
        ),
        ...list,
      ];
    }
    final level = game.professionLevel(s, profession.id);
    NodeDef? best;
    for (final n in game.data.nodes.values) {
      if (n.profession == profession.id &&
          n.level <= level &&
          !game.nodeFogged(s, n.id) &&
          (best == null || n.level > best.level)) {
        best = n;
      }
    }
    if (best == null) return const [];
    final spot = best;
    final area = game.data.locations.values.firstWhere(
      (l) => l.nodes.contains(spot.id),
    );
    return [
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: LevelBadge(
          level: spot.level,
          colour: professionColour(
            game,
            s,
            profession.id,
            spot.level,
            open: true,
          ),
        ),
        title: Text('${spot.name} · ${labels.location(area.id)}'),
        subtitle: const Text('Where to practise'),
        trailing: FilledButton.tonal(
          key: ValueKey('go-${profession.id}'),
          onPressed: () => startAction(context, c, Activity.gather(spot.id)),
          child: const Text('Go there'),
        ),
      ),
    ];
  }

  /// The camp fire: here, or how far, with Go there (spec 0011 §5.1, §8.1).
  Widget _fireRow(BuildContext context) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    final labels = Labels(game.data);
    final fire = game
        .openLocationsByDistance(s)
        .entries
        .where((e) => game.data.locations[e.key]!.fire)
        .firstOrNull;
    return ListTile(
      key: const ValueKey('fire'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.outdoor_grill),
      title: Text(switch (fire) {
        MapEntry(:final key, value: 0) =>
          'At the camp fire (${labels.location(key)})',
        MapEntry(:final key, :final value) =>
          'Camp fire: ${labels.location(key)} · ${fmt(value)} steps away',
        null => 'No camp fire within reach',
      }),
      subtitle: fire == null || fire.value == 0
          ? null
          : const Text('Cooking walks you there first.'),
      trailing: fire == null || fire.value == 0
          ? null
          : FilledButton.tonal(
              key: const ValueKey('go-cooking'),
              onPressed: () =>
                  startAction(context, c, Activity.travel(fire.key)),
              child: const Text('Go there'),
            ),
    );
  }

  /// The meal running, tap for its card, and the auto-eat choice (spec
  /// 0011 §8.1).
  List<Widget> _mealRows(BuildContext context) {
    final c = controller;
    final line = mealLine(c.game, c.state, withAuto: false);
    return [
      ListTile(
        key: const ValueKey('cooking-meal'),
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.restaurant),
        title: Text(line ?? 'No meal running'),
        onTap: line == null
            ? null
            : () => showItemCard(context, c, c.state.meal!.key),
      ),
      Padding(
        key: const ValueKey('cooking-auto'),
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(autoEatLine(c.game, c.state)),
      ),
    ];
  }

  /// The heaviest catch of each fish the known waters hold, "???" for
  /// those not caught yet; a hidden water's only once revealed (spec 0011
  /// §8.1).
  List<Widget> _records(BuildContext context) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    final labels = Labels(game.data);
    final fish = [
      for (final l in game.data.locations.values)
        if (!game.isHidden(s, l.id))
          for (final id in l.nodes)
            if (game.data.nodes[id]!.profession == 'fishing') ...[
              for (final row in game.data.nodes[id]!.catches) row.item,
              ?game.data.nodes[id]!.rareFind,
            ],
    ];
    return [
      const SizedBox(height: 8),
      Text('Records', style: Theme.of(context).textTheme.titleSmall),
      for (final f in fish)
        Text(switch (s.records[f]) {
          final w? => '${labels.plain(f)} · ${labels.kg(w)}',
          null => '???',
        }, key: ValueKey('record-$f')),
    ];
  }
}

class _RecipeTile extends StatelessWidget {
  const _RecipeTile({required this.controller, required this.recipe});

  final GameController controller;
  final String recipe;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final game = c.game;
    final s = c.state;
    final labels = Labels(game.data);
    final r = game.data.recipes[recipe]!;
    final out = game.data.items[r.output]!;
    final short = Theme.of(context).colorScheme.error;
    final active = s.activity?.activity == Activity.craft(recipe);
    // With 3 queue slots a craft can always be queued before its materials
    // are gathered (spec 0003 §4, spec 0008 decision 7); only its Crafting
    // level holds it back (spec 0010 §2.2).
    final levelMet = game.recipeLevelMet(s, recipe);
    final kind = [
      if (out.meal != null) labels.mealLength(out.id),
      ...labels.bonus(out.bonus),
      if (out.slot case final slot?) labels.slot(slot),
      if (out.tool != null) labels.toolLine(out.id),
    ].join(' · ');
    return ListTile(
      key: ValueKey('option-craft-$recipe'),
      contentPadding: EdgeInsets.zero,
      leading: LevelBadge(
        level: r.craftingLevel,
        // Its XP fades by the recipe's level (spec 0010 §2.3).
        colour: professionColour(
          game,
          s,
          r.profession,
          r.level,
          open: levelMet,
        ),
      ),
      enabled: levelMet,
      title: Text(labels.recipe(recipe)),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: '$kind\n'),
            for (final (i, e) in r.inputs.entries.indexed) ...[
              if (i > 0) const TextSpan(text: ', '),
              TextSpan(
                text:
                    '${labels.item(e.key)} ${s.inventory[e.key] ?? 0}/${e.value}',
                style: (s.inventory[e.key] ?? 0) < e.value
                    ? TextStyle(color: short)
                    : null,
              ),
            ],
            TextSpan(
              text: levelMet
                  ? ' · ${game.professionSteps(s, r.profession, r.steps)} '
                        'steps · '
                        '${game.professionXpFor(s, r.profession, r.level, r.xp)} '
                        '${labels.profession(r.profession)} XP'
                  : ' · ${game.lockedReason(s, Activity.craft(recipe))}',
            ),
          ],
        ),
      ),
      trailing: active ? const Chip(label: Text('Active')) : null,
      onTap: active || !levelMet
          ? null
          : () => startAction(context, c, Activity.craft(recipe)),
    );
  }
}
