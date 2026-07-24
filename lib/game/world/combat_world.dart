import 'package:flame/components.dart';

/// The direct parent for all stage and combat presentation components.
class CombatWorld extends World {
  CombatWorld({this.onChildLifecycle, this.onChildRemoving});

  void Function(Component, ChildrenChangeType)? onChildLifecycle;
  void Function(Component)? onChildRemoving;

  /// A read-only snapshot of components owned by this world.
  List<Component> get worldComponents => List.unmodifiable(children);

  @override
  void remove(Component component) {
    onChildRemoving?.call(component);
    super.remove(component);
  }

  @override
  void removeAll(Iterable<Component> components) {
    final removalTargets = components.toList(growable: false);
    for (final component in removalTargets) {
      onChildRemoving?.call(component);
    }
    super.removeAll(removalTargets);
  }

  @override
  void removeWhere(bool Function(Component component) test) {
    removeAll(worldComponents.where(test));
  }

  @override
  void onChildrenChanged(Component child, ChildrenChangeType type) {
    super.onChildrenChanged(child, type);
    onChildLifecycle?.call(child, type);
  }
}
