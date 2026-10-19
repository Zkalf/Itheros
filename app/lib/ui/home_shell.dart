import 'package:flutter/material.dart';

import 'achievements_tab.dart';
import 'away_summary_card.dart';
import 'character_tab.dart';
import 'controller_scope.dart';
import 'craft_tab.dart';
import 'journal_screen.dart';
import 'labels.dart';
import 'map_tab.dart';
import 'now_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

/// The bottom bar's screens (spec 0006 decision 1).
enum _Screen {
  now('Now', Icons.directions_walk),
  map('Map', Icons.map),
  craft('Craft', Icons.handyman),
  character('Character', Icons.person),
  achievements('Achievements', Icons.emoji_events);

  const _Screen(this.title, this.icon);

  final String title;
  final IconData icon;
}

class _HomeShellState extends State<HomeShell> {
  /// The app opens on Now.
  var _screen = _Screen.now;

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    // Crafting stays hidden until its first recipe opens (spec 0001
    // criterion 8: locked systems are hidden, not greyed out).
    final screens = [
      for (final screen in _Screen.values)
        if (screen != _Screen.craft ||
            c.game.unlockedRecipes(c.state).isNotEmpty)
          screen,
    ];
    if (!screens.contains(_screen)) _screen = _Screen.now;
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
            key: const ValueKey('journal-button'),
            icon: const Icon(Icons.menu_book),
            tooltip: 'Journal',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const JournalScreen()),
            ),
          ),
        ],
      ),
      body: switch (_screen) {
        _Screen.now => NowTab(
          onOpenMap: () => setState(() => _screen = _Screen.map),
        ),
        _Screen.map => const MapTab(),
        _Screen.craft => const CraftTab(),
        _Screen.character => const CharacterTab(),
        _Screen.achievements => const AchievementsTab(),
      },
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
