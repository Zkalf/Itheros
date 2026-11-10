import 'dart:async';

import 'package:flutter/material.dart';

import '../game_controller.dart';
import 'achievements_screen.dart';
import 'actions.dart';
import 'away_summary_card.dart';
import 'bank_screen.dart';
import 'camp_tour.dart';
import 'character_tab.dart';
import 'controller_scope.dart';
import 'journal_screen.dart';
import 'labels.dart';
import 'now_tab.dart';
import 'profession_screen.dart' show RecipeFilter;
import 'professions_tab.dart';
import 'settings_screen.dart';
import 'supply_chest_screen.dart';
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

  /// Ends the camp tour on the Now tab (spec 0022 rules 14-16).
  void _endTour() {
    setState(() => _screen = _Screen.now);
    ControllerScope.read(context).endTour();
  }

  @override
  Widget build(BuildContext context) {
    final c = ControllerScope.of(context);
    const screens = _Screen.values;
    // The camp tour (spec 0022): its step picks the tab, and only its card
    // takes taps (decision 5).
    final tourIndex = c.tourStep;
    final tour = tourIndex == null ? null : tourSteps[tourIndex];
    final screen = tour == null
        ? _screen
        : _Screen.values.byName(tour.tab.name);
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
    return PopScope(
      // The back gesture ends the tour (spec 0022 rule 15).
      canPop: tour == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && c.tourStep != null) _endTour();
      },
      child: _scaffold(context, c, screens, screen, tourIndex),
    );
  }

  Widget _scaffold(
    BuildContext context,
    GameController c,
    List<_Screen> screens,
    _Screen screen,
    int? tourIndex,
  ) {
    final touring = tourIndex != null;
    return Scaffold(
      // No title: the lit tab names the screen (spec 0014 §4.1). The
      // buttons stand on one plate (§2.2).
      appBar: AppBar(
        actions: [
          // During the tour the buttons do nothing (spec 0022 rule 13).
          IgnorePointer(
            ignoring: touring,
            child: BarPlate(
              children: [
                // The bank in one tap, from any tab (spec 0020 amendment 5).
                IconButton(
                  key: const ValueKey('bank-button'),
                  icon: const Icon(Icons.account_balance),
                  tooltip: 'Bank',
                  onPressed: () => openBank(context),
                ),
                // Spec 0013 §3.1: left of Achievements, a dot while a chest
                // waits.
                IconButton(
                  key: const ValueKey('supply-chest-button'),
                  icon: Badge(
                    key: const ValueKey('supply-chest-dot'),
                    isLabelVisible: c.state.supplyChests.isNotEmpty,
                    child: const Icon(Icons.inventory_2),
                  ),
                  tooltip: 'Supply chest',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SupplyChestScreen(),
                    ),
                  ),
                ),
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
                    unawaited(c.markSeen(unseen));
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
          ),
        ],
      ),
      body: IgnorePointer(
        ignoring: touring,
        child: ShowNow(
          show: () {
            if (mounted) setState(() => _screen = _Screen.now);
          },
          child: switch (screen) {
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
            // The tour opens Character on a pane (spec 0022 rule 18).
            _Screen.character => switch (tourIndex) {
              final i? => CharacterTab(
                key: ValueKey('tour-character-$i'),
                pane: tourSteps[i].pane,
              ),
              null => const CharacterTab(),
            },
          },
        ),
      ),
      // The bottom bar is a plate with the four tabs (spec 0014 §2.2).
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(gutter, 0, gutter, gutter),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // The tour's card, just above the bar (spec 0022 §3.2).
              if (tourIndex != null) ...[
                TourCard(controller: c, step: tourIndex, onEnd: _endTour),
                const SizedBox(height: 8),
              ],
              IgnorePointer(
                ignoring: touring,
                child: DecoratedBox(
                  decoration: plateDecoration,
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: NavigationBar(
                      selectedIndex: screens.indexOf(screen),
                      onDestinationSelected: (i) =>
                          setState(() => _screen = screens[i]),
                      destinations: [
                        for (final s in screens)
                          _Tab(
                            key: ValueKey('tab-${s.name}'),
                            icon: Icon(s.icon),
                            label: s.title,
                            lit: s == screen,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
