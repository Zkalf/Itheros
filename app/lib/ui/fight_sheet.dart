import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'controller_scope.dart';
import 'labels.dart';
import 'theme.dart';

/// Opens the fight sheet of the running fight action (spec 0019 §3.2).
Future<void> showFightSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  builder: (_) => const FightSheet(),
);

/// The story of the fights (spec 0019 §3.2): the last fights, one line each,
/// then the latest fight round by round. The oldest is at the top; the sheet
/// opens at the bottom. It reads the controller through the scope, so a fight
/// that ends while it is open shows in it.
class FightSheet extends StatelessWidget {
  const FightSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final run = c.state.activity;
    if (run == null || run.activity.kind != ActivityKind.fight) {
      return const SizedBox.shrink();
    }
    final labels = Labels(c.game.data, c.state.character);
    final enemy = run.activity.target;
    final text = Theme.of(context).textTheme;
    final playerHp = c.game.stats(c.state).hp;
    final log = run.log;
    // The fight in the round log: the running one, or the one that ended on
    // its last round.
    final ended = log.isNotEmpty && log.last.outcome != null;
    final number = run.won + run.lost + (ended ? 0 : 1);
    final children = <Widget>[
      Text('Fights: ${labels.enemy(enemy)}', style: text.titleLarge),
      if (run.fights.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('Last fights', style: headingStyle(context)),
        const SizedBox(height: 4),
        for (final f in run.fights) _SummaryRow(f, labels.fightSummary(f)),
      ],
      if (log.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text('Fight $number, round by round', style: headingStyle(context)),
        const SizedBox(height: 4),
        if (log.first.round > 1)
          Text(
            'Earlier rounds are not kept',
            style: text.bodySmall?.copyWith(color: Quiet.faint),
          ),
        for (final r in log)
          _RoundRow(r, labels.swings(r, enemy, playerHp: playerHp)),
      ],
    ];
    return SafeArea(
      key: const ValueKey('fight-sheet'),
      // Reversed, so the sheet opens at the bottom (spec 0019 §3.2).
      child: ListView(
        reverse: true,
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ],
      ),
    );
  }
}

/// One finished fight: a check mark or a cross, then its line.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow(this.fight, this.line);

  final FightSummary fight;
  final String line;

  @override
  Widget build(BuildContext context) {
    final won = fight.outcome == FightOutcome.won;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            won ? Icons.check : Icons.close,
            key: ValueKey('fight-${won ? 'won' : 'lost'}-${fight.number}'),
            size: 16,
            color: won ? Quiet.met : Quiet.short,
          ),
          const SizedBox(width: 6),
          Expanded(child: Text(line)),
        ],
      ),
    );
  }
}

/// One round: "Round 1" in the faint colour, then its swings, each in its
/// look (spec 0019 §3.3).
class _RoundRow extends StatelessWidget {
  const _RoundRow(this.round, this.swings);

  final RoundLog round;
  final List<SwingLine> swings;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium!;
    TextStyle look(SwingLine s) {
      final style = switch (s.look) {
        SwingLook.hit || SwingLook.end => base.copyWith(color: Quiet.text),
        SwingLook.hitOnYou => base.copyWith(color: Quiet.short),
        SwingLook.crit => base.copyWith(
          color: Quiet.risky,
          fontWeight: FontWeight.bold,
          fontSize: (base.fontSize ?? 14) + 2,
        ),
        SwingLook.block => base.copyWith(color: Quiet.steel),
        SwingLook.dodge => base.copyWith(color: Quiet.teal),
        SwingLook.miss => base.copyWith(color: Quiet.faint),
      };
      return s.big ? style.copyWith(fontWeight: FontWeight.bold) : style;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Wrap(
        spacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'Round ${round.round}',
            style: base.copyWith(color: Quiet.faint),
          ),
          for (final (i, s) in swings.indexed) ...[
            if (i > 0) Text('·', style: base.copyWith(color: Quiet.faint)),
            Text(s.text, style: look(s)),
          ],
        ],
      ),
    );
  }
}
