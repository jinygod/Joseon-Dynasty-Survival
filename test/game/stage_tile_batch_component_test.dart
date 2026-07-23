import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/components/stage_tile_batch_component.dart';
import 'package:pixel_survivor/game/content/stage_visual_spec.dart';

void main() {
  const spec = StageVisualSpec(
    stageId: 'test_stage',
    seedSalt: 0x531A6E,
    tileAssetKey: 'tiles.png',
    decalAssetKey: 'decals.png',
    propAssetKey: 'props.png',
  );
  final layout = StageLayout.build(
    spec,
    seed: 3107,
    bounds: const ui.Rect.fromLTWH(0, 0, 128, 128),
  );

  Future<ui.Image> image() async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      const ui.Rect.fromLTWH(0, 0, 256, 128),
      ui.Paint()..color = const ui.Color(0xffffffff),
    );
    final picture = recorder.endRecording();
    final result = await picture.toImage(256, 128);
    picture.dispose();
    return result;
  }

  Future<Map<String, ui.Image>> imagesForAllAtlases() async {
    final tile = await image();
    final decal = await image();
    final prop = await image();
    addTearDown(tile.dispose);
    addTearDown(decal.dispose);
    addTearDown(prop.dispose);
    return {'tiles.png': tile, 'decals.png': decal, 'props.png': prop};
  }

  test('stage batch does no per-frame allocation work', () async {
    final atlas = await image();
    addTearDown(atlas.dispose);
    final component = StageTileBatchComponent(
      layout: layout,
      images: {'tiles.png': atlas},
    );

    await component.onLoad();
    final placementBefore = component.placementBuildCount;
    final batchBefore = component.batchBuildCount;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    component.update(1 / 60);
    component.render(canvas);
    component.update(1 / 60);
    component.render(canvas);
    recorder.endRecording().dispose();

    expect(component.stageId, spec.stageId);
    expect(component.placementBuildCount, placementBefore);
    expect(component.batchBuildCount, batchBefore);
    expect(component.ownsCollision, isFalse);
    expect(component.batchBuildCount, 1);
  });

  test('missing decal image retains tile and prop batches', () async {
    final images = await imagesForAllAtlases()
      ..remove('decals.png');
    final component = StageTileBatchComponent(layout: layout, images: images);

    await component.onLoad();

    expect(component.batchBuildCount, 2);
    expect(component.ownsCollision, isFalse);
  });

  test('missing prop image retains tile and decal batches', () async {
    final images = await imagesForAllAtlases()
      ..remove('props.png');
    final component = StageTileBatchComponent(layout: layout, images: images);

    await component.onLoad();

    expect(component.batchBuildCount, 2);
    expect(component.ownsCollision, isFalse);
  });

  test(
    'missing base tile image fails safely without building batches',
    () async {
      final component = StageTileBatchComponent(
        layout: layout,
        images: const {},
      );

      await component.onLoad();

      expect(component.batchBuildCount, 0);
      expect(component.ownsCollision, isFalse);
    },
  );
}
