import 'package:flutter/material.dart';

import 'achievements_tab.dart';
import 'adventure_tab.dart';
import 'away_summary_card.dart';
import 'character_tab.dart';
import 'controller_scope.dart';
import 'journal_screen.dart';
import 'labels.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  var _tab = 0;

  static const _titles = ['Adventure', 'Character', 'Achievements'];

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
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
        title: Text(_titles[_tab]),
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
      body: switch (_tab) {
        0 => const AdventureTab(),
        1 => const CharacterTab(),
        _ => const AchievementsTab(),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.explore), label: 'Adventure'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Character'),
          NavigationDestination(
            icon: Icon(Icons.emoji_events),
            label: 'Achievements',
          ),
        ],
      ),
    );
  }
}
