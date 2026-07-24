import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/world/world_chunk_coordinate.dart';
import 'package:pixel_survivor/game/world/world_runtime_config.dart';

void main() {
  test('standard world is aligned to four by ten chunks', () {
    final config = WorldRuntimeConfig.standard;

    expect(config.worldSize, Vector2(2048, 5120));
    expect(config.chunkSize, 512);
    expect(config.chunkColumns, 4);
    expect(config.chunkRows, 10);
    expect(config.cameraZoom, .90);
    expect(config.maxActiveExperienceGems, 96);
  });

  test('configuration does not expose mutable vector inputs', () {
    final worldSize = Vector2(100, 200);
    final deadZone = Vector2(10, 20);
    final config = WorldRuntimeConfig(
      worldSize: worldSize,
      chunkSize: 50,
      cameraZoom: 1,
      cameraDeadZone: deadZone,
      cameraFollowSharpness: 1,
      zoneHysteresis: 1,
      maxActiveExperienceGems: 1,
    );

    worldSize.x = 999;
    deadZone.y = 999;
    final exposedWorldSize = config.worldSize..x = 777;
    final exposedDeadZone = config.cameraDeadZone..y = 777;

    expect(config.worldSize, Vector2(100, 200));
    expect(config.cameraDeadZone, Vector2(10, 20));
    expect(exposedWorldSize, Vector2(777, 200));
    expect(exposedDeadZone, Vector2(10, 777));
  });

  test('world position resolves to a stable chunk coordinate', () {
    expect(
      WorldChunkCoordinate.fromWorldPosition(
        Vector2(1025, 2561),
        chunkSize: 512,
      ),
      const WorldChunkCoordinate(2, 5),
    );
  });

  test('chunk coordinate rejects invalid and negative positions', () {
    expect(
      () => WorldChunkCoordinate.fromWorldPosition(
        Vector2(-1, 0),
        chunkSize: 512,
      ),
      throwsRangeError,
    );
    expect(
      () => WorldChunkCoordinate.fromWorldPosition(
        Vector2(double.nan, 0),
        chunkSize: 512,
      ),
      throwsRangeError,
    );
    expect(
      () =>
          WorldChunkCoordinate.fromWorldPosition(Vector2.zero(), chunkSize: 0),
      throwsArgumentError,
    );
  });
}
