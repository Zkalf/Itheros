part of '../game.dart';

/// The story (spec 0023): people and their lines, the King lines at Camp,
/// and lore pages.
extension GameStory on Game {
  /// Whether [c] holds for [s]: a counter or the level (§2.3).
  bool _holds(GameState s, Criterion? c) => switch (c) {
    null => true,
    CounterCriterion(:final counter, :final atLeast) =>
      (s.counters[counter] ?? 0) >= atLeast,
    LevelCriterion(level: final need) => level(s) >= need,
    _ => false,
  };

  /// Whether [line] is open: its condition holds and its origin fits (§2.2).
  bool lineOpen(GameState s, LineDef line) =>
      _holds(s, line.after) &&
      (line.origin == null || s.character?.origin == line.origin);

  /// [person]'s open lines, in data order.
  List<LineDef> openLines(GameState s, String person) => [
    for (final l in data.people[person]!.lines)
      if (lineOpen(s, l)) l,
  ];

  /// [person]'s newest line: the open line last in data order (§2.2).
  LineDef? newestLine(GameState s, String person) =>
      openLines(s, person).lastOrNull;

  /// Whether [person] has an open line not yet heard: the dot (§3.1).
  bool hasNewLine(GameState s, String person) =>
      openLines(s, person).any((l) => !s.heard.contains(l.id));

  /// The people where the character stands (§3.1).
  List<PersonDef> peopleHere(GameState s) => [
    for (final p in data.people.values)
      if (p.location == s.location) p,
  ];

  /// The open Camp lines of [who], a teacher's profession or
  /// [GameData.trainerId], in data order (spec 0023 §2.5, spec 0025 §2.4).
  Iterable<LineDef> openCampLines(GameState s, String who) =>
      (data.campLines[who] ?? const <LineDef>[]).where((l) => lineOpen(s, l));

  /// The newest open Camp line of [who], the last open one in data order, or
  /// null (spec 0025 §2.4).
  LineDef? campLine(GameState s, String who) =>
      openCampLines(s, who).lastOrNull;

  /// Whether one of [who]'s open Camp lines is not heard: the dot (§2.5).
  bool campLineWaiting(GameState s, String who) =>
      openCampLines(s, who).any((l) => !s.heard.contains(l.id));

  /// The trainer's opening line, filled: the newest Camp line once open,
  /// else the greeting (§2.5).
  String trainerLine(GameState s) => fill(
    campLine(s, GameData.trainerId)?.text ?? data.trainer.greeting,
    s.character,
  );

  /// Hears [who]: a person, who must be here, or a teacher or the trainer.
  /// Every open line becomes heard, and the lines' pages are found (§2.2).
  /// The pages are those this hearing found; the events name the lore
  /// achievements that they complete (§2.6).
  ({GameState state, List<String> pages, List<GameEvent> events}) hear(
    GameState s,
    String who,
  ) {
    final n = s.copy();
    final pages = <String>[];
    final events = <GameEvent>[];
    if (data.people[who] case final person?) {
      if (s.location != person.location) {
        throw ActivityError('${person.name} is not here');
      }
      for (final l in openLines(s, who)) {
        n.heard.add(l.id);
        if (l.page case final page? when n.lore.add(page)) pages.add(page);
      }
    } else {
      n.heard.addAll(openCampLines(s, who).map((l) => l.id));
    }
    if (pages.isNotEmpty) {
      for (final a in data.achievements.values) {
        if (a.criterion is LoreCriterion &&
            !n.achievements.contains(a.id) &&
            achievementMet(n, a)) {
          _earn(n, a, events);
        }
      }
    }
    return (state: n, pages: pages, events: events);
  }

  /// How much of [place]'s lore is found (§3.3).
  ({int found, int total}) loreCount(GameState s, String place) {
    final all = data.loreOf(place);
    return (found: all.where(s.lore.contains).length, total: all.length);
  }

  /// Gives each page whose source has happened: the start, a first visit
  /// or a deed (§2.4). Mutates [s]; [events] gets one per page, if given.
  void _givePages(GameState s, [List<GameEvent>? events]) {
    for (final p in data.pages.values) {
      if (s.lore.contains(p.id)) continue;
      final due = switch (p.source) {
        PageSource.start => true,
        PageSource.visit => (s.counters['visited.${p.place}'] ?? 0) > 0,
        PageSource.deed => _holds(s, p.after),
        PageSource.line || PageSource.find => false,
      };
      if (!due) continue;
      s.lore.add(p.id);
      events?.add(LorePageFound(p.id));
    }
  }
}
