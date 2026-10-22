import 'activity.dart';

/// The "Next goal" line (spec 0002 §9.3): the first rule that applies.
sealed class Goal {
  const Goal();
}

/// An owned item beats the one equipped in its slot.
class EquipGoal extends Goal {
  const EquipGoal(this.item);
  final String item;
}

/// A recipe that improves a slot can be crafted now.
class CraftGoal extends Goal {
  const CraftGoal(this.recipe);
  final String recipe;
}

/// A recipe that improves a slot is missing [count] more [item], which
/// [source] (a fight or gathering) provides.
class CollectGoal extends Goal {
  const CollectGoal(this.item, this.count, this.source);
  final String item;
  final int count;
  final Activity source;
}

/// The best upgrade for the character's level waits only on [profession]
/// reaching [level] (it is at [current]): [target] is the recipe or the
/// spot that level opens (spec 0010 §8.4).
class ProfessionGoal extends Goal {
  const ProfessionGoal(this.profession, this.level, this.current, this.target);
  final String profession;
  final int level;
  final int current;
  final Activity target;
}

/// The yellow monster with the most XP per step.
class FightGoal extends Goal {
  const FightGoal(this.enemy);
  final String enemy;
}
