// The screen of one profession (spec 0010 amendment 4), moved out of
// professions_tab.dart (issue #62).

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'actions.dart';
import 'controller_scope.dart';
import 'images.dart';
import 'item_card.dart';
import 'item_square.dart';
import 'labels.dart';
import 'level_badge.dart';
import 'meals.dart';
import 'socket.dart';
import 'theme.dart';

/// "Have level" or "Up to 5 levels ahead": never both (spec 0010
/// amendment 3).
enum LevelFilter { level, ahead }

/// The recipe filters (spec 0010 amendment 3): a view setting, not saved,
/// shared by the Crafting and Cooking screens (amendment 4).
class RecipeFilter {
  const RecipeFilter({this.mats = false, this.level});

  final bool mats;
  final LevelFilter? level;
}

/// One profession's card alone; Crafting and Cooking put the recipe
/// filters on top.
class ProfessionScreen extends StatelessWidget {
  const ProfessionScreen({
    super.key,
    required this.profession,
    required this.filter,
    this.showNow,
  });

  final String profession;
  final ValueNotifier<RecipeFilter> filter;
  final VoidCallback? showNow;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final game = c.game;
    final s = c.state;
    final p = game.data.professions[profession]!;
    // The filters show once the player has learned a profession with
    // recipes (spec 0010 amendment 6).
    final filters =
        s.learned.contains(profession) &&
        game.data.recipes.values.any((r) => r.profession == profession);
    final route = ModalRoute.of(context);
    return Scaffold(
      appBar: AppBar(leading: const BackPlate(), title: Text(p.name)),
      body: ShowNow(
        show: () {
          if (route != null && route.isActive) {
            Navigator.of(context).removeRoute(route);
          }
          showNow?.call();
        },
        child: SafeArea(
          top: false,
          child: ValueListenableBuilder(
            valueListenable: filter,
            builder: (context, f, _) {
              // The running craft always shows, filter or not.
              bool shows(String id) {
                if (s.activity?.activity == Activity.craft(id)) return true;
                if (f.mats && !game.hasMaterials(s, id)) return false;
                final r = game.data.recipes[id]!;
                return switch (f.level) {
                  null => true,
                  LevelFilter.level => game.recipeLevelMet(s, id),
                  LevelFilter.ahead =>
                    r.craftingLevel <=
                        game.professionLevel(s, r.profession) + 5,
                };
              }

              return ListView(
                padding: const EdgeInsets.all(gutter),
                children: [
                  // The filters stand on a plate (spec 0014 §2.2). The
                  // gutter as padding and spacing keeps the three filters on
                  // one line at 360 dp.
                  if (filters)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(gutter),
                        child: Wrap(
                          spacing: gutter,
                          runSpacing: gutter,
                          children: [
                            FilterChip(
                              key: const ValueKey('filter-mats'),
                              label: const Text('Have mats'),
                              selected: f.mats,
                              onSelected: (on) => filter.value = RecipeFilter(
                                mats: on,
                                level: f.level,
                              ),
                            ),
                            for (final (l, label) in const [
                              (LevelFilter.level, 'Have level'),
                              (LevelFilter.ahead, 'Up to 5 levels ahead'),
                            ])
                              FilterChip(
                                key: ValueKey('filter-${l.name}'),
                                label: Text(label),
                                selected: f.level == l,
                                onSelected: (on) => filter.value = RecipeFilter(
                                  mats: f.mats,
                                  level: on ? l : null,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  _ProfessionCard(controller: c, profession: p, shows: shows),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

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

    // The top bar holds the name, so the card does not repeat it (spec 0010
    // amendment 6). A screen reader still hears it on the icon.
    final rows = <Widget>[
      Row(
        key: ValueKey('profession-head-${p.id}'),
        children: [
          Icon(professionIcon(p.icon), semanticLabel: p.name),
          const Spacer(),
          if (learned)
            Text.rich(numberSpan('Level $level'), style: text.titleMedium),
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
            Text.rich(
              numberSpan('${fmt(xp)} / ${fmt(next)} XP'),
              style: text.bodySmall,
            ),
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

  /// The worn tool: its picture with the ring of its quality (spec 0014
  /// §3.1, plan 0017 choice 8), then its name in its quality colour and its
  /// step cost; tap for its card. The socket is 32 dp, the banner size of
  /// §2.3, as the design phones 11 and 25 show for an item on one line.
  Widget _toolRow(BuildContext context) {
    final c = controller;
    final data = c.game.data;
    final labels = Labels(data);
    final tool = c.state.tools[profession.id];
    if (tool == null) {
      return Text('No ${profession.toolName.toLowerCase()}');
    }
    return InkWell(
      key: ValueKey('tool-${profession.id}'),
      onTap: () => showItemCard(context, c, tool, toolWorn: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            PictureSocket.item(
              data,
              tool,
              picture: ImageScope.of(context).pictureOf(data, ItemThing(tool)),
              size: 32,
            ),
            // The text starts 40 dp in, as the title of a row with an icon
            // does: an icon of 24 dp and a gap of 16.
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${labels.plain(tool)} · ${labels.stepSaving(tool)}',
                style: TextStyle(color: itemColour(data, tool)),
              ),
            ),
          ],
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
        // The title names the spot and its place.
        title: Text('${spot.name} · ${labels.location(area.id)}'),
        titleTextStyle: nameStyle(context),
        subtitle: const Text('Where to practise'),
        trailing: FilledButton.tonal(
          key: ValueKey('go-${profession.id}'),
          style: slateButton,
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
              style: slateButton,
              onPressed: () =>
                  startAction(context, c, Activity.travel(fire.key)),
              child: const Text('Go there'),
            ),
    );
  }

  /// The meal running, tap for its card, and the auto-eat choice (spec
  /// 0011 §8.1). The meal row starts with the meal (spec 0014 §4.2), in a
  /// 32 dp socket as on Now: the banner size of §2.3, as the design phones
  /// 11 and 25 show for an item on one line.
  List<Widget> _mealRows(BuildContext context) {
    final c = controller;
    final data = c.game.data;
    final meal = c.state.meal;
    final line = mealLine(c.game, c.state, withAuto: false);
    return [
      ListTile(
        key: const ValueKey('cooking-meal'),
        contentPadding: EdgeInsets.zero,
        leading: meal == null
            ? const Icon(Icons.restaurant)
            : PictureSocket.item(
                data,
                meal.key,
                picture: ImageScope.of(context)
                    .pictureOf(data, ItemThing(meal.key)),
                size: 32,
              ),
        // The title starts 40 dp in, as beside the icon and in the tool line.
        horizontalTitleGap: meal == null ? null : 8,
        title: Text(line ?? 'No meal running'),
        onTap: meal == null ? null : () => showItemCard(context, c, meal.key),
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
      Text('Records', style: headingStyle(context)),
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
    final active = s.activity?.activity == Activity.craft(recipe);
    // With 3 queue slots a craft can always be queued before its materials
    // are gathered (spec 0003 §4, spec 0008 decision 7); only its Crafting
    // level holds it back (spec 0010 §2.2).
    final levelMet = game.recipeLevelMet(s, recipe);
    // A weapon says its damage type and hands before its stats, in place of
    // its slot (spec 0010 amendment 7).
    final weapon = out.damageType != null ? labels.typeLine(out.id) : null;
    final kind = [
      ?weapon,
      if (out.meal != null) labels.mealLength(out.id),
      ...labels.bonus(out.bonus),
      if (weapon == null)
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
      titleTextStyle: nameStyle(context),
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
                    ? const TextStyle(color: Quiet.short)
                    : null,
              ),
            ],
            // The crafts the bag of now allows (spec 0010 amendment 5 §2.1).
            if (game.craftsAllowed(s.inventory, recipe) case final n?)
              TextSpan(
                text: ' · Enough for $n',
                style: n == 0 ? const TextStyle(color: Quiet.short) : null,
              ),
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
      trailing: active ? statusChip('Active', Quiet.steel) : null,
      onTap: active || !levelMet
          ? null
          : () => startAction(context, c, Activity.craft(recipe)),
    );
  }
}
