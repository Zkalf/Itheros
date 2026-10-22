import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'controller_scope.dart';
import 'labels.dart';

/// One card per level gained, before the away report (spec 0002 §9.1).
/// With more than 3, all but the last are collapsed into one summary card.
class LevelUpScreen extends StatefulWidget {
  const LevelUpScreen({super.key});

  @override
  State<LevelUpScreen> createState() => _LevelUpScreenState();
}

class _LevelUpScreenState extends State<LevelUpScreen> {
  final _pages = PageController();
  var _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final levels = c.levelCards;
    final groups = levels.length > 3
        ? [
            levels.sublist(0, levels.length - 1),
            [levels.last],
          ]
        : [
            for (final l in levels) [l],
          ];
    final last = _page >= groups.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (p) => setState(() => _page = p),
                children: [for (final g in groups) _LevelCard(levels: g)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (!last)
                    TextButton(
                      onPressed: c.dismissLevelCards,
                      child: const Text('Skip all'),
                    ),
                  const Spacer(),
                  if (groups.length > 1)
                    Text('${_page + 1} / ${groups.length}'),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: last
                        ? c.dismissLevelCards
                        : () => _pages.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          ),
                    child: Text(last ? 'Continue' : 'Next'),
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

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.levels});

  /// One level, or several collapsed into one card.
  final List<int> levels;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final game = c.game;
    final labels = Labels(game.data, c.state.character);
    final text = Theme.of(context).textTheme;
    final gained = game.data.statsPerLevel * levels.length;
    final news = [for (final l in levels) ...game.levelNews(l, c.state)];
    final ranks = news.where((n) => n.kind == NewsKind.rank);
    final points = news.where((n) => n.kind == NewsKind.talentPoint).length;
    final rest = news.where(
      (n) => n.kind != NewsKind.rank && n.kind != NewsKind.talentPoint,
    );
    final title = levels.length == 1
        ? 'Level ${levels.single}!'
        : 'Levels ${levels.first}–${levels.last}';

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 24),
        Icon(
          ranks.isEmpty ? Icons.arrow_circle_up : Icons.military_tech,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 8),
        Text(title, style: text.displaySmall, textAlign: TextAlign.center),
        for (final r in ranks) ...[
          const SizedBox(height: 16),
          Text(r.id, style: text.headlineSmall, textAlign: TextAlign.center),
          Text(
            labels.news(r),
            style: text.titleMedium,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          '+${gained.hp} HP · +${gained.attack} Attack · '
          '+${gained.defense} Defense',
          style: text.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (rest.isNotEmpty || points > 0) ...[
          const SizedBox(height: 24),
          Text("What's new", style: text.titleLarge),
          const SizedBox(height: 8),
          for (final n in rest)
            ListTile(
              dense: true,
              leading: Icon(_icon(n.kind)),
              title: Text(labels.news(n)),
            ),
          if (points > 0)
            ListTile(
              dense: true,
              leading: const Icon(Icons.auto_awesome),
              title: Text(
                points == 1
                    ? labels.news(const LevelNews(NewsKind.talentPoint, ''))
                    : '+$points talent points. Talents arrive in a later '
                          'update; your points wait for you.',
              ),
            ),
        ],
      ],
    );
  }

  static IconData _icon(NewsKind k) => switch (k) {
    NewsKind.yourLevel => Icons.sports_kabaddi,
    NewsKind.gatheringSpot => Icons.landscape,
    NewsKind.recipe => Icons.handyman,
    NewsKind.turnedGrey => Icons.trending_down,
    NewsKind.rank || NewsKind.talentPoint => Icons.auto_awesome,
  };
}
