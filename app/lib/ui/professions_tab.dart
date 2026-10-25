import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import '../game_controller.dart';
import 'actions.dart';
import 'controller_scope.dart';
import 'item_square.dart';
import 'labels.dart';
import 'profession_screen.dart';
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

/// Professions (spec 0010 §8.1 and amendment 4, spec 0011 §8.1): one
/// button per profession with its level, progress and tier; a tap opens
/// that profession's own screen.
class ProfessionsTab extends StatelessWidget {
  const ProfessionsTab({super.key, required this.filter});

  final ValueNotifier<RecipeFilter> filter;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final game = c.game;
    final text = Theme.of(context).textTheme;
    // Slate buttons with the border, on one plate (spec 0014 §2.2).
    return ListView(
      padding: const EdgeInsets.all(gutter),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: gutter,
              children: [
                for (final p in game.data.professions.values)
                  TextButton(
                    key: ValueKey('profession-button-${p.id}'),
                    style: ButtonStyle(
                      padding: sinkingPadding(const EdgeInsets.all(14)),
                      alignment: Alignment.centerLeft,
                      textStyle: WidgetStatePropertyAll(text.bodyMedium),
                    ),
                    onPressed: () => openProfession(context, p.id, filter),
                    child: _Summary(controller: c, profession: p, text: text),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Icon, name and level, then the tier and a bar to the next level; or
/// whom to learn from.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.controller,
    required this.profession,
    required this.text,
  });

  final GameController controller;
  final ProfessionDef profession;
  final TextTheme text;

  @override
  Widget build(BuildContext context) {
    final game = controller.game;
    final data = game.data;
    final s = controller.state;
    final p = profession;
    final learned = s.learned.contains(p.id);
    final level = game.professionLevel(s, p.id);
    final xp = s.professions[p.id] ?? 0;
    final floor = data.professionXpForLevel(level);
    final next = data.professionXpForLevel(level + 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(professionIcon(p.icon)),
            const SizedBox(width: 8),
            Text(p.name, style: text.titleLarge),
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
        ],
      ],
    );
  }
}

/// Opens [profession]'s own screen over the bottom bar (spec 0010
/// amendment 4). Starting an action there closes it and shows Now, via
/// [showNow] or else the one above [context].
void openProfession(
  BuildContext context,
  String profession,
  ValueNotifier<RecipeFilter> filter, {
  VoidCallback? showNow,
}) {
  showNow ??= ShowNow.maybeOf(context);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ProfessionScreen(
        profession: profession,
        filter: filter,
        showNow: showNow,
      ),
    ),
  );
}
