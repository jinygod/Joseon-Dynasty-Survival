import 'dart:ui';

import 'package:flame/components.dart';

import '../combat/attack_visual_event.dart';
import '../components/area_vfx_component.dart';
import '../components/enemy_telegraph_vfx_component.dart';
import '../components/hwando_vfx_component.dart';
import '../components/projectile_vfx_component.dart';
import '../components/status_marker_vfx_component.dart';
import 'attack_visual_registry.dart';

class CombatVisualFactory {
  const CombatVisualFactory({required this.images});

  final Map<String, Image> images;

  PositionComponent create(AttackVisualEvent event) {
    return createFromSpec(event, AttackVisualRegistry.byId(event.effectId));
  }

  PositionComponent createFromSpec(
    AttackVisualEvent event,
    AttackVisualSpec spec,
  ) {
    _validateEventAndSpec(event, spec);
    return switch (spec.category) {
      CombatVisualCategory.hwando =>
        HwandoVfxComponent(event: event, images: images),
      CombatVisualCategory.projectile =>
        ProjectileVfxComponent(event: event, spec: spec, images: images),
      CombatVisualCategory.area =>
        AreaVfxComponent(event: event, spec: spec, images: images),
      CombatVisualCategory.telegraph =>
        EnemyTelegraphVfxComponent(event: event, spec: spec, images: images),
      CombatVisualCategory.status =>
        StatusMarkerVfxComponent(event: event, spec: spec, images: images),
    };
  }

  void _validateEventAndSpec(AttackVisualEvent event, AttackVisualSpec spec) {
    if (event.effectId != spec.effectId) {
      throw ArgumentError.value(
        event.effectId,
        'event.effectId',
        'must match spec.effectId (${spec.effectId})',
      );
    }
  }
}
