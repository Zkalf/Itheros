import 'package:flutter/material.dart';

import 'achievements_tab.dart';
import 'adventure_tab.dart';
import 'character_tab.dart';
import 'journal_screen.dart';

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
