/// [reroll] is a forge action on one item (spec 0010 §7.2-7.3).
enum ActivityKind { travel, fight, gather, craft, reroll }

/// What the player asked the character to do. Every activity costs steps.
class Activity {
  const Activity.travel(String to) : this._(ActivityKind.travel, to);
  const Activity.fight(String enemy) : this._(ActivityKind.fight, enemy);
  const Activity.gather(String node) : this._(ActivityKind.gather, node);
  const Activity.craft(String recipe) : this._(ActivityKind.craft, recipe);

  /// Rerolls the quality of the item with [key] (spec 0010 §7.2).
  const Activity.reroll(String key) : this._(ActivityKind.reroll, key);

  /// Rerolls bonus stat [index] (in key order) of the Legendary with [key]
  /// (spec 0010 §7.3).
  Activity.rerollStat(String key, int index)
    : this._(ActivityKind.reroll, '$key$statMark$index');
  const Activity._(this.kind, this.target);

  factory Activity.fromJson(Map<String, Object?> json) => Activity._(
    ActivityKind.values.byName(json['kind'] as String),
    json['target'] as String,
  );

  final ActivityKind kind;

  /// Destination, enemy, node or recipe id, or a reroll's item key (with
  /// [statMark] and an index for a stat reroll), depending on [kind].
  final String target;

  /// Separates a stat reroll's item key from the stat's index.
  static const statMark = '#';

  /// A reroll's item key.
  String get rerollKey => target.split(statMark).first;

  /// A stat reroll's index, or null for a quality reroll.
  int? get rerollStatIndex => switch (target.split(statMark)) {
    [_, final i] => int.tryParse(i),
    _ => null,
  };

  Map<String, Object?> toJson() => {'kind': kind.name, 'target': target};

  @override
  bool operator ==(Object other) =>
      other is Activity && other.kind == kind && other.target == target;

  @override
  int get hashCode => Object.hash(kind, target);

  @override
  String toString() => 'Activity.${kind.name}($target)';
}

enum StopKind { untilGrey, untilHave, untilCrafted, untilQuality, never }

/// When a queued action ends by itself (spec 0003 §3).
class StopCondition {
  /// Fights: the monster is grey for the player.
  const StopCondition.untilGrey() : this._(StopKind.untilGrey);

  /// Fights and gathering: the player owns [count] of [item].
  const StopCondition.untilHave(String item, int count)
    : this._(StopKind.untilHave, item: item, count: count);

  /// Crafting: this action crafted [count] items.
  const StopCondition.untilCrafted(int count)
    : this._(StopKind.untilCrafted, count: count);

  /// Crafting: this action made an item of [quality] (an id) or better
  /// (spec 0006 decision 9).
  const StopCondition.untilQuality(String quality)
    : this._(StopKind.untilQuality, item: quality);

  /// Keeps going; only allowed for the last action.
  const StopCondition.never() : this._(StopKind.never);

  const StopCondition._(this.kind, {this.item, this.count = 0});

  factory StopCondition.fromJson(Map<String, Object?> json) => StopCondition._(
    StopKind.values.byName(json['kind'] as String),
    item: json['item'] as String?,
    count: json['count'] as int? ?? 0,
  );

  /// The default for [a] (spec 0003 decision 4).
  factory StopCondition.defaultFor(Activity a) => switch (a.kind) {
    ActivityKind.fight => const StopCondition.untilGrey(),
    // A reroll is one roll (spec 0010 §7.2).
    ActivityKind.reroll => const StopCondition.untilCrafted(1),
    _ => const StopCondition.never(),
  };

  final StopKind kind;
  final String? item;
  final int count;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    if (item != null) 'item': item,
    if (count != 0) 'count': count,
  };

  @override
  bool operator ==(Object other) =>
      other is StopCondition &&
      other.kind == kind &&
      other.item == item &&
      other.count == count;

  @override
  int get hashCode => Object.hash(kind, item, count);

  @override
  String toString() => 'StopCondition.${kind.name}($item, $count)';
}

/// An action waiting in the queue.
class PlannedAction {
  const PlannedAction(this.activity, this.stop);

  factory PlannedAction.fromJson(Map<String, Object?> json) => PlannedAction(
    Activity.fromJson(json),
    StopCondition.fromJson(json['stop'] as Map<String, Object?>),
  );

  final Activity activity;
  final StopCondition stop;

  Map<String, Object?> toJson() => {
    ...activity.toJson(),
    'stop': stop.toJson(),
  };
}

/// A player action the rules don't allow (locked, wrong place, no materials).
class ActivityError implements Exception {
  ActivityError(this.message);

  final String message;

  @override
  String toString() => 'ActivityError: $message';
}
