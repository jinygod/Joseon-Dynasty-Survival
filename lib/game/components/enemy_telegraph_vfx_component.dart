import 'registry_vfx_component.dart';
import '../content/attack_visual_registry.dart';

class EnemyTelegraphVfxComponent extends RegistryVfxComponent {
  EnemyTelegraphVfxComponent({
    required super.event,
    required super.spec,
    required super.images,
    super.onExpired,
  }) : super(expectedCategory: CombatVisualCategory.telegraph);
}
