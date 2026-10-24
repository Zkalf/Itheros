import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show AssetBundle, AssetManifest;
import 'package:game_core/game_core.dart';

/// The keys that have an image file (plan 0017, choice 3). A key is the path
/// under `assets/images/` without `.webp`, for example `items/hide_vest`.
class ImageIndex {
  const ImageIndex([this.keys = const {}]);

  /// No image files: each thing shows its placeholder.
  static const empty = ImageIndex();

  /// The keys of the `.webp` files under `assets/images/` in [paths]. It
  /// ignores each other path.
  factory ImageIndex.fromAssets(Iterable<String> paths) => ImageIndex({
    for (final p in paths)
      if (p.startsWith(_folder) && p.endsWith(_type))
        p.substring(_folder.length, p.length - _type.length),
  });

  /// The index of the images in the asset manifest of [bundle].
  static Future<ImageIndex> load(AssetBundle bundle) async =>
      ImageIndex.fromAssets(
        (await AssetManifest.loadFromAssetBundle(bundle)).listAssets(),
      );

  static const _folder = 'assets/images/';
  static const _type = '.webp';

  final Set<String> keys;

  bool has(String key) => keys.contains(key);

  /// The image of [thing] by its key (spec 0014 §3.1), or else its
  /// placeholder (§3.2). A placeholder comes from [phSpots], not from the
  /// index, so the placeholders show without an index.
  Picture pictureOf(GameData data, Thing thing) => switch (thing) {
    MonsterThing(:final id) => _image('monsters/$id', 'monster'),
    ItemThing(:final key) => _item(data, key),
    // The locked patch is a picture, not a placeholder: it has no PH mark.
    AchievementThing(earned: false) => const Picture('pictures/locked_patch'),
    AchievementThing(:final id) => _image('achievements/$id', 'generic'),
    RankThing(:final name) => _image(
      'achievements/rank_${name.toLowerCase()}',
      'generic',
    ),
    PlaceThing(fogged: true) => _image('places/fog', 'generic'),
    PlaceThing(:final id) => _place(data, id),
    PlayerThing(:final origin, :final gender) => _image(
      'players/${origin}_${gender.name}',
      'player',
    ),
    // A spot shows the tool of its profession until it has an image (spec
    // 0014 amendment 1).
    SpotThing(:final id) => _image(
      'spots/$id',
      'tool_${data.nodes[id]?.profession}',
    ),
  };

  Picture _image(String key, String placeholder) =>
      has(key) ? Picture(key) : Picture.placeholderOf(placeholder);

  /// An item key may carry a quality and bonus rolls (`hide_vest@rare`): the
  /// image is the image of its item. Gear never gets the material
  /// placeholder.
  Picture _item(GameData data, String key) {
    final def = data.itemOf(key);
    final id = def?.id ?? key.split(RegExp(r'[@+]')).first;
    return _image('items/$id', switch (def) {
      null => 'generic',
      ItemDef(:final slot?) => 'gear_$slot',
      ItemDef(:final tool?) => 'tool_${tool.profession}',
      ItemDef(meal: != null) => 'meal',
      _ => 'material',
    });
  }

  /// A place: its own marker, else the marker of its kind (plan 0017, choice
  /// 5). A water place without a marker keeps today's water icon.
  Picture _place(GameData data, String id) {
    if (has('places/$id')) return Picture('places/$id');
    final kind = placeKind(data, id);
    if (kind != null && has('places/$kind')) return Picture('places/$kind');
    return kind == 'water'
        ? const Picture.icon(Icons.water)
        : Picture.placeholderOf('generic');
  }
}

/// The kind of a place, as the World map tells it today: `forge`, `water`,
/// `no_monsters` or `monsters` (plan 0017, choice 5).
String? placeKind(GameData data, String id) {
  final l = data.locations[id];
  if (l == null) return null;
  if (l.crafting) return 'forge';
  // A lake or cove: only fishing spots, no monsters (spec 0011 §3.1).
  if (l.enemies.isEmpty &&
      l.nodes.isNotEmpty &&
      l.nodes.every((n) => data.nodes[n]?.profession == 'fishing')) {
    return 'water';
  }
  return l.enemies.isEmpty ? 'no_monsters' : 'monsters';
}

/// What a socket shows: an image file, a placeholder or an icon.
class Picture {
  const Picture(String this.key, {this.placeholder = false}) : icon = null;

  /// Today's icon for a thing without an image: only the water icon.
  const Picture.icon(IconData this.icon) : key = null, placeholder = false;

  /// The placeholder of [kind] (`gear_ring`, `material`), or the generic
  /// placeholder for a kind that has none (spec 0014 §3.2).
  factory Picture.placeholderOf(String kind) {
    final key = 'placeholders/$kind';
    return Picture(
      phSpots.containsKey(key) ? key : 'placeholders/generic',
      placeholder: true,
    );
  }

  /// For example `items/hide_vest`, `placeholders/gear_chest` or
  /// `pictures/locked_patch`; null for an icon.
  final String? key;
  final IconData? icon;
  final bool placeholder;

  String? get asset => key == null ? null : 'assets/images/$key.webp';
}

/// A thing of spec 0014 §3.1 that shows an image.
sealed class Thing {
  const Thing();
}

final class MonsterThing extends Thing {
  const MonsterThing(this.id);
  final String id;
}

/// An item key: an item id, maybe with a quality and bonus rolls.
final class ItemThing extends Thing {
  const ItemThing(this.key);
  final String key;
}

final class AchievementThing extends Thing {
  const AchievementThing(this.id, {required this.earned});
  final String id;
  final bool earned;
}

/// A rank by its name, such as `Recruit`.
final class RankThing extends Thing {
  const RankThing(this.name);
  final String name;
}

final class PlaceThing extends Thing {
  const PlaceThing(this.id, {required this.fogged});
  final String id;
  final bool fogged;
}

/// The player's portrait follows the origin and the gender (spec 0014
/// decision 9).
final class PlayerThing extends Thing {
  const PlayerThing(this.origin, this.gender);
  final String origin;
  final Gender gender;
}

/// A gathering spot, such as `copper_vein` (spec 0014 amendment 1).
final class SpotThing extends Thing {
  const SpotThing(this.id);
  final String id;
}

/// Where the PH mark sits on a placeholder (spec 0014 §3.2). [x] and [y] are
/// parts of the image from its top left. A negative [angle] (in degrees)
/// turns the mark anticlockwise. The spec fixes the size of the mark, so a
/// spot has no scale.
class PhSpot {
  const PhSpot(this.x, this.y, this.angle);
  final double x;
  final double y;
  final double angle;
}

/// The PH spot of each of the 25 placeholders of plan 0017, with the part of
/// the object that it marks.
const phSpots = {
  'placeholders/gear_head': PhSpot(.47, .47, -9), // the forehead of the cap
  'placeholders/gear_neck': PhSpot(.44, .73, -12), // the face of the stone
  'placeholders/gear_shoulder': PhSpot(.42, .45, -12), // the outer plate
  'placeholders/gear_cloak': PhSpot(.42, .68, 0), // the front, above the hem
  'placeholders/gear_chest': PhSpot(.63, .43, -5), // right of the laces
  'placeholders/gear_bracer': PhSpot(.52, .47, -6), // between the two straps
  'placeholders/gear_gloves': PhSpot(.68, .52, -6), // the back of a hand
  'placeholders/gear_belt': PhSpot(.7, .62, 0), // the strap by the buckle
  'placeholders/gear_legs': PhSpot(.31, .47, 0), // the left shin plate
  'placeholders/gear_boots': PhSpot(.25, .4, -4), // the front boot's shaft
  'placeholders/gear_ring': PhSpot(.56, .27, -14), // the top of the band
  'placeholders/gear_trinket': PhSpot(.27, .64, 0), // the face of the disc
  'placeholders/gear_mainHand': PhSpot(.585, .415, -41), // along the blade
  'placeholders/gear_offHand': PhSpot(.5, .76, 0), // the planks under the boss
  'placeholders/tool_mining': PhSpot(.45, .63, -62), // the handle wrap
  'placeholders/tool_woodcutting': PhSpot(.43, .65, -56), // the handle wrap
  'placeholders/tool_fishing': PhSpot(.2, .8, -48), // the cork grip
  'placeholders/tool_hunting': PhSpot(.46, .38, -60), // the grip wrap
  'placeholders/tool_crafting': PhSpot(.5, .55, -57), // the handle wrap
  'placeholders/tool_cooking': PhSpot(.5, .62, 0), // the belly of the pot
  'placeholders/material': PhSpot(.46, .66, 0), // the belly of the sack
  'placeholders/meal': PhSpot(.56, .75, 0), // the front of the bowl
  'placeholders/monster': PhSpot(.43, .83, 0), // the chest of the robe
  'placeholders/player': PhSpot(.5, .82, 0), // the cloak, below the toggle
  'placeholders/generic': PhSpot(.48, .62, -4), // the burlap of the bundle
};

/// Gives the screens the [ImageIndex] of the app. Without a scope, each
/// thing shows its placeholder.
class ImageScope extends InheritedWidget {
  const ImageScope({super.key, required this.images, required super.child});

  final ImageIndex images;

  static ImageIndex of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ImageScope>()?.images ??
      ImageIndex.empty;

  @override
  bool updateShouldNotify(ImageScope oldWidget) => images != oldWidget.images;
}
