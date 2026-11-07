import 'package:flutter/material.dart';

import '../game_controller.dart';
import 'character_tab.dart' show CharacterPane;
import 'images.dart';
import 'socket.dart';

/// The tab of the bottom bar that a step of the camp tour opens.
enum TourTab { now, world, professions, character }

/// One step of the camp tour (spec 0022 §3.3).
typedef TourStep = ({TourTab tab, CharacterPane? pane, String words});

/// The guide of the tour (spec 0022 decision 3, erratum 1).
const guideName = 'Odda';
const guide = GuideThing('odda');

/// The six steps, in order (spec 0022 §3.3). `{name}` is the character's
/// name.
const List<TourStep> tourSteps = [
  (
    tab: TourTab.now,
    pane: null,
    words:
        "Welcome to the Guild camp, {name}. I'm Odda, the quartermaster. Now "
        'shows what you are doing and what comes next. Every step you walk '
        'moves it on.',
  ),
  (
    tab: TourTab.world,
    pane: null,
    words:
        'This is the map. Tap a place to travel there, or to see what lives '
        'there. Beat the Graveyard King to cross the river.',
  ),
  (
    tab: TourTab.professions,
    pane: null,
    words:
        'Mining, woodcutting, fishing, hunting, cooking, crafting. Each has a '
        'teacher here at Camp. Learn from them, and go back for their '
        'tips.',
  ),
  (
    tab: TourTab.character,
    pane: CharacterPane.gear,
    words:
        'Your gear and your talents. Wear the best of what you find, and '
        'spend your talent points as you level.',
  ),
  (
    tab: TourTab.character,
    pane: CharacterPane.bag,
    words:
        'Your bag has only so many spaces, and past that you walk heavy. Keep '
        'the rest in the bank. Things move in and out of it only here at '
        'Camp.',
  ),
  (
    tab: TourTab.now,
    pane: null,
    words:
        'Up top: your supply chest, your achievements, the Journal and '
        'Settings. Settings can show you this tour again. Off you go, {name}. '
        'Walk.',
  ),
];

/// The card of the tour above the bottom bar (spec 0022 §3.2): Odda, the
/// step, the words, Skip tour and Next or Done.
class TourCard extends StatelessWidget {
  const TourCard({
    super.key,
    required this.controller,
    required this.step,
    required this.onEnd,
  });

  final GameController controller;
  final int step;

  /// Ends the tour: Skip tour and Done (rule 14).
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    final c = controller;
    final text = Theme.of(context).textTheme;
    final last = step == tourSteps.length - 1;
    final name = c.state.character?.name ?? '';
    return Card(
      key: const ValueKey('tour-card'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                PictureSocket(
                  key: const ValueKey('tour-portrait'),
                  picture: ImageScope.of(context).pictureOf(c.game.data, guide),
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(guideName, style: text.titleMedium)),
                Text(
                  '${step + 1} / ${tourSteps.length}',
                  key: const ValueKey('tour-step'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              tourSteps[step].words.replaceAll('{name}', name),
              key: const ValueKey('tour-words'),
            ),
            const SizedBox(height: 10),
            // Skip tour left and Next right; with very large text they stack
            // and never overflow.
            OverflowBar(
              alignment: MainAxisAlignment.spaceBetween,
              overflowAlignment: OverflowBarAlignment.end,
              overflowSpacing: 8,
              children: [
                TextButton(
                  key: const ValueKey('tour-skip'),
                  onPressed: onEnd,
                  child: const Text('Skip tour'),
                ),
                FilledButton(
                  key: const ValueKey('tour-next'),
                  onPressed: last ? onEnd : () => c.showTourStep(step + 1),
                  child: Text(last ? 'Done' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
