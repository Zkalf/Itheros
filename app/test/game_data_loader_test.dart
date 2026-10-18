// The game data must be bundled into the app as package assets.
import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/game_data_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled game data loads', () async {
    final data = await loadBundledGameData();
    expect(data.enemies.keys, contains('goblin'));
    expect(data.startLocation, 'camp');
  });
}
