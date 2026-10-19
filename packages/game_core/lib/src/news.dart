/// What a level-up card lists, in the order of spec 0002 §9.1.
enum NewsKind {
  /// A new rank and its ceremony line.
  rank,
  area,
  monster,
  gatheringSpot,
  recipe,
  gearSlot,
  talentPoint,

  /// A monster that is now exactly the player's level.
  yourLevel,

  /// A monster that just turned grey; it still drops its loot.
  turnedGrey,

  /// The queue grows to [LevelNews.id] actions (spec 0003 §2).
  queueSlots,

  /// "Until I have N" and "until N crafted" open (spec 0003 §3).
  untilN,
}

class LevelNews {
  const LevelNews(this.kind, this.id);

  final NewsKind kind;

  /// Rank name, location, enemy, node, recipe or slot id, or the queue
  /// size; empty for a talent point or "until N".
  final String id;

  @override
  bool operator ==(Object other) =>
      other is LevelNews && other.kind == kind && other.id == id;

  @override
  int get hashCode => Object.hash(kind, id);

  @override
  String toString() => 'LevelNews(${kind.name}, $id)';
}
