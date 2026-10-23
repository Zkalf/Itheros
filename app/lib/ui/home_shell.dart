import 'package:flutter/material.dart';

import 'achievements_screen.dart';
import 'actions.dart';
import 'away_summary_card.dart';
import 'character_tab.dart';
import 'controller_scope.dart';
import 'journal_screen.dart';
import 'labels.dart';
import 'now_tab.dart';
import 'professions_tab.dart';
import 'settings_screen.dart';
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
      appBar: AppBar(
        title: Text(_screen.title),
        actions: [
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
                for (final id in unseen) id.substring('achievement.'.length),
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
              MaterialPageRoute<void>(builder: (_) => const JournalScreen()),
            ),
          ),
          IconButton(
            key: const ValueKey('settings-button'),
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: screens.indexOf(_screen),
        onDestinationSelected: (i) => setState(() => _screen = screens[i]),
        destinations: [
          for (final screen in screens)
            NavigationDestination(
              key: ValueKey('tab-${screen.name}'),
              icon: Icon(screen.icon),
              label: screen.title,
            ),
        ],
      ),
    );
  }
}
