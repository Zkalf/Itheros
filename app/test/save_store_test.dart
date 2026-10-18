// Atomic save file: acceptance criterion 3 (a crash mid-save loses nothing).
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/persistence/save_data.dart';
import 'package:walkingrpg/persistence/save_store.dart';

import 'support.dart';

void main() {
  final game = loadTestGame();
  late Directory dir;
  late SaveStore store;

  SaveData saveWithBank(int bank) => SaveData(
    game: game.newGame(seed: 1)..bank = bank,
    firstDay: '2026-10-18',
    credited: {'2026-10-18': bank},
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('save_store_test');
    store = SaveStore(dir);
  });

  tearDown(() => dir.delete(recursive: true));

  test('no save yet loads as null', () async {
    expect(await store.load(), isNull);
  });

  test('a save loads back identically', () async {
    await store.save(saveWithBank(42));
    final loaded = await store.load();
    expect(loaded!.toJson(), saveWithBank(42).toJson());
  });

  test('a later save replaces the earlier one', () async {
    await store.save(saveWithBank(1));
    await store.save(saveWithBank(2));
    expect((await store.load())!.game.bank, 2);
  });

  test('a crash before the rename leaves the old save intact', () async {
    await store.save(saveWithBank(7));
    // Simulate a crash mid-save: a half-written temp file, never renamed.
    await File('${dir.path}/save.json.tmp').writeAsString('{"version": 1, "fi');

    final loaded = await store.load();
    expect(loaded!.game.bank, 7);

    await store.save(saveWithBank(8));
    expect((await store.load())!.game.bank, 8);
  });
}
