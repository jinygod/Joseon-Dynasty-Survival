import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_survivor/game/combat/attack_spec.dart';
import 'package:pixel_survivor/game/combat/attack_visual_event.dart';
import 'package:pixel_survivor/game/components/area_vfx_component.dart';
import 'package:pixel_survivor/game/components/enemy_telegraph_vfx_component.dart';
import 'package:pixel_survivor/game/components/projectile_vfx_component.dart';
import 'package:pixel_survivor/game/components/registry_vfx_component.dart';
import 'package:pixel_survivor/game/components/status_marker_vfx_component.dart';
import 'package:pixel_survivor/game/content/combat_visual_factory.dart';
import 'package:pixel_survivor/game/content/attack_visual_registry.dart';

void main() {
  const factory = CombatVisualFactory(images: {});

  AttackVisualEvent eventFor(
    String effectId, {
    double duration = 1,
    double windup = 0,
  }) {
    return AttackVisualEvent.fromAttack(
      AttackInstance(
        spec: AttackSpec(
          id: effectId,
          shape: AttackShape.circle,
          damage: 0,
          range: 0,
          angleRadians: 0,
          radius: 0,
          width: 0,
          windupSeconds: windup,
          activeSeconds: duration,
          lingerSeconds: 0,
          knockback: 0,
          slowFraction: 0,
          traits: const {},
          presentation: AttackPresentation.normal,
        ),
        origin: Vector2.zero(),
        direction: Vector2(1, 0),
        sequenceIndex: 0,
      ),
    );
  }

  AttackVisualSpec specFor(
    CombatVisualCategory category, {
    String? effectId,
    List<AttackVisualLayerSpec> layers = const [],
  }) {
    return AttackVisualSpec(
      effectId: effectId ?? 'test_${category.name}',
      category: category,
      status: AttackVisualStatus.temporary,
      layers: layers,
      rotateWithDirection: false,
    );
  }

  RegistryVfxComponent componentFor(
    AttackVisualEvent event,
    AttackVisualSpec spec, {
    Map<String, ui.Image> images = const {},
    void Function()? onExpired,
  }) {
    return switch (spec.category) {
      CombatVisualCategory.projectile => ProjectileVfxComponent(
        event: event,
        spec: spec,
        images: images,
        onExpired: onExpired,
      ),
      CombatVisualCategory.area => AreaVfxComponent(
        event: event,
        spec: spec,
        images: images,
        onExpired: onExpired,
      ),
      CombatVisualCategory.telegraph => EnemyTelegraphVfxComponent(
        event: event,
        spec: spec,
        images: images,
        onExpired: onExpired,
      ),
      CombatVisualCategory.status => StatusMarkerVfxComponent(
        event: event,
        spec: spec,
        images: images,
        onExpired: onExpired,
      ),
      CombatVisualCategory.hwando => throw StateError('not a registry VFX'),
    };
  }

  RegistryVfxComponent namedComponentFor(
    CombatVisualCategory category,
    AttackVisualEvent event,
    AttackVisualSpec spec,
  ) {
    return switch (category) {
      CombatVisualCategory.projectile => ProjectileVfxComponent(
        event: event,
        spec: spec,
        images: const {},
      ),
      CombatVisualCategory.area => AreaVfxComponent(
        event: event,
        spec: spec,
        images: const {},
      ),
      CombatVisualCategory.telegraph => EnemyTelegraphVfxComponent(
        event: event,
        spec: spec,
        images: const {},
      ),
      CombatVisualCategory.status => StatusMarkerVfxComponent(
        event: event,
        spec: spec,
        images: const {},
      ),
      CombatVisualCategory.hwando => throw StateError('not a registry VFX'),
    };
  }

  Future<ui.Image> solidImage(int width, int height) async {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawRect(
      ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      ui.Paint()..color = const ui.Color(0xffffffff),
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    picture.dispose();
    return image;
  }

  Future<int> renderedPixelCount(RegistryVfxComponent component) async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder)..translate(4, 4);
    component.render(canvas);
    final picture = recorder.endRecording();
    final image = await picture.toImage(8, 8);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    picture.dispose();
    image.dispose();
    return List<int>.generate(
      bytes!.lengthInBytes ~/ 4,
      (index) => bytes.getUint8(index * 4 + 3),
    ).where((alpha) => alpha > 0).length;
  }

  test('factory dispatches each visual category', () {
    expect(
      factory.createFromSpec(
        eventFor('test_projectile'),
        specFor(CombatVisualCategory.projectile),
      ),
      isA<ProjectileVfxComponent>(),
    );
    expect(
      factory.createFromSpec(
        eventFor('test_area'),
        specFor(CombatVisualCategory.area),
      ),
      isA<AreaVfxComponent>(),
    );
    expect(
      factory.createFromSpec(
        eventFor('test_telegraph'),
        specFor(CombatVisualCategory.telegraph),
      ),
      isA<EnemyTelegraphVfxComponent>(),
    );
    expect(
      factory.createFromSpec(
        eventFor('test_status'),
        specFor(CombatVisualCategory.status),
      ),
      isA<StatusMarkerVfxComponent>(),
    );
  });

  test('factory rejects an event and spec with different IDs', () {
    expect(
      () => factory.createFromSpec(
        eventFor('test_projectile'),
        specFor(CombatVisualCategory.projectile, effectId: 'other_effect'),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('factory validates identity before delegating a Hwando spec', () {
    expect(
      () => factory.createFromSpec(
        eventFor('wrong_event'),
        specFor(CombatVisualCategory.hwando, effectId: 'hwando_slash'),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  for (final category in <CombatVisualCategory>[
    CombatVisualCategory.projectile,
    CombatVisualCategory.area,
    CombatVisualCategory.telegraph,
    CombatVisualCategory.status,
  ]) {
    test('${category.name} VFX rejects a mismatched event ID', () {
      expect(
        () => componentFor(eventFor('wrong_event'), specFor(category)),
        throwsA(isA<ArgumentError>()),
      );
    });
  }

  test('projectile VFX rejects a non-projectile spec', () {
    expect(
      () => ProjectileVfxComponent(
        event: eventFor('test_area'),
        spec: specFor(CombatVisualCategory.area),
        images: const {},
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  for (final category in <CombatVisualCategory>[
    CombatVisualCategory.projectile,
    CombatVisualCategory.area,
    CombatVisualCategory.telegraph,
    CombatVisualCategory.status,
  ]) {
    test('${category.name} VFX rejects another category spec', () {
      final wrongCategory = category == CombatVisualCategory.projectile
          ? CombatVisualCategory.area
          : CombatVisualCategory.projectile;
      expect(
        () => namedComponentFor(
          category,
          eventFor('test_${wrongCategory.name}'),
          specFor(wrongCategory),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  }

  test('non-finite dt does not poison progress or expiry', () {
    var expired = 0;
    final event = eventFor('test_projectile');
    final component = ProjectileVfxComponent(
      event: event,
      spec: specFor(CombatVisualCategory.projectile),
      images: const {},
      onExpired: () => expired += 1,
    );

    for (final dt in [double.nan, double.infinity, double.negativeInfinity]) {
      component.update(dt);
    }
    component.update(.5);

    expect(component.progress, .5);
    expect(component.progress.isFinite, isTrue);
    component.update(.5);
    component.update(1);
    expect(component.isRemoving, isTrue);
    expect(expired, 1);
  });

  for (final duration in <double>[0, -1, double.nan, double.infinity]) {
    test('terminal duration $duration expires once at terminal progress', () {
      var expired = 0;
      final component = ProjectileVfxComponent(
        event: eventFor('test_projectile', duration: duration),
        spec: specFor(CombatVisualCategory.projectile),
        images: const {},
        onExpired: () => expired += 1,
      );

      expect(component.progress, 1);
      component.update(0);
      component.update(1);

      expect(component.isRemoving, isTrue);
      expect(expired, 1);
    });
  }

  test('missing cached image renders safely without a layer sprite', () {
    final component = ProjectileVfxComponent(
      event: eventFor('test_projectile'),
      spec: specFor(
        CombatVisualCategory.projectile,
        layers: const [
          AttackVisualLayerSpec(
            id: 'trail',
            assetKey: 'missing.png',
            frameSize: 1,
            frameCount: 1,
            anchor: Anchor.center,
            priorityOffset: 0,
            startFraction: 0,
            endFraction: 1,
          ),
        ],
      ),
      images: const {},
    );
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    expect(() => component.render(canvas), returnsNormally);
    recorder.endRecording().dispose();
  });

  test('impact layer waits for its impact timing', () async {
    final image = await solidImage(1, 1);
    addTearDown(image.dispose);
    final component = ProjectileVfxComponent(
      event: eventFor('test_projectile', duration: .25, windup: .75),
      spec: specFor(
        CombatVisualCategory.projectile,
        layers: const [
          AttackVisualLayerSpec(
            id: 'impact',
            assetKey: 'impact.png',
            frameSize: 1,
            frameCount: 1,
            anchor: Anchor.center,
            priorityOffset: 0,
            startFraction: 0,
            endFraction: 1,
          ),
        ],
      ),
      images: {'impact.png': image},
    );

    component.update(.74);
    expect(await renderedPixelCount(component), 0);
    component.update(.01);
    expect(await renderedPixelCount(component), greaterThan(0));
  });

  test(
    'zero and reversed layer spans render safely with bounded frames',
    () async {
      final image = await solidImage(2, 1);
      addTearDown(image.dispose);
      final component = ProjectileVfxComponent(
        event: eventFor('test_projectile'),
        spec: specFor(
          CombatVisualCategory.projectile,
          layers: const [
            AttackVisualLayerSpec(
              id: 'zero_span',
              assetKey: 'spans.png',
              frameSize: 1,
              frameCount: 2,
              anchor: Anchor.center,
              priorityOffset: 0,
              startFraction: .5,
              endFraction: .5,
            ),
            AttackVisualLayerSpec(
              id: 'reversed_span',
              assetKey: 'spans.png',
              frameSize: 1,
              frameCount: 2,
              anchor: Anchor.center,
              priorityOffset: 1,
              startFraction: .8,
              endFraction: .2,
            ),
          ],
        ),
        images: {'spans.png': image},
      );

      component.update(.5);

      expect(await renderedPixelCount(component), greaterThan(0));
    },
  );

  for (final category in <CombatVisualCategory>[
    CombatVisualCategory.projectile,
    CombatVisualCategory.area,
    CombatVisualCategory.telegraph,
    CombatVisualCategory.status,
  ]) {
    test('${category.name} VFX expires and calls its callback once', () {
      var expired = 0;
      final event = eventFor('test_${category.name}');
      final spec = specFor(category);
      final RegistryVfxComponent component = switch (category) {
        CombatVisualCategory.projectile => ProjectileVfxComponent(
          event: event,
          spec: spec,
          images: const {},
          onExpired: () => expired += 1,
        ),
        CombatVisualCategory.area => AreaVfxComponent(
          event: event,
          spec: spec,
          images: const {},
          onExpired: () => expired += 1,
        ),
        CombatVisualCategory.telegraph => EnemyTelegraphVfxComponent(
          event: event,
          spec: spec,
          images: const {},
          onExpired: () => expired += 1,
        ),
        CombatVisualCategory.status => StatusMarkerVfxComponent(
          event: event,
          spec: spec,
          images: const {},
          onExpired: () => expired += 1,
        ),
        CombatVisualCategory.hwando => throw StateError('not a registry VFX'),
      };

      component.update(event.duration + .001);
      component.update(1);

      expect(component.isRemoving, isTrue);
      expect(expired, 1);
    });
  }
}
