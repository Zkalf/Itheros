import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
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
    final saved =
        (jsonDecode(f.readAsStringSync())['game'] as Map)['version'] as int;
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

    // Spec 0009 criterion 10: gear above Common rolls its bonus stats once,
    // and every monster with a kill counts as fought.
    test('$name rolls bonus stats and marks fought monsters', () {
      final json = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      final raw = json['game'] as Map<String, Object?>;
      final game = loadTestGame();
      final data = game.data;
      final s = game.migrate(SaveData.fromJson(json).game);
      for (final key in [...s.inventory.keys, ...s.equipment.values]) {
        if (data.itemOf(key)?.slot == null) continue;
        expect(
          data.bonusRolls(key),
          hasLength(data.qualities.indexOf(data.qualityOf(key))),
          reason: key,
        );
      }
      final killed = {
        for (final MapEntry(:key, :value) in (raw['counters'] as Map).entries)
          if ((key as String).startsWith('kills.') && (value as int) > 0)
            key.substring(6),
      };
      expect(s.fought, killed);
    });

    // Spec 0010 criterion 13: Mining and Crafting learned, at the XP the
    // counters earn; the character's XP kept.
    test('$name learns Mining and Crafting from its counters', () {
      final json = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      final raw = json['game'] as Map<String, Object?>;
      final counters = (raw['counters'] as Map).cast<String, int>();
      final game = loadTestGame();
      final data = game.data;
      final s = game.migrate(SaveData.fromJson(json).game);
      var mining = 0, crafting = 0;
      for (final n in data.nodes.values) {
        mining += (counters['gathered.${n.item}'] ?? 0) * n.xp;
      }
      for (final r in data.recipes.values) {
        crafting += (counters['crafted.${r.output}'] ?? 0) * r.xp;
      }
      expect(s.learned, {'mining', 'crafting'});
      expect(s.tools, {'mining': 'old_pick', 'crafting': 'old_hammer'});
      expect(s.professions['mining'] ?? 0, mining);
      expect(s.professions['crafting'] ?? 0, crafting);
      expect(s.xp, raw['xp']);
    }, skip: saved >= 8 ? 'saved with professions: nothing to migrate' : false);

    // Spec 0011 criterion 14: version 9, the new professions unlearned, no
    // meal, no records, the cove hidden.
    test('$name loads as version 9 with nothing of the lake yet', () {
      final json = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      final game = loadTestGame();
      final s = game.migrate(SaveData.fromJson(json).game);
      for (final p in ['fishing', 'hunting', 'cooking']) {
        expect(s.learned, isNot(contains(p)));
        expect(s.tools, isNot(contains(p)));
      }
      expect(s.meal, isNull);
      expect(s.autoEat, isNull);
      expect(s.records, isEmpty);
      expect(s.bottles, 0);
      expect(game.isHidden(s, 'smugglers_cove'), isTrue);
    });

    // Spec 0012 criterion 10: no character yet, so "Who are you?" shows
    // once; everything else kept. Spec 0016 §6 raised the version to 11,
    // spec 0017 to 12.
    test('$name loads as version 12 with no character', () {
      final json = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      final raw = json['game'] as Map<String, Object?>;
      final game = loadTestGame();
      final s = game.migrate(SaveData.fromJson(json).game);
      expect(GameState.fromJson(s.toJson()).loadedVersion, 12);
      expect(s.character, isNull);
      expect(s.xp, raw['xp']);
      expect(s.bank, raw['bank']);
    });

    // Spec 0018 criteria 32-33: a save from before version 4 has no last
    // version; a save of version 4 keeps it.
    final saveVersion = jsonDecode(f.readAsStringSync())['version'] as int;
    test('$name loads with an empty last version', () {
      final json = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      final save = SaveData.fromJson(json);
      expect(save.lastVersion, isNull);
      final again = SaveData.fromJson(
        save.copyWith(lastVersion: '0.6.0').toJson(),
      );
      expect(again.toJson()['version'], 4);
      expect(again.lastVersion, '0.6.0');
    }, skip: saveVersion >= 4 ? 'saved with a last version' : false);
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
