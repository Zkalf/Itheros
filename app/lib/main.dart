import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:path_provider/path_provider.dart';

import 'game_controller.dart';
import 'game_data_loader.dart';
import 'persistence/save_store.dart';
import 'steps/health_connect_step_source.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final data = await loadBundledGameData();
  final source = HealthConnectStepSource();
  final controller = GameController(
    game: Game(data),
    source: source,
    permissions: source,
    store: SaveStore(await getApplicationSupportDirectory()),
    // Owner builds pass --dart-define=TEST_WALK=true; friends' builds don't.
    testWalkAllowed: const bool.fromEnvironment('TEST_WALK'),
  );
  runApp(WalkingRpgApp(controller: controller));
  await controller.start();
}
