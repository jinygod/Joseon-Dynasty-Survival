import 'actor_render_sizes.dart';
import 'character_definitions.dart';
import 'enemy_definitions.dart';
import 'ids.dart';

/// Render-only dimensions for an actor.
///
/// These values deliberately do not alter collision dimensions.  They let a
/// replacement sprite have readable mobile proportions while the established
/// gameplay and save-data contracts keep their original IDs and hitboxes.
class ActorVisualSpec {
  const ActorVisualSpec({
    required this.visualSize,
    required this.groundOffsetY,
    required this.shadowWidth,
  });

  final double visualSize;
  final double groundOffsetY;
  final double shadowWidth;
}

/// Returns the presentation contract for a playable character ID.
///
/// The representative exorcist uses the new compact-casual target. Other
/// characters retain their existing visual scale until they receive their own
/// reviewed replacement art.
ActorVisualSpec playerVisualSpecFor(CharacterId id) {
  if (id == exorcistDosa) return _visualSpec(56);
  return _visualSpec(ActorRenderSizes.playerVisual);
}

/// Returns the presentation contract for an enemy ID.
///
/// Only the four representative roles receive a new target scale here. Every
/// other enemy keeps its rank-derived legacy scale, including unknown IDs so
/// a missing content record has a safe, readable rendering fallback.
ActorVisualSpec enemyVisualSpecFor(EnemyId id) => switch (id) {
  plagueRatSwarm => _visualSpec(32),
  vengefulSpirit || sakkatSpecter => _visualSpec(40),
  dokkaebi => _visualSpec(44),
  _ => _visualSpec(
    ActorRenderSizes.enemyVisualSize(
      enemyDefinitionFor(id)?.rank ?? EnemyRank.normal,
    ),
  ),
};

ActorVisualSpec _visualSpec(double visualSize) => ActorVisualSpec(
  visualSize: visualSize,
  groundOffsetY: visualSize * ActorRenderSizes.actorGroundOffsetRatio,
  shadowWidth: visualSize * ActorRenderSizes.actorShadowWidthRatio,
);
