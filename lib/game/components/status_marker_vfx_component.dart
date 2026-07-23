import 'registry_vfx_component.dart';
import '../content/attack_visual_registry.dart';

class StatusMarkerVfxComponent extends RegistryVfxComponent {
  StatusMarkerVfxComponent({
    required super.event,
    required super.spec,
    required super.images,
    super.onExpired,
  }) : super(expectedCategory: CombatVisualCategory.status);
}
