import 'package:flutter/material.dart';

import 'achievements_screen.dart';
import 'actions.dart';
import 'away_summary_card.dart';
import 'character_tab.dart';
import 'controller_scope.dart';
import 'journal_screen.dart';
import 'labels.dart';
import 'now_tab.dart';
import 'profession_screen.dart' show RecipeFilter;
import 'professions_tab.dart';
import 'settings_screen.dart';
import 'theme.dart';
import 'world_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

/// The bottom bar: four screens, each answering one question (spec 0008
/// §3.1).
enum _Screen {
  now('Now', Icons.directions_walk),
  world('World', Icons.map),
  professions('Professions', Icons.handyman),
  character('Character', Icons.person);

  const _Screen(this.title, this.icon);

  final String title;
  final IconData icon;
}

class _HomeShellState extends State<HomeShell> {
  /// The app opens on Now.
  var _screen = _Screen.now;

  /// The recipe filters, kept while the app runs (spec 0010 amendment 4).
  final _filter = ValueNotifier(const RecipeFilter());

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    const screens = _Screen.values;
    // Nothing happened but steps: a short note, not the screen (spec 0004
    // amendment 2).
    if (c.quietReport != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final quiet = c.quietReport;
        if (!mounted || quiet == null) return;
        c.clearQuietReport();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reportLines(quiet, Labels(c.game.data)).join(' ')),
          ),
        );
      });
    }
    return Scaffold(
      // No title: the lit tab names the screen (spec 0014 §4.1). The three
      // buttons stand on one plate (§2.2).
      appBar: AppBar(
        actions: [
          BarPlate(
            children: [
              IconButton(
                key: const ValueKey('achievements-button'),
                icon: Badge(
                  key: const ValueKey('achievements-dot'),
                  isLabelVisible: c.unseenAchievements.isNotEmpty,
                  child: const Icon(Icons.emoji_events),
                ),
                tooltip: 'Achievements',
                onPressed: () {
                  final unseen = c.unseenAchievements;
                  c.markSeen(unseen);
                  final fresh = {
                    for (final id in unseen)
                      id.substring('achievement.'.length),
                  };
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AchievementsScreen(fresh: fresh),
                    ),
                  );
                },
              ),
              IconButton(
                key: const ValueKey('journal-button'),
                icon: const Icon(Icons.menu_book),
                tooltip: 'Journal',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const JournalScreen(),
                  ),
                ),
              ),
              IconButton(
                key: const ValueKey('settings-button'),
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const SettingsScreen(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ShowNow(
        show: () {
          if (mounted) setState(() => _screen = _Screen.now);
        },
        child: switch (_screen) {
          _Screen.now => NowTab(
            onOpenWorld: () => setState(() => _screen = _Screen.world),
            // Back from the profession's screen lands on Professions.
            onOpenProfessions: ([profession]) {
              setState(() => _screen = _Screen.professions);
              if (profession != null) {
                openProfession(
                  context,
                  profession,
                  _filter,
                  showNow: () {
                    if (mounted) setState(() => _screen = _Screen.now);
                  },
                );
              }
            },
          ),
          _Screen.world => const WorldTab(),
          _Screen.professions => ProfessionsTab(filter: _filter),
          _Screen.character => const CharacterTab(),
        },
      ),
      // The bottom bar is a plate with the four tabs (spec 0014 §2.2).
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(gutter, 0, gutter, gutter),
          child: DecoratedBox(
            decoration: plateDecoration,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: NavigationBar(
                selectedIndex: screens.indexOf(_screen),
                onDestinationSelected: (i) =>
                    setState(() => _screen = screens[i]),
                destinations: [
                  for (final screen in screens)
                    _Tab(
                      key: ValueKey('tab-${screen.name}'),
                      icon: Icon(screen.icon),
                      label: screen.title,
                      lit: screen == _screen,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A tab of the bottom bar in a box with the 2 dp black border; the open tab
/// has the selected fill (spec 0014 amendment 4). It stays a
/// NavigationDestination, so the bar stays a NavigationBar (plan 0017).
class _Tab extends NavigationDestination {
  const _Tab({
    super.key,
    required super.icon,
    required super.label,
    required this.lit,
  });

  final bool lit;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(3),
    child: ControlBox(
      fill: lit ? Quiet.selected : Quiet.transparent,
      child: super.build(context),
    ),
  );
}
