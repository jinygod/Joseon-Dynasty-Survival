import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';
import 'package:pixel_survivor/game/content/attack_visual_registry.dart';
import 'package:pixel_survivor/game/content/sprite_atlas_contract.dart';

void main() {
  test('all registered Hwando runtime sheets satisfy their PNG contracts', () {
    for (final assetKey in AttackVisualRegistry.requiredAssetKeys) {
      final runtimePath = 'assets/images/$assetKey';
      final contract = ReplaceableArtCatalog.atlases.singleWhere(
        (contract) => contract.runtimePath == runtimePath,
      );

      expect(AssetCatalog.allPaths, contains(runtimePath), reason: assetKey);
      expect(contract.runtimePath, runtimePath, reason: assetKey);

      final bytes = File(contract.runtimePath).readAsBytesSync();
      expect(contract.validatePngHeader(bytes), isEmpty, reason: assetKey);
    }
  });

  test('the Flutter asset manifest includes the Hwando VFX directory', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(
      pubspec,
      contains(RegExp(r'^\s*-\s+assets/images/vfx/\s*$', multiLine: true)),
    );
  });

  test('release Hwando renderer has no primitive or legacy atlas fallback', () {
    final source = File(
      'lib/game/components/hwando_vfx_component.dart',
    ).readAsStringSync();
    final registry = File(
      'lib/game/content/attack_visual_registry.dart',
    ).readAsStringSync();

    for (final forbidden in [
      'drawCircle',
      'drawRect',
      'drawPath',
      'weapon_effects_atlas',
    ]) {
      expect(source, isNot(contains(forbidden)), reason: forbidden);
    }
    expect(
      AttackVisualRegistry.byId('hwando_slash').status,
      AttackVisualStatus.ready,
    );
    expect(
      AttackVisualRegistry.byId('hwando_slash').layers.map((layer) => layer.id),
      ['windup', 'strike', 'recovery'],
    );
    expect(registry, contains('vfx/hwando/hwando_strike_128.png'));
  });
}
