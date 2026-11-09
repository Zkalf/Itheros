import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'theme.dart';

/// The overload as a whole percent: "15%".
String overloadPercent(Game game, GameState s) =>
    '${(game.overload(s) * 100).round()}%';

/// "Spaces 32 / 40", or with the overload in `Quiet.risky` (spec 0021
/// points 13, 14, 18).
class BagSpacesLine extends StatelessWidget {
  const BagSpacesLine({super.key, required this.game, required this.state});

  final Game game;
  final GameState state;

  @override
  Widget build(BuildContext context) {
    final over = game.overloaded(state);
    final spaces =
        'Spaces ${game.spacesUsed(state)} / ${game.bagSpaces(state)}';
    return Text(
      over
          ? '$spaces · Overloaded +${overloadPercent(game, state)} steps'
          : spaces,
      key: const ValueKey('bag-spaces'),
      style: over ? const TextStyle(color: Quiet.risky) : null,
    );
  }
}

/// The Overloaded line of Now's status card, or null when not overloaded
/// (spec 0021 points 15-17). A tap opens its sheet.
Widget? overloadedLine(BuildContext context, Game game, GameState s) {
  if (!game.overloaded(s)) return null;
  return InkWell(
    key: const ValueKey('overloaded-line'),
    onTap: () => _showOverloaded(context, game, s),
    child: Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          const Icon(Icons.backpack, color: Quiet.risky, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Overloaded: +${overloadPercent(game, s)} steps',
              key: const ValueKey('overloaded-text'),
              style: const TextStyle(color: Quiet.risky),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showOverloaded(BuildContext context, Game game, GameState s) {
  final data = game.data;
  String pct(double x) => '${(x * 100).round()}%';
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        key: const ValueKey('overloaded-sheet'),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overloaded', style: Theme.of(context).textTheme.titleLarge),
            for (final line in [
              // Spaces, not kinds, since stacks (spec 0021 amendment 4,
              // rule 10).
              'Your bag uses ${game.spacesUsed(s)} spaces. It has '
                  '${game.bagSpaces(s)}.',
              'Each space over adds ${pct(data.bagOverloadStep)} to the steps '
                  'of your actions, up to ${pct(data.bagOverloadMax)}.',
              'At Camp, crafts and rerolls cost no more.',
              'Store items in the bank at Camp, or salvage, eat or use them.',
            ]) ...[const SizedBox(height: 8), Text(line)],
          ],
        ),
      ),
    ),
  );
}
