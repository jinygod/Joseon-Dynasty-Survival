import 'dart:collection';

import 'package:flame/components.dart';

import '../components/enemy_component.dart';
import '../components/enemy_projectile_component.dart';
import '../components/projectile_component.dart';

/// Identity-backed index of the combat populations mounted directly on a game.
class GamePopulationIndex {
  final HashSet<EnemyComponent> _mountedEnemies =
      HashSet<EnemyComponent>.identity();
  final HashSet<EnemyComponent> _enemies = HashSet<EnemyComponent>.identity();
  final HashSet<ProjectileComponent> _playerProjectiles =
      HashSet<ProjectileComponent>.identity();
  final HashSet<EnemyProjectileComponent> _enemyProjectiles =
      HashSet<EnemyProjectileComponent>.identity();

  late final Set<EnemyComponent> _mountedEnemiesView = UnmodifiableSetView(
    _mountedEnemies,
  );
  late final Set<EnemyComponent> _enemiesView = UnmodifiableSetView(_enemies);
  late final Set<ProjectileComponent> _playerProjectilesView =
      UnmodifiableSetView(_playerProjectiles);
  late final Set<EnemyProjectileComponent> _enemyProjectilesView =
      UnmodifiableSetView(_enemyProjectiles);

  int get enemyCount => _enemies.length;
  int get projectileCount =>
      _playerProjectiles.length + _enemyProjectiles.length;

  /// Mounted enemies, including an alive enemy awaiting lifecycle removal.
  Set<EnemyComponent> get mountedEnemies => _mountedEnemiesView;

  /// A live, read-only view. Iteration order is intentionally unspecified.
  Set<EnemyComponent> get enemies => _enemiesView;

  /// A live, read-only view. Iteration order is intentionally unspecified.
  Set<ProjectileComponent> get playerProjectiles => _playerProjectilesView;

  /// A live, read-only view. Iteration order is intentionally unspecified.
  Set<EnemyProjectileComponent> get enemyProjectiles => _enemyProjectilesView;

  /// Returns false for unrelated or already-registered components.
  bool register(Component component) {
    if (component is EnemyComponent) {
      _mountedEnemies.add(component);
      return _enemies.add(component);
    }
    return switch (component) {
      ProjectileComponent() => _playerProjectiles.add(component),
      EnemyProjectileComponent() => _enemyProjectiles.add(component),
      _ => false,
    };
  }

  /// Excludes a scheduled removal from admission counts immediately.
  bool markRemoving(Component component) => switch (component) {
    EnemyComponent() => _enemies.remove(component),
    ProjectileComponent() => _playerProjectiles.remove(component),
    EnemyProjectileComponent() => _enemyProjectiles.remove(component),
    _ => false,
  };

  /// Returns false for unrelated or already-removed components.
  bool unregister(Component component) => switch (component) {
    EnemyComponent() =>
      _enemies.remove(component) | _mountedEnemies.remove(component),
    ProjectileComponent() => _playerProjectiles.remove(component),
    EnemyProjectileComponent() => _enemyProjectiles.remove(component),
    _ => false,
  };

  void clear() {
    _mountedEnemies.clear();
    _enemies.clear();
    _playerProjectiles.clear();
    _enemyProjectiles.clear();
  }
}
