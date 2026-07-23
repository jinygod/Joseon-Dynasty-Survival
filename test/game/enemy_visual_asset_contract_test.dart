import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/asset_catalog.dart';
import 'package:pixel_survivor/game/content/attack_visual_registry.dart';
import 'package:pixel_survivor/game/content/sprite_atlas_contract.dart';

void main() {
  test(
    'enemy runtime sheets have locked registry, catalog, and atlas contracts',
    () {
      const required =
          <
            String,
            ({
              CombatVisualCategory category,
              int frames,
              bool rotate,
              String path,
            })
          >{
            'enemy_poison_pool': (
              category: CombatVisualCategory.area,
              frames: 8,
              rotate: false,
              path: 'assets/images/vfx/enemy/poison_pool_128.png',
            ),
            'enemy_shockwave': (
              category: CombatVisualCategory.area,
              frames: 6,
              rotate: false,
              path: 'assets/images/vfx/enemy/shockwave_128.png',
            ),
            'enemy_spirit_scream': (
              category: CombatVisualCategory.area,
              frames: 6,
              rotate: false,
              path: 'assets/images/vfx/enemy/spirit_scream_128.png',
            ),
            'enemy_line_telegraph': (
              category: CombatVisualCategory.telegraph,
              frames: 6,
              rotate: true,
              path: 'assets/images/vfx/enemy/line_telegraph_128.png',
            ),
            'enemy_ranged_telegraph': (
              category: CombatVisualCategory.telegraph,
              frames: 6,
              rotate: true,
              path: 'assets/images/vfx/enemy/ranged_telegraph_128.png',
            ),
            'enemy_radial_telegraph': (
              category: CombatVisualCategory.telegraph,
              frames: 8,
              rotate: false,
              path: 'assets/images/vfx/enemy/radial_telegraph_128.png',
            ),
            'enemy_shield_block_flash': (
              category: CombatVisualCategory.status,
              frames: 5,
              rotate: true,
              path: 'assets/images/vfx/enemy/shield_block_flash_128.png',
            ),
            'sakkat_spirit_projectile': (
              category: CombatVisualCategory.projectile,
              frames: 4,
              rotate: true,
              path:
                  'assets/images/projectiles/enemy/sakkat_spirit_projectile_128.png',
            ),
          };
      for (final entry in required.entries) {
        final spec = AttackVisualRegistry.byId(entry.key);
        final layer = spec.layers.single;
        final atlas = ReplaceableArtCatalog.byId('${entry.key}_128');
        expect(spec.status, AttackVisualStatus.generatedReview);
        expect(spec.category, entry.value.category);
        expect(spec.rotateWithDirection, entry.value.rotate);
        expect(layer.id, 'effect');
        expect(layer.frameSize, 128);
        expect(layer.frameCount, entry.value.frames);
        expect(layer.anchor, Anchor.center);
        expect(layer.priorityOffset, 0);
        expect(layer.startFraction, 0);
        expect(layer.endFraction, 1);
        expect(AssetCatalog.effects[entry.key], entry.value.path);
        expect(atlas.runtimePath, entry.value.path);
        expect(File(entry.value.path).existsSync(), isTrue);
      }
    },
  );

  test('enemy runtime sheets have source and runtime ledger hashes', () {
    final rows = File('docs/assets/asset-rights-ledger.csv').readAsLinesSync();
    for (final id in [
      'enemy_poison_pool_128',
      'enemy_shockwave_128',
      'enemy_spirit_scream_128',
      'enemy_line_telegraph_128',
      'enemy_ranged_telegraph_128',
      'enemy_radial_telegraph_128',
      'enemy_shield_block_flash_128',
      'sakkat_spirit_projectile_128',
    ]) {
      final row = rows.singleWhere((line) => line.startsWith('$id,'));
      final columns = row.split(',');
      expect(columns[10], startsWith('art_source/generated/enemy_vfx/'));
      expect(columns[11], matches(RegExp(r'^[A-F0-9]{64}$')));
      expect(row, contains(RegExp(r'runtime-sha256=[A-F0-9]{64}')));
    }
  });
}
