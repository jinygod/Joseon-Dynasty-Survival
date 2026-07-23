import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';
import 'package:pixel_survivor/game/content/attack_visual_registry.dart';
import 'package:pixel_survivor/game/content/sprite_atlas_contract.dart';

class PlayerVisualContract {
  const PlayerVisualContract({
    required this.id,
    required this.category,
    required this.rotates,
    required this.layerId,
    required this.assetKey,
    required this.frameCount,
    required this.sourcePath,
  });

  final String id;
  final CombatVisualCategory category;
  final bool rotates;
  final String layerId;
  final String assetKey;
  final int frameCount;
  final String sourcePath;

  String get runtimePath => 'assets/images/$assetKey';
}

const playerVisualContracts = <PlayerVisualContract>[
  PlayerVisualContract(
    id: 'sealing_slash',
    category: CombatVisualCategory.hwando,
    rotates: true,
    layerId: 'trail',
    assetKey: 'vfx/player/sealing_slash_128.png',
    frameCount: 6,
    sourcePath: 'art_source/generated/player_vfx/sealing_slash_source.png',
  ),
  PlayerVisualContract(
    id: 'wind_thunder_fan',
    category: CombatVisualCategory.area,
    rotates: true,
    layerId: 'effect',
    assetKey: 'vfx/player/wind_thunder_fan_128.png',
    frameCount: 6,
    sourcePath: 'art_source/generated/player_vfx/wind_thunder_fan_source.png',
  ),
  PlayerVisualContract(
    id: 'singijeon_volley',
    category: CombatVisualCategory.projectile,
    rotates: true,
    layerId: 'effect',
    assetKey: 'projectiles/player/singijeon_128.png',
    frameCount: 4,
    sourcePath: 'art_source/generated/player_vfx/singijeon_source.png',
  ),
  PlayerVisualContract(
    id: 'jangseung_ward',
    category: CombatVisualCategory.area,
    rotates: false,
    layerId: 'effect',
    assetKey: 'zones/player/jangseung_ward_128.png',
    frameCount: 8,
    sourcePath: 'art_source/generated/player_vfx/jangseung_ward_source.png',
  ),
  PlayerVisualContract(
    id: 'frost_flask',
    category: CombatVisualCategory.area,
    rotates: false,
    layerId: 'effect',
    assetKey: 'zones/player/frost_field_128.png',
    frameCount: 8,
    sourcePath: 'art_source/generated/player_vfx/frost_field_source.png',
  ),
  PlayerVisualContract(
    id: 'talisman_attachment',
    category: CombatVisualCategory.status,
    rotates: false,
    layerId: 'effect',
    assetKey: 'vfx/player/talisman_attachment_128.png',
    frameCount: 4,
    sourcePath:
        'art_source/generated/player_vfx/talisman_attachment_source.png',
  ),
  PlayerVisualContract(
    id: 'talisman_transfer',
    category: CombatVisualCategory.status,
    rotates: true,
    layerId: 'effect',
    assetKey: 'vfx/player/talisman_transfer_128.png',
    frameCount: 6,
    sourcePath: 'art_source/generated/player_vfx/talisman_transfer_source.png',
  ),
  PlayerVisualContract(
    id: 'talisman_explosion',
    category: CombatVisualCategory.area,
    rotates: false,
    layerId: 'effect',
    assetKey: 'vfx/player/talisman_explosion_128.png',
    frameCount: 6,
    sourcePath: 'art_source/generated/player_vfx/talisman_explosion_source.png',
  ),
  PlayerVisualContract(
    id: 'talisman_small_ward',
    category: CombatVisualCategory.area,
    rotates: false,
    layerId: 'effect',
    assetKey: 'zones/player/talisman_ward_128.png',
    frameCount: 8,
    sourcePath: 'art_source/generated/player_vfx/talisman_ward_source.png',
  ),
  PlayerVisualContract(
    id: 'talisman_master_ward',
    category: CombatVisualCategory.area,
    rotates: false,
    layerId: 'effect',
    assetKey: 'zones/player/talisman_ward_128.png',
    frameCount: 8,
    sourcePath: 'art_source/generated/player_vfx/talisman_ward_source.png',
  ),
];

const sourceSha256ByPath = <String, String>{
  'art_source/generated/player_vfx/sealing_slash_source.png':
      '8489F18F29D0FFA7718740F913F357F27F360D38D71B2F6FAB688E6C4252249C',
  'art_source/generated/player_vfx/wind_thunder_fan_source.png':
      'FD13655DFE576C3C5A288F3428A44B128ECD9958C7F8DA7823ACCD4B36815298',
  'art_source/generated/player_vfx/singijeon_source.png':
      'D74B7E0ADC1FCC4B3C6591C0905A92D446EF132D09876A33FFAA29BF4062492B',
  'art_source/generated/player_vfx/jangseung_ward_source.png':
      '06FA239621BE14DA3D39D27E94DCF607EFD05333C2758B523F03F98BD7636321',
  'art_source/generated/player_vfx/frost_field_source.png':
      'D44C607209A3DEA91E5AEC9D130E275F28BB347891AC5F1162C3A243FB8BECF9',
  'art_source/generated/player_vfx/talisman_attachment_source.png':
      '1B0F3E9088F0F305A38F13EFE88DE658FA5A3CEA2100EC15499FB7BE8A705586',
  'art_source/generated/player_vfx/talisman_transfer_source.png':
      'E5C13F017D1F077AE9588943DE0B6C960950856653417F9AC52AABF8F0EA6129',
  'art_source/generated/player_vfx/talisman_explosion_source.png':
      '4F0D95405936D2745260CED39C59AE1899D4F6B0E2AA1CBCB273F95230C07683',
  'art_source/generated/player_vfx/talisman_ward_source.png':
      '428EE6B09087037EC37AB3E9B3C9890B53B6ECD8E6C53FD8FDC44E46C31BA444',
};

const runtimeSha256ByPath = <String, String>{
  'assets/images/vfx/player/sealing_slash_128.png':
      'B82F3541F2B4FDD78F70BEC746A4DAD66AA28B89D79FBFB284BEAEFD5E23921A',
  'assets/images/vfx/player/wind_thunder_fan_128.png':
      '5F5D263BCC3FEF8C78C950D3F195A69C45B5C080C0EB7F09D83C68F90EAB4629',
  'assets/images/projectiles/player/singijeon_128.png':
      '70F35C0E4AC6C959CF2913E1F6A8DB8DBECD4BBA1565F1FCADA4329A64F3931E',
  'assets/images/zones/player/jangseung_ward_128.png':
      'A98D7D872B8B76DA921353DB26D942D0675947E6956D66F82E2A9EC0EDC0F733',
  'assets/images/zones/player/frost_field_128.png':
      '18F3793EBEC841ED46B7708778389CAE2A2967772B0796D8108D9BD6DD50E201',
  'assets/images/vfx/player/talisman_attachment_128.png':
      '8D4F2A2EC3BAFF6B3925A9C47E67784EB1989697B04EB0CE3C9B95A0EC6B2B23',
  'assets/images/vfx/player/talisman_transfer_128.png':
      '70C349BC3C8C02FB85305125BFD334A952F3D25755BB6FF4AC4D68DD0D0366BF',
  'assets/images/vfx/player/talisman_explosion_128.png':
      'AFA34E825690CF823C2A6758ADDF2177118BEA082F51157C05FED27630F4564B',
  'assets/images/zones/player/talisman_ward_128.png':
      '83EE69223F5CCB73845C24E73CA36E486A8EF4CD221CC9124A15EF1CE6371385',
};

void main() {
  test('pubspec bundles each nested player visual directory', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    for (final directory in const [
      'assets/images/vfx/player/',
      'assets/images/projectiles/player/',
      'assets/images/zones/player/',
    ]) {
      expect(pubspec, contains('- $directory'));
    }
  });

  test('player combat visual IDs match their exact visual contracts', () {
    expect(playerVisualContracts, hasLength(10));
    expect(
      playerVisualContracts.map((contract) => contract.id).toSet(),
      hasLength(10),
    );

    for (final expected in playerVisualContracts) {
      final spec = AttackVisualRegistry.byId(expected.id);
      expect(spec.effectId, expected.id, reason: expected.id);
      expect(spec.category, expected.category, reason: expected.id);
      expect(
        spec.status,
        AttackVisualStatus.generatedReview,
        reason: expected.id,
      );
      expect(spec.rotateWithDirection, expected.rotates, reason: expected.id);
      expect(spec.layers, hasLength(1), reason: expected.id);

      final layer = spec.layers.single;
      expect(layer.id, expected.layerId, reason: expected.id);
      expect(layer.assetKey, expected.assetKey, reason: expected.id);
      expect(layer.frameSize, 128, reason: expected.id);
      expect(layer.frameCount, expected.frameCount, reason: expected.id);
      expect(layer.anchor, Anchor.center, reason: expected.id);
      expect(layer.priorityOffset, 0, reason: expected.id);
      expect(layer.startFraction, 0, reason: expected.id);
      expect(layer.endFraction, 1, reason: expected.id);
    }
  });

  test(
    'player visual sheets have exactly nine shared atlas and catalog paths',
    () {
      final runtimePaths = playerVisualContracts
          .map((contract) => contract.runtimePath)
          .toSet();
      expect(runtimePaths, hasLength(9));

      final smallWard = playerVisualContracts.singleWhere(
        (contract) => contract.id == 'talisman_small_ward',
      );
      final masterWard = playerVisualContracts.singleWhere(
        (contract) => contract.id == 'talisman_master_ward',
      );
      expect(smallWard.runtimePath, masterWard.runtimePath);
      expect(smallWard.sourcePath, masterWard.sourcePath);

      final matchingAtlases = ReplaceableArtCatalog.atlases
          .where((contract) => runtimePaths.contains(contract.runtimePath))
          .toList();
      final matchingCatalogPaths = AssetCatalog.effects.values
          .where(runtimePaths.contains)
          .toList();
      final atlasPaths = matchingAtlases
          .map((contract) => contract.runtimePath)
          .toSet();
      final catalogPaths = matchingCatalogPaths.toSet();
      expect(matchingAtlases, hasLength(9));
      expect(matchingCatalogPaths, hasLength(9));
      expect(atlasPaths, runtimePaths);
      expect(catalogPaths, runtimePaths);

      for (final expected in playerVisualContracts) {
        final contract = ReplaceableArtCatalog.atlases.singleWhere(
          (contract) => contract.runtimePath == expected.runtimePath,
        );
        expect(contract.frameWidth, 128, reason: expected.id);
        expect(contract.frameHeight, 128, reason: expected.id);
        expect(contract.columns, expected.frameCount, reason: expected.id);
        expect(contract.rows, 1, reason: expected.id);
        expect(
          contract.validatePngHeader(
            File(expected.runtimePath).readAsBytesSync(),
          ),
          isEmpty,
          reason: expected.id,
        );
      }
    },
  );

  test(
    'player visual rights records match source and runtime SHA-256 files',
    () {
      final ledger = _readCsv('docs/assets/asset-rights-ledger.csv');
      final headers = ledger.first;
      final rows = ledger
          .skip(1)
          .map((fields) => _row(headers, fields))
          .toList();
      final runtimeContracts = <String, PlayerVisualContract>{
        for (final contract in playerVisualContracts)
          contract.runtimePath: contract,
      };

      expect(runtimeContracts, hasLength(9));
      for (final entry in runtimeContracts.entries) {
        final runtimePath = entry.key;
        final expected = entry.value;
        final row = rows.singleWhere(
          (row) => row['runtime_path'] == runtimePath,
        );
        final sourcePath = expected.sourcePath;

        expect(File(sourcePath).existsSync(), isTrue, reason: runtimePath);
        expect(File(runtimePath).existsSync(), isTrue, reason: runtimePath);
        expect(row['source_file_sha256'], sourceSha256ByPath[sourcePath]);
        expect(row['notes'], contains('generated-original source=$sourcePath'));
        expect(
          row['notes'],
          contains('runtime-sha256=${runtimeSha256ByPath[runtimePath]}'),
        );
        expect(row['notes'], contains('runtime owner=AttackVisualRegistry'));
        expect(row['notes'], contains('runtime status=temporary'));
      }
    },
  );
}

Map<String, String> _row(List<String> headers, List<String> fields) {
  if (headers.length != fields.length) {
    throw FormatException(
      'ledger row has ${fields.length} fields, expected ${headers.length}',
    );
  }
  return Map<String, String>.fromIterables(headers, fields);
}

List<List<String>> _readCsv(String path) {
  final rows = <List<String>>[];
  var fields = <String>[];
  var field = StringBuffer();
  var quoted = false;
  final text = File(path).readAsStringSync();

  for (var index = 0; index < text.length; index += 1) {
    final character = text[index];
    if (character == '"') {
      if (quoted && index + 1 < text.length && text[index + 1] == '"') {
        field.write('"');
        index += 1;
      } else {
        quoted = !quoted;
      }
    } else if (character == ',' && !quoted) {
      fields.add(field.toString().trim());
      field = StringBuffer();
    } else if ((character == '\n' || character == '\r') && !quoted) {
      if (character == '\r' &&
          index + 1 < text.length &&
          text[index + 1] == '\n') {
        index += 1;
      }
      fields.add(field.toString().trim());
      if (fields.any((value) => value.isNotEmpty)) rows.add(fields);
      fields = <String>[];
      field = StringBuffer();
    } else {
      field.write(character);
    }
  }
  fields.add(field.toString().trim());
  if (fields.any((value) => value.isNotEmpty)) rows.add(fields);
  if (quoted) throw const FormatException('unterminated quoted CSV field');
  return rows;
}
