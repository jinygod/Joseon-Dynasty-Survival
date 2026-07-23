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
        expect(layer.startFraction, 0);
        expect(layer.endFraction, 1);
        expect(AssetCatalog.effects[entry.key], entry.value.path);
        expect(atlas.runtimePath, entry.value.path);
      }
    },
  );
}
