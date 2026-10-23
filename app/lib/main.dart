import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:game_core/game_core.dart';
import 'package:path_provider/path_provider.dart';

import 'game_controller.dart';
import 'game_data_loader.dart';
import 'persistence/save_store.dart';
import 'steps/health_connect_step_source.dart';
import 'ui/app.dart';
import 'ui/images.dart';
import 'ui/onboarding_screens.dart' show precacheSplash;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The first frame of the splash shows its picture (spec 0014 §3.3). Until
  // then the phone shows its own splash screen with the emblem.
  final splash = precacheSplash();
  final data = await loadBundledGameData();
  // The keys that have an image file (plan 0017, choice 3). Without the
  // index, each thing shows its placeholder.
  final images = await ImageIndex.load(rootBundle)
      .catchError((Object _) => ImageIndex.empty);
  final source = HealthConnectStepSource();
  final controller = GameController(
    game: Game(data),
    source: source,
    permissions: source,
    store: SaveStore(await getApplicationSupportDirectory()),
    // Owner builds pass --dart-define=TEST_WALK=true; friends' builds don't.
    testWalkAllowed: const bool.fromEnvironment('TEST_WALK'),
  );
  await splash;
  runApp(WalkingRpgApp(controller: controller, images: images));
  await controller.start();
}
