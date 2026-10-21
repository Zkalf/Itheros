import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:walkingrpg/persistence/save_data.dart';
import 'package:walkingrpg/version.dart';

import 'support.dart';

/// Every released version's save must load in this one (spec 0007 §8).
void main() {
  final fixtures =
      Directory('test/fixtures/saves')
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  test('there is at least one sample save', () {
    expect(fixtures, isNotEmpty);
  });

  for (final f in fixtures) {
    final name = f.uri.pathSegments.last;
    test('$name loads with level, XP, bank and items kept', () {
      final json = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      final raw = json['game'] as Map<String, Object?>;
      final save = SaveData.fromJson(json);
      expect(save.game.xp, raw['xp']);
      expect(save.game.bank, raw['bank']);
      expect(save.game.location, raw['location']);
      expect(save.game.inventory, raw['inventory']);
      expect(save.journal, hasLength((json['journal'] as List).length));
    });

    // Spec 0008 criterion 12: gear on paper-doll slots, visited areas
    // explored.
    test('$name migrates to the paper doll and explored areas', () {
      final json = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      final raw = json['game'] as Map<String, Object?>;
      final game = loadTestGame();
      final s = game.migrate(SaveData.fromJson(json).game);
      final slots = {for (final g in game.data.gearSlots) g.id};
      expect(slots, containsAll(s.equipment.keys));
      for (final MapEntry(:key, :value) in s.equipment.entries) {
        expect(game.slotsFor(value), contains(key));
      }
      expect(
        s.equipment.length + s.inventory.values.fold(0, (a, b) => a + b),
        (raw['equipment'] as Map).length +
            (raw['inventory'] as Map).values.fold<int>(
              0,
              (a, b) => a + (b as int),
            ),
        reason: 'no item lost',
      );
      final visited = [
        for (final k in (raw['counters'] as Map).keys)
          if ((k as String).startsWith('visited.')) k.substring(8),
      ];
      expect(s.explored, containsAll({...visited, raw['location']}));
      expect(s.xp, raw['xp']);
    });
  }

  test('the version shown in the game matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final name = RegExp(
      r'^version: ([^+\s]+)',
      multiLine: true,
    ).firstMatch(pubspec)!.group(1);
    expect(appVersion, name);
  });
}
