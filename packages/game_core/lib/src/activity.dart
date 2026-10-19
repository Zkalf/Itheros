enum ActivityKind { travel, fight, gather, craft }

/// What the player asked the character to do. Every activity costs steps.
class Activity {
  const Activity.travel(String to) : this._(ActivityKind.travel, to);
  const Activity.fight(String enemy) : this._(ActivityKind.fight, enemy);
  const Activity.gather(String node) : this._(ActivityKind.gather, node);
  const Activity.craft(String recipe) : this._(ActivityKind.craft, recipe);
  const Activity._(this.kind, this.target);

  factory Activity.fromJson(Map<String, Object?> json) => Activity._(
    ActivityKind.values.byName(json['kind'] as String),
    json['target'] as String,
  );

  final ActivityKind kind;

  /// Destination, enemy, node or recipe id, depending on [kind].
  final String target;

  Map<String, Object?> toJson() => {'kind': kind.name, 'target': target};

  @override
  bool operator ==(Object other) =>
      other is Activity && other.kind == kind && other.target == target;

  @override
  int get hashCode => Object.hash(kind, target);

  @override
  String toString() => 'Activity.${kind.name}($target)';
}

enum StopKind { untilGrey, untilHave, untilCrafted, never }

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

  /// Keeps going; only allowed for the last action.
  const StopCondition.never() : this._(StopKind.never);

  const StopCondition._(this.kind, {this.item, this.count = 0});

  factory StopCondition.fromJson(Map<String, Object?> json) => StopCondition._(
    StopKind.values.byName(json['kind'] as String),
    item: json['item'] as String?,
    count: json['count'] as int? ?? 0,
  );

  /// The default for [a] (spec 0003 decision 4).
  factory StopCondition.defaultFor(Activity a) => a.kind == ActivityKind.fight
      ? const StopCondition.untilGrey()
      : const StopCondition.never();

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
