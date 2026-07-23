import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/content/attack_visual_registry.dart';
import 'package:pixel_survivor/game/content/combat_visual_factory.dart';
import 'package:pixel_survivor/game/components/area_vfx_component.dart';
import 'package:pixel_survivor/game/components/registry_vfx_component.dart';
import 'package:pixel_survivor/game/vfx_gallery_game.dart';

void main() {
  test(
    'gallery uses the registry IDs and the production visual factory',
    () async {
      final game = VfxGalleryGame(loadVisualAssets: false);
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();
      game.processLifecycleEvents();
      addTearDown(game.onDispose);

      expect(game.factory, isA<CombatVisualFactory>());
      expect(game.activeProductionComponent, isA<AreaVfxComponent>());
      expect(
        game.status.value.selectedEffectId,
        AttackVisualRegistry.effectIds.first,
      );
      expect(game.status.value.activeProductionComponentCount, 1);
      expect(game.children.whereType<AreaVfxComponent>(), hasLength(1));
    },
  );

  test(
    'gallery controls restart the selected production component safely',
    () async {
      final game = VfxGalleryGame(loadVisualAssets: false);
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();
      game.processLifecycleEvents();
      addTearDown(game.onDispose);

      game.selectEffect(AttackVisualRegistry.effectIds.last);
      game.setDirectionIndex(7);
      game.setSpeed(.5);
      game.setSpeed(double.nan);
      game.setLooping(false);
      game.update(double.nan);
      game.update(.1);

      expect(
        game.status.value.selectedEffectId,
        AttackVisualRegistry.effectIds.last,
      );
      expect(game.status.value.directionIndex, 7);
      expect(game.status.value.speed, .5);
      expect(game.status.value.looping, isFalse);
      expect(game.status.value.currentFrame, greaterThanOrEqualTo(0));
      expect(game.status.value.activeProductionComponentCount, 1);
      expect(game.children.whereType<AreaVfxComponent>(), hasLength(1));
    },
  );

  test(
    'gallery has eight normalized directions and reflects playback state',
    () async {
      final game = VfxGalleryGame(loadVisualAssets: false);
      game.onGameResize(Vector2(960, 540));
      await game.onLoad();
      game.processLifecycleEvents();
      addTearDown(game.onDispose);

      final directions = <String>{};
      for (var index = 0; index < 8; index += 1) {
        game.setDirectionIndex(index);
        game.processLifecycleEvents();
        final event =
            (game.activeProductionComponent! as RegistryVfxComponent).event;
        expect(event.direction.length, closeTo(1, .0001));
        directions.add(
          '${event.direction.x.toStringAsFixed(3)},${event.direction.y.toStringAsFixed(3)}',
        );
      }
      expect(directions, hasLength(8));

      expect(game.backgroundColor().toARGB32(), 0xff1d3344);
      game.setBackground(VfxGalleryBackground.plague);
      expect(game.backgroundColor().toARGB32(), 0xff3f4930);
      game.setBackground(VfxGalleryBackground.neutral);
      expect(game.backgroundColor().toARGB32(), 0xffd8d2c2);
      game.processLifecycleEvents();

      game.setSpeed(.25);
      game.processLifecycleEvents();
      game.update(.5);
      expect(game.status.value.currentFrame, greaterThan(0));
      game.setLooping(false);
      game.activeProductionComponent!.update(10);
      game.update(0);
      expect(game.status.value.activeProductionComponentCount, 0);
    },
  );
}
