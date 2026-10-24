import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';

import 'actions.dart' show Heading;
import 'controller_scope.dart';
import 'images.dart';
import 'labels.dart';
import 'socket.dart';
import 'theme.dart';

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

    // The cards and their buttons stand on one plate (spec 0014 §2.2).
    return Scaffold(
      body: SafeArea(
        child: Card(
          margin: const EdgeInsets.all(gutter),
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
                        style: ghostButton,
                        onPressed: c.dismissLevelCards,
                        child: const Text('Skip all'),
                      ),
                    const Spacer(),
                    if (groups.length > 1)
                      Text.rich(numberSpan('${_page + 1} / ${groups.length}')),
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
        // A new rank shows its image in a 72 dp socket (spec 0014 §2.3,
        // §4.2): the newest rank, if the card holds several levels.
        if (ranks.lastOrNull case final rank?)
          Center(
            child: PictureSocket(
              picture: ImageScope.of(context)
                  .pictureOf(game.data, RankThing(rank.id)),
              size: 72,
            ),
          )
        else
          Icon(
            Icons.arrow_circle_up,
            size: 72,
            color: Theme.of(context).colorScheme.primary,
          ),
        const SizedBox(height: 8),
        Text.rich(
          numberSpan(title),
          style: text.displaySmall,
          textAlign: TextAlign.center,
        ),
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
        Text.rich(
          numberSpan(
            '+${gained.hp} HP · +${gained.attack} Attack · '
            '+${gained.defense} Defense',
          ),
          style: text.titleMedium,
          textAlign: TextAlign.center,
        ),
        if (rest.isNotEmpty || points > 0) ...[
          const SizedBox(height: 12),
          const Heading("What's new"),
          const SizedBox(height: 8),
          for (final n in rest) NewsTile(news: n),
          if (points > 0)
            ListTile(
              dense: true,
              leading: _newsIcon(Icons.auto_awesome),
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
}

/// One "What's new" row of a level-up card (spec 0014 §4.2). A row of a
/// monster or a recipe starts with its picture in a 48 dp socket; a row of a
/// gathering spot or a talent point keeps its icon.
class NewsTile extends StatelessWidget {
  const NewsTile({super.key, required this.news});

  final LevelNews news;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    final data = c.game.data;
    final images = ImageScope.of(context);
    Widget socket(Thing thing) =>
        PictureSocket(picture: images.pictureOf(data, thing), size: 48);
    return ListTile(
      dense: true,
      // Room above and below a socket, so that two sockets do not touch.
      minTileHeight: 56,
      leading: switch (news.kind) {
        NewsKind.yourLevel ||
        NewsKind.turnedGrey => socket(MonsterThing(news.id)),
        // The item that the recipe makes. Its quality rolls when it is
        // made, so the socket has no ring.
        NewsKind.recipe => socket(ItemThing(data.recipes[news.id]!.output)),
        NewsKind.rank => socket(RankThing(news.id)),
        NewsKind.gatheringSpot => _newsIcon(Icons.landscape),
        NewsKind.talentPoint => _newsIcon(Icons.auto_awesome),
      },
      title: Text(Labels(data, c.state.character).news(news)),
    );
  }
}

/// The icon of a "What's new" row, in the middle of the place of a socket,
/// so that the text of each row starts at the same place.
Widget _newsIcon(IconData icon) => SizedBox(width: 48, child: Icon(icon));
